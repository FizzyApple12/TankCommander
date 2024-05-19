Game = {}

function Game.NewPlayer() 
    return {
        position = {
            -- true state
            x = 0,
            y = 0,
            r = 0,
            tr = 0,

            -- network sync
            vf = 0,
            vr = 0,
            vtr = 0
        },
        reload = 1.0,
        health = 1.0,

        mechanics = {
            forwardSpeed = 5,
            turnSpeed = 0.5,
            turretSpeed = 0.2,

            bigHitDamage = 1/8,
            smallHitDamage = 1/24,

            degreesToReload = 3 * 360
        }
    }
end

Game.SendType = {
    UpdateTruePosition = 1,
    UpdateTrueTurretPosition = 2,

    SendNewVelocity = 3,
    SendNewRotationVelocity = 4,
    SendNewTurretVelocity = 5,

    FireBig = 6,
    FireSmall = 7,

    HitBig = 8,
    HitSmall = 9,
    
    ReloadProgress = 10,

    NewHealth = 11,
}

Game.TeamType = {
    Team1 = 1,
    Team2 = 2,
}

Game.TeamRole = {
    Driver = 1,
    Gunner = 2,
}

-- 2 players for now, up to N players in the future
Game.TeamPlayers = {
    Game.NewPlayer(),
    Game.NewPlayer()
}

Game.LocalTeam = Game.TeamType.Team1
Game.LocalRole = Game.TeamRole.Driver

function Game.Send(type, data) 
    Game.Recieve(type, Game.LocalTeam, data)

    local container = {
        type = type,
        from = Game.LocalTeam,
        data = data
    }

    print("msg " .. json.encode(container))
end

function Game.Recieve(type, from, data) 
    function CASE_UpdateTruePosition(data)
        Game.TeamPlayers[from].position.x = data.x
        Game.TeamPlayers[from].position.y = data.y
        Game.TeamPlayers[from].position.r = data.r
    end

    function CASE_UpdateTrueTurretPosition(data)
        Game.TeamPlayers[from].position.tr = data
    end

    function CASE_SendNewVelocity(data)
        Game.TeamPlayers[from].position.vf = data
    end

    function CASE_SendNewRotationVelocity(data)
        Game.TeamPlayers[from].position.vr = data
    end

    function CASE_SendNewTurretVelocity(data)
        Game.TeamPlayers[from].position.vtr = data
    end

    function CASE_FireBig(data)
        Game.TeamPlayers[from].position.tr = data
        Game.TeamPlayers[from].reload = 0.0

        -- TODO: trigger any fire visuals here
    end

    function CASE_FireSmall(data)
        Game.TeamPlayers[from].position.r = data

        -- TODO: trigger any fire visuals here
    end

    function CASE_HitBig(data)
        Game.TeamPlayers[data].health = Game.TeamPlayers[data].health - Game.TeamPlayers[data].mechanics.bigHitDamage;

        if Game.LocalTeam == data and Game.LocalRole == Game.TeamRole.Driver then
            Game.Send(Game.SendType.NewHealth, Game.TeamPlayers[data].health)
        end

        -- TODO: trigger any big hit visuals here
    end

    function CASE_HitSmall(data)
        Game.TeamPlayers[data].health = Game.TeamPlayers[data].health - Game.TeamPlayers[data].mechanics.smallHitDamage;
        
        -- idea: Make small hits healable and not big hits
        
        if Game.LocalTeam == data and Game.LocalRole == Game.TeamRole.Driver then
            Game.Send(Game.SendType.NewHealth, Game.TeamPlayers[data].health)
        end

        -- TODO: trigger any small hit visuals here
    end

    function CASE_ReloadProgress(data)
        Game.TeamPlayers[from].reload = data
    end

    function CASE_NewHealth(data)
        Game.TeamPlayers[from].health = data

        if data <= 0 then
            -- TODO: trigger any death visuals here
        end
    end

    local Cases = {
        [Game.SendType.UpdateTruePosition] =  CASE_UpdateTruePosition,
        [Game.SendType.UpdateTrueTurretPosition] =  CASE_UpdateTrueTurretPosition,
        [Game.SendType.SendNewVelocity] =  CASE_SendNewVelocity,
        [Game.SendType.SendNewRotationVelocity] =  CASE_SendNewRotationVelocity,
        [Game.SendType.SendNewTurretVelocity] =  CASE_SendNewTurretVelocity,
        [Game.SendType.FireBig] =  CASE_FireBig,
        [Game.SendType.FireSmall] =  CASE_FireSmall,
        [Game.SendType.HitBig] =  CASE_HitBig,
        [Game.SendType.HitSmall] =  CASE_HitSmall,
        [Game.SendType.ReloadProgress] =  CASE_ReloadProgress,
        [Game.SendType.NewHealth] =  CASE_NewHealth,
    }

    Cases[type](data)
end

function playdate.serialMessageReceived(message)
    local container = json.decode(message)

    Game.Recieve(container.type, container.from, container.data)
end

function Game.Update() 
    for i=1, #(Game.TeamPlayers) do
        Game.TeamPlayers[i].position.x = Game.TeamPlayers[i].position.x + (Game.TeamPlayers[i].position.vf * math.sin(Game.TeamPlayers[i].position.r) * UpdateDeltaTime * Game.TeamPlayers[i].mechanics.forwardSpeed);
        Game.TeamPlayers[i].position.y = Game.TeamPlayers[i].position.y + (Game.TeamPlayers[i].position.vf * math.cos(Game.TeamPlayers[i].position.r) * UpdateDeltaTime * Game.TeamPlayers[i].mechanics.forwardSpeed);

        Game.TeamPlayers[i].position.r = Game.TeamPlayers[i].position.r + (Game.TeamPlayers[i].position.vr * UpdateDeltaTime * Game.TeamPlayers[i].mechanics.turnSpeed);
        Game.TeamPlayers[i].position.tr = Game.TeamPlayers[i].position.tr + (Game.TeamPlayers[i].position.vtr * UpdateDeltaTime * Game.TeamPlayers[i].mechanics.turretSpeed);
    end
end