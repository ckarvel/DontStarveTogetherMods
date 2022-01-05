name = "Expand Abigail's Aura [Leaf Mods]"
description = "Expands Abigail's attack aura, aka range"
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
clients_only_mod = false

configuration_options =
{
  {
    name = "AURA_RADIUS",
    label = "Attack Range",
    hover = "Increase Abigail's attack range",
    options =
    {
      {description = "+50%", data = 6},
      {description = "+100%", data = 8},
      {description = "+150%", data = 10},
      {description = "+200%", data = 12}
    },
    default = 8
  }
}
