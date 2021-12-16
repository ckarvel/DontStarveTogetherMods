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
  self.maxstamina = 100
  self.minstamina = 0
  self.currentstamina = self.maxstamina
  self.wants_to_sprint = false -- keeps track of button state for sprinting
  self.old_wants_to_sprint = false
  self.usingstamina = false
  -- I want:
    -- 1. empty after 12s
      -- 100 / 12 = 8.33
    -- 2. full after 45s
      -- 100 / 45 = 2.22
  -- actual values going up/down every second
  self.ratedown = 8.33
  self.rateup = 2.22
  self.needcooldown = false
  self.cooldowntask = nil
  self.time = nil
  self.sprintspeedmult = 1.55 -- in between saddle basic and walking cane
  self.gave_empty_warning = false
  self.warning_interval = 10 -- when user tries to sprint but can't
  self.disabled = false -- player aggroed enemies?
  self.invincible = false
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
function Stamina:SetMinStamina(amount)
  self.minstamina = amount
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
    self.old_wants_to_sprint = self.wants_to_sprint
    self.wants_to_sprint = flag
  end
end
----------------------------------------------------------------------
-- Increase player walkspeed
----------------------------------------------------------------------
function Stamina:BoostWalkSpeed()
  self.inst.components.locomotor:SetExternalSpeedMultiplier(self.inst, "stamina", self.sprintspeedmult)
  self.usingstamina = true
end
----------------------------------------------------------------------
-- Reset player walkspeed
----------------------------------------------------------------------
function Stamina:ResetPlayerSpeed()
  -- key param is option. here we only want to remove the "stamina" speed
  self.inst.components.locomotor:RemoveExternalSpeedMultiplier(self.inst, "stamina")
  self.usingstamina = false
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
  return amount
end
----------------------------------------------------------------------
function Stamina:GetDebugString()
  return string.format("%2.2f / %2.2f, disabled: %s, state: %s", self.currentstamina, self.maxstamina, tostring(self.disabled), tostring(self.wants_to_sprint))
end
----------------------------------------------------------------------
local function CanStaminaRegen(self)
  if self:IsFull() then
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
local function is_disabled(self)
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

  if not self:IsInvincible() then
    self.disabled = is_disabled(self) or self.needcooldown -- called every loop to update mode
    if self.disabled then
      -- if we didn't warn yet, and user is running or is trying to run, warn
      if not self.gave_empty_warning and (self.usingstamina or self.wants_to_sprint and self.old_wants_to_sprint ~= self.wants_to_sprint) then
          self.inst:PushEvent("staminawarning")
          self.gave_empty_warning = true
          self.inst:DoTaskInTime(self.warning_interval, function() self.gave_empty_warning = false end)
          self.old_wants_to_sprint = self.wants_to_sprint
      end

      self:ResetPlayerSpeed()

      if CanStaminaRegen(self) then
        self:DoDelta(self.rateup * dt, true) -- increase stamina
      end
      return
    end
  end

  -- Is pressing sprint button
  if self.wants_to_sprint then
    if is_moving(self.inst) then
      if not self.usingstamina then
        self:BoostWalkSpeed()
        self.old_wants_to_sprint = self.wants_to_sprint
      end
      self:DoDelta(-self.ratedown * dt, true) -- decrease stamina
    elseif is_working(self.inst) then
      self:ResetPlayerSpeed() -- reset speed just in case
      self.usingstamina = true
      self:DoDelta(-self.ratedown * dt, true) -- decrease stamina
    else
      self:ResetPlayerSpeed() -- reset speed just in case
    end
  -- Not pressing sprint button
  else
    if self.old_wants_to_sprint ~= self.wants_to_sprint then
      self:ResetPlayerSpeed()
      self.old_wants_to_sprint = self.wants_to_sprint
    end
  end
  if not self.usingstamina and CanStaminaRegen(self) then
    self:DoDelta(self.rateup * dt, true) -- increase stamina
  end
end
----------------------------------------------------------------------
return Stamina
