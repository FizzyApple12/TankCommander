local Player = {
    Blank = {
        position = {
            x = 0,
            y = 0,
            r = 0
        },
        turretRotation = 0,
        reload = 1.0,
        health = 1.0
    }
}

local SendType = {
    UpdatePositionRotation = 1,
    UpdateTurretRotation = 2,

    FireBig = 3,
    FireSmall = 4,
    
    ReloadProgress = 5,
}

local TeamType = {
    Team1 = 1,
    Team2 = 2,
}

Team1Player = Player.Blank
Team2Player = Player.Blank

LocalTeam = TeamType.Team1

function Send(type, from, data) 
    Recieve(type, from, data)

    local container = {
        type = type,
        from = from,
        data = data
    }

    print("msg " .. json.encode(container))
end

function Recieve(type, from, data) 
    local playerToUpdate = Player.Blank

    if from == TeamType.Team1Driver or from == TeamType.Team1Gunner then
        playerToUpdate = Team1Player
    elseif from == TeamType.Team2Driver or from == TeamType.Team2Gunner then
        playerToUpdate = Team2Player
    end

    function CASE_UpdatePositionRotation(data)
        playerToUpdate.position.x = data.x
        playerToUpdate.position.y = data.y
        playerToUpdate.position.r = data.r
    end

    function CASE_UpdateTurretRotation(data)
        playerToUpdate.turretRotation = data
    end

    function CASE_FireBig(data)
        playerToUpdate.turretRotation = data
        playerToUpdate.reload = 0.0
    end

    function CASE_FireSmall(data)
        playerToUpdate.turretRotation = data
    end

    function CASE_ReloadProgress(data)
        playerToUpdate.reload = data
    end

    local Cases = {
        [SendType.UpdatePositionRotation] =  CASE_UpdatePositionRotation,
        [SendType.UpdateTurretRotation] =  CASE_UpdateTurretRotation,
        [SendType.FireBig] =  CASE_FireBig,
        [SendType.FireSmall] =  CASE_FireSmall,
        [SendType.ReloadProgress] =  CASE_ReloadProgress,
    }

    Cases[type](data)

    if from == TeamType.Team1Driver or from == TeamType.Team1Gunner then
        Team1Player = playerToUpdate
    elseif from == TeamType.Team2Driver or from == TeamType.Team2Gunner then
        Team2Player = playerToUpdate
    end
end

function playdate.serialMessageReceived(message)
    local container = json.decode(message)

    Recieve(container.type, container.from, container.data)
end

function Update() 

    -- return {
    --     team1Player: team1Player,
    --     team2Player: team2Player
    -- }
end

return {
    SendType = SendType,
    TeamType = TeamType,

    Send = Send,
    Recieve = Recieve,

    Update = Update
}