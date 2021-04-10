GLOBAL.CHEATS_ENABLED = true
GLOBAL.require("debugkeys")
----------------------------------------------------------------------
-- Debug: Enable ctrl-r for resetting world
----------------------------------------------------------------------
AddSimPostInit(function()
  if GLOBAL.TheWorld.ismastersim then
      GLOBAL.TheWorld:PushEvent("ms_setseasonsegmodifier", {day = 2, dusk = 0, night = 0})
  end
GLOBAL.TheInput:AddKeyHandler(
function(key, down)
  if not down then return end -- Only trigger on key press
  -- Require CTRL for any debug keybinds
  if GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_CTRL) then
     -- Load latest save and run latest scripts
    if key == GLOBAL.KEY_R then
      if GLOBAL.TheWorld.ismastersim then
        GLOBAL.c_reset()
      else
        GLOBAL.TheNet:SendRemoteExecute("c_reset()")
      end
    end
  end
end)
end)
----------------------------------------------------------------------
-- Turn off miner's hat with keybind
----------------------------------------------------------------------
local toggle_on = false
---
local function LightToggle(player)
  if not player or not player.components or not player.components.inventory then
    print("LightToggle::Unexpected NIL value!")
    return
  end
  -- does player have a light source gear equipped?
  local hat = player.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HEAD)
  if not hat or not hat.components or hat.prefab ~= "minerhat" then
    return
  end
  -- turn light on/off depending on toggle_on state
  if toggle_on and hat.components.equippable then
    print("Turning on light source for -> "..hat.prefab)
    hat.components.equippable.onequipfn(hat)
  elseif not toggle_on and hat.components.inventoryitem then
    print("Turning off light source for -> "..hat.prefab)
    hat.components.inventoryitem.ondropfn(hat)
  end
  -- reset toggle state
  toggle_on = not toggle_on
end
------
AddModRPCHandler("LightToggleRPC", "LightToggle", LightToggle)
------
local function SendLightToggleRPC()
  SendModRPCToServer(GetModRPC("LightToggleRPC", "LightToggle"))
end
------
GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_T, SendLightToggleRPC)
----------------------------------------------------------------------
----------------------------------------------------------------------
