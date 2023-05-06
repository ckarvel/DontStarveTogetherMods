----------------------------------------------------------------------
local function onmaxstamina(self, maxstamina)
  self.inst.replica.stamina:SetMax(maxstamina)
  self.inst.replica.stamina:SetIsFull((self.currentstamina or maxstamina) >= maxstamina)
end
----------------------------------------------------------------------
local function oncurrentstamina(self, currentstamina)
  self.inst.replica.stamina:SetCurrent(currentstamina)
  self.inst.replica.stamina:SetIsTired(currentstamina <= 0)
  self.inst.replica.stamina:SetIsFull(currentstamina >= self.maxstamina)
end
----------------------------------------------------------------------
local function onwantstosprint(self, flag)
  self.inst.replica.stamina:SetWantsToSprint(flag)
end
----------------------------------------------------------------------
local function onusingstamina(self, flag)
  self.inst.replica.stamina:SetUsingStamina(flag)
end
----------------------------------------------------------------------
local function ondisabled(self, flag)
  self.inst.replica.stamina:SetDisabled(flag)
end
----------------------------------------------------------------------
local function oninvincible(self, flag)
  self.inst.replica.stamina:SetInvincible(flag)
end
----------------------------------------------------------------------
local Stamina = Class(function(self, inst)
  self.inst = inst
  -- config
  self.maxstamina = TUNING.STAMINA.WILSON_MAX_STAMINA
    -- hunger side-effects
    -- see sleepingbag.lua and sleepingbaguser.lua
  self.hunger_tick = TUNING.STAMINA.WILSON_HUNGER_PER_TICK
  -- 1. empty after 12/15/20/25s
    -- 100 / 10 = 10
    -- 100 / 12 = 8.33
    -- 100 / 15 = 6.67
    -- 100 / 20 = 5
  -- 2. full after 60/45/30/15s
    -- 100 / 60 = 1.67
    -- 100 / 45 = 2.22
    -- 100 / 30 = 3.33
    -- 100 / 15 = 6.67
  -- actual values going up/down every second
  self.rateup = TUNING.STAMINA.WILSON_RATE_UP
  self.ratedown = TUNING.STAMINA.WILSON_RATE_DOWN
  self.sprintspeedmult = TUNING.STAMINA.WILSON_SPEED_MULT

  -- stamina data
  self.minstamina = 0
  self.currentstamina = self.maxstamina
  self.wants_to_sprint = false -- keeps track of button state for sprinting
  self.usingstamina = false
  self.needcooldown = false
  self.gave_empty_warning = false
  self.warning_interval = 5 -- when user tries to sprint but can't
  self.disabled = false -- player aggroed enemies?
  self.invincible = false
  self.debounce_count = 0
  self.has_boosted_speed = false
  self.inst:StartUpdatingComponent(self)
end,
nil,
{
  maxstamina = onmaxstamina,
  currentstamina = oncurrentstamina,
  wants_to_sprint = onwantstosprint,
  usingstamina = onusingstamina,
  disabled = ondisabled,
  invincible = oninvincible,
})
----------------------------------------------------------------------
function Stamina:ForceUpdateHUD(overtime)
  self:DoDelta(0, overtime)
end
----------------------------------------------------------------------
function Stamina:OnSave()
  return
  {
    stamina = self.currentstamina,
    maxstamina = self.save_maxstamina and self.maxstamina or nil
  }
end
----------------------------------------------------------------------
function Stamina:OnLoad(data)
  if data.maxstamina ~= nil then
    self.maxstamina = data.maxstamina
  end

  if data.invincible ~= nil then 
    self.invincible = data.invincible
  end

  if data.currentstamina ~= nil then
    self:SetValue(data.currentstamina, "file_load")
    self:ForceUpdateHUD(true)
  end
end
----------------------------------------------------------------------
function Stamina:GetPercent()
  return self.currentstamina / self.maxstamina
end
----------------------------------------------------------------------
function Stamina:SetInvincible(val)
  self.invincible = val
  self.disabled = false
  self:SetCurrentStamina(100)
