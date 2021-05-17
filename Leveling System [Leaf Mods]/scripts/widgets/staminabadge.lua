local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"

-- rgba
local STAMINA_TINT = { 29 / 255, 146 / 255, 247 / 255, 1 } -- the color blue
--------------------------------------------------------------------------
local StaminaBadge = Class(Badge, function(self, owner)
    Badge._ctor(self, nil, owner, STAMINA_TINT, "status_stamina")

    self.arrow = self.underNumber:AddChild(UIAnim())
    self.arrow:GetAnimState():SetBank("sanity_arrow")
    self.arrow:GetAnimState():SetBuild("sanity_arrow")
    self.arrow:GetAnimState():PlayAnimation("neutral", true)
    self.arrow:SetClickable(false)

    self:StartUpdating()
end)
--------------------------------------------------------------------------
function StaminaBadge:OnUpdate(dt)
    local anim = "neutral"
    if  self.owner ~= nil and
        self.owner.replica.stamina ~= nil then
        if self.owner.replica.stamina:IsSprinting() then
            anim = "arrow_loop_decrease"
        elseif not self.owner.replica.stamina:IsFull() then
            anim = "arrow_loop_increase"
        end
    end

    if self.arrowdir ~= anim then
        self.arrowdir = anim
        self.arrow:GetAnimState():PlayAnimation(anim, true)
    end
end
--------------------------------------------------------------------------
return StaminaBadge
