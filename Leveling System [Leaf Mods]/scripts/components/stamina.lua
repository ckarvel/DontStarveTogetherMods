----------------------------------------------------------------------
local function onmaxstamina(self, maxstamina)
    self.inst.replica.stamina:SetMax(maxstamina)
    self.inst.replica.stamina:SetIsFull((self.currentstamina or maxstamina) >= maxstamina)
end
----------------------------------------------------------------------
local function oncurrentstamina(self, currentstamina)
    self.inst.replica.stamina:SetCurrent(currentstamina)
    self.inst.replica.stamina:SetIsTired(currentstamina <= 0)
    self.inst.replica.stamina:SetIsFull(currentstamina >= self.maxstamina)
end
----------------------------------------------------------------------
local function onusingstamina(self, flag)
    self.inst.replica.stamina:SetIsSprinting(flag)
end
----------------------------------------------------------------------
local function onpenalty(self, penalty)
    self.inst.replica.stamina:SetPenalty(penalty)
end
----------------------------------------------------------------------
local Stamina = Class(function(self, inst)
    self.inst = inst
    self.maxstamina = 100
    self.minstamina = 0
    self.currentstamina = self.maxstamina
    self.penalty = 0.0
    self.usingstamina = false -- meant to call this... wants_to_sprint
    self.old_usingstamina = false
    -- I want:
        -- 1. empty after 5s
            -- 100 / 5 = 20
        -- 2. full after 60s
            -- 100 / 60 = 1.67
    -- actual values going up/down every second
    self.ratedown = 20
    self.rateup = 1.67
    -- I want user to wait... 2 seconds before stamina starts regen'ing
    self.cooldownperiod = 2
    self.needcooldown = false
    self.cooldowntask = nil
    self.time = nil
    self.inst:StartUpdatingComponent(self)
end,
nil,
{
    maxstamina = onmaxstamina,
    currentstamina = oncurrentstamina,
    usingstamina = onusingstamina,
    penalty = onpenalty,
})
----------------------------------------------------------------------
function Stamina:OnRemoveFromEntity()
    self:StopRegen()
end
----------------------------------------------------------------------
function Stamina:ForceUpdateHUD(overtime)
    self:DoDelta(0, overtime, nil, true, nil, true)
end
----------------------------------------------------------------------
function Stamina:OnSave()
    return
    {
        stamina = self.currentstamina,
        penalty = self.penalty > 0 and self.penalty or nil,
		maxstamina = self.save_maxstamina and self.maxstamina or nil
    }
end
----------------------------------------------------------------------
function Stamina:OnLoad(data)
	if data.maxstamina ~= nil then
		self.maxstamina = data.maxstamina
	end

    local haspenalty = data.penalty ~= nil and data.penalty > 0 and data.penalty < 1
    if haspenalty then
        self:SetPenalty(data.penalty)
    end

    if data.currentstamina ~= nil then
        self:SetVal(data.currentstamina, "file_load")
        self:ForceUpdateHUD(true)
    elseif data.percent ~= nil then
        -- used for setpieces!
        -- SetPercent already calls ForceUpdateHUD
        self:SetPercent(data.percent, true, "file_load")
    elseif haspenalty then
        self:ForceUpdateHUD(true)
    end
end
----------------------------------------------------------------------
function Stamina:SetPenalty(penalty)
    --Penalty should never be less than 0% or ever above 75%.
    self.penalty = math.clamp(penalty, 0, TUNING.MAXIMUM_STAMINA_PENALTY)
end
----------------------------------------------------------------------
function Stamina:DeltaPenalty(delta)
    self:SetPenalty(self.penalty + delta)
    self:ForceUpdateHUD(false) --handles capping stamina at max with penalty
end
----------------------------------------------------------------------
function Stamina:GetPenaltyPercent()
    return self.penalty
end
----------------------------------------------------------------------
function Stamina:GetPercent()
    return self.currentstamina / self.maxstamina
end
----------------------------------------------------------------------
function Stamina:GetPercentWithPenalty()
    return self.currentstamina / self:GetMaxWithPenalty()
end
----------------------------------------------------------------------
function Stamina:SetCurrentStamina(amount)
    self.currentstamina = amount
end
----------------------------------------------------------------------
function Stamina:SetMaxStamina(amount)
    self.maxstamina = amount
    self.currentstamina = amount
    self:ForceUpdateHUD(true) --handles capping stamina at max with penalty
end
----------------------------------------------------------------------
function Stamina:SetMinStamina(amount)
    self.minstamina = amount
end
----------------------------------------------------------------------
function Stamina:GetMaxWithPenalty()
    return self.maxstamina - self.maxstamina * self.penalty
end
----------------------------------------------------------------------
function Stamina:MakeTired()
    if self.currentstamina > 0 then
        self:DoDelta(-self.currentstamina, nil, nil)
    end
end
----------------------------------------------------------------------
function Stamina:IsTired()
    return self.currentstamina <= 0
end
----------------------------------------------------------------------
function Stamina:MakeFull()
    self:DoDelta(self.maxstamina, nil, nil)
end
----------------------------------------------------------------------
function Stamina:IsFull()
    return self.currentstamina >= self.maxstamina
end
----------------------------------------------------------------------
function Stamina:SetPercent(percent, overtime)
    self:SetVal(self.maxstamina * percent)
    self:DoDelta(0, overtime)
