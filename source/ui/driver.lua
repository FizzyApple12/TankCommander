import "CoreLibs/sprites"
import "CoreLibs/animation"
import "CoreLibs/frameTimer"

Driver = {}

-- background
local backgroundFrameTime = 1000 / 12
local backgroundImagetable = playdate.graphics.imagetable.new("images/TankCockpit-table-400-240.png")
local backgroundLoop = playdate.graphics.animation.loop.new(backgroundFrameTime, backgroundImagetable, true)
backgroundLoop.startFrame = 1
backgroundLoop.endFrame = 6
backgroundLoop.paused = true
local backgroundSprite = playdate.graphics.sprite.new(backgroundLoop:image())
backgroundSprite:moveTo(200, 120)
backgroundSprite.update = function()
    backgroundSprite:setImage(backgroundLoop:image())

    if backgroundLoop.frame == 1 then
        backgroundLoop.paused = true;
    end
end

-- radar
local longRadarFrameTime = 2000
local shortRadarFrameTime = 1000 / 12
local radarImagetable = playdate.graphics.imagetable.new("images/Radar-table-128-128.png")
local radarLoop = playdate.graphics.animation.loop.new(longRadarFrameTime, radarImagetable, true)
radarLoop.startFrame = 1
radarLoop.endFrame = 10
local radarSprite = playdate.graphics.sprite.new(radarLoop:image())
radarSprite:moveTo(63, 178)
radarSprite.update = function()
    radarSprite:setImage(radarLoop:image())

    if radarLoop.frame == 1 then
        radarLoop.delay = longRadarFrameTime;
    else
        radarLoop.delay = shortRadarFrameTime;
    end
end

-- steering wheel
local steeringWheelImagetable = playdate.graphics.imagetable.new("images/SteeringWheel-table-128-128.png")
local steeringWheelSprite = playdate.graphics.sprite.new(steeringWheelImagetable[1])
steeringWheelSprite:moveTo(200, 181)

-- instrument panel
local instrumentPanelImage = playdate.graphics.image.new("images/InstrumentPanel.png")
local instrumentPanelSprite = playdate.graphics.sprite.new(instrumentPanelImage)
instrumentPanelSprite:moveTo(336, 176)

local nixieDisplayThumbsUp = true
local nixieTubeFrameTime = 1000 / 8
local nixieTubeImagetable = playdate.graphics.imagetable.new("images/Instrument_Nixie-table-64-128.png")
local nixieTubeLoop = playdate.graphics.animation.loop.new(nixieTubeFrameTime, nixieTubeImagetable, true)
nixieTubeLoop.startFrame = 1
nixieTubeLoop.endFrame = 6
local nixieTubeSprite = playdate.graphics.sprite.new(nixieTubeLoop:image())
nixieTubeSprite:moveTo(368, 176)
nixieTubeSprite:setVisible(false)
nixieTubeSprite.update = function()
    if nixieDisplayThumbsUp then
        nixieTubeSprite:setImage(nixieTubeImagetable[7])
    else
        nixieTubeSprite:setImage(nixieTubeLoop:image())
    end
end

-- health bar
local healthBarImagetable = playdate.graphics.imagetable.new("images/HealthBar-table-128-64.png")
local healthBarSprite = playdate.graphics.sprite.new(healthBarImagetable[1])
healthBarSprite:moveTo(319, 152)

function Driver.Init()
    backgroundSprite:add()
    radarSprite:add()
    steeringWheelSprite:add()
    instrumentPanelSprite:add()
    healthBarSprite:add()
    nixieTubeSprite:add()
end

local lastForwardVelocity = 0
local lastRotationVelocity = 0

local steeringFrameCounter = 0;

local totalCrankDegrees = 0
local crankSendCounter = 0
local crankSendInterval = 300

local thumbsUpShowThisIteration = true
local thumbsUpDuration = 1000

local steeringFrame = 3

