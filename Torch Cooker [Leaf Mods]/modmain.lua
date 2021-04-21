----------------------------------------------------------------------
-- Cook with Torch
----------------------------------------------------------------------
local function MakeCooker(inst)
  inst:AddTag("cooker")
  if not GLOBAL.TheWorld.ismastersim then return end
  local function oncook(inst, product, chef)
    if not chef:HasTag("expertchef") then
      if chef.components.health ~= nil then
        chef.components.health:DoFireDamage(1, inst, true)
        chef:PushEvent("burnt")
      end
    end
    if inst.components.fueled ~= nil then
      inst.components.fueled:DoDelta(-.01 * inst.components.fueled.maxfuel)
    end
  end
  inst:AddComponent("cooker")
  inst.components.cooker.oncookfn = oncook
end
AddPrefabPostInit("torch", MakeCooker)
