GLOBAL.CHEATS_ENABLED = true
GLOBAL.require("debugkeys")
----------------------------------------------------------------------
-- Add Stamina
  -- Shift to increase speed by 100% for 5 seconds
  -- Cooldown starting at 1 minute
  -- Options to detect if user's not trying to sprint?
    -- 1. Player wants to sprint if running (sg::"run_state")
      -- add delay before sprint then to make sure this is what they want
----------------------------------------------------------------------
GLOBAL.TUNING.WILSON_STAMINA = 100
GLOBAL.TUNING.STAMINA_PENALTY = 0.25
GLOBAL.TUNING.MAXIMUM_STAMINA_PENALTY = 0.75
local SPRINTKEY = GetModConfigData("SPRINTKEY")
AddReplicableComponent("stamina")
----------------------------------------------------------------------
-- Clients send to Server through RPCs
-- Server send to Client through netvars
----------------------------------------------------------------------
local function InGame()
  return GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD and not GLOBAL.ThePlayer.HUD:HasInputFocus()
end
---
local function IsSprinting(inst, flag)
  if not InGame() then return end
	if inst and inst.components and inst.components.stamina then
    print("===============================================")
    print("Setting IsSprinting to")
    print(flag)
    inst.components.stamina:SetIsSprinting(flag)
  end
end
AddModRPCHandler(modname, "IsSprinting", IsSprinting)
---
local function SendSprintRPC(flag)
	SendModRPCToServer(GetModRPC(modname, "IsSprinting"), flag)
end
---
GLOBAL.TheInput:AddKeyDownHandler(SPRINTKEY, function(inst) SendSprintRPC(true) end)
GLOBAL.TheInput:AddKeyUpHandler(SPRINTKEY, function(inst) SendSprintRPC(false) end)
----------------------------------------------------------------------
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
  AddStaminaToMisc(inst)
end
---
AddPlayerPostInit(AddStaminaComponent)

