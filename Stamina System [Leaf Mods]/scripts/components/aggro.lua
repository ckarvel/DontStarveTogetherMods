local Aggro = Class(function(self, inst)
  self.inst = inst
  self.enemies = { total = {}, asleep = {} }
end)
--------------------------------------------------------------------------
local untargetcallback = function(inst)
  local target = inst and inst.components.combat.target or nil
  if target and target.components.aggro then
    target.components.aggro:RemoveEnemy(inst)
  end
end
--------------------------------------------------------------------------
local onsleepcallback =  function(inst)
  local target = inst and inst.components.combat.target or nil
  if target and target.components.aggro then
    target.components.aggro:AddAsleepEnemy(inst)
  end
end
--------------------------------------------------------------------------
local onwakecallback =  function(inst)
  local target = inst and inst.components.combat.target or nil
  if target and target.components.aggro then
    target.components.aggro:RemoveAsleepEnemy(inst)
  end
end
--------------------------------------------------------------------------
function Aggro:GetEnemy(guid)
  return self.enemies.total[guid]
end
--------------------------------------------------------------------------
function Aggro:IsInCombat()
  -- total # - sleeping # = active #
  return GetTableSize(self.enemies.total) - GetTableSize(self.enemies.asleep) > 0
end
--------------------------------------------------------------------------
function Aggro:AddEnemy(enemy)
  if not enemy then return end
  local guid = enemy.entity:GetGUID()
  if self:GetEnemy(guid) ~= nil then return end

  self.enemies.total[guid] = enemy

  self.inst:ListenForEvent("death", untargetcallback, enemy) -- shouldn't enemy call DropTarget() here?
  self.inst:ListenForEvent("onremove", untargetcallback, enemy) -- shadowcreatures
  self.inst:ListenForEvent("entitysleep", onsleepcallback, enemy) -- far
  self.inst:ListenForEvent("entitywake", onwakecallback, enemy) -- near
end
--------------------------------------------------------------------------
function Aggro:AddAsleepEnemy(enemy)
  if not enemy then return end
  local guid = enemy.entity:GetGUID()
  self.enemies.asleep[guid] = enemy
end
--------------------------------------------------------------------------
function Aggro:RemoveAsleepEnemy(enemy)
  if not enemy then return end
  local guid = enemy.entity:GetGUID()
  self.enemies.asleep[guid] = nil
end
--------------------------------------------------------------------------
function Aggro:RemoveEnemy(enemy)
  if not enemy then return end
  local guid = enemy.entity:GetGUID()
  if self:GetEnemy(guid) == nil then return end

  self.inst:RemoveEventCallback("death", untargetcallback, enemy)
  self.inst:RemoveEventCallback("onremove", untargetcallback, enemy)
  self.inst:RemoveEventCallback("entitysleep", onsleepcallback, enemy)
  self.inst:RemoveEventCallback("entitywake", onwakecallback, enemy)

  self.enemies.total[guid] = nil -- lua's way to remove elements
  self.enemies.asleep[guid] = nil
end
--------------------------------------------------------------------------
return Aggro
