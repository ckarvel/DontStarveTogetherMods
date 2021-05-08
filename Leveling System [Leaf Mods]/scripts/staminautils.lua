local StaminaUtils = {}

StaminaUtils.OnStaminaDirty = function(inst)
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

local function SetDirty(netvar, val)
  --Forces a netvar to be dirty regardless of value
  netvar:set_local(val)
  netvar:set(val)
end

StaminaUtils.OnStaminaDelta = function(parent, data)
  if data.newpercent > data.oldpercent then
      --Force dirty, we just want to trigger an event on the client
      SetDirty(parent.player_classified.isstaminapulseup, true)
  elseif data.newpercent < data.oldpercent then
      --Force dirty, we just want to trigger an event on the client
      SetDirty(parent.player_classified.isstaminapulsedown, true)
  end
end

StaminaUtils.RegisterNetListeners = function(inst)
  if TheWorld.ismastersim then
    inst._parent = inst.entity:GetParent()
    inst:ListenForEvent("staminadelta", StaminaUtils.OnStaminaDelta, inst._parent)
  else
    inst.isstaminapulseup:set_local(false)
    inst.isstaminapulsedown:set_local(false)
    inst:ListenForEvent("staminadirty", StaminaUtils.OnStaminaDirty)
    if inst._parent ~= nil then
      inst._oldstaminapercent = inst.maxstamina:value() > 0 and inst.currentstamina:value() / inst.maxstamina:value() or 0
    end
  end
end

StaminaUtils.SetupNetvars = function(inst)
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

return StaminaUtils
