local AURA_RADIUS = GetModConfigData("AURA_RADIUS")
----------------------------------------------------------------------
-- Expand Abigail's aggro range
----------------------------------------------------------------------
local function ExpandAggroRange(inst)
  if not GLOBAL.TheWorld.ismastersim then return end
  if inst.components ~= nil and inst.components.aura ~= nil then
    inst.components.aura.radius = AURA_RADIUS
  end
end

AddPrefabPostInit("abigail", ExpandAggroRange)
