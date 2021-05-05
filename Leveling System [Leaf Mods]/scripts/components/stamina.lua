local function onmaxstamina(self, maxstamina)
    self.inst.replica.stamina:SetMax(maxstamina)
    self.inst.replica.stamina:SetIsFull((self.currentstamina or maxstamina) >= maxstamina)
end

local function oncurrentstamina(self, currentstamina)
    self.inst.replica.stamina:SetCurrent(currentstamina)
    self.inst.replica.stamina:SetIsTired(currentstamina <= 0)
    self.inst.replica.stamina:SetIsFull(currentstamina >= self.maxstamina)
end

local function onpenalty(self, penalty)
    self.inst.replica.stamina:SetPenalty(penalty)
end

local Stamina = Class(function(self, inst)
    self.inst = inst
    self.maxstamina = 100
    self.minstamina = 0
    self.currentstamina = self.maxstamina
    self.using_stamina = false
    self.penalty = 0.0
    self.rate = 1
    -- self.cooldown = 0
    -- self.regen_rate = 0
end,
nil,
{
    maxstamina = onmaxstamina,
    currentstamina = oncurrentstamina,
    penalty = onpenalty,
})

function Stamina:OnRemoveFromEntity()
    print("=====================================")
    print("OnRemoveFromEntity")
    self:StopRegen()
end

function Stamina:ForceUpdateHUD(overtime)
    print("=====================================")
    print("ForceUpdateHUD")
    self:DoDelta(0, overtime, nil, true, nil, true)
end

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

function Stamina:OnUpdate(dt)
    print("=====================================")
    print("OnUpdate")

    if not (self.inst:HasTag("spawnprotection") or
            self.inst.sg:HasStateTag("sleeping") or
            self.inst.is_teleporting) then
        self:Recalc(dt)
    end
end

function Stamina:DoUseStamina(amount)
    local time = GetTime()
    if not self.using_stamina then
        self.using_stamina = true
        self.using_staminastarttime = time
        self.inst:StartUpdatingComponent(self)

        amount = math.clamp(amount, self.minstamina, self.maxstamina)
        print("stamina amount to use = "..amount)

        self:DoDelta(-amount, false, "sprint")
    end
end

local function DoRegen(inst, self)
    print("=====================================")
    print("OnDoRegen")
    -- print(string.format("stamina:DoRegen ^%.2g/%.2fs", self.regen.amount, self.regen.period))
    -- force tired when aggro?
    if not self:IsTired() then
        self:DoDelta(self.regen.amount, true, "regen")
    --else
        --print("    can't regen from dead!")
    end
end

function Stamina:StartRegen(amount, period)
    print("=====================================")
    print("Stamina:StartRegen")
    if self.regen == nil then
        self.regen = {}
    end
    self.regen.amount = amount
    self.regen.period = period

    if self.regen.task == nil then
        print("Starting regen task")
        self.regen.task = self.inst:DoPeriodicTask(self.regen.period, DoRegen, nil, self)
    end
end

function Stamina:StopRegen()
    print("=====================================")
    print("Stamina:StopRegen")
    if self.regen ~= nil then
        if self.regen.task ~= nil then
            print("Stopping regen task")
            self.regen.task:Cancel()
            self.regen.task = nil
        end
        self.regen = nil
    end
end

function Stamina:SetPenalty(penalty)
    --Penalty should never be less than 0% or ever above 75%.
    self.penalty = math.clamp(penalty, 0, TUNING.MAXIMUM_STAMINA_PENALTY)
end

function Stamina:DeltaPenalty(delta)
    self:SetPenalty(self.penalty + delta)
    self:ForceUpdateHUD(false) --handles capping stamina at max with penalty
end

function Stamina:GetPenaltyPercent()
    return self.penalty
end

function Stamina:GetPercent()
    print("=====================================")
    print("GetPercent")
    return self.currentstamina / self.maxstamina
end

function Stamina:GetPercentWithPenalty()
    return self.currentstamina / self:GetMaxWithPenalty()
end

function Stamina:GetDebugString()
    local s = string.format("%2.2f / %2.2f", self.currentstamina, self:GetMaxWithPenalty())
    if self.regen ~= nil then
        s = s..string.format(", regen %.2f every %.2fs", self.regen.amount, self.regen.period)
    end
    return s
end

function Stamina:SetCurrentStamina(amount)
    self.currentstamina = amount
end

function Stamina:SetMaxStamina(amount)
    print("=====================================")
    print("SetMaxStamina")
    self.maxstamina = amount
    self.currentstamina = amount
    self:ForceUpdateHUD(true) --handles capping stamina at max with penalty
end

function Stamina:SetMinStamina(amount)
    self.minstamina = amount
end

function Stamina:GetMaxWithPenalty()
    return self.maxstamina - self.maxstamina * self.penalty
end

function Stamina:MakeTired()
    print("=====================================")
    print("MakeTired")
    if self.currentstamina > 0 then
        self:DoDelta(-self.currentstamina, nil, nil)
    end
end

function Stamina:IsTired()
    print("=====================================")
    print("IsTired")
    return self.currentstamina <= 0
end

function Stamina:SetPercent(percent, overtime, cause)
    self:SetVal(self.maxstamina * percent, cause)
    self:DoDelta(0, overtime, cause)
end

-- maybe things can affect stamina
function Stamina:SetVal(val, cause, afflicter)
    print("=====================================")
    print("SetVal")
    local old_stamina = self.currentstamina
    local maxstamina = self:GetMaxWithPenalty()
    local minstamina = math.min(self.minstamina or 0, maxstamina)
    print("old_stamina = "..old_stamina)
    
    if val > maxstamina then
        val = maxstamina
    end

    if val <= minstamina then
        self.currentstamina = minstamina
        -- self.inst:PushEvent("minstamina", { cause = cause, afflicter = afflicter })
    else
        self.currentstamina = val
    end

    print("currentstamina = "..self.currentstamina)

    if old_stamina > 0 and self.currentstamina <= 0 then
        print("stamina [death]")
    end
end

function Stamina:DoDelta(amount, overtime, cause)
    print("=====================================")
    print("DoDelta::amount = "..amount)

    local old_percent = self:GetPercent()
    print("DoDelta::old_percent = "..old_percent)
    self:SetVal(self.currentstamina + amount, cause)
    local new_percent = self:GetPercent()
    print("DoDelta::new_percent = "..new_percent)

    self.inst:PushEvent("staminadelta", { oldpercent = old_percent, newpercent = self:GetPercent(), overtime = overtime, cause = cause, amount = amount })

    if self.ondelta ~= nil then
        self.ondelta(self.inst, old_percent, self:GetPercent())
    end
    return amount
end

function Stamina:Recalc(dt)
    print("=====================================")
    print("Recalc")
    self:DoDelta(self.rate * dt, true)
end


return Stamina
