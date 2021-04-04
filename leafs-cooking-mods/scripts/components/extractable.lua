local Extractable = Class(function(self, inst)
    self.inst = inst
    self.onextract = nil
    self.inst:AddTag("extractable")
end)

function Extractable:OnRemoveFromEntity()
    self.inst:RemoveTag("extractable")
end

function Extractable:SetOnExtract(fn)
    self.onextract = fn
end

function Extractable:OnExtract(doer)
    if self.onextract then
        self.onextract(self.inst, doer)
    end
end

return Extractable