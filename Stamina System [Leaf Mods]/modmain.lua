local StaminaHelper = GLOBAL.require("staminahelper")
local StaminaBadge = GLOBAL.require("widgets/staminabadge")
local SPRINTKEY = GetModConfigData("SPRINTKEY")

Assets = {
  Asset("ANIM", "anim/status_stamina.zip")
}

local function InGame()
  return GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD and not GLOBAL.ThePlayer.HUD:HasInputFocus()
end

----------------------------------------------------------------------
-- add stamina/aggro components to players
----------------------------------------------------------------------

GLOBAL.TUNING.WILSON_STAMINA = 100
GLOBAL.STRINGS.CHARACTERS.GENERIC.ANNOUNCE_TIRED = "I'm... so... tired."
GLOBAL.STRINGS.CHARACTERS.GENERIC.ANNOUNCE_STAMINA_WARNING = "I can't sprint right now!"

local function AddSystemComponents(inst)
  if not GLOBAL.TheWorld.ismastersim then return end

  inst:AddComponent("stamina")
  inst.components.stamina:SetMaxStamina(GLOBAL.TUNING.WILSON_STAMINA)
  inst:ListenForEvent("staminaempty", function(inst, data)
      inst.components.talker:Say(GLOBAL.GetString(inst, "ANNOUNCE_TIRED"))
  end)
  inst:ListenForEvent("staminadisabled", function(inst, data)
    inst.components.talker:Say(GLOBAL.GetString(inst, "ANNOUNCE_STAMINA_WARNING"))
  end)

  inst:AddComponent("aggro")
end

-- called on each player spawned
AddPlayerPostInit(AddSystemComponents)

----------------------------------------------------------------------
-- modify combat so we're notified when players are in/out of combat
----------------------------------------------------------------------
local function NotifyCombatState(self)
  -- in combat
  local old_engagetarget = self.EngageTarget
  self.EngageTarget = function(self, target)
    old_engagetarget(self, target)
    if self.target and self.target.components.aggro then
      self.target.components.aggro:AddEnemy(self.inst)
    end
  end

  -- out of combat
  local old_droptarget = self.DropTarget
  self.DropTarget = function(self, hasnexttarget)
    if self.target and self.target.components.aggro then
      self.target.components.aggro:RemoveEnemy(self.inst)
    end
    old_droptarget(self, hasnexttarget)
  end
end

AddComponentPostInit("combat", NotifyCombatState)

----------------------------------------------------------------------
-- client to server communication
----------------------------------------------------------------------

-- here server receives and grants client request
local function WantsToSprint(inst, flag)
	if inst and inst.components and inst.components.stamina then
    inst.components.stamina:SetWantsToSprint(flag)
  end
end

-- rpc handler sends client requests to server
AddModRPCHandler(modname, "WantsToSprint", WantsToSprint)

-- the actual client request that will be sent to server
-- handles user request to sprint
local last_key_pressed = false
local function SendSprintRPC(key_pressed)
  local player = GLOBAL.ThePlayer;
  if player and player:HasTag("playerghost") then
    last_key_pressed = false
    return -- exit if player is dead
  end

  if (last_key_pressed and key_pressed) -- if key state hasn't changed or
     or (key_pressed and not InGame()) then return end -- if game not active, exit

  --note: if press == false and game not active, I'll send the request
	SendModRPCToServer(GetModRPC(modname, "WantsToSprint"), key_pressed)
  last_key_pressed = key_pressed
end

-- client triggers requests to server through key press
GLOBAL.TheInput:AddKeyDownHandler(SPRINTKEY, function(inst) SendSprintRPC(true) end)
GLOBAL.TheInput:AddKeyUpHandler(SPRINTKEY, function(inst) SendSprintRPC(false) end)

----------------------------------------------------------------------
-- server to client communication
----------------------------------------------------------------------

-- player_classified/replicas used for server to client comms
AddReplicableComponent("stamina")

local function AddStaminaClassified(inst)
  -- WARNING: some of this code needs to be run on the client
  -- if by mistake, you force it to only run on the server, side effects will occur.
  -- in my case, the UI badge values, like hunger, will not update.
  StaminaHelper.SetupNetvars(inst)
  inst:DoTaskInTime(0, StaminaHelper.RegisterNetListeners)
end

-- server updates the client by using stamina netvars on the player_classified
AddPrefabPostInit("player_classified", AddStaminaClassified)

----------------------------------------------------------------------
-- user interface - implements stamina badge
----------------------------------------------------------------------

AddClassPostConstruct("widgets/statusdisplays", function(self)
  -- show/hide badge value
  local old_ShowStatusNumbers = self.ShowStatusNumbers
  self.ShowStatusNumbers = function(self)
    StaminaHelper.ShowStatusNumbers(self, old_ShowStatusNumbers)
  end
  local old_HideStatusNumbers = self.HideStatusNumbers
  self.HideStatusNumbers = function(self)
    StaminaHelper.HideStatusNumbers(self, old_HideStatusNumbers)
  end

  -- sets value that affects the actual value
  -- and the visual level in the badge
  self.SetStaminaPercent = function(self, pct)
    StaminaHelper.SetStaminaPercent(self, pct)
  end
  self.StaminaDelta = function(self, data)
    StaminaHelper.StaminaDelta(self, data)
  end

  -- show/hide badge
  local old_SetGhostMode = self.SetGhostMode
  self.SetGhostMode = function(self, ghostmode)
    StaminaHelper.SetGhostMode(self, ghostmode, old_SetGhostMode)
  end

  self.lungs = self:AddChild(StaminaBadge(self.owner))
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
  -- look for combined status mod or combined status mod files
  local using_combined_status_mod = GLOBAL.KnownModIndex:IsModEnabled("workshop-376333686") or GLOBAL.softresolvefilepath("scripts/widgets/playerbadge_combined_status.lua")

  if using_combined_status_mod then -- adjust other badge positions to add stamina badge
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
  end
end)
