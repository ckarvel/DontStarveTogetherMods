local StaminaHelper = {}
--------------------------------------------------------------------------
StaminaHelper.OnStaminaDirty = function(inst)
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
--------------------------------------------------------------------------
local function SetDirty(netvar, val)
  --Forces a netvar to be dirty regardless of value
  netvar:set_local(val)
  netvar:set(val)
end
--------------------------------------------------------------------------
StaminaHelper.OnStaminaDelta = function(parent, data)
  if data.newpercent > data.oldpercent then
      --Force dirty, we just want to trigger an event on the client
      SetDirty(parent.player_classified.isstaminapulseup, true)
  elseif data.newpercent < data.oldpercent then
      --Force dirty, we just want to trigger an event on the client
      SetDirty(parent.player_classified.isstaminapulsedown, true)
  end
end
--------------------------------------------------------------------------
StaminaHelper.RegisterNetListeners = function(inst)
  if TheWorld.ismastersim then
    inst._parent = inst.entity:GetParent()
    inst:ListenForEvent("staminadelta", StaminaHelper.OnStaminaDelta, inst._parent)
  else
    inst.isstaminapulseup:set_local(false)
    inst.isstaminapulsedown:set_local(false)
    inst:ListenForEvent("staminadirty", StaminaHelper.OnStaminaDirty)
    if inst._parent ~= nil then
      inst._oldstaminapercent = inst.maxstamina:value() > 0 and inst.currentstamina:value() / inst.maxstamina:value() or 0
    end
  end
end
--------------------------------------------------------------------------
StaminaHelper.SetupNetvars = function(inst)
  --Stamina variables
  inst.currentstamina = net_ushortint(inst.GUID, "stamina.currentstamina", "staminadirty")
  inst.maxstamina = net_ushortint(inst.GUID, "stamina.maxstamina", "staminadirty")
  inst.staminapenalty = net_byte(inst.GUID, "stamina.penalty", "staminadirty")
  -- stamina pulse aka, stamina going up or down over time (regenerating)
  inst.isstaminapulseup = net_bool(inst.GUID, "stamina.dodeltaovertime(up)", "staminadirty")
  inst.isstaminapulsedown = net_bool(inst.GUID, "stamina.dodeltaovertime(down)", "staminadirty")
  inst.currentstamina:set(100)
  inst.maxstamina:set(100)
end
--------------------------------------------------------------------------
StaminaHelper.ShowStatusNumbers = function(self, callback)
  callback()
  self.lungs.num:Show()
end
--------------------------------------------------------------------------
StaminaHelper.HideStatusNumbers = function(self, callback)
  callback()
  self.lungs.num:Hide()
end
--------------------------------------------------------------------------
local function OnSetPlayerMode(self)
  print("OnSetPlayerMode")
  if self.owner.replica and self.owner.replica.stamina then
    if self.onstaminadelta == nil then
      self.onstaminadelta = function(owner, data) self:StaminaDelta(data) end
      self.inst:ListenForEvent("staminadelta", self.onstaminadelta, self.owner)
      StaminaHelper.SetStaminaPercent(self, self.owner.replica.stamina:GetPercent())
    end
  end
end
--------------------------------------------------------------------------
local function OnSetGhostMode(self)
  print("OnSetGhostMode")
  if self.onstaminadelta ~= nil then
      self.inst:RemoveEventCallback("staminadelta", self.onstaminadelta, self.owner)
      self.onstaminadelta = nil
  end
end
--------------------------------------------------------------------------
StaminaHelper.SetGhostMode = function(self, ghostmode, callback)
  print("ghostmode is")
  print(ghostmode)
  callback(self, ghostmode)
  if ghostmode then
    self.lungs:Hide()
    self.lungs:StopWarning()
    OnSetGhostMode(self)
  else
    self.lungs:Show()
    OnSetPlayerMode(self)
  end
end
--------------------------------------------------------------------------
StaminaHelper.SetStaminaPercent = function(self, pct)
  print("percent")
  print(pct)
  self.lungs:SetPercent(pct, self.owner.replica.stamina:Max())

  if pct <= 0 then
      self.lungs:StartWarning()
  else
      self.lungs:StopWarning()
  end
end
--------------------------------------------------------------------------
StaminaHelper.StaminaDelta = function(self, data)
  self:SetStaminaPercent(data.newpercent)
  if not data.overtime then
      if data.newpercent > data.oldpercent then
          self.lungs:PulseGreen()
          TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/hunger_up")
      elseif data.newpercent < data.oldpercent then
          TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/hunger_down")
          self.lungs:PulseRed()
      end
  end
end
--------------------------------------------------------------------------
return StaminaHelper
