require("stategraph")
local TimelineUtils = {}
----------------------------------------------------------------------
-- CHOPPING
-- Warning: Order of TimeEvents in SGwilson.lua seems to be wrong?
-- I found the following values by printing to the log
-- This is the actual timeline keys/values that is stored in this variable = SGwilson.State.timeline
-- Key     Value
--  1        2 * FRAMES = 0.067 -- woodcutter
--  2        2 * FRAMES = 0.067 -- normal
--  3        5 * FRAMES = 0.167 -- woodcutter
--  4        9 * FRAMES = 0.300 -- normal <-- insert fast frame here
--  5       10 * FRAMES = 0.333 -- woodcutter
--  6       12 * FRAMES = 0.400 -- woodcutter (this is not a typo)
--  7       14 * FRAMES = 0.467 -- normal
--  8       16 * FRAMES = 0.533 -- normal

-- MINING
-- This is the original timeline keys/values
-- Key     Value
--  1        7 * FRAMES = 0.233 -- normal
--  2        9 * FRAMES = 0.467 -- normal <- insert fast mining here
--  3        14 * FRAMES = 0.467 -- normal

-- HAMMERING
----------------------------------------------------------------------
-- see stategraph.lua
-- see SGwilson.lua
-- State
--- onenter
--- events
--- timeline = [TimeEvent]
-- TimeEvent
--- time = number
--- fn = function
-- Example print output
-- -- using fast action --	
-- removed: premine	
-- key: 1 value: 0.233 defline: [string "scripts/stategraphs/SGwilson.lua"]:3486	
-- key: 2 value: 0.167 defline: [string "../mods/Stamina System [Leaf Mods]/scripts/..."]:55	
-- key: 3 value: 0.300 defline: [string "scripts/stategraphs/SGwilson.lua"]:3494	
-- key: 4 value: 0.467 defline: [string "scripts/stategraphs/SGwilson.lua"]:3499	
-- you might think, why does mining have 4 frames now? we were supposed to replace 2? no that causes weird anim
-- idk how this works but seems to work
local action_timelines = {}
local function ModifyTimeline(inst, state, data)
  local old_onenter = state.onenter
  state.onenter = function(inst)
    if inst:HasTag("staminauser") then
      -- timeline (set once) --
      if action_timelines[state.name] == nil then
        action_timelines[state.name] = true

        local fast_action = TimeEvent(data.time * FRAMES, function(inst)
          if inst.replica.stamina:IsUsingStamina() then
            -- print("-- using fast action --")
            inst.sg:RemoveStateTag("pre"..state.name)
            inst:RemoveTag("pre"..state.name)
            -- print("removed: pre"..state.name)
          end
        end)
        table.insert(state.timeline, data.key, fast_action)
      end
      -- for k,v in ipairs(state.timeline) do
      --   print("key: "..k.." value: "..v.time.." defline: "..v.defline)
      -- end
    end
    old_onenter(inst) -- all players will call this, I just added the above to modify timeline
  end
end
----------------------------------------------------------------------
-- see stategraph.lua
-- class refs: StateGraph, State
-- inst = StateGraph
-- named = str
-- states = {name, State}
-- events = {name, EventHandler}
-- defaultstate = State ??
-- actionhandlers = {action, ActionHandler}
function TimelineUtils.ModifyWorkingTimelines(inst)
  for k, state in pairs(inst.states) do
    local frame_data = nil
    if state.name == "chop" then
      frame_data = { key = 4, time = 5.25 }
    elseif state.name == "mine" then
      frame_data = { key = 2, time = 5 }
    -- elseif state.name == "hammer" then
    --   frame_data = { key = 2, time = 5 } -- todo
    end

    if frame_data ~= nil then
      ModifyTimeline(inst, state, frame_data)
    end
  end
end
----------------------------------------------------------------------------
return TimelineUtils
