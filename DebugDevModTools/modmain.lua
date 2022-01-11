--[[
================= Debug Commands from in-game console ================
[Backspace] - Show FPS
[~] - Opens in-game console

c_spawn("bat")

c_spawn("prefab",amount)

c_spawn("prefab",amount)
c_give("prefab",amount)
c_sethea​lth(percent)
c_setsanit​y(percent)
c_sethunger(pe​rcent)
c_setmoisture(pe​rcent)
c_settemperature(degrees)
c_godmode()
c_supergodmode()
c_maintainhealth(ThePlayer)
c_maintainsanity(ThePlayer)
c_maintainhunger(ThePlayer)
c_maintaintemperature(ThePlayer)
c_maintainmoisture(ThePlayer)
c_maintainall(ThePlayer)
c_speedmult(multiplier)

Teleport to something
c_gonext("wormhole")

Remove something under mouse
ConsoleWorldEntityUnderMouse():Remove()
c_select():Remove()

Skip in-game time
LongUpdate(X)

Speed up sim
c_speedup()

c_spawn("bat")
c_spawn("leif")
print(ThePlayer.components.aggro:GetDebugString())
print(TheCamera:GetDistance())

get abigail from wendy:
  ThePlayer.components.ghostlybond.ghost
print(ThePlayer.components.ghostlybond.ghost.components.aura.radius)
ThePlayer.components.ghostlybond.ghost.components.aura.radius = 8

================= (W/Caves) TheWorld ================
inlimbo | Pathfinder | worldstatewatching |
worldprefab | ismastershard | wallupdatecomponents |
OnRemoveEntity | pendingtasks | hideminimap |
state | spawntime | Transform |
generated | event_listening | minimap |
lower_components_shadow | entity | prefab |
updatecomponents | Map | net |
GroundCreep | persists | meta |
PostInit | SoundEmitter | actioncomponents |
has_ocean | ismastersim | name |
WaveComponent | replica | topology |
components | event_listeners | GUID
================= (W/Caves)TheWorld Components ================
moonstormlightningmanager | wavemanager | colourcube |
dynamicmusic | nutrients_visual_manager | ambientsound |
hallucinations | groundcreep | walkableplatformmanager |
hudindicatablemanager | worldstate | dsp |
oceancolor | ambientlighting | waterphysics
================= (w/o CAVES) TheWorld ================
yotc_raceprizemanager | shadowhandspawner | colourcube |
dsp | birdspawner | worldsettingstimer |
shadowcreaturespawner | specialeventsetup | retrofitforestmap_anr |
deerherdspawner | hounded | wildfires |
skeletonsweeper | brightmarespawner | sandstorms |
dynamicmusic | groundcreep | butterflyspawner |
worldmeteorshower | feasts | worlddeciduoustreeupdater |
mermkingmanager | regrowthmanager | klaussackloot |
nutrients_visual_manager | lureplantspawner | worldstate |
yotb_stagemanager | hudindicatablemanager | desolationspawner |
ambientlighting | hunter | forestresourcespawner |
moosespawner | worldwind | beargerspawner |
walkableplatformmanager | deerherding | flotsamgenerator |
uniqueprefabids | moonstormmanager | moonstormlightningmanager |
waterphysics | penguinspawner | worldoverseer |
wavemanager | sharklistener | klaussackspawner |
messagebottlemanager | playerspawner | oceancolor |
townportalregistry | crabkingspawner | malbatrossspawner |
ambientsound | timer | hallucinations |
chessunlocks | deerclopsspawner | forestpetrification |
farming_manager | frograin | kramped |
schoolspawner | squidspawner |
================= Player ================
DynamicShadow | inlimbo | GetMoistureRateScale
ghostenabled | EnableMovementPrediction | worldstatewatching
playercolour | IsOverheating | Light
Network | OnRemoveEntity | GetMoisture
pendingtasks | LightWatcher | ondetachclassified
inherentactions | spawntime | player_classified
prefab | SetGhostMode | name
HUD | _hermit_music | Transform
_winters_feast_music | GUID | actionreplica
event_listening | userid | actioncomponents
ShakeCamera | lower_components_shadow | GetMaxMoisture
updatecomponents | entity | CanUseTouchStone
IsCarefulWalking | IsActionsVisible | AttachClassified
isplayer | persists | _sharksoundparam
MiniMapEntity | SoundEmitter | GetSandstormLevel
IsFreezing | AnimState | Physics
event_listeners | DetachClassified | replica
components | GetTemperature
================= Player Components ================
plantregistryupdater | playermetrics | playerhearing
frostybreather | embarker | areaaware
playervoter | playeractionpicker | playeravatardata
cookbookupdater | playertargetindicator | constructionbuilderuidata
playercontroller | talker | inkable
attuner | playervision
================= Player replica ================
--]]

