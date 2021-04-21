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
