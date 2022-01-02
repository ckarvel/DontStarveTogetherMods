local Aggro = Class(function(self, inst)
  self.inst = inst
  self.enemies = { total = {}, asleep = {} }
end)
--------------------------------------------------------------------------
local untargetcallback = function(inst)
  local target = inst and inst.components.combat and inst.components.combat.target or nil
  if target and target.components.aggro then
    target.components.aggro:RemoveEnemy(inst)
  end
  -- if inst.entity ~= nil then
  --   print(inst.name..":"..tostring(inst.entity:GetGUID()).." death/onremove called")
  -- end
end
--------------------------------------------------------------------------
local onsleepcallback =  function(inst)
  local target = inst and inst.components.combat and inst.components.combat.target or nil
  if target and target.components.aggro then
    target.components.aggro:AddAsleepEnemy(inst)
  end
  -- if inst.entity ~= nil then
  --   print(inst.name..":"..tostring(inst.entity:GetGUID()).." entitysleep/enterlimbo called")
  -- end
end
--------------------------------------------------------------------------
local onwakecallback =  function(inst)
   -- for some reason, bees "wake up" when caught, so check if in limbo
  if inst:HasTag("INLIMBO") then return end -- not actually awake...
  local target = inst and inst.components.combat and inst.components.combat.target or nil
  if target and target.components.aggro then
    target.components.aggro:RemoveAsleepEnemy(inst)
  end
  -- if inst.entity ~= nil then
    --   print(inst.name..":"..tostring(inst.entity:GetGUID()).." entitywake/exitlimbo called")
    -- end
end
--------------------------------------------------------------------------
function Aggro:GetEnemy(guid)
  return self.enemies.total[guid]
end
--------------------------------------------------------------------------
function Aggro:IsInCombat()
  -- total # - sleeping # = active #
  for k,v in pairs(self.enemies.total) do
    if not v.entity:IsValid() then -- happens with bats (dst bug?)
      self.enemies.total[k] = nil
      self.enemies.asleep[k] = nil
    end
  end
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

  -- self.inst:ListenForEvent("detachchild", onsleepcallback, enemy) -- when bees are caught
  self.inst:ListenForEvent("entitysleep", onsleepcallback, enemy) -- ex. far leif
  self.inst:ListenForEvent("entitywake", onwakecallback, enemy) -- ex. close leif

  -- ex. bats (this doesn't really work because wakeup is called even when asleep... i don't get it)
  self.inst:ListenForEvent("gotosleep", onsleepcallback, enemy)
  self.inst:ListenForEvent("onwakeup", onwakecallback, enemy)

  -- ex. catching/dropping bees
  self.inst:ListenForEvent("enterlimbo", onsleepcallback, enemy)
  self.inst:ListenForEvent("exitlimbo", onwakecallback, enemy)
end
--------------------------------------------------------------------------
function Aggro:GetEnemyDebugString(enemy)
  local msg = "nil"
  if enemy == nil then return msg end
  local guid = enemy.entity and enemy.entity:GetGUID() or nil
  local combat = enemy.components.combat and enemy.components.combat:GetDebugString() or nil
  local sg = enemy.sg and enemy.sg:__tostring() or nil
  local isactive = guid and self.enemies.asleep[guid] == nil
  msg = ""
  msg = msg.."name="..enemy.name.."\n"
  msg = msg.."guid="..tostring(guid).."\n"
  msg = msg.."combat="..tostring(combat).."\n"
  msg = msg.."stategraph="..tostring(sg).."\n"
  if isactive == true then
    msg = msg.."aggro=active\n"
  else
    msg = msg.."aggro=inactive\n"
  end
  return msg
end
--------------------------------------------------------------------------
function Aggro:GetDebugString()
  local msg = "\n--- Enemy Info ---\n"
  for k,v in pairs(self.enemies.total) do
    msg = msg..self:GetEnemyDebugString(v)
    if v.components.teamleader ~= nil then
      msg = msg.."-- teammembers:\n"
      for tk,tv in pairs(v.components.teamleader.team) do
        msg = msg..self:GetEnemyDebugString(tv)
        if tv.components.teamattacker ~= nil then
          msg = msg.."teamattacker="..tv.components.teamattacker:GetDebugString().."\n"
        end
        msg = msg.."===\n"
      end
    end
    msg = msg.."-----------\n"
  end
  return msg
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

  -- self.inst:RemoveEventCallback("detachchild", onsleepcallback, enemy)
  self.inst:RemoveEventCallback("entitysleep", onsleepcallback, enemy)
  self.inst:RemoveEventCallback("entitywake", onwakecallback, enemy)

  self.inst:RemoveEventCallback("enterlimbo", onsleepcallback, enemy)
  self.inst:RemoveEventCallback("exitlimbo", onwakecallback, enemy)

  self.enemies.total[guid] = nil -- lua's way to remove elements
  self.enemies.asleep[guid] = nil
end
--------------------------------------------------------------------------
return Aggro
