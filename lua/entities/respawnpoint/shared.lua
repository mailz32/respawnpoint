--[[                Entity info             ]]
ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.Category        = "Respawn Point"
ENT.Spawnable       = true
ENT.PrintName       = "Respawn Point"
ENT.Author          = "Mailz"
ENT.Contact         = "Steam"
ENT.Purpose         = "Allow players set their custom spawn points"
ENT.Instructions    = "Spawn and press 'E' to register your spawnpoint. After respawning device will be deactivated for 60s. Avoid device damage."

--[[    Shared values (just to keep all in one place)   ]]
RespawnPoint = RespawnPoint or {}

-- Constants
RespawnPoint.RechargeTime   = 60 -- seconds
RespawnPoint.MaxHP          = 80
RespawnPoint.LowHP          = 25

-- Enums
RespawnPoint.DISCHARGED     = 0
RespawnPoint.CHARGED        = 1
RespawnPoint.UNASSIGNED     = 2

-- Sound tables
RespawnPoint.TeleportSounds = {
    "ambient/machines/teleport1.wav",
    "ambient/machines/teleport3.wav",
    "ambient/machines/teleport4.wav",
}

RespawnPoint.SparkSounds = {
    "ambient/energy/spark1.wav",
    "ambient/energy/spark2.wav",
    "ambient/energy/spark3.wav",
    "ambient/energy/spark4.wav",
    "ambient/energy/spark5.wav",
    "ambient/energy/spark6.wav",
}

RespawnPoint.ExplodeSounds = {
    "ambient/levels/labs/electric_explosion1.wav",
    "ambient/levels/labs/electric_explosion2.wav",
    "ambient/levels/labs/electric_explosion3.wav",
    "ambient/levels/labs/electric_explosion4.wav",
    "ambient/levels/labs/electric_explosion5.wav",
}

-- (Indicator) color tables
RespawnPoint.IndicatorColor = {}
RespawnPoint.IndicatorColor[RespawnPoint.UNASSIGNED] = Color(127, 127, 127)
RespawnPoint.IndicatorColor[RespawnPoint.DISCHARGED] = Color(255, 192, 0)
RespawnPoint.IndicatorColor[RespawnPoint.CHARGED] = Color(0, 63, 255)

