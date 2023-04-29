local StaminaUtils = {}

--------------------------------------------------------------------------
-- NETWORKING: Netvar setup/register-listeners/updates
--------------------------------------------------------------------------

local function OnStaminaDirty(inst)
  if inst._parent ~= nil then
    local oldpercent = inst._oldstaminapercent
    local percent = inst.currentstamina:value() / inst.maxstamina:value()
    -- I don't get the overtime condition
    -- I would think if pulse is up/down, overtime = true because values are being changed over time??
    local data =
    {
      oldpercent = oldpercent,
      newpercent = percent,
      overtime =
        not (inst.isstaminapulseup:value() and percent > oldpercent) and
        not (inst.isstaminapulsedown:value() and percent < oldpercent),
    }
    inst._oldstaminapercent = percent
    inst.isstaminapulseup:set_local(false)
    inst.isstaminapulsedown:set_local(false)
    inst._parent:PushEvent("staminadelta", data)
  else
    inst._oldstaminapercent = 1
    inst.isstaminapulseup:set_local(false)
    inst.isstaminapulsedown:set_local(false)
  end
end
-----------------------------------
local function SetDirty(netvar, val)
  --Forces a netvar to be dirty regardless of value
  netvar:set_local(val)
  netvar:set(val)
end
-----------------------------------
local function OnStaminaDelta(parent, data)
  if data.newpercent > data.oldpercent then
    --Force dirty, we just want to trigger an event on the client
    SetDirty(parent.player_classified.isstaminapulseup, true)
  elseif data.newpercent < data.oldpercent then
    SetDirty(parent.player_classified.isstaminapulsedown, true)
  end
end
-----------------------------------
function StaminaUtils.RegisterNetListeners(inst)
  if TheWorld.ismastersim then
    inst._parent = inst.entity:GetParent()
    inst:ListenForEvent("staminadelta", OnStaminaDelta, inst._parent)
  else
    inst.isstaminapulseup:set_local(false)
    inst.isstaminapulsedown:set_local(false)
    inst:ListenForEvent("staminadirty", OnStaminaDirty)
    if inst._parent ~= nil then
      inst._oldstaminapercent = inst.maxstamina:value() > 0 and inst.currentstamina:value() / inst.maxstamina:value() or 0
    end
  end
end
-----------------------------------
function StaminaUtils.SetupNetvars(inst)
  --Stamina variables
  inst.currentstamina = net_ushortint(inst.GUID, "stamina.currentstamina", "staminadirty")
  inst.maxstamina = net_ushortint(inst.GUID, "stamina.maxstamina", "staminadirty")
  -- stamina pulse aka, stamina going up or down over time (regenerating)
  inst.isstaminapulseup = net_bool(inst.GUID, "stamina.dodeltaovertime(up)", "staminadirty")
  inst.isstaminapulsedown = net_bool(inst.GUID, "stamina.dodeltaovertime(down)", "staminadirty")
  inst.currentstamina:set(100)
  inst.maxstamina:set(100)
end

--------------------------------------------------------------------------
-- UI BADGE
--------------------------------------------------------------------------
function StaminaUtils.ShowHungerRate(self, args, callback)
  callback(self, args)
  if self.owner == nil or 
      self.owner.replica.hunger == nil or
      self.owner.replica.stamina == nil or
      self.arrowdir ~= "neutral" then
    return
  end
  
  -- if we're here, hunger badge is neutral, let's check if we need to update that
  local anim = self.arrowdir
  -- if hunger is above 0
  if self.owner.replica.hunger:GetPercent() > 0 then
    -- if player is sleeping OR using stamina, show arrow decrease
    if self.owner:HasTag("sleeping") or
        self.owner.replica.stamina:IsUsingStamina() then
      anim = "arrow_loop_decrease"
    end
  end
  if self.arrowdir ~= anim then
    self.arrowdir = anim
    self.hungerarrow:GetAnimState():PlayAnimation(anim, true)
  end
end
-----------------------------------
function StaminaUtils.ShowStatusNumbers(self, callback)
  callback(self)
  self.lungs.num:Show()
end
-----------------------------------
function StaminaUtils.HideStatusNumbers(self, callback)
  callback(self)
  self.lungs.num:Hide()
end
-----------------------------------
local function OnSetPlayerMode(self)
  if self.owner.replica and self.owner.replica.stamina then
    if self.onstaminadelta == nil then
      self.onstaminadelta = function(owner, data) self:StaminaDelta(data) end
      self.inst:ListenForEvent("staminadelta", self.onstaminadelta, self.owner)
      StaminaUtils.SetStaminaPercent(self, self.owner.replica.stamina:GetPercent())
    end
  end
end
-----------------------------------
local function OnSetGhostMode(self)
  if self.onstaminadelta ~= nil then
    self.inst:RemoveEventCallback("staminadelta", self.onstaminadelta, self.owner)
    self.onstaminadelta = nil
  end
end
-----------------------------------
function StaminaUtils.SetGhostMode(self, ghostmode, callback)
  callback(self, ghostmode)
  if ghostmode then
    self.lungs:Hide()
    OnSetGhostMode(self)
  else
    self.lungs:Show()
    OnSetPlayerMode(self)
  end
end
-----------------------------------
function StaminaUtils.SetStaminaPercent(self, pct)
  self.lungs:SetPercent(pct, self.owner.replica.stamina:Max())
end
-----------------------------------
function StaminaUtils.StaminaDelta(self, data)
  self:SetStaminaPercent(data.newpercent)
end
--------------------------------------------------------------------------
return StaminaUtils
