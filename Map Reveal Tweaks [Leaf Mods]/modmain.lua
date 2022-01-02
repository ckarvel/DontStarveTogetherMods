----------------------------------------------------------------------
-- Map spot radius depending on camera distance (zoom)
  -- unfortunately the radius is hardcoded to 50m :/ so the workaround
  -- is to reveal multiple overlapping spots to fake a bigger radius
----------------------------------------------------------------------
local REVEAL_SPEED = GetModConfigData("RevealSpeed")
local MIN_CAM_DIST = 50 -- (hardcoded in C++ files) :/
local SMOOTHNESS_FACTOR = 5 -- 80/16=5 | at 80m, > 16 steps added no real benefit to smoothness
local TICK_RATE = 1/3 -- rate in which ModifyMapExplorer() is called (every 33 ms)

local last_camera_distance = 0
local last_pos_revealed = GLOBAL.Vector3(math.inf,0,math.inf)
----------------------------------------------------------------------
-- one-time request client to server
----------------------------------------------------------------------
local function RevealArea(inst, radius, step)
  local pos = inst:GetPosition()
  for theta = 0, GLOBAL.PI2, step do
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
    if inst:HasTag("playerghost") then return end -- player is dead, don't reveal

    local camera_distance = math.max(MIN_CAM_DIST, GLOBAL.TheCamera:GetDistance()) -- clamp to min
    if camera_distance <= MIN_CAM_DIST then return end -- within minimum radius, don't reveal

    local pos = inst:GetPosition()
    local dist_traveled = pos:Dist(last_pos_revealed)
    local dist_threshold = (last_camera_distance * REVEAL_SPEED)
    if dist_traveled < dist_threshold and last_camera_distance == camera_distance then return end -- no change, don't reveal

    -- if player moved by some % of camera distance, reveal area
    -- if player just zoomed in/out, reveal area
    local radius = camera_distance - MIN_CAM_DIST
    -- calculate number of steps for reveal area to look smooth
    local num_steps = camera_distance / SMOOTHNESS_FACTOR
    local step = GLOBAL.PI2 / num_steps
    SendModRPCToServer(GetModRPC(modname, "RevealArea"), radius, step)
    last_pos_revealed = pos
    last_camera_distance = camera_distance
  end)
end
AddPlayerPostInit(ModifyMapExplorer)