end
----------------------------------------------------------------------
function Stamina:IsInvincible()
  return self.invincible
end
----------------------------------------------------------------------
function Stamina:SetCurrentStamina(amount)
  self.currentstamina = amount
end
----------------------------------------------------------------------
function Stamina:SetMaxStamina(amount)
  self.maxstamina = amount
  self.currentstamina = amount
  self:ForceUpdateHUD(true)
end
----------------------------------------------------------------------
function Stamina:MakeTired()
  self.currentstamina = 0
end
----------------------------------------------------------------------
function Stamina:IsTired()
  return self.currentstamina <= 0
end
----------------------------------------------------------------------
function Stamina:MakeFull()
  self:DoDelta(self.maxstamina, nil, nil)
end
----------------------------------------------------------------------
function Stamina:IsFull()
  return self.currentstamina >= self.maxstamina
end
----------------------------------------------------------------------
function Stamina:SetPercent(percent, overtime)
  self:SetValue(self.maxstamina * percent)
  self:DoDelta(0, overtime)
end
----------------------------------------------------------------------
function Stamina:SetWantsToSprint(flag)
  if self.wants_to_sprint ~= flag then
    self.wants_to_sprint = flag
  end
end
----------------------------------------------------------------------
function Stamina:StaminaTick()
  local hunger_tick = self.hunger_tick * 0.33
  self.inst.components.hunger:DoDelta(hunger_tick, true, true)
end
----------------------------------------------------------------------
function Stamina:BoostWalkSpeed()
  if not self.has_boosted_speed then
    self.inst.components.locomotor:SetExternalSpeedMultiplier(self.inst, "stamina", self.sprintspeedmult)
  end
  self.has_boosted_speed = true
end
----------------------------------------------------------------------
function Stamina:ResetPlayerSpeed()
  if self.has_boosted_speed then
    -- key param is option. here we only want to remove the "stamina" speed
    self.inst.components.locomotor:RemoveExternalSpeedMultiplier(self.inst, "stamina")
  end
  self.has_boosted_speed = false
end
----------------------------------------------------------------------
-- [Setter] Sets actual stamina value
-- an example cause : "file_load"
----------------------------------------------------------------------
function Stamina:SetValue(value, cause)
  local old_stamina = self.currentstamina
  -- make sure its between min and max
  self.currentstamina = math.clamp(value, self.minstamina, self.maxstamina)

  if old_stamina < self.maxstamina and self.currentstamina >= self.maxstamina then
    -- self.inst:PushEvent("staminafull")
  elseif old_stamina > 0 and self.currentstamina <= 0 then
    self:ResetPlayerSpeed()
    self.needcooldown = true
    self.inst:PushEvent("staminaempty")
    self:OnWarning()
  end

  -- 25% full so reenabled sprint ability
  if self.needcooldown and self.currentstamina >= 25 then
    self.needcooldown = false
  end
end
----------------------------------------------------------------------
-- [Event Push] Sets stamina percentage
-- overtime: True if amount is supposed to be given over time?
----------------------------------------------------------------------
function Stamina:DoDelta(amount, overtime, cause)
  if self:IsInvincible() then
    amount = self.maxstamina
  end
  local old_percent = self:GetPercent()
  self:SetValue(self.currentstamina + amount, cause)
  local new_percent = self:GetPercent()
  self.inst:PushEvent("staminadelta", { oldpercent = old_percent, newpercent = new_percent, overtime = overtime, amount = amount })

  if self.ondelta ~= nil then
    self.ondelta(self.inst, old_percent, new_percent)
  end

  if not self:IsInvincible() then
    if (new_percent < old_percent) and self.usingstamina then
      self:StaminaTick()
    end
  end

  return amount
end
----------------------------------------------------------------------
function Stamina:OnWarning()
  self.gave_empty_warning = true
  self.inst:DoTaskInTime(self.warning_interval, function() self.gave_empty_warning = false end)
