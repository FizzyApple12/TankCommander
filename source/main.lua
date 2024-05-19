import "game"

import "ui/home"
import "ui/driver"
-- import "ui/gunner"

local menu = playdate.getSystemMenu()

local teams = { "Team 1", "Team2" }
local currentTeam = teams[1]

-- local roles = { "Driver", "Gunner" }
-- local currentRole = roles[1]

local isReady = false

function PopulateTempMenuItems() 
    TeamSelectorMenuItem, error = menu:addOptionsMenuItem("Team", teams, currentTeam, function (value)
        currentTeam = value
    end)
    
    -- RoleSelectorMenuItem, error = menu:addOptionsMenuItem("Role", roles, currentRole, function (value)
    --     currentRole = value
    -- end)
end

function RemoveTempMenuItems() 
    menu:removeMenuItem(TeamSelectorMenuItem)
    -- menu:removeMenuItem(RoleSelectorMenuItem)
end

local readySelectorMenuItem, error = menu:addCheckmarkMenuItem("Ready", false, function(value)
    if value ~= isReady then
        if value then
            StartGame()
        else
            EndGame()
        end
    end
    
    isReady = value
end)

PopulateTempMenuItems()

Home.Init()

function StartGame() 
    if currentTeam == teams[1] then
        Game.LocalTeam = Game.TeamType.Team1
    elseif currentTeam == teams[2] then
        Game.LocalTeam = Game.TeamType.Team2
    end

    Home.Dispose()

    Game.LocalRole = Game.TeamRole.Driver
    Driver.Init()

    -- if currentRole == roles[1] then
    --     Game.LocalRole = Game.TeamRole.Driver
    --     Driver.Init()
    -- elseif currentRole == roles[2] then
    --     Game.LocalRole = Game.TeamRole.Gunner
    --     Gunner.Init()
    -- end

    RemoveTempMenuItems()
end

function EndGame() 
    -- if Game.LocalRole == Game.TeamRole.Driver then
    --     Driver.Dispose()
    -- elseif Game.LocalRole == Game.TeamRole.Gunner then
    --     Gunner.Dispose()
    -- end

    Driver.Dispose()

    Home.Init()

    PopulateTempMenuItems()
end

playdate.resetElapsedTime();

function playdate.update()
    UpdateDeltaTime = playdate.getElapsedTime();
    playdate.resetElapsedTime();

    playdate.graphics.clear()

    Game.Update()

    playdate.frameTimer.updateTimers()
    playdate.graphics.sprite.update() 

    if isReady then
        Driver.Update()

        -- if Game.LocalRole == Game.TeamRole.Driver then
        --     Driver.Update()
        -- elseif Game.LocalRole == Game.TeamRole.Gunner then
        --     Gunner.Update()
        -- end
    else
        Home.Update()
    end
end