local Driver = import "views/driver"
local Gunner = import "views/gunner"

local GameRelay = import "gameplay/relay"

local menu = playdate.getSystemMenu()

local teams = { "Team 1", "Team2" }
local currentTeam = teams[0]

local roles = { "Driver", "Gunner" }
local currentRole = roles[0]

local isReady = false

local teamSelectorMenuItem, error = menu:addOptionsMenuItem("Team", teams, currentTeam, function (value)
    currentTeam = value
end)

local roleSelectorMenuItem, error = menu:addOptionsMenuItem("Role", roles, currentRole, function (value)
    if value ~= currentRole then
        if value == roles[0] then
            Gunner.Dispose()
    
            Driver.Init()
        end
        if value == roles[1] then
            Driver.Dispose()
    
            Gunner.Init()
        end
    end

    currentRole = value
end)

local readySelectorMenuItem, error = menu:addCheckmarkMenuItem("Ready", false, function(value)
    isReady = value
end)

Driver.Init()

function playdate.update()
    playdate.graphics.clear()

    GameRelay.Send(GameRelay.SendType.UpdateRotation, GameRelay.FromType.Team1, 10)

    if currentRole == roles[0] then
        Driver.Update()
    end
    if currentRole == roles[1] then
        Gunner.Update()
    end
end