----------------------------------------------------------------------
-- Cook Pinecones
----------------------------------------------------------------------
local function InGame()
  return GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD and not GLOBAL.ThePlayer.HUD:HasInputFocus()
end

PrefabFiles =
{
  "pinecone_cooked"
}

GLOBAL.STRINGS.NAMES.PINECONE_COOKED = "Toasted Pine Cone"

local function MakeCookable(inst)
  inst:AddTag("cookable")
  if not GLOBAL.TheWorld.ismastersim then return end

  inst:AddComponent("cookable")
  inst.components.cookable.product = "pinecone_cooked"
end

local PineconeTypes =
{
  "pinecone",
  "twiggy_nut"
}
for k,v in pairs(PineconeTypes) do
  AddPrefabPostInit(v, MakeCookable)
end

-- hacky way of switching actions when using pinecone over campfire
-- AFAIK only 1 actions can be shown at a time (how about LMB/RMB actions??)
-- the workaround is: "cook" action is default, while holding shift shows "add fuel" action
-- to switch actions the "cookable" component is added/removed to the pinecone
-- the "cook" action has higher priority over "add fuel" and that's why this works
-- note: if shift was used for cook, the player would have to hold shift throughout the cook animation
-- otherwise the cook would fail. that's why shift is used for add fuel which has a quick animation. 
local function server_SwitchActions(inst, flag)
  if not inst or not inst.components or not inst.components.inventory then return end -- exit
  -- is there an active item?
  local activeitem = inst.components.inventory:GetActiveItem()
  -- if so is it a pinecone or twiggy_nut?
  if not activeitem or
     activeitem.prefab ~= "pinecone" or
     activeitem.prefab ~= "twiggy_nut" then return end -- exit
  -- if false, show cook actions if not exists
  if not flag then
    if activeitem.components.cookable == nil then
      activeitem:AddComponent("cookable")
      activeitem.components.cookable.product = "pinecone_cooked"
    end
  -- if true, hide cook actions if exists
  elseif activeitem.components.cookable ~= nil then
    activeitem:RemoveComponent("cookable")
  end
end
AddModRPCHandler(modname, "SwitchActions", server_SwitchActions)

-- check activeitem if shift is pressed
local last_key_pressed = false
local function client_SwitchActions(key_pressed)
  if (last_key_pressed and key_pressed) -- if key state hasn't changed or
     or (key_pressed and not InGame()) then return end -- if game not active, exit

  SendModRPCToServer(GetModRPC(modname, "SwitchActions"), key_pressed)
  last_key_pressed = key_pressed
end

GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_LSHIFT, function(inst) client_SwitchActions(true) end)
GLOBAL.TheInput:AddKeyUpHandler(GLOBAL.KEY_LSHIFT, function(inst) client_SwitchActions(false) end)