end
----------------------------------------------------------------------
-- Ways to implement stamina regeneration:
-- 1. StartRegen()
    -- Amount increased by certain value every X seconds.
        -- Stamina increase always but.. if I can use Shift callback to stop/start/set value...
-- 2. OnUpdate() - (StartUpdatingComponent must be called)
        -- Best option because we don't want stamina regenerating while user is moving.
        -- * Can check if monsters are nearby to determine if stamina should be empty
----------------------------------------------------------------------
function Stamina:StopCooldown()
    if self.cooldowntask ~= nil then
        self.cooldowntask:Cancel()
        self.cooldowntask = nil
    end
end
----------------------------------------------------------------------
local function finish_cooldown(self)
    self:StopCooldown()
    self.needcooldown = false
    print("COOLDOWN FINISHED")
end
----------------------------------------------------------------------
-- Stop player from sprinting by resetting walk speed
----------------------------------------------------------------------
function Stamina:ResetPlayerSpeed()
    print("ResetPlayerSpeed")
end
----------------------------------------------------------------------
-- [Setter] Sets actual stamina value
-- an example cause : "file_load"
-- Cooldown of 2 seconds when player is tired, but player has to let go of stamina key.
-- cooldown reset each time player presses stamina key before finished
----------------------------------------------------------------------
function Stamina:SetValue(value, cause)
    local old_stamina = self.currentstamina
    -- make sure its between min and max (don't forget penalty)
    self.currentstamina = math.clamp(value, self.minstamina, self:GetMaxWithPenalty())
    if old_stamina > 0 and self.currentstamina <= 0 then
        self:ResetPlayerSpeed()
        self.needcooldown = true
    elseif self.currentstamina > 0 then
        -- maybe food can cancel cooldown in the future?
        if self.cooldowntask ~= nil then
            self.cooldowntask:Cancel()
            self.cooldowntask = nil
        end
        self.needcooldown = false
    end
end
----------------------------------------------------------------------
function Stamina:SetIsSprinting(flag)
    if self.usingstamina ~= flag then
        self.old_usingstamina = self.usingstamina
        self.usingstamina = flag
    end
end
----------------------------------------------------------------------
-- [Event Push] Sets stamina percentage (used for UI?)
-- overtime: True if amount is supposed to be given over time?
----------------------------------------------------------------------
function Stamina:DoDelta(amount, overtime, cause)
    local old_percent = self:GetPercent()
    self:SetValue(self.currentstamina + amount, cause)
    local new_percent = self:GetPercent()
    self.inst:PushEvent("staminadelta", { oldpercent = old_percent, newpercent = new_percent, overtime = overtime, amount = amount })

    if self.ondelta ~= nil then
        self.ondelta(self.inst, old_percent, new_percent)
    end
    return amount
end
----------------------------------------------------------------------
-- debug
local function PrintInterval(self, dt, interval)
    if self.time == nil then
        self.time = dt
    elseif self.time >= interval then
        print("========================")
        print(self.currentstamina)
        self.time = dt
    else
        self.time = self.time + dt
    end
end
----------------------------------------------------------------------
-- Stamina cannot regen if ANY of these are true
-- 1. spawn protected
-- 2. sleeping
-- 3. teleporting
-- 4. stamina bar full
----------------------------------------------------------------------
local function CanStaminaRegen(self)
    if self.inst:HasTag("spawnprotection") or
        self.inst.sg:HasStateTag("sleeping") or
        self.inst.is_teleporting or
        self:IsFull() then
        return false
    else
        return true
    end
end
----------------------------------------------------------------------
-- Start player sprinting
----------------------------------------------------------------------
function Stamina:BoostWalkSpeed()
    print("BoostWalkSpeed")
end
----------------------------------------------------------------------
-- MAIN LOOP
-- This is called every tick (33ms) after StartUpdatingComponent is called
-- Note: Here using_stamina means player is holding down the shift button
----------------------------------------------------------------------
function Stamina:OnUpdate(dt)
    PrintInterval(self, dt, 1.0)

    -- Are we in cooldown?
    if self.need_cooldown then
        -- if button state hasn't changed -> exit
        if self.old_usingstamina == self.usingstamina then return end
        -- button state has changed -> check if sprinting
        if self.usingstamina then
            -- cancel task -> not starting till user stops sprinting -- REVIEW THIS
            self:StopCooldown()
        else
            -- restart task
            self.cooldowntask = self.inst:DoTaskInTime(self.cooldownperiod, finish_cooldown, self)
        end
        -- set old to current so we only come here when button state changes
        self.old_usingstamina = self.usingstamina
        -- we're in cooldown so no need to execute the next block of code
        return
    end

    if self.usingstamina then
        if not self:IsTired() then
            -- if just started sprinting, set speed
            if self.old_usingstamina ~= self.usingstamina then
                self:BoostWalkSpeed()
                self.old_usingstamina = self.usingstamina
            end
            self:DoDelta(-self.ratedown * dt, true) -- decrease stamina
        end
    else
        if self.old_usingstamina ~= self.usingstamina then
            self:ResetPlayerSpeed()
        end
        if CanStaminaRegen(self) then
            self:DoDelta(self.rateup * dt, true) -- increase stamina
        end
    end
end
----------------------------------------------------------------------
return Stamina
