AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
resource.AddSingleFile("materials/entities/respawnpoint.png")

include("shared.lua")


--[[                Overrides                   ]]

function ENT:Initialize()
    -- Appearance
    self:SetModel("models/props_combine/combine_mine01.mdl")

    -- Physics
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetMass(40)
        phys:Wake()
    end

    -- Logic
    self.HP = RespawnPoint.MaxHP
    self.play_teleportation_effect = false
    self.spark_timer = 0
    self:Discharge()
    self:UpdateLabel()
end

-- Unassign on duped entities
function ENT:PostEntityPaste()
    self.AssignedPlayer = NULL
end

-- Consume suit battery
function ENT:PhysicsCollide(data)
    local hitent = data.HitEntity

    if IsValid(hitent) and hitent:GetClass() == "item_battery" and self.HP < RespawnPoint.MaxHP
    then
        self.HP = self.HP + math.min(RespawnPoint.MaxHP - self.HP, 40)
        self:EmitSound(Sound("items/battery_pickup.wav"), 75, 125)
        hitent:Remove()
    end
end

function ENT:OnTakeDamage(dmginfo)
    self.HP = self.HP - dmginfo:GetDamage()
    if self.HP <= 0 then
        -- Play (large) spark effect
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        effectdata:SetMagnitude(6)
        effectdata:SetRadius(4)
        effectdata:SetScale(2)
        util.Effect("ElectricSpark", effectdata)

        -- Play explode sound
        self:EmitSound(Sound(table.Random(RespawnPoint.ExplodeSounds)), 75, 150)

        self:Remove()
    end

    self:TakePhysicsDamage(dmginfo)
end

function ENT:Use(activator, caller)
    if IsValid(activator) and activator:IsPlayer() then
        self:AssignPlayer(caller)
    end
end

function ENT:Think()
    local curtime = CurTime()

    -- Check recharge timer
    if IsValid(self.AssignedPlayer) and not self.charged and self.charge_timer < curtime then
        self:Recharge()
    end

    -- Periodically emit sparks at low HP
    if self.HP <= RespawnPoint.LowHP and self.spark_timer < curtime then
        self.spark_timer = curtime + math.random(4, 12)
        -- Play spark effect
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        effectdata:SetMagnitude(4)
        effectdata:SetRadius(2)
        util.Effect("ElectricSpark", effectdata)

        -- Play sound
        self:EmitSound(Sound(table.Random(RespawnPoint.SparkSounds)), 75, 150)
    end

    -- Play delayed teleportation effect
    if self.play_teleportation_effect then
        -- Play teleport effect
        local effectdata = EffectData()
        effectdata:SetOrigin(self:LocalToWorld(Vector(0, 0, 20)))
        util.Effect("VortDispel", effectdata, true, true)

        -- Play sound
        self:EmitSound(Sound(table.Random(RespawnPoint.TeleportSounds)), 85, 150)

        self.play_teleportation_effect = false
    end
end


--[[              Custom functions              ]]

function ENT:MovePlayer(ply)
    if self.charged then
        local pos = self:GetPos()
        -- Move player
        ply:SetPos(pos + Vector(0, 0, 20))

        -- Teleportation effect is applied in next Think to ensure that
        -- player enters in sound play range
        self.play_teleportation_effect = true

        self:Discharge()
    else
        ply:PrintMessage(HUD_PRINTCENTER, "Respawn Point not yet charged")
    end
end

function ENT:Recharge()
    self.charged = true
    self:EmitSound(Sound("buttons/combine_button3.wav"), 75, 100)

    self:UpdateIndicator()
end

function ENT:Discharge()
    self.charged = false
    self.charge_timer = CurTime() + RespawnPoint.RechargeTime

    self:UpdateIndicator()
end

function ENT:AssignPlayer(ply)
    -- Don't overwrite assigned player
    if IsValid(self.AssignedPlayer) then return end

    -- Unassign from previous RespawnPoint
    if IsValid(ply.RespawnPoint) then
        ply.RespawnPoint:UnassignPlayer()
    end

    ply.RespawnPoint = self
    self.AssignedPlayer = ply

    self:EmitSound(Sound("buttons/combine_button5.wav"), 65, 100, 0.75)

    self:Discharge()
    self:UpdateLabel()
end

function ENT:UnassignPlayer()
    local ply = self.AssignedPlayer
    if IsValid(ply) then
        ply.RespawnPoint = NULL
    end

    self.AssignedPlayer = NULL

    self:EmitSound(Sound("buttons/combine_button7.wav"), 65, 100, 0.75)

    self:UpdateIndicator()
    self:UpdateLabel()
end

function ENT:UpdateLabel()
    local ply = self.AssignedPlayer
    local name = "<unassigned>"

    if IsValid(ply) then
        name = ply:Nick()
    end

    self:SetOverlayText("Respawn Point\n" .. name)
end

function ENT:UpdateIndicator()
    if IsValid(self.AssignedPlayer) then
        if self.charged then
            self:SetNWInt("IndicatorStatus", RespawnPoint.CHARGED)
        else
            self:SetNWInt("IndicatorStatus", RespawnPoint.DISCHARGED)
        end
    else
        self:SetNWInt("IndicatorStatus", RespawnPoint.UNASSIGNED)
    end
end
