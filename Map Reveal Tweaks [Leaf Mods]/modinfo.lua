name = "Map Reveal Tweaks [Leaf Mods]"
description = "Radius of the map spot revealer adjusts with camera zoom."
author = "amoryleaf"
version = "1.0.0"

forumthread = ""

api_version = 10

icon_atlas = "modicon.xml"
icon = "modicon.tex"

dont_starve_compatible = false
reign_of_giants_compatible = true
dst_compatible = true

all_clients_require_mod = true
client_only_mod = false

configuration_options =
{
  {
    name = "RevealSpeed",
    label = "Reveal Speed",
    hover = "If Camera Distance is > 50, this is how quickly your entire radius will be revealed on the map. (Faster values may affect PC performance)",
    options =
    {
      {description = "Fast", data = 0.1},
      {description = "Default", data = 0.5},
      {description = "Slow", data = 0.8}
    },
    default = 0.5
  }
}
