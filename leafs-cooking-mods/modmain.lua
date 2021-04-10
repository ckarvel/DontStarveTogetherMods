-- GLOBAL.CHEATS_ENABLED = true
-- GLOBAL.require("debugkeys")


----------------------------------------------------------------------
-- Cook Pinecones
----------------------------------------------------------------------
local FOODTYPE = GLOBAL.FOODTYPE
local function MakeCookable(inst)
  inst:AddTag("icebox_valid")
  inst:AddTag("show_spoilage")
  inst:AddTag("cookable")
  if not GLOBAL.TheWorld.ismastersim then
      return
  end
  inst:RemoveComponent("fuel")
  inst:AddComponent("cookable")
  inst.components.cookable.product = "seeds_cooked"
  inst:AddComponent("edible")
  inst.components.edible.hungervalue = TUNING.CALORIES_TINY
  inst.components.edible.healthvalue = TUNING.HEALING_TINY
  inst.components.edible.foodtype = FOODTYPE.RAW
end
AddPrefabPostInit("pinecone", MakeCookable)


----------------------------------------------------------------------
-- Cook with Torch
----------------------------------------------------------------------
local function MakeCooker(inst)
  inst:AddTag("cooker")

  if not GLOBAL.TheWorld.ismastersim then
    return
  end
  local function oncook(inst, product, chef)
    if not chef:HasTag("expertchef") then
      --burn
      if chef.components.health ~= nil then
        chef.components.health:DoFireDamage(1, inst, true)
        chef:PushEvent("burnt")
      end
    elseif inst.components.fueled ~= nil then
      inst.components.fueled:DoDelta(-.01 * inst.components.fueled.maxfuel)
    end
  end

  inst:AddComponent("cooker")
  inst.components.cooker.oncookfn = oncook
end
AddPrefabPostInit("torch", MakeCooker)


----------------------------------------------------------------------
-- Add Seeds and Toasted Seeds to Cookpot
----------------------------------------------------------------------
AddIngredientValues({"seeds"}, {seed=1}, true)
AddIngredientValues({"seeds_cooked"}, {seed=1}, true)


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

local Action = GLOBAL.Action
local ActionHandler = GLOBAL.ActionHandler

local function onextract(inst, doer)
  if inst and inst:HasTag("extractable") then
    local item = doer.components.inventory:RemoveItem(inst)
    doer.components.inventory:GiveItem(GLOBAL.SpawnPrefab("seeds"))
    item:Remove()
  end
end
-- wtf is "right". It comes out to be false. I thought it was like the right mouse button
AddComponentAction("INVENTORY", "extractable", function(inst, doer, actions, right)
  if inst:HasTag("extractable") then
    table.insert(actions, GLOBAL.ACTIONS.EXTRACT)
  end
end)

AddStategraphActionHandler("wilson", ActionHandler(EXTRACT, "dolongaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(EXTRACT, "dolongaction"))

--- Define Extractable objects---
local EXTRACTABLE =
{
  "acorn",
  "pinecone"
}

local function SetExtractable(inst)
	if not GLOBAL.TheWorld.ismastersim then return end
	inst:AddComponent('extractable')
	inst.components.extractable:SetOnExtract(onextract)
end

for k,v in pairs(EXTRACTABLE) do
  AddPrefabPostInit(v, SetExtractable)
end

----------------------------------------------------------------------