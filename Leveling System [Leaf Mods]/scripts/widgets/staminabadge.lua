local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"

local StaminaBadge = Class(Badge, function(self, owner)
    Badge._ctor(self, nil, owner, { 255 / 255, 204 / 255, 51 / 255, 1 }, "status_stamina")

    self.topperanim = self.underNumber:AddChild(UIAnim())
    self.topperanim:GetAnimState():SetBank("status_meter")
    self.topperanim:GetAnimState():SetBuild("status_meter")
    self.topperanim:GetAnimState():PlayAnimation("anim")
    self.topperanim:GetAnimState():SetMultColour(0, 0, 0, 1)
    self.topperanim:SetScale(1, -1, 1)
    self.topperanim:SetClickable(false)

    if self.circleframe ~= nil then
        self.circleframe:GetAnimState():Hide("frame")
    else
        self.anim:GetAnimState():Hide("frame")
    end

    self.circleframe2 = self.underNumber:AddChild(UIAnim())
    self.circleframe2:GetAnimState():SetBank("status_meter")
    self.circleframe2:GetAnimState():SetBuild("status_meter")
    self.circleframe2:GetAnimState():PlayAnimation("frame")

    self.sanityarrow = self.underNumber:AddChild(UIAnim())
    self.sanityarrow:GetAnimState():SetBank("sanity_arrow")
    self.sanityarrow:GetAnimState():SetBuild("sanity_arrow")
    self.sanityarrow:GetAnimState():PlayAnimation("neutral")
    self.sanityarrow:SetClickable(false)

    self:StartUpdating()
end)

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
        self.sanityarrow:GetAnimState():PlayAnimation(anim, true)
    end
end

return StaminaBadge
