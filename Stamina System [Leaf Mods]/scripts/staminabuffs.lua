local StaminaBuffs = Class(function(self, inst)
    self.inst = inst
end)

function StaminaBuffs:GetBuff(action)
    if self.inst.components.workmultiplier ~= nil then
        return self.inst.components.workmultiplier:GetMultiplier(action)
    end
    return 1
end

function StaminaBuffs:AddBuff(action, multiplier)
    if self.inst.components.workmultiplier ~= nil then
        self.inst.components.workmultiplier:AddMultiplier(action, multiplier, self.inst)
    end
end

function StaminaBuffs:RemoveBuff(action)
    if self.inst.components.workmultiplier ~= nil then
        self.inst.components.workmultiplier:RemoveMultiplier(action, self.inst)
    end
end

return StaminaBuffs
