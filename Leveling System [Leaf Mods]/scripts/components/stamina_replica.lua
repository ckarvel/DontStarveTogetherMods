--------------------------------------------------------------------------
local Stamina = Class(function(self, inst)
  self.inst = inst

  self._istired = net_bool(inst.GUID, "stamina._istired")
  self._isfull = net_bool(inst.GUID, "stamina._isfull")
  self._issprinting = net_bool(inst.GUID, "stamina._issprinting")
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
--Client helpers
--------------------------------------------------------------------------
local function GetPenaltyPercent_Client(self)
  return self.classified.staminapenalty:value() / 200
end

local function MaxWithPenalty_Client(self)
  return self.classified.maxstamina:value() * (1 - GetPenaltyPercent_Client(self))
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
function Stamina:SetPenalty(penalty)
  if self.classified ~= nil then
    assert(penalty >= 0 and penalty <= 1, "Player staminapenalty out of range: "..tostring(penalty))
    self.classified.staminapenalty:set(math.floor(penalty * 200 + .5))
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
function Stamina:MaxWithPenalty()
  if self.inst.components.stamina ~= nil then
    return self.inst.components.stamina:GetMaxWithPenalty()
  elseif self.classified ~= nil then
    return MaxWithPenalty_Client(self)
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
function Stamina:GetPenaltyPercent()
  if self.inst.components.stamina ~= nil then
    return self.inst.components.stamina:GetPenaltyPercent()
  elseif self.classified ~= nil then
    return GetPenaltyPercent_Client(self)
  else
    return 0
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
function Stamina:SetIsSprinting(flag)
  -- when flag is false, its actually nil. set(nil) crashes the game.
  -- but y tho...
  if not flag then
    self._issprinting:set(false)
  else
    self._issprinting:set(flag)
  end
end
--------------------------------------------------------------------------
function Stamina:IsSprinting()
  return self._issprinting:value()
end
--------------------------------------------------------------------------
return Stamina
