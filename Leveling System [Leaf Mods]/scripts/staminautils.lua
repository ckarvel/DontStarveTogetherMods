local StaminaUtils = {}

StaminaUtils.OnStaminaDirty = function(inst)
  if inst._parent ~= nil then
    local oldpercent = inst._oldstaminapercent
    local percent = inst.currentstamina:value() / inst.maxstamina:value()
    local data =
    {
        oldpercent = oldpercent,
        newpercent = percent,
        overtime =
            not percent > oldpercent and
            not percent < oldpercent,
    }
    inst._oldstaminapercent = percent
    inst._parent:PushEvent("staminadelta", data)
  else
    inst._oldstaminapercent = 1
  end
end

StaminaUtils.OnStaminaDelta = function(parent, data)
  print("OnStaminaDelta")
end

StaminaUtils.RegisterNetListeners = function(inst)
  if TheWorld.ismastersim then
    inst._parent = inst.entity:GetParent()
    inst:ListenForEvent("staminadelta", StaminaUtils.OnStaminaDelta, inst._parent)
  else
    inst:ListenForEvent("staminadirty", StaminaUtils.OnStaminaDirty)
  end
end

StaminaUtils.SetupNetvars = function(inst)
  --Stamina variables
  inst.currentstamina = net_ushortint(inst.GUID, "stamina.currentstamina", "staminadirty")
  inst.maxstamina = net_ushortint(inst.GUID, "stamina.maxstamina", "staminadirty")
  inst.staminapenalty = net_byte(inst.GUID, "stamina.penalty", "staminadirty")
  inst.currentstamina:set(100)
  inst.maxstamina:set(100)
end

return StaminaUtils
