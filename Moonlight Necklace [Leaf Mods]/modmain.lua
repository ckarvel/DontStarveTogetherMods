----------------------------------------------------------------------
-- Craft cheaper Magiluminescence amulet
----------------------------------------------------------------------
GLOBAL.TUNING.MOONLACE_BUFFS = GetModConfigData("Item Buffs")

PrefabFiles =
{
	"moonlace"
}

GLOBAL.STRINGS.NAMES.MOONLACE = "Moonlace"
GLOBAL.STRINGS.RECIPE_DESC.MOONLACE = "It's not pretty but it shines."

AddRecipe("moonlace",
  {GLOBAL.Ingredient("moonrocknugget", 1), GLOBAL.Ingredient("rope", 1), GLOBAL.Ingredient("lightbulb", 1)},
  GLOBAL.RECIPETABS.LIGHT,
  GLOBAL.TECH.SCIENCE_ONE,
  nil, -- placer
  nil, -- min_spacing
  nil, -- nounlock
  nil, -- numtogive
  nil, -- builder_tag
  "images/moonlace/moonlace.xml", -- atlas
  "moonlace.tex")
