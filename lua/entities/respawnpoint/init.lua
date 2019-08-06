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
    self:UnassignPlayer()
    self:Discharge()

    -- Damage
    self.HP = RespawnPoint.MaxHP
    self.spark_next = CurTime()
    self.battery_fed = NULL
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

-- Emit impact sound on collide and consume attached battery cell
function ENT:PhysicsCollide(data)
    -- Restore device health with suit battery by 40 HP
    local hitent = data.HitObject:GetEntity()
    if IsValid(hitent)
        and hitent:GetClass() == "item_battery"
        and self.HP < RespawnPoint.MaxHP
    then
        self:ConsumeBattery(hitent)
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
    if not self.charged and self.charge_ETA < curtime then
        self:Recharge()
    end

    -- Check for battery fed
    self:ConsumeBattery()

    -- Emit sparks at low HP
    if self.HP <= RespawnPoint.LowHP and self.spark_next < curtime then
        self.spark_next = curtime + math.random(4, 12)
        self:Spark()
    end

    BaseClass.Think(self)
end


--[[              Custom functions              ]]

function ENT:MovePlayer(ply)
    if self.charged then
        local pos = self:GetPos()
        -- Move player
        ply:SetPos(pos + Vector(0,0,self:BoundingRadius()))

        -- Add effect to device
        local effectdata = EffectData()
        effectdata:SetOrigin(pos)
        util.Effect("VortDispel", effectdata, true, true)

        -- Add teleporting sound
        self:EmitSound(table.Random(RespawnPoint.TeleportSounds), 80, 150)

        self:Discharge()
    else
        --ply:PrintMessage(HUD_PRINTCENTER, "Respawn point is discharged")
    end
end

function ENT:Recharge()
    self.charged = true
    self:EmitSound("buttons/combine_button3.wav", 60, 100)

    self:UpdateIndicator()
end

function ENT:Discharge()
    -- Reset timer
    self.charged = false
    self.charge_ETA = CurTime() + RespawnPoint.RechargeTime

    -- Update indicator
    self:UpdateIndicator()
end

function ENT:Spark()
    -- Apply spark effect
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    effectdata:SetMagnitude(4)
    --effectdata:SetRadius(1)
    util.Effect("ElectricSpark", effectdata)

    -- Apply spark sound
    self:EmitSound(table.Random(RespawnPoint.SparkSounds), 60, 150)
end

-- Restore device health with suit battery by 40 HP
--  This is called in PhysicsCollide with battery entity argument and
--  in Think without arguments. Removing battery in PhysicsCollide
--  results in warning about crash possibility
function ENT:ConsumeBattery(ent_battery)
    -- Remove battery and add HP if it's present
    local bat = self.battery_fed

    if IsValid(ent_battery) then
        self.battery_fed = ent_battery

    elseif IsValid(bat) then
        local max_HP = RespawnPoint.MaxHP
        self.HP = self.HP + math.min(max_HP - self.HP, 40)
        self:EmitSound("items/battery_pickup.wav", 75, 125)

        bat:Remove()
    end

end

function ENT:Explode()
    local effectdata = EffectData()
    local pos = self:GetPos()
    effectdata:SetOrigin(pos)
    util.Effect("cball_explode", effectdata)
    self:EmitSound(table.Random(RespawnPoint.ExplodeSounds), 80, 150)
    self:Remove()
end

function ENT:AssignPlayer(ply)
    -- Don't overwrite assigned player
    if IsValid(self.AssignedPlayer) then return end

    -- Unassign from previous R.P.
    if IsValid(ply.RespawnPoint) then
        ply.RespawnPoint:UnassignPlayer()
    end

    ply.RespawnPoint = self
    self.AssignedPlayer = ply
    self:UpdateLabel()
    self:UpdateIndicator()
end

function ENT:UnassignPlayer()
    local ply = self.AssignedPlayer
    if IsValid(ply) then
        ply.RespawnPoint = NULL
    end

    self.AssignedPlayer = NULL
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