GLOBAL.CHEATS_ENABLED = true
GLOBAL.require("debugkeys")
AddSimPostInit(function()
  -- only day
  GLOBAL.TheWorld:PushEvent("ms_setseasonsegmodifier", {day = 3, dusk = 0, night = 0})
end)
----------------------------------------------------------------------
-- Print from server to chat log without caves
----------------------------------------------------------------------
-- local msg = tostring(enemy).." is asleep: "..tostring(enemy:IsAsleep())
-- local msg2 = tostring(enemy).." in limbo: "..tostring(enemy:IsInLimbo())
-- TheNet:SystemMessage(msg, false)
-- TheNet:SystemMessage(msg2, false)
-- AddSimPostInit(function()
--   GLOBAL.TheInput:AddKeyHandler(
--   function(key, down)
--     if not down then return end -- Only trigger on key press
--     if key == GLOBAL.KEY_Z then
--       local x, y, z = GLOBAL.TheSim:ProjectScreenPos(GLOBAL.TheSim:GetPosition())
--       GLOBAL.TheNet:SendRemoteExecute("c_maintainhealth()")
--       GLOBAL.TheNet:SendRemoteExecute("c_spawn(\"bat\")", x, z)
--       GLOBAL.TheNet:SendRemoteExecute("print(ThePlayer.components.aggro:GetDebugString())")
--     elseif key == GLOBAL.KEY_X then
--       GLOBAL.TheNet:SendRemoteExecute("print(ThePlayer.components.aggro:GetDebugString())")
--     end
--   end)
-- end)
----------------------------------------------------------------------
-- Enable ctrl-r for resetting world
-- Daytime only
----------------------------------------------------------------------
AddSimPostInit(function()
  GLOBAL.TheInput:AddKeyHandler(
  function(key, down)
    if not down then return end -- Only trigger on key press
    -- Require CTRL for any debug keybinds
    if GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_CTRL) then
      -- Load latest save and run latest scripts
      -- if GLOBAL.TheWorld.ismastersim then
      -- this prints successfully when playing without caves
      -- with caves for some reason this doesnt print
      --   print("iamserver")
      -- end
      -- if GLOBAL.TheWorld.components.hounded ~= nil then
      --   GLOBAL.TheWorld.components.hounded:ForceNextWave()
      --   print("timetoattack "..tostring(GLOBAL.TheWorld.components.hounded:GetTimeToAttack()))
      -- endif key == GLOBAL.KEY_R then
      if key == GLOBAL.KEY_R then
        if GLOBAL.TheWorld.ismastersim then
          GLOBAL.c_reset()
        else
          GLOBAL.TheNet:SendRemoteExecute("c_reset()")
        end
      elseif key == GLOBAL.KEY_C then
        if GLOBAL.TheWorld.ismastersim then -- not sure in which case this would hit... running public game, im not server??
          GLOBAL.c_supergodmode(GLOBAL.ThePlayer) 
          print("setting godmode")
        else
          GLOBAL.TheNet:SendRemoteExecute("c_supergodmode(ThePlayer)")
        end
      end
    elseif GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_SHIFT) then
      if key == GLOBAL.KEY_R then
        if GLOBAL.TheWorld.ismastersim then
          GLOBAL.c_regenerateworld()
        else
          GLOBAL.TheNet:SendRemoteExecute("c_regenerateworld()")
        end
      end
    end
  end)
end)
----------------------------------------------------------------------
-- AddPlayerPostInit(fn)
---- Lets you apply changes to all characters in the game at once.
----------------------------------------------------------------------
-- AddComponentPostInit(component, fn)
---- Lets you make changes to components
---- will NOT let you make changes to replica components (use AddClassPostConstruct)
----------------------------------------------------------------------
-- AddClassPostConstruct(filepath, fn)
---- Lets you make changes to classes
---- commonly used to make changes to widgets, screens, replica components
----------------------------------------------------------------------
-- AddBrainPostInit(brain, fn)
----------------------------------------------------------------------
-- AddStategraphPostInit(stategraph, fn)
---- Stategraphs are responsible for the animations, and executing actions when the entity needs to do them.
----------------------------------------------------------------------
-- AddReplicableComponent(name)
---- Replica components are used for passing information from the server to the client
---- You must have your replica file under the components folder, and name it to “componentname_replica”
------ Call: AddReplicableComponent(“componentname”)
-------- And the game will automatically add the replica of the component to the client when the component is added to the server side.
----------------------------------------------------------------------
-- AddPlayerPostInit -> AddComponent: LevelSystem -> If Server, LevelSystem:Init()
---- Here you would load the mod_data?
-- Global.TheWorld.State.IsWet
----------------------------------------------------------------------
-- listen for new state:
    -- if running: dotask (every something increase level by something)
    -- if run_stop: end dotask and start the decay process
        -- stategraph.lua line 508

