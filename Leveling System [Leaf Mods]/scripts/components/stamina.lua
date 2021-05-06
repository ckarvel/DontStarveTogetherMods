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
    print("onusingstamina")
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
    self.usingstamina = false
    self.penalty = 0.0
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
    print("=====================================")
    print("OnRemoveFromEntity")
    self:StopRegen()
end
----------------------------------------------------------------------
function Stamina:ForceUpdateHUD(overtime)
    print("=====================================")
    print("ForceUpdateHUD")
    self:DoDelta(0, overtime, nil, true, nil, true)
end
----------------------------------------------------------------------
function Stamina:OnSave()
    print("=====================================")
    print("OnSave")
    return
    {
        stamina = self.currentstamina,
        penalty = self.penalty > 0 and self.penalty or nil,
		maxstamina = self.save_maxstamina and self.maxstamina or nil
    }
end
----------------------------------------------------------------------
function Stamina:OnLoad(data)
    print("=====================================")
    print("OnLoad")
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
    print("=====================================")
    print("GetPercent")
    return self.currentstamina / self.maxstamina
end
----------------------------------------------------------------------
function Stamina:GetPercentWithPenalty()
    return self.currentstamina / self:GetMaxWithPenalty()
end
----------------------------------------------------------------------
function Stamina:GetDebugString()
    local s = string.format("%2.2f / %2.2f", self.currentstamina, self:GetMaxWithPenalty())
    if self.regen ~= nil then
        s = s..string.format(", regen %.2f every %.2fs", self.regen.amount, self.regen.period)
    end
    return s
end
----------------------------------------------------------------------
function Stamina:SetCurrentStamina(amount)
    self.currentstamina = amount
end
----------------------------------------------------------------------
function Stamina:SetMaxStamina(amount)
    print("=====================================")
    print("SetMaxStamina")
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
    print("=====================================")
    print("MakeTired")
    if self.currentstamina > 0 then
        self:DoDelta(-self.currentstamina, nil, nil)
    end
end
----------------------------------------------------------------------
function Stamina:IsTired()
    print("=====================================")
    print("IsTired")
    return self.currentstamina <= 0
end
----------------------------------------------------------------------
function Stamina:MakeFull()
    print("=====================================")
    print("MakeFull")
    self:DoDelta(self.maxstamina, nil, nil)
end
----------------------------------------------------------------------
function Stamina:IsFull()
    print("=====================================")
    print("IsFull")
    return self.currentstamina >= self.maxstamina
end
----------------------------------------------------------------------
function Stamina:SetPercent(percent, overtime)
    self:SetVal(self.maxstamina * percent)
    self:DoDelta(0, overtime)
end
----------------------------------------------------------------------
----------------------------------------------------------------------
-- Ways to implement stamina regeneration:
-- 1. StartRegen()
    -- Amount increased by certain value every X seconds.
        -- Stamina increase always but.. if I can use Shift callback to stop/start/set value...
-- 2. OnUpdate() - (StartUpdatingComponent must be called)
        -- Best option because we don't want stamina regenerating while user is moving.
        -- * Can check if monsters are nearby to determine if stamina should be empty
----------------------------------------------------------------------
----------------------------------------------------------------------
-- [Setter] Sets actual stamina value
-- an example cause : "file_load"
----------------------------------------------------------------------
function Stamina:SetValue(value, cause)
    print("=====================================")
    print("SetVal")
    local old_stamina = self.currentstamina
    -- make sure its between min and max (don't forget penalty)
    self.currentstamina = math.clamp(value, self.minstamina, self:GetMaxWithPenalty())

    print("old_stamina = "..old_stamina.."currentstamina = "..self.currentstamina)

    if old_stamina > 0 and self.currentstamina <= 0 then
        print("no stamina left")
    end
end
----------------------------------------------------------------------
-- TODO: Find way from main to get replica to give us this value
----------------------------------------------------------------------
function Stamina:SetIsSprinting(flag)
    print("=====================================")
    print("Server:SetIsSprinting")
    print(flag)
    self.usingstamina = flag
end
----------------------------------------------------------------------
-- [Event Push] Sets stamina percentage (used for UI?)
-- overtime: True if amount is supposed to be given over time?
----------------------------------------------------------------------
function Stamina:DoDelta(amount, overtime, cause)
    print("=====================================")
    print("DoDelta")
    local old_percent = self:GetPercent()
    self:SetValue(self.currentstamina + amount, cause)
    local new_percent = self:GetPercent()
    print("old_percent = "..old_percent.." new_percent = "..new_percent)

    self.inst:PushEvent("staminadelta", { oldpercent = old_percent, newpercent = new_percent, overtime = overtime, amount = amount })

    if self.ondelta ~= nil then
        self.ondelta(self.inst, old_percent, new_percent)
    end
    return amount
end
----------------------------------------------------------------------
-- MAIN LOOP
-- This is called every tick after StartUpdatingComponent is called
----------------------------------------------------------------------
function Stamina:OnUpdate(dt)
    print("=====================================")
    print("OnUpdate")

    if self.usingstamina then
        if self:IsTired() then
            self.usingstamina = false
            print("Ran out of stamina hoe")
        else
            print("Decrease rate = 1")
            self:DoDelta(-self.rate * dt, true)
            print("Amount decreased = "..self.rate * dt)
        end
    elseif self:IsFull() then
        print("Stamina Full, no change")
    elseif not (self.inst:HasTag("spawnprotection") or
            self.inst.sg:HasStateTag("sleeping") or
            self.inst.is_teleporting) then
        -- not using stamina and stamina not full
        self:DoDelta(self.rate * dt, true)
    end
end
----------------------------------------------------------------------
return Stamina
