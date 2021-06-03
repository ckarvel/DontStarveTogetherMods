local AggroSystem = {}
--------------------------------------------------------------------------
local untargetcallback =  function(inst)
  if not inst then return end
  local target = inst.components.combat.target
  if target and target:HasTag("player") and target.components.combat then
    target.components.combat:GetUntargeted(inst)
  end
end
--------------------------------------------------------------------------
local onsleepcallback =  function(inst)
  if not inst or not inst.components.combat.target then return end
  local target = inst.components.combat.target
  if target:HasTag("player") then
    local guid = tostring(inst.entity:GetGUID())
    local num_enemies = GetTableSize(target.components.combat.aggroed_enemies)
    if target.components.combat.aggroed_enemies[guid] ~= nil then
      num_enemies = num_enemies - 1 -- subtract sleeping enemy
    end
    target.components.combat.has_aggro = num_enemies > 0
  end
end
--------------------------------------------------------------------------
local onwakecallback =  function(inst)
  if not inst or not inst.components.combat.target then return end
  local target = inst.components.combat.target
  if target:HasTag("player") then
    target.components.combat.has_aggro = GetTableSize(target.components.combat.aggroed_enemies) > 0
  end
end
--------------------------------------------------------------------------
AggroSystem.GetTargeted = function(self, attacker)
  if not attacker then return end

  local guid = tostring(attacker.entity:GetGUID())
  if self.aggroed_enemies[guid] ~= nil then return end -- exists in our enemy list so exit

  self.aggroed_enemies[guid] = attacker
  self.has_aggro = true

  self.inst:ListenForEvent("death", untargetcallback, attacker) -- upon death, why no call to DropTarget()?
  self.inst:ListenForEvent("onremove", untargetcallback, attacker) -- shadowcreatures

  -- handle entities wake/sleep(noaggro) state
  self.inst:ListenForEvent("entitysleep", onsleepcallback, attacker)
  self.inst:ListenForEvent("entitywake", onwakecallback, attacker)
end
--------------------------------------------------------------------------
AggroSystem.GetUntargeted = function(self, attacker)
  if not attacker then return end

  local guid = tostring(attacker.entity:GetGUID())
  if self.aggroed_enemies[guid] == nil then return end -- does not exist in our enemy list so exit

  -- this is lua's way to say this element is deleted but its like... not actually removed...
  self.aggroed_enemies[guid] = nil

  -- remove our event callbacks
  self.inst:RemoveEventCallback("death", untargetcallback, attacker)
  self.inst:RemoveEventCallback("onremove", untargetcallback, attacker)
  self.inst:RemoveEventCallback("entitysleep", onsleepcallback, attacker)
  self.inst:RemoveEventCallback("entitywake", onwakecallback, attacker)

  -- GetTableSize counts the #entries whose value != nil
  self.has_aggro = GetTableSize(self.aggroed_enemies) > 0
end
--------------------------------------------------------------------------
-- Modifies base function for non-player entities in combat
-- targets are notified when being targeted
--------------------------------------------------------------------------
AggroSystem.EngageTarget = function(self, target, callback)
  -- does actual engaging
  callback(self, target)

  if target and target.components and target.components.combat then
    if target.components.combat.GetTargeted ~= nil then
      -- non-players won't have this function
      target.components.combat:GetTargeted(self.inst);
    end
  end
end
--------------------------------------------------------------------------
-- Modifies base function for non-player entities in combat
--------------------------------------------------------------------------
AggroSystem.DropTarget = function(self, hasnexttarget, callback)
  -- only notifies target that theyre about to be dropped
  if self.target and self.target.components and self.target.components.combat then
    if self.target.components.combat.GetUntargeted ~= nil then
      -- non-players won't have this function
      self.target.components.combat:GetUntargeted(self.inst);
    end
  end

  -- does the actual target dropping
  callback(self, hasnexttarget)
end
--------------------------------------------------------------------------
AggroSystem.ModifyCombatSystem = function(self)
  -- player-only data
  -- determines if player has aggro or not
  if self.inst:HasTag("player") then
    self.has_aggro = false
    self.aggroed_enemies = {}
    self.GetTargeted = AggroSystem.GetTargeted
    self.GetUntargeted = AggroSystem.GetUntargeted
  end

  -- Overrides to notify player when being engaged/dropped
  local old_engagetarget = self.EngageTarget
  self.EngageTarget = function(self, target)
    AggroSystem.EngageTarget(self, target, old_engagetarget)
  end
  local old_droptarget = self.DropTarget
  self.DropTarget = function(self, hasnexttarget)
    AggroSystem.DropTarget(self, hasnexttarget, old_droptarget)
  end
end
--------------------------------------------------------------------------
return AggroSystem