----------------------------------------------------------------------
-- Extract Seeds from Pinecone
----------------------------------------------------------------------
local EXTRACT = AddAction("EXTRACT", "Extract", function(act)
  local item = act.invobject
  if item.components.extractable then
    item.components.extractable:OnExtract(act.doer)
    return true
  end
end)
EXTRACT.priority = 2

-- Pinecones and acorns can be extracted if in inventory
AddComponentAction("INVENTORY", "extractable", function(inst, doer, actions, right)
  if inst:HasTag("extractable") then
    table.insert(actions, GLOBAL.ACTIONS.EXTRACT)
  end
end)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(EXTRACT, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(EXTRACT, "dolongaction"))
----------------------------------------------------------------------
-- Compatibility with any mod that modifies the "pick" action length
-- this will apply the same to "extract"
----------------------------------------------------------------------
AddPlayerPostInit(function(inst)
  if not GLOBAL.TheWorld.ismastersim then return end -- exit
  -- see details for all this in stategraph.lua
  local sg = inst.sg.sg -- the first sg type is "StateGraphInstance"
  if not sg.actionhandlers then return end -- exit
  
  -- from "pick" actionhandler, get actionlength
  local handler = sg.actionhandlers[GLOBAL.ACTIONS.PICK]
  if not handler or not handler.deststate then return end -- exit

  -- WARNING: this doesn't work when pick is not modded. action is nil. idky. execution order?
  -- for now, let's do a try-catch, or in lua terms, a "pcall"
  local success, result = GLOBAL.pcall(function()
    return handler.deststate(inst)
  end)
  if not success then return end  -- exit

  -- apply the same actionlength as "pick" to handler for "extract"
  handler = sg.actionhandlers[EXTRACT]
  handler.deststate = function(inst) return result end
end)
----------------------------------------------------------------------
--- Define Extractable objects and result (remove/replace with randomseed)
----------------------------------------------------------------------
local EXTRACTABLE =
{
  "acorn", -- birchnut
  "pinecone",
  "twiggy_nut"
}
local function onextract(inst, doer)
  if inst and inst:HasTag("extractable") then
    doer.components.inventory:RemoveItem(inst):Remove()
    -- the "stack increase" sound plays if a pos is passed to "GiveItem"
    -- otherwise the sound doesn't play when stacksize > 0
    -- not sure why pos triggers it
    local pos = GLOBAL.Vector3(doer.Transform:GetWorldPosition())
    doer.components.inventory:GiveItem(GLOBAL.SpawnPrefab("seeds"), nil, pos)
  end
end
local function SetExtractable(inst)
	if not GLOBAL.TheWorld.ismastersim then return end
	inst:AddComponent('extractable')
	inst.components.extractable:SetOnExtract(onextract)
end
for k,v in pairs(EXTRACTABLE) do
  AddPrefabPostInit(v, SetExtractable)
end
----------------------------------------------------------------------
-- Add All Seed types and Toasted Seeds to Cookpot
----------------------------------------------------------------------
local seed_types =
{
  "watermelon_seeds",
  "onion_seeds",
  "potato_seeds",
  "asparagus_seeds",
  "durian_seeds",
  "dragonfruit_seeds",
  "pomegranate_seeds",
  "tomato_seeds",
  "pepper_seeds",
  "eggplant_seeds",
  "garlic_seeds",
  "corn_seeds",
  "pumpkin_seeds",
  "carrot_seeds",
  "seeds",
  "seeds_cooked"
}
for k,v in pairs(seed_types) do
  AddIngredientValues({v}, {seed=1}, true)
end
