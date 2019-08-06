include("shared.lua")
DEFINE_BASECLASS("base_gmodentity")

RespawnPoint = RespawnPoint or {}

function ENT:Initialize()
    self.status = RespawnPoint.UNASSIGNED
    self.indicator_pos = Vector(0, 0, 0)
    self.indicator_color = RespawnPoint.IndicatorColor[RespawnPoint.UNASSIGNED]

    local bounds = self:GetModelBounds()
    self.z_offset = -bounds.z + 3
end

function ENT:Draw()
    self:DrawModel()
    
    if (halo.RenderedEntity() == self) then return end
    -- Stop rendering halo here. Halo will be rendered only for drawn model

    render.SetMaterial(Material("sprites/light_glow02_add"))
    render.DrawSprite(self.indicator_pos, 32, 32, self.indicator_color)
end

function ENT:Think()
    self.indicator_status = self:GetNWInt("IndicatorStatus", RespawnPoint.UNASSIGNED)
    self.indicator_color = RespawnPoint.IndicatorColor[self.indicator_status]
    self.indicator_pos = self:LocalToWorld(Vector(0, 0, self.z_offset))

    BaseClass.Think(self) -- To attach a label and so on
end
