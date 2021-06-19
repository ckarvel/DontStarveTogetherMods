local ThirstHelper = GLOBAL.require("thirsthelper")
local ThirstBadge = GLOBAL.require("widgets/thirstbadge")

Assets = {
  Asset("ANIM", "anim/status_thirst.zip")
}

local function InGame()
  return GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD and not GLOBAL.ThePlayer.HUD:HasInputFocus()
end

----------------------------------------------------------------------
-- add thirst components to players
----------------------------------------------------------------------

GLOBAL.TUNING.WILSON_THIRST = 100
GLOBAL.STRINGS.CHARACTERS.GENERIC.ANNOUNCE_THIRST_WARNING = "I need water!"

local function AddSystemComponents(inst)
  if not GLOBAL.TheWorld.ismastersim then return end

  inst:AddComponent("thirst")
  inst.components.thirst:SetMaxThirst(GLOBAL.TUNING.WILSON_THIRST)

  inst:ListenForEvent("thirstempty", function(inst, data)
      inst.components.talker:Say(GLOBAL.GetString(inst, "ANNOUNCE_THIRST_EMPTY"))
  end)
    -- inst.components.talker:Say(GLOBAL.GetString(inst, "ANNOUNCE_THIRST_WARNING"))
end

-- called on each player spawned
AddPlayerPostInit(AddSystemComponents)

----------------------------------------------------------------------
-- server to client communication
----------------------------------------------------------------------

-- player_classified/replicas used for server to client comms
AddReplicableComponent("thirst")

local function AddThirstClassified(inst)
  -- WARNING: some of this code needs to be run on the client
  -- if by mistake, you force it to only run on the server, side effects will occur.
  -- in my case, the UI badge values, like hunger, will not update.
  ThirstHelper.SetupNetvars(inst)
  inst:DoTaskInTime(0, ThirstHelper.RegisterNetListeners)
end

-- server updates the client by using thirst netvars on the player_classified
AddPrefabPostInit("player_classified", AddThirstClassified)

----------------------------------------------------------------------
-- user interface - implements thirst badge
----------------------------------------------------------------------

AddClassPostConstruct("widgets/statusdisplays", function(self)
  -- show/hide badge value
  local old_ShowStatusNumbers = self.ShowStatusNumbers
  self.ShowStatusNumbers = function(self)
    ThirstHelper.ShowStatusNumbers(self, old_ShowStatusNumbers)
  end
  local old_HideStatusNumbers = self.HideStatusNumbers
  self.HideStatusNumbers = function(self)
    ThirstHelper.HideStatusNumbers(self, old_HideStatusNumbers)
  end

  -- sets value that affects the actual value
  -- and the visual level in the badge
  self.SetThirstPercent = function(self, pct)
    ThirstHelper.SetThirstPercent(self, pct)
  end
  self.ThirstDelta = function(self, data)
    ThirstHelper.ThirstDelta(self, data)
  end

  -- show/hide badge
  local old_SetGhostMode = self.SetGhostMode
  self.SetGhostMode = function(self, ghostmode)
    ThirstHelper.SetGhostMode(self, ghostmode, old_SetGhostMode)
  end

  self.lungs = self:AddChild(ThirstBadge(self.owner))
  self.onstaminadelta = nil
  self:SetGhostMode(false)

  if self.pethealthbadge ~= nil then -- wendy
    self.lungs:SetPosition(0,-160,0)
  elseif self.inspirationbadge ~= nil then -- wigfrid
    local heart_pos = self.heart:GetPosition()
    local inspiration_pos = self.inspirationbadge:GetPosition()
    self.lungs:SetPosition(heart_pos.x,inspiration_pos.y-60,0)
  else -- all other players
    -- copy wendy's widget layout
    self.lungs:SetPosition(40, -100, 0)
    self.moisturemeter:SetPosition(-40, -100, 0)
  end
end)

----------------------------------------------------------------------
-- compatability with CombinedStatus mod
----------------------------------------------------------------------

local function AddOffset(badge, value)
  if not badge then return end
  local position = badge:GetPosition()
  new_position = position + value
  badge:SetPosition(new_position)
end

AddSimPostInit(function(inst)
  -- check if using CombinedStatus mod
  if not GLOBAL.KnownModIndex:IsModEnabled("workshop-376333686") then return end

  -- modify badge positions
  AddClassPostConstruct("widgets/statusdisplays", function(self)
      self.lungs:SetPosition(self.moisturemeter:GetPosition())
      local heart_pos = self.heart:GetPosition()
      AddOffset(self.moisturemeter,  GLOBAL.Vector3(heart_pos.x, 0, 0))
      AddOffset(self.temperature,    GLOBAL.Vector3(0,         -90, 0))
      AddOffset(self.tempbadge,      GLOBAL.Vector3(0,         -90, 0))
      AddOffset(self.naughtiness,    GLOBAL.Vector3(0,         -90, 0))
      AddOffset(self.worldtemp,      GLOBAL.Vector3(0,         -90, 0))
      AddOffset(self.worldtempbadge, GLOBAL.Vector3(0,         -90, 0))
  end)
end)