end
----------------------------------------------------------------------
function Stamina:GetDebugString()
  return string.format("%2.2f / %2.2f, disabled: %s, state: %s, speedmult: %s", self.currentstamina, self.maxstamina, tostring(self.disabled), tostring(self.wants_to_sprint), tostring(self.sprintspeedmult))
end
----------------------------------------------------------------------
local function CanStaminaRegen(self)
  -- if stamina is already full OR player is still trying to run, no regen for you
  if self:IsFull() or self.wants_to_sprint then
    return false
  end
  return true
end
----------------------------------------------------------------------
local function is_dead(inst)
  if inst:HasTag("playerghost") then return true end
  return false
end
----------------------------------------------------------------------
local function is_moving(inst)
  if inst.sg:HasStateTag("moving") then return true end
  return false
end
----------------------------------------------------------------------
local function is_working(inst)
  if inst.sg:HasStateTag("working") then return true end
  return false
end
----------------------------------------------------------------------
local function is_incombat(inst)
  if inst.components.aggro then
    return inst.components.aggro:IsInCombat()
  end
  return false
end
----------------------------------------------------------------------
local function is_mounted(inst)
  if inst.components.rider then
    return inst.components.rider:IsRiding()
  end
  return false
end
----------------------------------------------------------------------
local function is_weremode(inst)
  if inst:HasTag("wereplayer") then return true end
  return false
end
----------------------------------------------------------------------
local function is_disabled(self, dt)
  self.disabled = false
  if is_incombat(self.inst) or is_mounted(self.inst) or is_weremode(self.inst) then
    self.disabled = true
  end
  return self.disabled
end
----------------------------------------------------------------------
-- MAIN LOOP
-- This is called every tick (33ms) after StartUpdatingComponent is called
----------------------------------------------------------------------
function Stamina:OnUpdate(dt)
  if is_dead(self.inst) then
    self.wants_to_sprint = false
    if self.usingstamina then
      self:ResetPlayerSpeed()
    end
    return -- exit if dead
  end

  if self:IsInvincible() then
    if self.wants_to_sprint then
      if not self.usingstamina then
        self:BoostWalkSpeed()
      end
      self.usingstamina = true
    else
      if self.usingstamina then
        self:ResetPlayerSpeed()
      end
      self.usingstamina = false
    end
    return
  end

  -- todo: listen to staminaempty to avoid unnecessary polling
  self.disabled = is_disabled(self, dt) or self.needcooldown -- called every loop to update mode

  -- Handle when stamina is emptied
  if self.disabled then
    -- if we didn't warn yet and user is trying to run, warn
    if not self.gave_empty_warning and self.wants_to_sprint then
        self.inst:PushEvent("staminawarning")
        self:OnWarning()
    end
    if self.usingstamina then
      self:ResetPlayerSpeed()
    end
    self.usingstamina = false
    if CanStaminaRegen(self) then
      self:DoDelta(self.rateup * dt, true) -- increase stamina
    end
    return -- exit here
  end

  -- handle user input
  -- determine if stamina is in use or not
  -- boost/reset speed accordingly
  -- increase/decrease stamina accordingly

  local using_stamina = false
  if not self.wants_to_sprint then
    using_stamina = false
  elseif is_moving(self.inst) or is_working(self.inst) then
    using_stamina = true
  end

  if self.usingstamina ~= using_stamina then
    if using_stamina then
      -- just started sprinting
      self:BoostWalkSpeed() -- add speed boost
      self.debounce_count = 0
    else
      -- just stopped sprinting
      -- debounce (set state after 5 ticks to make sure we stopped)
      if self.debounce_count < 5 then
        self.debounce_count = self.debounce_count + 1
        using_stamina = self.usingstamina -- sabotage if debounce not finished
      else
        self:ResetPlayerSpeed() -- remove speed boost
        self.debounce_count = 0
      end
    end
    self.usingstamina = using_stamina
  end

  if self.usingstamina then
    self:DoDelta(-self.ratedown * dt, true) -- decrease stamina
  else
    if CanStaminaRegen(self) then
      self:DoDelta(self.rateup * dt, true) -- increase stamina
    end
  end
end
----------------------------------------------------------------------
return Stamina
