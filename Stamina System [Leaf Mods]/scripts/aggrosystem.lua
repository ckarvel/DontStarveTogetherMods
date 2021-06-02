local AggroSystem = {}
--------------------------------------------------------------------------
AggroSystem.GetTargeted = function(self, attacker)
  if not attacker or not self.inst:HasTag("player") then return end

  local guid = tostring(attacker.entity:GetGUID())
  self.aggroed_enemies[guid] = attacker
  self.has_aggro = true

  -- on enemy death it seems DropTarget() isn't called
  -- make callback here
  attacker:ListenForEvent("death", function()
    self:GetUntargeted(attacker)
  end)
  -- need this for shadow creatures
  attacker:ListenForEvent("onremove", function()
    self:GetUntargeted(attacker)
  end)
end
--------------------------------------------------------------------------
AggroSystem.GetUntargeted = function(self, attacker)
  -- this is repeatedly called
  -- lets early exit if player has no aggro
  if not self.has_aggro then return end
  if not attacker or not self.inst:HasTag("player") then return end

  local guid = tostring(attacker.entity:GetGUID())
  -- this is lua's way to say this element is deleted but its like... not actually removed...
  self.aggroed_enemies[guid] = nil

  -- GetTableSize counts the #entries whose value != nil so ^ works for getting
  -- accurate table size
  if GetTableSize(self.aggroed_enemies) == 0 then
    self.has_aggro = false
  end
end
--------------------------------------------------------------------------
-- Modifies base function for non-player entities in combat
-- targets are notified when being targeted
--------------------------------------------------------------------------
AggroSystem.EngageTarget = function(self, target, callback)
  callback(self, target)
  
  if self.inst:HasTag("player") then return end
  if target and target.components and target.components.combat then
    target.components.combat:GetTargeted(self.inst);
  end
end
--------------------------------------------------------------------------
-- Modifies base function for non-player entities in combat
--------------------------------------------------------------------------
AggroSystem.DropTarget = function(self, hasnexttarget, callback)
  -- only notifies target that theyre about to be dropped
  if not self.inst:HasTag("player") and self.target and self.target.components and self.target.components.combat then
    self.target.components.combat:GetUntargeted(self.inst);
  end

  -- does the actual target dropping
  callback(self, hasnexttarget)
end
--------------------------------------------------------------------------
AggroSystem.ModifyCombatSystem = function(self)
  self.has_aggro = false
  self.aggroed_enemies = {}

  -- player-only functions
  -- determines if player has aggro or not
  self.GetTargeted = AggroSystem.GetTargeted
  self.GetUntargeted = AggroSystem.GetUntargeted

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