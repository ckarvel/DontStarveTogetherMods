print("=====================================")
GLOBAL.CHEATS_ENABLED = true
GLOBAL.require("debugkeys")

-- this is good for detecting if shift is being used for like typing or something
local function InGame()
  return GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD and not GLOBAL.ThePlayer.HUD:HasInputFocus()
end
----------------------------------------------------------------------
-- Add Stamina
  -- Shift to increase speed by 100% for 5 seconds
  -- Cooldown starting at 1 minute
  -- Options to detect if user's not trying to sprint?
    -- 1. Player wants to sprint if running (sg::"run_state")
      -- add delay before sprint then to make sure this is what they want
----------------------------------------------------------------------
AddReplicableComponent("stamina")

local function WantsToSprint()
  print("WantsToSprint")
  if not InGame() then return print("Not in game") end
  print("InGame")
  local player = GLOBAL.ThePlayer
  if player and player.replica and player.replica.stamina then
    print("===============================================")
    print("player:"..player.prefab.." has valid stamina replica")
    -- if player.sg:HasStateTag("running") then
    --   print("Stamina::OnUpdate")
    --   -- player.components.stamina:OnUpdate()
    -- end
  end
end

GLOBAL.TUNING.WILSON_STAMINA = 100
GLOBAL.TUNING.STAMINA_PENALTY = 0.25
GLOBAL.TUNING.MAXIMUM_STAMINA_PENALTY = 0.75
local SPRINTKEY = GetModConfigData("SPRINTKEY")
GLOBAL.TheInput:AddKeyDownHandler(SPRINTKEY, WantsToSprint)

local StaminaUtils = GLOBAL.require("staminautils")

----------------------------------------------------------------------
-- Add stamina netvars to player classified
----------------------------------------------------------------------
local function AddStaminaClassified(inst)
  if not GLOBAL.TheWorld.ismastersim then return end
  StaminaUtils.SetupNetvars(inst)
  inst:DoTaskInTime(0, StaminaUtils.RegisterNetListeners)
end
---
AddPrefabPostInit("player_classified", AddStaminaClassified)

----------------------------------------------------------------------
-- Add stamina component to all player prefabs
----------------------------------------------------------------------
local function AddStaminaToMisc(inst)
  -- uh, I'm guessing I have to do this?
  if inst.components.trader and inst.components.trader.onaccept then
    local old_onaccept = inst.components.trader.onaccept

    -- add stamina penalty when player revives
    inst.components.trader.onaccept = function(inst, giver, item)
      if item ~= nil and item.prefab == "reviver" and inst:HasTag("playerghost") then
        inst.components.stamina:DeltaPenalty(GLOBAL.TUNING.STAMINA_PENALTY)
      end
      old_onaccept()
    end

  end
end
---
local function AddStaminaComponent(inst)
  if not GLOBAL.TheWorld.ismastersim then return end
  inst:AddComponent("stamina")
  inst.components.stamina:SetMaxStamina(GLOBAL.TUNING.WILSON_STAMINA)
  -- inst.components.stamina:StartRegen(1, 1)
  inst.components.stamina.save_maxstamina = true

  AddStaminaToMisc(inst)
end
---
AddPlayerPostInit(AddStaminaComponent)

----------------------------------------------------------------------
print("=====================================")
----------------------------------------------------------------------
