-- GLOBAL.CHEATS_ENABLED = true
-- GLOBAL.require("debugkeys")

-- TODO:
-- bug: Rolled-back server -> at start wendy insane -> sanity callback not triggered -> abbie can't attack nightmares
-- enhancement: abbie can attack tentacle pillar
----------------------------------------------------------------------
-- Abigail fight shadow creatures
-- NOTES:
-- AddPrefabPostInit - called once on start
-- sanitymodechanged: refers to mode change between lunacy and insanity
-- _playerlink -> this is for the quest ghosts, pipspook
-- Q's:
-- why isn't player the follower.leader?! what is follower.leader then?
----------------------------------------------------------------------

-- Among all players, find Abigail's Wendy
local function GetWendyPlayer()
  if not GLOBAL.TheWorld.ismastersim then return end
  for index, player in ipairs(GLOBAL.AllPlayers) do -- we need to find the correct wendy player
    if player:HasTag("ghostlyfriend") then
        return player
    end
  end
  return nil
end

-- Adds/removes crazy tag on Wendy sanity change which enables
-- Abigail to attack shadows or not.
local function OnSanityChange(inst, player, insane)
  if not player or not player.entity:IsVisible() then return end
  if insane then
    inst:AddTag("crazy")
  else
    inst:RemoveTag("crazy")
  end
end

-- Enables Abigail to attack shadow creatures when Wendy's insane
local function CanAttackShadowCreatures(inst)
  if not GLOBAL.TheWorld.ismastersim then return end
  player = GetWendyPlayer()
  if player then
      inst:ListenForEvent("goinsane", function(player) OnSanityChange(inst, player, true) end, player)
      inst:ListenForEvent("gosane", function(player) OnSanityChange(inst, player, false) end, player)
  end
end
AddPrefabPostInit("abigail", CanAttackShadowCreatures)

-- When toggling between defensive/aggressive Abigail, this will
-- make sure if Wendy is insane, Abigail is also insane.
local function OnGhostChangeBehavior(inst)
  if not GLOBAL.TheWorld.ismastersim then return end
  old_ghostlybond_changebehaviour = inst.components.ghostlybond.changebehaviourfn
  inst.components.ghostlybond.changebehaviourfn = function(inst, ghost)
    if inst.components.sanity:IsInsane() and not ghost:HasTag("crazy") then
        ghost:AddTag("crazy")
    end
    return old_ghostlybond_changebehaviour(inst, ghost)
  end
end
AddPrefabPostInit("wendy", OnGhostChangeBehavior)

-- Shadow/nightmare creatures rewards Wendy sanity when Abigail kills them
local function CheckIfAbigailAttacking(inst)
  if not GLOBAL.TheWorld.ismastersim then return end
  old_onkilledbyother = inst.components.combat.onkilledbyother
  inst.components.combat.onkilledbyother = function(inst, attacker)
    if attacker:HasTag("abigail") then
      player = GetWendyPlayer()
      if player then
        attacker = player
      end
    end
    old_onkilledbyother(inst, attacker)
  end
end
AddPrefabPostInit("crawlinghorror", CheckIfAbigailAttacking)
AddPrefabPostInit("terrorbeak", CheckIfAbigailAttacking)
AddPrefabPostInit("crawlingnightmare", CheckIfAbigailAttacking)
AddPrefabPostInit("nightmarebeak", CheckIfAbigailAttacking)
AddPrefabPostInit("oceanhorror", CheckIfAbigailAttacking)


