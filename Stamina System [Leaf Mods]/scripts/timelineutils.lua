require("stategraph")
local TimelineUtils = {}
----------------------------------------------------------------------
-- Modify timeline by inserting a fast chop action in Key 4
-- Warning: SGwilson.lua timeline order is wrong?
-- This is the actual timeline keys/values
-- Key     Value
--  1        2 * FRAMES = 0.067 -- woodcutter
--  2        2 * FRAMES = 0.067 -- normal
--  3        5 * FRAMES = 0.167 -- woodcutter
--  4        9 * FRAMES = 0.300 -- normal <-- insert fast frame here
--  5       10 * FRAMES = 0.333 -- woodcutter
--  6       12 * FRAMES = 0.400 -- woodcutter (this is not a typo)
--  7       14 * FRAMES = 0.467 -- normal
--  8       16 * FRAMES = 0.533 -- normal
----------------------------------------------------------------------
local has_fastchop_timeline = false
local function DoChopping(inst, state)
  if state.name ~= "chop" then
    return
  end

  local old_onenter = state.onenter
  state.onenter = function(inst)
    if not inst:HasTag("woodcutter") and inst:HasTag("staminauser") then
      -- timeline (set once) --
      if not has_fastchop_timeline then
        has_fastchop_timeline = true

        local fast_chop = TimeEvent(5.25 * FRAMES, function(inst) -- slower than woodie
          if not inst:HasTag("woodcutter") and inst.replica.stamina:IsUsingStamina() then
            inst.sg:RemoveStateTag("prechop")
          end
        end)
        table.insert(state.timeline, 4, fast_chop)
      end
    end
    old_onenter(inst) -- all players will call this, I just added the above to modify timeline
  end
end
----------------------------------------------------------------------
-- Modify timeline by inserting a fast mine action in Key 2
-- This is the original timeline keys/values
-- Key     Value
--  1        7 * FRAMES = 0.233 -- normal
--  2        9 * FRAMES = 0.467 -- normal <- insert fast mining here
--  3        14 * FRAMES = 0.467 -- normal
----------------------------------------------------------------------
local has_fastmine_timeline = false
local function DoMining(inst, state)
  if state.name ~= "mine" then
    return
  end

  local old_onenter = state.onenter
  state.onenter = function(inst)
    if inst:HasTag("staminauser") then
      -- timeline (set once) --
      if not has_fastmine_timeline then
        has_fastmine_timeline = true

        local fast_mine = TimeEvent(5 * FRAMES, function(inst)
          if inst.replica.stamina:IsUsingStamina() then
            inst.sg:RemoveStateTag("premine")
          end
        end)
        table.insert(state.timeline, 2, fast_mine)
      end
    end
    old_onenter(inst) -- all players will call this, I just added the above to modify timeline
  end
end
----------------------------------------------------------------------
----------------------------------------------------------------------
function TimelineUtils.ModifyWorkingTimelines(inst)
  for k, data in pairs(inst.states) do
    if data.name == "chop" then
      DoChopping(inst, data)
    elseif data.name == "mine" then
      DoMining(inst, data)
    end
  end
end
----------------------------------------------------------------------------
return TimelineUtils
