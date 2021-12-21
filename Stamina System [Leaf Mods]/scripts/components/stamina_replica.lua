--------------------------------------------------------------------------
local Stamina = Class(function(self, inst)
  self.inst = inst

  self._istired = net_bool(inst.GUID, "stamina._istired")
  self._isfull = net_bool(inst.GUID, "stamina._isfull")
  self._wantstosprint = net_bool(inst.GUID, "stamina._wantstosprint")
  self._usingstamina = net_bool(inst.GUID, "stamina._usingstamina")
  self._disabled = net_bool(inst.GUID, "stamina._disabled")
  self._invincible = net_bool(inst.GUID, "stamina._invincible")
  if TheWorld.ismastersim then
    self.classified = inst.player_classified
  elseif self.classified == nil and inst.player_classified ~= nil then
    self:AttachClassified(inst.player_classified)
  end
end)
--------------------------------------------------------------------------
function Stamina:OnRemoveFromEntity()
  if self.classified ~= nil then
    if TheWorld.ismastersim then
      self.classified = nil
    else
      self.inst:RemoveEventCallback("onremove", self.ondetachclassified, self.classified)
      self:DetachClassified()
    end
  end
end
--------------------------------------------------------------------------
Stamina.OnRemoveEntity = Stamina.OnRemoveFromEntity
--------------------------------------------------------------------------
function Stamina:AttachClassified(classified)
  self.classified = classified
  self.ondetachclassified = function() self:DetachClassified() end
  self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)
end
--------------------------------------------------------------------------
function Stamina:DetachClassified()
  self.classified = nil
  self.ondetachclassified = nil
end
--------------------------------------------------------------------------
function Stamina:SetCurrent(current)
  if self.classified ~= nil then
    self.classified:SetValue("currentstamina", current)
  end
end
--------------------------------------------------------------------------
function Stamina:SetMax(max)
  if self.classified ~= nil then
    self.classified:SetValue("maxstamina", max)
  end
end
--------------------------------------------------------------------------
function Stamina:Max()
  if self.inst.components.stamina ~= nil then
    return self.inst.components.stamina.maxstamina
  elseif self.classified ~= nil then
    return self.classified.maxstamina:value()
  else
    return 100
  end
end
--------------------------------------------------------------------------
function Stamina:GetPercent()
  if self.inst.components.stamina ~= nil then
    return self.inst.components.stamina:GetPercent()
  elseif self.classified ~= nil then
    return self.classified.currentstamina:value() / self.classified.maxstamina:value()
  else
    return 1
  end
end
--------------------------------------------------------------------------
function Stamina:GetCurrent()
  if self.inst.components.stamina ~= nil then
    return self.inst.components.stamina.currentstamina
  elseif self.classified ~= nil then
    return self.classified.currentstamina:value()
  else        
    return 100
  end
end
--------------------------------------------------------------------------
function Stamina:SetIsTired(istired)
  self._istired:set(istired)
end
--------------------------------------------------------------------------
function Stamina:IsTired()
  return self._istired:value()
end
--------------------------------------------------------------------------
function Stamina:SetIsFull(isfull)
  self._isfull:set(isfull)
end
--------------------------------------------------------------------------
function Stamina:IsFull()
  return self._isfull:value()
end
--------------------------------------------------------------------------
function Stamina:WantsToSprint()
  return self._wantstosprint:value()
end
--------------------------------------------------------------------------
function Stamina:SetWantsToSprint(flag)
  if not flag then
    self._wantstosprint:set(false)
  else
    self._wantstosprint:set(flag)
  end
end
--------------------------------------------------------------------------
function Stamina:SetUsingStamina(flag)
  -- when flag is false, its actually nil. set(nil) crashes the game.
  -- but y tho...
  if not flag then
    self._usingstamina:set(false)
  else
    self._usingstamina:set(flag)
  end
end
--------------------------------------------------------------------------
function Stamina:IsUsingStamina()
  return self._usingstamina:value()
end
--------------------------------------------------------------------------
function Stamina:SetDisabled(flag)
  if not flag then
    self._disabled:set(false)
  else
    self._disabled:set(flag)
  end
end
--------------------------------------------------------------------------
function Stamina:IsDisabled()
  return self._disabled:value()
end
--------------------------------------------------------------------------
function Stamina:SetInvincible(flag)
  if not flag then
    self._invincible:set(false)
  else
    self._invincible:set(flag)
  end
end
--------------------------------------------------------------------------
function Stamina:IsInvincible()
  return self._invincible:value()
end
--------------------------------------------------------------------------
return Stamina
