local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"

-- rgba
local STAMINA_TINT = { 160 / 255, 224 / 255, 255 / 255, 1 }
local STAMINA_DISABLED_TINT = { 100 / 255, 100 / 255, 100 / 255, 1 } -- light grey
--------------------------------------------------------------------------
local StaminaBadge = Class(Badge, function(self, owner)
  Badge._ctor(self, nil, owner, STAMINA_TINT, "status_stamina", false, true) -- no circle meter/use clear bg

  self.disabled_mode = false

  self.anim_tint = {self.anim:GetAnimState():GetMultColour()}
  self.backing_tint = {self.backing:GetAnimState():GetMultColour()}
  self.circleframe_tint = {self.circleframe:GetAnimState():GetMultColour()}

  self.arrow = self.underNumber:AddChild(UIAnim())
  self.arrow:GetAnimState():SetBank("sanity_arrow")
  self.arrow:GetAnimState():SetBuild("sanity_arrow")
  self.arrow:GetAnimState():PlayAnimation("neutral", true)
  self.arrow:SetClickable(false)
  self.arrow:GetAnimState():AnimateWhilePaused(false)

  self:StartUpdating()
end)
--------------------------------------------------------------------------
function StaminaBadge:DoTransition()
  if self.disabled_mode then
    self.anim:GetAnimState():SetMultColour(unpack(STAMINA_DISABLED_TINT))
    self.backing:GetAnimState():SetMultColour(unpack(STAMINA_DISABLED_TINT))
    self.circleframe:GetAnimState():SetMultColour(unpack(STAMINA_DISABLED_TINT))
  else
    self.anim:GetAnimState():SetMultColour(unpack(self.anim_tint))
    self.backing:GetAnimState():SetMultColour(unpack(self.backing_tint))
    self.circleframe:GetAnimState():SetMultColour(unpack(self.circleframe_tint))
  end
end
--------------------------------------------------------------------------
function StaminaBadge:OnUpdate(dt)
  local anim = "neutral"
  if self.owner ~= nil and self.owner.replica.stamina ~= nil then
    -- is it disabled?
    local disabled = self.owner.replica.stamina:IsDisabled()
    if self.disabled_mode ~= disabled then
      self.disabled_mode = disabled
      self:DoTransition()
    end
    -- don't show arrows when its disabled
    if not self.disabled_mode and not self.owner.replica.stamina:IsInvincible() then
      -- is it increasing/decreasing?
      if self.owner.replica.stamina:IsUsingStamina() then
        anim = "arrow_loop_decrease_most"
      elseif not self.owner.replica.stamina:IsFull() then
        anim = "arrow_loop_increase"
      end
    end
  end

  if self.arrowdir ~= anim then
    self.arrowdir = anim
    self.arrow:GetAnimState():PlayAnimation(anim, true)
  end
end
--------------------------------------------------------------------------
return StaminaBadge
