----------------------------------------------------------------------
-- Add Stamina
  -- Shift to increase speed by 100% for 5 seconds
  -- Cooldown starting at 1 minute
  -- Options to detect if user's not trying to sprint?
    -- 1. Player wants to sprint if running (sg::"run_state")
      -- add delay before sprint then to make sure this is what they want
----------------------------------------------------------------------
AddReplicableComponent("stamina")
----------------------------------------------------------------------
-- CLIENT->SERVER COMMS
-- Clients send to Server through RPCs
-- Server send to Client through netvars
----------------------------------------------------------------------
local function InGame()
  return GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD and not GLOBAL.ThePlayer.HUD:HasInputFocus()
end
---
local function IsSprinting(inst, flag)
	if inst and inst.components and inst.components.stamina then
    inst.components.stamina:SetIsSprinting(flag)
  end
end
AddModRPCHandler(modname, "IsSprinting", IsSprinting)
---
local key_pressed = false
local function SendSprintRPC(press)
  -- if key state hasn't changed or
  -- if game not active, don't send request
  if (key_pressed and press) or (press and not InGame()) then return end

  --note: if press == false and game not active, I'll send the request
	SendModRPCToServer(GetModRPC(modname, "IsSprinting"), press)

  -- keep track of key state
  key_pressed = press
end
---
local SPRINTKEY = GetModConfigData("SPRINTKEY")
GLOBAL.TheInput:AddKeyDownHandler(SPRINTKEY, function(inst) SendSprintRPC(true) end)
GLOBAL.TheInput:AddKeyUpHandler(SPRINTKEY, function(inst) SendSprintRPC(false) end)
----------------------------------------------------------------------
local StaminaHelper = GLOBAL.require("staminahelper")
----------------------------------------------------------------------
-- NETVARS
-- Add stamina netvars to player classified
----------------------------------------------------------------------
local function AddStaminaClassified(inst)
  -- WARNING: some of this code needs to be run on the client
  -- if by mistake, you force it to only run on the server, side effects will occur.
  -- in my case, the UI badge values, like hunger, will not update.
  StaminaHelper.SetupNetvars(inst)
  inst:DoTaskInTime(0, StaminaHelper.RegisterNetListeners)
end
---
AddPrefabPostInit("player_classified", AddStaminaClassified)
----------------------------------------------------------------------
-- APPLY TO PLAYER PREFABS
-- Add stamina component to all player prefabs
----------------------------------------------------------------------
GLOBAL.TUNING.WILSON_STAMINA = 100
GLOBAL.TUNING.STAMINA_PENALTY = 0.25
GLOBAL.TUNING.MAXIMUM_STAMINA_PENALTY = 0.75
---
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

