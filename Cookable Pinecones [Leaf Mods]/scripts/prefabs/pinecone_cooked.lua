local assets =
{
    Asset("ANIM", "anim/pinecone_cooked.zip"),
    Asset("ATLAS", "images/pinecone_cooked/pinecone_cooked.xml"),
    Asset("IMAGE", "images/pinecone_cooked/pinecone_cooked.tex")
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("pinecone_cooked")
    inst.AnimState:SetBuild("pinecone_cooked")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "small", 0.1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("edible")
    inst.components.edible.hungervalue = TUNING.CALORIES_TINY
    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.foodtype = "SEEDS"

    inst:AddComponent("tradable")

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "pinecone_cooked"
    inst.components.inventoryitem.atlasname = "images/pinecone_cooked/pinecone_cooked.xml"

    inst:AddComponent("forcecompostable")
    inst.components.forcecompostable.brown = true

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("pinecone_cooked", fn, assets)