include("shared.lua")
DEFINE_BASECLASS("base_gmodentity")

RespawnPoint = RespawnPoint or {}

function ENT:Initialize()
    self.status = RespawnPoint.UNASSIGNED
    self.indicator_color = RespawnPoint.IndicatorColor[RespawnPoint.UNASSIGNED]

    local bounds = self:GetModelBounds()
    self.z_offset = -bounds.z + 3
end

function ENT:Draw()
    self:DrawModel()

    if (halo.RenderedEntity() == self) then return end
    -- Stop rendering halo here. Halo will be rendered only for drawn model

    local indicator_pos = self:LocalToWorld(Vector(0, 0, 11))
    -- Moved here to glue sprite to model on clients in multiplayer

    render.SetMaterial(Material("sprites/light_glow02_add"))
    render.DrawSprite(indicator_pos, 32, 32, self.indicator_color)
end

function ENT:Think()
    -- Other appearance parameters that don't need to be calculated each frame
    self.indicator_status = self:GetNWInt("IndicatorStatus", RespawnPoint.UNASSIGNED)
    self.indicator_color = RespawnPoint.IndicatorColor[self.indicator_status]

    BaseClass.Think(self) -- To attach a label and so on
end
