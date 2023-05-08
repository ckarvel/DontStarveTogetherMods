----------------------------------------------------------------------
-- Among all players, find Abigail's Wendy
-- TODO:
--  1. better fix for: if wendy starts at sanity 0, abbie won't be crazy.
--  2. find out how to get Wendy from Abbie and vice versa because
--     Abigail is linked without first Wendy found on server
-- NOTES:
-- for 2: look at follower.lua where it talks about cached leader id
-- _playerlink -> this is for the quest ghosts, pipspook
-- Q's:
-- why isn't player the follower.leader?! what is follower.leader then?
-- ^^^ look that over again in follower.lua
----------------------------------------------------------------------
local function GetWendyPlayer()
  if not GLOBAL.TheWorld.ismastersim then return end
  for index, player in ipairs(GLOBAL.AllPlayers) do -- we need to find the correct wendy player
    if player:HasTag("ghostlyfriend") then
        return player
    end
  end
  return nil
end

----------------------------------------------------------------------
-- Abigail stick to Wendy like glue on paper!
---------------------------------------------------------------------
-- Stay close to Wendy
-- see tuning.lua
GLOBAL.ABIGAIL_DEFENSIVE_MIN_FOLLOW = 1
GLOBAL.ABIGAIL_DEFENSIVE_MAX_FOLLOW = 3 -- 5
GLOBAL.ABIGAIL_DEFENSIVE_MED_FOLLOW = 2 -- 3
GLOBAL.ABIGAIL_AGGRESSIVE_MIN_FOLLOW = 1 -- 3
GLOBAL.ABIGAIL_AGGRESSIVE_MAX_FOLLOW = 5 -- 10
GLOBAL.ABIGAIL_AGGRESSIVE_MED_FOLLOW = 3 -- 6
-- Maintain Wendy speed
local function MaintainWendySpeed(inst)
  if not GLOBAL.TheWorld.ismastersim then return end
  -- default: false or nil??
  inst.components.locomotor.fasteronroad = true
  -- default 5
  inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED -- 6
  -- on usingstamina event, boost speed of abigail
  local boost_speed = function(inst, player, data)
    if data.usingstamina then
      local multiplier = player.components.stamina.sprintspeedmult
      inst.components.locomotor:SetExternalSpeedMultiplier(inst, "stamina", multiplier)
    else
      inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "stamina")
    end
  end
  local player = GetWendyPlayer()
  if not player then return end
  inst:ListenForEvent("usingstamina", function(player, data) boost_speed(inst, player, data) end, player)
end
AddPrefabPostInit("abigail", MaintainWendySpeed)
----------------------------------------------------------------------
-- Enable Abigail to fight nightmare creatures
----------------------------------------------------------------------
-- Adds/removes crazy tag on Abigail which enables her to fight nightmares
local function OnSanityChange(inst, player, insane)
  if not player or not player.entity:IsVisible() then return end
  if insane then
    inst:AddTag("crazy")
  else
    inst:RemoveTag("crazy")
  end
end
-- Abigail is notified when Wendy is insane
local function TrackWendySanity(inst)
  if not GLOBAL.TheWorld.ismastersim then return end
  local player = GetWendyPlayer()
  if not player then return end
  inst:ListenForEvent("goinsane", function(player) OnSanityChange(inst, player, true) end, player)
  inst:ListenForEvent("gosane", function(player) OnSanityChange(inst, player, false) end, player)
end
AddPrefabPostInit("abigail", TrackWendySanity)
-- Maintain sanity state when toggling between passive/aggressive Abigail
local function OnAbigailChangeBehavior(inst)
  if not GLOBAL.TheWorld.ismastersim then return end
  local old_ghostlybond_changebehaviour = inst.components.ghostlybond.changebehaviourfn
  inst.components.ghostlybond.changebehaviourfn = function(inst, ghost)
    if inst.components.sanity:IsInsane() and not ghost:HasTag("crazy") then
        ghost:AddTag("crazy")
    end
    return old_ghostlybond_changebehaviour(inst, ghost)
  end
end
AddPrefabPostInit("wendy", OnAbigailChangeBehavior)
-- Reward Wendy sanity when Abigail kills nightmares
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
-- Get All Nightmare creatures which do the sanity rewarding
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
-- Enable Abigail to attack Tentacle Pillars
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
