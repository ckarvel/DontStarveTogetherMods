----------------------------------------------------------------------
-- Map spot radius depending on camera distance (zoom)
  -- unfortunately the radius is hardcoded to 50m :/ so the workaround
  -- is to reveal multiple overlapping spots to fake a bigger radius
----------------------------------------------------------------------
local MIN_CAM_DIST = 50 -- (hardcoded in C++ files) :/
local MAX_CAM_DIST = 80 -- I feel like its op after this value
local UPDATE_STEP = GLOBAL.PI2 / 16 -- (arbitrary) min # of reveals for it to look smooth
local FULL_CIRCLE = GLOBAL.PI2
local last_camera_distance = 0
local reveal_distance = GetModConfigData("RevealSpeed")
local last_pos_revealed = GLOBAL.Vector3(math.inf,0,math.inf)
local TICK_RATE = 1/3
----------------------------------------------------------------------
-- one-time request client to server
----------------------------------------------------------------------
local function RevealArea(inst, distance)
  local radius = distance - MIN_CAM_DIST -- diff w/ hardcoded dist and cam dist
  local pos = inst:GetPosition()
  for theta = 0, FULL_CIRCLE, UPDATE_STEP do
    next_x = pos.x + radius * math.cos(theta)
    next_z = pos.z + radius * math.sin(theta)
    inst.player_classified.MapExplorer:RevealArea(next_x, 0 ,next_z)
  end
end
AddModRPCHandler(modname, "RevealArea", RevealArea)
----------------------------------------------------------------------
-- entry point
----------------------------------------------------------------------
local function ModifyMapExplorer(inst)
  inst:DoPeriodicTask(TICK_RATE, function()
    if inst:HasTag("playerghost") then return end

    local camera_distance = math.min(GLOBAL.TheCamera:GetDistance(), MAX_CAM_DIST)
    local pos = inst:GetPosition()

    -- reveal area if player has traveled some % of the last cam distance
    if camera_distance > MIN_CAM_DIST and
       pos:Dist(last_pos_revealed) >= (last_camera_distance * reveal_distance) or
       last_camera_distance ~= camera_distance then
        SendModRPCToServer(GetModRPC(modname, "RevealArea"), camera_distance)
        last_pos_revealed = pos
        last_camera_distance = camera_distance
    end
  end)
end
AddPlayerPostInit(ModifyMapExplorer)