function Driver.Update() 
    -- Big Fire

    if playdate.buttonJustPressed(playdate.kButtonA) and Game.TeamPlayers[Game.LocalTeam].reload >= 1 then
        Game.TeamPlayers[Game.LocalTeam].reload = 0

        backgroundLoop.paused = false
        backgroundLoop.frame = 2

        nixieTubeSprite:setVisible(true)
        nixieDisplayThumbsUp = false

        Game.Send(Game.SendType.FireBig, Game.LocalTeam, 0)
    end

    -- Crank-to-reload

    local change, acceleratedChange = playdate.getCrankChange()

    -- > for clockwise, < for counter-clockwise
    if change > 0 then
        totalCrankDegrees = totalCrankDegrees + math.abs(change)
    end

    if Game.TeamPlayers[Game.LocalTeam].reload < 1 then
        Game.TeamPlayers[Game.LocalTeam].reload = totalCrankDegrees / Game.TeamPlayers[Game.LocalTeam].mechanics.degreesToReload

        crankSendCounter = crankSendCounter + UpdateDeltaTime

        if crankSendCounter >= crankSendInterval or Game.TeamPlayers[Game.LocalTeam].reload >= 1 then
            Game.Send(Game.SendType.ReloadProgress, Game.LocalTeam, Game.TeamPlayers[Game.LocalTeam].reload)

            if Game.TeamPlayers[Game.LocalTeam].reload >= 1 then
                nixieDisplayThumbsUp = true
            end

            crankSendCounter = 0
        end
    else
        crankSendCounter = crankSendCounter + UpdateDeltaTime

        if crankSendCounter >= thumbsUpDuration and not thumbsUpShowThisIteration then
            nixieTubeSprite:setVisible(false)

            thumbsUpShowThisIteration = true
        end

        totalCrankDegrees = 0
    end

    -- Movement input

    local newForwardVelocity = 0 
    local newRotationVelocity = 0 
    local shouldUpdatePosition = false

    local steeringFrameCounterUpdate = 0

    if playdate.buttonIsPressed(playdate.kButtonUp) then 
        newForwardVelocity = newForwardVelocity - 1
    end
    if playdate.buttonIsPressed(playdate.kButtonDown) then 
        newForwardVelocity = newForwardVelocity + 1
    end
    if playdate.buttonIsPressed(playdate.kButtonLeft) then 
        newRotationVelocity = newRotationVelocity - 1

        steeringFrameCounterUpdate = steeringFrameCounterUpdate + UpdateDeltaTime
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then 
        newRotationVelocity = newRotationVelocity + 1

        steeringFrameCounterUpdate = steeringFrameCounterUpdate - UpdateDeltaTime
    end

    local newSteeringFrame = 3

    if steeringFrameCounterUpdate ~= 0 then
        steeringFrameCounter = math.max(math.min(steeringFrameCounter + steeringFrameCounterUpdate, 2), -2)
        newSteeringFrame = math.floor(steeringFrameCounter + 0.5) + 2
    else
        steeringFrameCounterUpdate = steeringFrameCounterUpdate - (math.max(math.min(steeringFrameCounterUpdate * 1000000, 1), -1) * UpdateDeltaTime)
    end

    if newSteeringFrame ~= steeringFrame then
        steeringWheelSprite:setImage(steeringWheelImagetable[newSteeringFrame])

        steeringFrame = newSteeringFrame
    end

    -- Movement update

    if newForwardVelocity ~= lastForwardVelocity then
        Game.Send(Game.SendType.SendNewVelocity, Game.LocalTeam, newForwardVelocity)

        if newForwardVelocity == 0 then
            shouldUpdatePosition = true
        end

        lastForwardVelocity = newForwardVelocity
    end
    if newRotationVelocity ~= lastRotationVelocity then
        Game.Send(Game.SendType.SendNewRotationVelocity, Game.LocalTeam, newRotationVelocity)

        if newRotationVelocity == 0 then
            shouldUpdatePosition = true
        end

        lastRotationVelocity = newRotationVelocity
    end

    if shouldUpdatePosition then
        Game.Send(Game.SendType.UpdateTruePosition, Game.LocalTeam, {
            x = Game.TeamPlayers[Game.LocalTeam].position.x,
            y = Game.TeamPlayers[Game.LocalTeam].position.y,
            r = Game.TeamPlayers[Game.LocalTeam].position.r
        })
    end
end

function Driver.Dispose()
    backgroundSprite:remove()
    radarSprite:remove()
    steeringWheelSprite:remove()
    instrumentPanelSprite:remove()
    healthBarSprite:remove()
    nixieTubeSprite:remove()
end
