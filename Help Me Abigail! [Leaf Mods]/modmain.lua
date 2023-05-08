-- TODO:
-- Future:
--  better fix for: if wendy starts at sanity 0, abbie won't be crazy.
--  Find out how to get Wendy from Abbie and vice versa
--        Because Abigail is linked with the first Wendy found on the server
----------------------------------------------------------------------
-- Abigail fight shadow creatures
-- NOTES:
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

----------------------------------------------------------------------
-- Abigail will attack shadow creatures when Wendy's insane
----------------------------------------------------------------------
local function CanAttackShadowCreatures(inst)
  if not GLOBAL.TheWorld.ismastersim then return end
  local player = GetWendyPlayer()
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
  local old_ghostlybond_changebehaviour = inst.components.ghostlybond.changebehaviourfn
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
  local old_onkilledbyother = inst.components.combat.onkilledbyother
  inst.components.combat.onkilledbyother = function(inst, attacker)
    if attacker:HasTag("abigail") then
      local player = GetWendyPlayer()
      if player then
        attacker = player
      end
    end
    old_onkilledbyother(inst, attacker)
  end
end
--- Get All Nightmare creatures ---
local NIGHTMARES =
{
  "crawlinghorror",
  "terrorbeak",
  "crawlingnightmare",
  "nightmarebeak",
  "oceanhorror"
}
for k,v in pairs(NIGHTMARES) do
  AddPrefabPostInit(v, CheckIfAbigailAttacking)
end

----------------------------------------------------------------------
-- Abigail can attack Tentacle Pillar
----------------------------------------------------------------------
local function AllowAbigailHits(inst)
  if not GLOBAL.TheWorld.ismastersim then return end
  inst:AddTag("monster") -- so abigail can attack him
  local old_onhit = inst.components.combat.onhitfn
  inst.components.combat.onhitfn = function(inst, attacker, damage)
    old_onhit(inst, attacker, damage)
    if attacker:HasTag("abigail") then
      attacker.components.combat:SetTarget(inst)
    end
  end
end
AddPrefabPostInit("tentacle_pillar", AllowAbigailHits)