name = "Stamina System [Leaf Mods]"
description = "Use stamina to run faster"
author = "amoryleaf"
version = "1.1.6"

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

configuration_options =
{
  {
    name = "SPRINTKEY",
    label = "Sprint Button",
    options = keyslist,
    default = KEY_LSHIFT,
    hover = "Hold down this key to sprint.",
  }
}
