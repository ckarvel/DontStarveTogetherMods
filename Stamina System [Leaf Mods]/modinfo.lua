name = "Stamina System [Leaf Mods]"
description = "Use stamina to run faster"
author = "amoryleaf"
version = "1.2.0"

forumthread = ""

api_version = 10

icon_atlas = "modicon.xml"
icon = "modicon.tex"

dont_starve_compatible = false
reign_of_giants_compatible = false
dst_compatible = true

all_clients_require_mod = true
clients_only_mod = false

local function add_option(desc, result)
  return {description = desc, data = result}
end

-- KEY_SHIFT doesn't work...
local KEY_RSHIFT = 303 -- use KEY_SHIFT instead
local KEY_LSHIFT = 304 -- use KEY_SHIFT instead
local KEY_RCTRL = 305 -- use KEY_CTRL instead
local KEY_LCTRL = 306 -- use KEY_CTRL instead
local KEY_RALT = 307 -- use KEY_ALT instead
local KEY_LALT = 308 -- use KEY_ALT instead

local keyslist = {
  add_option("Right Shift", KEY_RSHIFT),
  add_option("Left Shift", KEY_LSHIFT),
  add_option("Right Ctrl", KEY_RCTRL),
  add_option("Left Ctrl", KEY_LCTRL),
  add_option("Right Alt", KEY_RALT),
  add_option("Left Alt", KEY_LALT)
}

-- WILSON_RUN_SPEED = 6 (base)
-- CANE_SPEED_MULT = 1.25
-- GHOSTLYELIXIR_SPEED_LOCO_MULT = 1.75
-- ROGUEWAVE_SPEED_MULTIPLIER = 3

-- BEEFALO_RUN_SPEED = (base)
-- {
--     DEFAULT = 7,
--     RIDER = 8.0,
--     ORNERY = 7.0,
--     PUDGY = 6.5,
-- },
-- SADDLE_WAR_SPEEDMULT = 1.25
-- SADDLE_BASIC_SPEEDMULT = 1.4
-- SADDLE_RACE_SPEEDMULT = 1.55
-- fastest beefalo: Rider * SADDLE_RACE_SPEEDMULT = 12.4

-- 6 * 1.33 = ~8 (Rider runspeed)
-- 6 * 1.55 = 9.3 (Elite Pig runspeed)
-- 6 * 1.75 = 10.5 (Wilson drinks Vigor Mortis)
-- 6 * 2.06 = ~12.4 (Rider with Race Saddle)
-- 6 * 3 = 18 (Minotaur runspeed)

local speedlist = {
  add_option("Rider Beefalo", 1.33),
  add_option("Elite Pig", 1.55),
  add_option("Vigor Mortis", 1.75),
  add_option("Racer Beefalo", 2.06),
  add_option("Minotaur", 3)
}

local rechargelist = {
  add_option("Slow", 1.67),
  add_option("Default", 2.22),
  add_option("Fast", 3.33),
  add_option("Faster", 6.67)
}

local ratedownlist = {
  add_option("Fast", 10),
  add_option("Default", 8.33),
  add_option("Slow", 6.67),
  add_option("Slower", 5)
}

local hungercostlist = {
  add_option("Less", -0.05),
  add_option("Default", -0.15),
  add_option("More", -0.30),
}

local maxstaminalist = {
  add_option("Less", 100),
  add_option("Default", 150),
  add_option("More", 200),
}

local function AddConfig(name, label, options, default, hover)
  return {name = name, label = label, options = options, default = default, hover = hover or ""}
end

configuration_options =
{
  AddConfig("SPRINTKEY", "Sprint Button", keyslist, KEY_LSHIFT, "Hold down this key to sprint."),
  AddConfig("SPRINTSPEED", "Sprint Speed", speedlist, 1.55, "Rider Beefalo=1.33x Elite Pig=1.55x (default) Vigor Mortis=1.75x Racer Beefalo=2x Minotaur=3x"),
  AddConfig("SPRINTRATEUP", "Recharge Speed", rechargelist, 2.22, "How quickly stamina is regenerated."),
  AddConfig("SPRINTRATEDOWN", "Diminish Speed", ratedownlist, 8.33, "How quickly you run out of stamina."),
  AddConfig("HUNGERPERTICK", "Hunger Cost", hungercostlist, -0.15, "Hunger cost when sprinting."),
  AddConfig("MAXSTAMINA", "Max Stamina", maxstaminalist, 150, "How much stamina do you want?"),
}
