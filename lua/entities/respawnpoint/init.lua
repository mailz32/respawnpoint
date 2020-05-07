AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")
DEFINE_BASECLASS("base_gmodentity")

RespawnPoint = RespawnPoint or {}


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
    self.spark_timer = 0
    self:Discharge()
    self:UpdateLabel()
    self:UpdateIndicator()
end

-- Overrided just to assign SENT to player who spawned it
function ENT:SpawnFunction(ply, tr, ClassName)
    local ent = BaseClass.SpawnFunction(self, ply, tr, ClassName)
    ent:SetPlayer(ply)
    return ent
end

-- Unbind duplicated spawnpoint from previous owner
function ENT:OnEntityCopyTableFinish(entdata)
    entdata.AssignedPlayer = NULL
end

function ENT:PostEntityPaste(ply)
    self:SetPlayer(ply)
    self:Discharge()
end

-- Emit impact sound on collide or consume suit battery
function ENT:PhysicsCollide(data)
    local hitent = data.HitEntity

    if IsValid(hitent) and
       hitent:GetClass() == "item_battery" and
       self.HP < RespawnPoint.MaxHP
    then
        self.battery_fed = hitent
        return -- Do not emit impact sound
    end

    if data.DeltaTime > 0.2 then
        self:EmitSound(Sound("SolidMetal.ImpactSoft"))
    end

end

function ENT:OnTakeDamage(dmginfo)
    self.HP = self.HP - dmginfo:GetDamage()
    if self.HP <= 0 then
        self:Explode()
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
    if not self.charged and self.charge_timer < curtime then
        self:Recharge()
    end

    -- Check for battery fed
    if IsValid(self.battery_fed) then
        self:ConsumeBattery(self.battery_fed)
    end

    -- Play teleporting effect if needed
    if self.should_play_tp_effect then
        self:TeleportingEffect()
        self.should_play_tp_effect = false
    end

    -- Emit sparks at low HP
    if self.HP <= RespawnPoint.LowHP and self.spark_timer < curtime then
        self.spark_timer = curtime + math.random(4, 12)
        self:Spark()
    end

    BaseClass.Think(self)
end


--[[              Custom functions              ]]

function ENT:MovePlayer(ply)
    if self.charged then
        local pos = self:GetPos()
        -- Move player
        ply:SetPos(pos + Vector(0, 0, 20))

        -- Teleporting effect is applied in next Think to ensure that
        -- player enters in sound play range
        self.should_play_tp_effect = true

        self:Discharge()
    else
        ply:PrintMessage(HUD_PRINTCENTER, "Respawn Point not yet charged")
    end
end

function ENT:TeleportingEffect()
        -- Add visual effect
        local effectdata = EffectData()
        effectdata:SetOrigin(self:LocalToWorld(Vector(0, 0, 20)))
        util.Effect("VortDispel", effectdata, true, true)

        -- Play sound
        self:EmitSound(Sound(table.Random(RespawnPoint.TeleportSounds)), 85, 150)
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

-- Restore device health with suit battery by up to 40 points
function ENT:ConsumeBattery(bat)
    local max_HP = RespawnPoint.MaxHP

    self.HP = self.HP + math.min(max_HP - self.HP, 40)
    self:EmitSound(Sound("items/battery_pickup.wav"), 75, 125)

    bat:Remove()
end

function ENT:Spark()
    -- Add spark effect
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    effectdata:SetMagnitude(4)
    effectdata:SetRadius(2)
    util.Effect("ElectricSpark", effectdata)

    -- Play sound
    self:EmitSound(Sound(table.Random(RespawnPoint.SparkSounds)), 75, 150)
end

function ENT:Explode()
    -- Add spark effect
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    effectdata:SetMagnitude(6)
    effectdata:SetRadius(4)
    effectdata:SetScale(2)
    util.Effect("ElectricSpark", effectdata)

    -- Play sound
    self:EmitSound(Sound(table.Random(RespawnPoint.ExplodeSounds)), 75, 150)

    self:Remove()
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

    self:UpdateLabel()
    self:UpdateIndicator()
end

function ENT:UnassignPlayer()
    local ply = self.AssignedPlayer
    if IsValid(ply) then
        ply.RespawnPoint = NULL
    end

    self.AssignedPlayer = NULL

    self:EmitSound(Sound("buttons/combine_button7.wav"), 65, 100, 0.75)

    self:UpdateLabel()
    self:UpdateIndicator()
end

function ENT:UpdateLabel()
    local ply = self.AssignedPlayer
    local name = "<unassigned>"

    if IsValid(ply) then
        name = ply:Nick()
    end

    self:SetOverlayText("Respawn Point\nPlayer: " .. name)
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