-- stategraph.lua
-- SGwilson.lua
-- commonstates.lua
-- line 45 beard.lua
-- self:WatchWorldState("cycles", OnDayComplete)

-- playercommon.lua
-- line 1597
-- inst:AddComponent("areaaware")
-- inst.components.areaaware:SetUpdateDist(.45)
-- line 1707
-- inst:AddComponent("maprevealable")
-- inst.components.maprevealable:SetIconPriority(10)
-- line 1860
-- inst:SetStateGraph("SGwilson")
-- line 445
-- RegisterMasterEventListeners(inst)

-- local function ToggleFueledItem(inst)
--   print("ToggleFueledItem")
--   if inst and inst.components and inst.components.fueled then
--     if inst.components.fueled:IsEmpty() then
--       print("Filling up fuel"..inst.prefab)
--       inst.components.fueled:DoDelta(100)
--     else
--       inst.components.fueled:MakeEmpty()
--       print("Emptying fuel"..inst.prefab)
--     end
--   end
-- end

-- ----------------------------------------------------------------------
-- -- set fuel to 1%
-- ----------------------------------------------------------------------
-- local function ToggleFuel(player)
--   print("ToggleFuel")
--   -- head
--   local hat = player.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HEAD)
--   ToggleFueledItem(hat)

--   -- body
--   local body = player.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.BODY)
--   ToggleFueledItem(body)

--   -- hands
--   local hands = player.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
--   ToggleFueledItem(hands)
-- end

-- -- Handles RPC comms between server and client for light toggling
-- AddModRPCHandler("ToggleFuelRPC", "ToggleFuel", ToggleFuel)
-- -- From client, this sends a request to server
-- local function SendToggleFuelRPC()
--   SendModRPCToServer(GetModRPC("ToggleFuelRPC", "ToggleFuel"))
-- end
-- -- On T, tell server to turn on/off light if wearing light source
-- GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_F, SendToggleFuelRPC)

----------------------------------------------------------------------
-- Turn off miner's hat with keybind
----------------------------------------------------------------------
-- local function LightToggle(player)
--   if not player or not player.components or not player.components.inventory then
--     print("LightToggle::Unexpected NIL value!")
--     return -- exit point
--   end
--   -- does player have a light source gear equipped?
--   local hat = player.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HEAD)
--   if not hat or not hat.components or hat.prefab ~= "minerhat" then return end -- exit point
--   -- turn light on if hat light is off
--   if not hat._light and hat.components.equippable then
--     print("Turning on light source for -> "..hat.prefab)
--     hat.components.equippable.onequipfn(hat)
--   elseif hat._light and hat.components.inventoryitem then
--     print("Turning off light source for -> "..hat.prefab)
--     hat.components.inventoryitem.ondropfn(hat)
--   end
-- end
-- -- Handles RPC comms between server and client for light toggling
-- AddModRPCHandler("LightToggleRPC", "LightToggle", LightToggle)
-- -- From client, this sends a request to server
-- local function SendLightToggleRPC()
--   SendModRPCToServer(GetModRPC("LightToggleRPC", "LightToggle"))
-- end
-- -- On T, tell server to turn on/off light if wearing light source
-- GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_T, SendLightToggleRPC)


-------------- CODE FOR TEAMLEADER/TEAMATTACK NOT IN USE BUT MAY BE HELPFUL IN FUTURE --------------
----------------------------------------------------------------------
-- modify teamleader to notify when it doesn't have threat anymore
-- this is important for bats and penguins
  -- basically any prefab with teamattacker [sic] component.
-- when bats attack, they're seen as a group instead of individuals
-- so teamleader is needed to check if the player is in/out combat with a bat
----------------------------------------------------------------------
-- local function NotifyThreatState(self)
--   -- in combat
--   local old_setup = self.SetUp
--   self.SetUp = function(self, target, first_member)
--     old_setup(self, target, first_member)
--     if target and target.components.aggro then
--       target.components.aggro:AddEnemy(self.inst)
--       -- print("Adding as threat = "..tostring(self.inst))
--     end
--   end

--   -- out of combat
--   local old_disbandteam = self.DisbandTeam
--   self.DisbandTeam = function(self)
--     if self.threat and self.threat.components.aggro then
--       self.threat.components.aggro:RemoveEnemy(self.inst)
--       -- print("Removing as threat = "..tostring(self.inst))
--     end
--     old_disbandteam(self)
--   end

--   -- out of combat
--   local d232 = self.NewTeammate
--   self.NewTeammate = function(self, member)
--     print("calling NewTeammate")
--     d232(self, member)
--   end

--   local d23 = self.OnLostTeammate
--   self.OnLostTeammate = function(self, member)
--     print("calling on lostteammate")
--     d23(self, member)
--   end
-- end
-- AddComponentPostInit("teamleader", NotifyThreatState)