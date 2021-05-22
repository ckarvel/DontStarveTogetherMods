----------------------------------------------------------------------
-- Add Stamina component
----------------------------------------------------------------------
AddReplicableComponent("stamina")
----------------------------------------------------------------------
-- CLIENT/SERVER
-- Clients send to Server through RPCs
-- Server send to Client through netvars
----------------------------------------------------------------------
local function InGame()
  return GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD and not GLOBAL.ThePlayer.HUD:HasInputFocus()
end
---
local function WantsToSprint(inst, flag)
	if inst and inst.components and inst.components.stamina then
    inst.components.stamina:SetWantsToSprint(flag)
  end
end
AddModRPCHandler(modname, "WantsToSprint", WantsToSprint)
---
local last_key_pressed = false
local function SendSprintRPC(key_pressed)
  -- check if player is dead
  local player = GLOBAL.ThePlayer;
  if player and player:HasTag("playerghost") then return end

  -- if key state hasn't changed or
  -- if game not active, don't send request
  if (last_key_pressed and key_pressed) or (key_pressed and not InGame()) then return end

  --note: if press == false and game not active, I'll send the request
	SendModRPCToServer(GetModRPC(modname, "WantsToSprint"), key_pressed)

  -- keep track of key state
  last_key_pressed = key_pressed
end
----------------------------------------------------------------------
-- KEYBINDINGS
----------------------------------------------------------------------
local SPRINTKEY = GetModConfigData("SPRINTKEY")
GLOBAL.TheInput:AddKeyDownHandler(SPRINTKEY, function(inst) SendSprintRPC(true) end)
GLOBAL.TheInput:AddKeyUpHandler(SPRINTKEY, function(inst) SendSprintRPC(false) end)
----------------------------------------------------------------------
local StaminaHelper = GLOBAL.require("staminahelper")
----------------------------------------------------------------------
-- NETVARS
-- Add stamina netvars to player classified
----------------------------------------------------------------------
local function AddStaminaClassified(inst)
  -- WARNING: some of this code needs to be run on the client
  -- if by mistake, you force it to only run on the server, side effects will occur.
  -- in my case, the UI badge values, like stamina, will not update.
  StaminaHelper.SetupNetvars(inst)
  inst:DoTaskInTime(0, StaminaHelper.RegisterNetListeners)
end
---
AddPrefabPostInit("player_classified", AddStaminaClassified)
----------------------------------------------------------------------
-- ADD AGGROED STATE to combat
----------------------------------------------------------------------
local function AddAggroSystem(self)
  self.has_aggro = false
  ---
  self.GetTargeted = function(attacker)
    self.has_aggro = true
  end
  ---
  self.GetUntargeted = function()
    self.has_aggro = false
  end
  ---
  local old_engagetarget = self.EngageTarget
  ---
  -- Override to notify player when being targeted
  ---
  self.EngageTarget = function(self, target)
    old_engagetarget(self, target)
    if target and target.components and target.components.combat then
      target.components.combat:GetTargeted(self.inst);
    end
  end
  ---
  local old_droptarget = self.DropTarget
  ---
  self.DropTarget = function(self, hasnexttarget)
    if self.target and self.target.components and self.target.components.combat then
      self.target.components.combat:GetUntargeted(self.inst);
    end
    old_droptarget(self, hasnexttarget)
  end
end
AddComponentPostInit("combat", AddAggroSystem)
----------------------------------------------------------------------
-- APPLY TO PLAYER PREFABS
----------------------------------------------------------------------
GLOBAL.TUNING.WILSON_STAMINA = 100
GLOBAL.TUNING.STAMINA_PENALTY = 0.25
GLOBAL.TUNING.MAXIMUM_STAMINA_PENALTY = 0.75
GLOBAL.STRINGS.CHARACTERS.GENERIC.ANNOUNCE_TIRED = "I'm too tired!"
-- i think i like this for the 25% threshold
-- GLOBAL.STRINGS.CHARACTERS.GENERIC.ANNOUNCE_STAMINA_FULL = "Finally caught my breath!"
---
local function AddStaminaComponent(inst)
  if not GLOBAL.TheWorld.ismastersim then return end
  inst:AddComponent("stamina")
  inst.components.stamina:SetMaxStamina(GLOBAL.TUNING.WILSON_STAMINA)

  inst:ListenForEvent("staminaempty", function(inst, data)
      inst.components.talker:Say(GLOBAL.GetString(inst, "ANNOUNCE_TIRED"))
  end)

  -- inst:ListenForEvent("staminafull", function(inst, data)
  --   inst.components.talker:Say(GLOBAL.GetString(inst, "ANNOUNCE_STAMINA_FULL"))
  -- end)
end
---
AddPlayerPostInit(AddStaminaComponent)
----------------------------------------------------------------------
-- USER INTERFACE
-- Add Stamina Badge to Status Display
----------------------------------------------------------------------
local StaminaBadge = GLOBAL.require("widgets/staminabadge")

Assets = {
  Asset("ANIM", "anim/status_stamina.zip")
}

AddClassPostConstruct("widgets/statusdisplays", function(self)
  ----------------------------------------------------------------------
  -- Show/Hide StaminaBadge Status value
  ----------------------------------------------------------------------
  local old_ShowStatusNumbers = self.ShowStatusNumbers
  self.ShowStatusNumbers = function(self)
    StaminaHelper.ShowStatusNumbers(self, old_ShowStatusNumbers)
  end
  ---
  local old_HideStatusNumbers = self.HideStatusNumbers
  self.HideStatusNumbers = function(self)
    StaminaHelper.HideStatusNumbers(self, old_HideStatusNumbers)
  end
  ----------------------------------------------------------------------
  -- Set data percentage for StaminaBadge
  ----------------------------------------------------------------------
  self.SetStaminaPercent = function(self, pct)
    StaminaHelper.SetStaminaPercent(self, pct)
  end
  ---
  self.StaminaDelta = function(self, data)
    StaminaHelper.StaminaDelta(self, data)
  end
  ----------------------------------------------------------------------
  -- Show/Hide StaminaBadge Status value depending on ghost mode
  ----------------------------------------------------------------------
  local old_SetGhostMode = self.SetGhostMode
  self.SetGhostMode = function(self, ghostmode)
    StaminaHelper.SetGhostMode(self, ghostmode, old_SetGhostMode)
  end
  ----------------------------------------------------------------------
  -- Creates actual Stamina badge drawn on HUD
  ----------------------------------------------------------------------
  self.brain:SetPosition(40, -55, 0) -- move sanity
  self.lungs = self:AddChild(StaminaBadge(self.owner))
  self.lungs:SetPosition(-40, -55, 0)
  self.onstaminadelta = nil
  self.staminapenalty = 0
  self:SetGhostMode(false)
  ---
end)
