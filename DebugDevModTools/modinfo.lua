name = "DebugTools"
description = [[
Development-only
-- atlas-0.tex: contains all images of animation. "Sprite-sheet"
--- save this file as .png with ktools. This is what we'll be working with.
-- build.bin: contains how each body part is labelled.
    -- Imagine a square around each picture in the atlas. That is your workspace.
    -- Anything outside of it will get cut off.
-- anim.bin: parts from atlas are scaled/translated for animation.
-- swap_box_full & player_encumbered
]]

author = "amoryleaf"
version = "1.0.0"

forumthread = ""

api_version = 10

dont_starve_compatible = false
reign_of_giants_compatible = true
dst_compatible = true

-- Server only
-- all_clients_require_mod = false
-- client_only_mod = false

-- Client only
-- all_clients_require_mod = false
-- client_only_mod = true

-- Server/Client
-- all_clients_require_mod = true
-- client_only_mod = false
all_clients_require_mod = true
clients_only_mod = false
