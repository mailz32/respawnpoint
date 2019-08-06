RespawnPoint = RespawnPoint or {}

function RespawnPoint.Respawn(ply)
    local rsp = ply.RespawnPoint

    if IsValid(rsp) then
        rsp:MovePlayer(ply)
    end
end

hook.Add("PlayerSpawn", "RespawnPoint", function(ply) RespawnPoint.Respawn(ply) end)
