local assets =
{
    Asset("ANIM",  "anim/moonlace.zip"),
    Asset("ATLAS", "images/moonlace/moonlace.xml"),
    Asset("IMAGE", "images/moonlace/moonlace.tex")
}

local function turnon_moonlace(inst)
    local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
    -- spawn the aura of light
    if not inst.components.fueled:IsEmpty() then
        if inst._light == nil or not inst._light:IsValid() then
            inst._light = SpawnPrefab("yellowamuletlight")
            if owner ~= nil then
                inst._light.entity:SetParent(owner.entity)
            end
        end
    -- start using fuel
    inst.components.fueled:StartConsuming()
    end
end

local function turnoff_moonlace(inst)
    -- stop using fuel
    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end

    -- remove aura of light
    if inst._light ~= nil then
        if inst._light:IsValid() then
            inst._light:Remove()
        end
        inst._light = nil
    end
end

local function onequip_moonlace(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "moonlace", "moonlace")

    turnon_moonlace(inst)

    if owner.components.bloomer ~= nil then
        owner.components.bloomer:PushBloom(inst, "shaders/anim.ksh", 1)
    else
        owner.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    end
end

local function onunequip_moonlace(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")

    turnoff_moonlace(inst)

    if owner.components.bloomer ~= nil then
        owner.components.bloomer:PopBloom(inst)
    else
        owner.AnimState:ClearBloomEffectHandle()
    end
end

local function takefuel_moonlace(inst)
    if inst.components.equippable ~= nil and inst.components.equippable:IsEquipped() then
        turnon_moonlace(inst)
    end
end

local function moonlace()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("moonlace") -- name of animation folder
    inst.AnimState:SetBuild("moonlace") -- name of spriter project
    inst.AnimState:PlayAnimation("idle") -- animation name

    inst.foleysound = "dontstarve/movement/foley/jewlery"

    MakeInventoryFloatable(inst, "med", nil, 0.6)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("equippable")
    if EQUIPSLOTS["NECK"] ~= nil then
        inst.components.equippable.equipslot = EQUIPSLOTS.NECK
    else
        inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    end
    inst.components.equippable:SetOnEquip(onequip_moonlace)
    inst.components.equippable:SetOnUnequip(onunequip_moonlace)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = true
    inst.components.inventoryitem.imagename = "moonlace"
    inst.components.inventoryitem.atlasname = "images/moonlace/moonlace.xml"
    inst.components.inventoryitem:SetOnDroppedFn(turnoff_moonlace)

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.CAVE
    inst.components.fueled:InitializeFuelLevel(TUNING.LANTERN_LIGHTTIME)
    inst.components.fueled:SetDepletedFn(turnoff_moonlace)
    inst.components.fueled:SetTakeFuelFn(takefuel_moonlace)
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
    inst.components.fueled.accepting = true

    MakeHauntableLaunch(inst)

    inst._light = nil
    inst.OnRemoveEntity = turnoff_moonlace

    return inst
end

return  Prefab("moonlace", moonlace, assets, { "yellowamuletlight" })
