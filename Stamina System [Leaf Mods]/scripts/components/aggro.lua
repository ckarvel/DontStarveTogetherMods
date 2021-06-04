local Aggro = Class(function(self, inst)
  self.inst = inst
  self.incombat = false
  self.enemies = { active = {}, asleep = {} }
end)
--------------------------------------------------------------------------
function Aggro:GetActiveEnemy(guid)
  return self.enemies.active[guid]
end
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
function Aggro:AddActiveEnemy(enemy)
  if not enemy then return end
  local guid = enemy.entity:GetGUID()
  if self:GetActiveEnemy(guid) ~= nil then return end

  self.enemies.active[guid] = enemy
  self.incombat = true

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
  if self:GetActiveEnemy(guid) == nil then return end

  self.inst:RemoveEventCallback("death", untargetcallback, enemy)
  self.inst:RemoveEventCallback("onremove", untargetcallback, enemy)
  self.inst:RemoveEventCallback("entitysleep", onsleepcallback, enemy)
  self.inst:RemoveEventCallback("entitywake", onwakecallback, enemy)

  self.enemies.active[guid] = nil -- lua's way to remove elements
  self.enemies.asleep[guid] = nil
end
--------------------------------------------------------------------------
return Aggro
