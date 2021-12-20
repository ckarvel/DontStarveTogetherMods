name = "Stamina System [Leaf Mods]"
description = "Use stamina to run faster"
author = "amoryleaf"
version = "1.1.7"

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

-- slow speeds
-- HEAVY_SPEED_MULT = .15,
-- SLINGSHOT_AMMO_MOVESPEED_MULT = 2/3, (0.667)
-- PIGGYBACK_SPEED_MULT = 0.9,

-- fast speeds
-- CANE_SPEED_MULT, SADDLE_WAR_SPEEDMULT = 1.25
-- SADDLE_BASIC_SPEEDMULT = 1.4,
-- SADDLE_RACE_SPEEDMULT = 1.55,
-- GHOSTLYELIXIR_SPEED_LOCO_MULT = 1.75,
-- ROGUEWAVE_SPEED_MULTIPLIER = 3,

local speedlist = {
  add_option("Walking Cane", 1.25),
  add_option("Basic Beefalo", 1.4),
  add_option("Race Beefalo", 1.55),
  add_option("Vigor Mortis", 1.75),
  add_option("Ocean Waves", 3)
}

local function AddConfig(name, label, options, default, hover)
  return {name = name, label = label, options = options, default = default, hover = hover or ""}
end

configuration_options =
{
  AddConfig("SPRINTKEY", "Sprint Button", keyslist, KEY_LSHIFT, "Hold down this key to sprint."),
  AddConfig("SPRINTSPEED", "Sprint Speed", speedlist, 1.55, "Walking Cane=1.25x Basic Beefalo=1.4x Race Beefalo=1.55x (Default) Vigor Mortis=1.75x Ocean Waves=3x"),
}
