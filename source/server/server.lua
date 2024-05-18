local Player = {
    Blank = {
        position = {
            x = 0,
            y = 0,
        },
        baseRotation = 0,
        turretRotation = 0,
        health = 
    }
}

local team1Player = Player.Blank
local team2Player = Player.Blank

function Connect()
end

SendType = {
    UpdatePosition = "1",
    UpdateRotation = "2",
    UpdateTurretRotation = "3",

    FireBig = "4",
    FireSmall = "5",
    
    ReloadProgress = "6"
}

FromType = {
    Team1 = "1",
    Team2 = "2",
}

function Send(type, from, data) 
    Recieve(type, from, data)
end

function Recieve(type, from, data) 
    local playerToUpdate = Player.Blank

    if from == FromType.Team1Driver or from == FromType.Team1Gunner then
        playerToUpdate = team1Player
    elseif from == FromType.Team2Driver or from == FromType.Team2Gunner then
        playerToUpdate = team2Player
    end

    function CASE_UpdatePosition(data)
        -- playerToUpdate.
    end

    function CASE_UpdateRotation(data)
    end

    function CASE_UpdateTurretRotation(data)
    end

    function CASE_FireBig(data)
    end

    function CASE_FireSmall(data)
    end

    function CASE_ReloadProgress(data)
    end

    local Cases = {
        [SendType.UpdatePosition] =  CASE_UpdatePosition,
        [SendType.UpdateRotation] =  CASE_UpdateRotation,
        [SendType.UpdateTurretRotation] =  CASE_UpdateTurretRotation,
        [SendType.FireBig] =  CASE_FireBig,
        [SendType.FireSmall] =  CASE_FireSmall,
        [SendType.ReloadProgress] =  CASE_ReloadProgress,
    }

    Cases[type](data)

    if from == FromType.Team1Driver or from == FromType.Team1Gunner then
        team1Player = playerToUpdate
    elseif from == FromType.Team2Driver or from == FromType.Team2Gunner then
        team2Player = playerToUpdate
    end
end

function Update() 

    -- return {
    --     team1Player: team1Player,
    --     team2Player: team2Player
    -- }
end

function Disconnect()
end

return {
    Connect = Connect,
    Send = Send,

    Update = Update,
    Disconnect = Disconnect,
}