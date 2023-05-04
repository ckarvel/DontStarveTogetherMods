----------------------------------------------------------------------
-- Cook Pinecones
----------------------------------------------------------------------
PrefabFiles =
{
  "pinecone_cooked"
}

GLOBAL.STRINGS.NAMES.PINECONE_COOKED = "Toasted Pine Cone"

local function MakeCookable(inst)
  inst:AddTag("cookable")
  if not GLOBAL.TheWorld.ismastersim then
      return
  end

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
