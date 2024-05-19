Game = import "game"

local Home = import "ui/home"

local Driver = import "ui/driver"
local Gunner = import "ui/gunner"

local menu = playdate.getSystemMenu()

local teams = { "Team 1", "Team2" }
local currentTeam = teams[1]

local roles = { "Driver", "Gunner" }
local currentRole = roles[1]

local isReady = false

function PopulateTempMenuItems() 
    TeamSelectorMenuItem, error = menu:addOptionsMenuItem("Team", teams, currentTeam, function (value)
        currentTeam = value
    end)
    
    RoleSelectorMenuItem, error = menu:addOptionsMenuItem("Role", roles, currentRole, function (value)
        currentRole = value
    end)
end

function RemoveTempMenuItems() 
    menu:removeMenuItem(TeamSelectorMenuItem)
    menu:removeMenuItem(RoleSelectorMenuItem)
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
        LocalTeam = Game.TeamType.Team1
    elseif currentTeam == teams[2] then
        LocalTeam = Game.TeamType.Team2
    end

    Home.Dispose()

    if currentRole == roles[1] then
        Driver.Init()
    elseif currentRole == roles[2] then
        Gunner.Init()
    end

    RemoveTempMenuItems()
end

function EndGame() 
    if currentRole == roles[1] then
        Driver.Dispose()
    elseif currentRole == roles[2] then
        Gunner.Dispose()
    end

    Home.Init()

    PopulateTempMenuItems()
end

function playdate.update()
    playdate.graphics.clear()

    -- Game.Send(Game.SendType.UpdatePositionRotation, Game.TeamType.Team1, {x = 0, y = 0, r = 10})

    if isReady then
        if currentRole == roles[1] then
            Driver.Update()
        elseif currentRole == roles[2] then
            Gunner.Update()
        end
    else
        Home.Update()
    end

    playdate.frameTimer.updateTimers()
    playdate.graphics.sprite.update() 
end