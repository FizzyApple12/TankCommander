local menu = playdate.getSystemMenu()

local teams = { "Team 1", "Team2" }
local roles = { "Driver", "Gunner" }

local menuItem, error = menu:addOptionsMenuItem("Team", teams, teams[0], function (value)
    print("Team Selected: ", value)
end)

local menuItem, error = menu:addOptionsMenuItem("Role", roles, roles[0], function (value)
    print("Role Selected: ", value)
end)

local ready, error = menu:addCheckmarkMenuItem("Ready", false, function(value)
    print("Ready: ", value)
end)

function playdate.update()
    playdate.graphics.clear()


end