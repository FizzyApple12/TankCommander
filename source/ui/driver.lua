import 'ui/minimap'

import "CoreLibs/sprites"
import "CoreLibs/animation"
import "CoreLibs/frameTimer"

Driver = {}

-- clouds
local cloudOffset = 0
local cloudWidth = 800
local cloudImage = playdate.graphics.image.new("images/Clouds.png")
local cloudSprite1 = playdate.graphics.sprite.new(cloudImage)
local cloudSprite2 = playdate.graphics.sprite.new(cloudImage)
cloudSprite1:setCenter(0,0)
cloudSprite2:setCenter(0,0)
cloudSprite1:moveTo(0, 16)
cloudSprite2:moveTo(800, 16)
cloudSprite1.update = function()
    local cloudOffsetTrue = math.abs(cloudOffset - cloudWidth) + cloudWidth

    if cloudOffset <= cloudWidth then
        cloudSprite1:moveTo(-(math.fmod(cloudOffsetTrue, cloudWidth * 2) - cloudWidth), 16)
    else
        cloudSprite1:moveTo(math.fmod(cloudOffsetTrue, cloudWidth * 2) - cloudWidth, 16)
    end
end
cloudSprite2.update = function()
    local cloudOffsetTrue = math.abs(cloudOffset - cloudWidth)

    if cloudOffset <= cloudWidth then
        cloudSprite2:moveTo(-(math.fmod(cloudOffsetTrue, cloudWidth * 2) - cloudWidth), 16)
    else
        cloudSprite2:moveTo(math.fmod(cloudOffsetTrue, cloudWidth * 2) - cloudWidth, 16)
    end
end

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
local displayHealth = 1.0
local healthFlashFrameTime = 1000 / 4
local healthBarImagetable = playdate.graphics.imagetable.new("images/HealthBar-table-128-64.png")
local healthBarLoop = playdate.graphics.animation.loop.new(healthFlashFrameTime, healthBarImagetable, true)
healthBarLoop.startFrame = 8
healthBarLoop.endFrame = 9
local healthBarSprite = playdate.graphics.sprite.new(healthBarImagetable[1])
healthBarSprite:moveTo(319, 152)
healthBarSprite.update = function()
    if displayHealth <= 1/8 then
        healthBarSprite:setImage(healthBarLoop:image())
    else
        local clampedHealth = math.max(math.min(displayHealth, 1), 0)
        healthBarSprite:setImage(healthBarImagetable[math.floor((1 - clampedHealth) * 8) + 1])
    end
end

function Driver.Init()
    cloudSprite1:add()
    cloudSprite2:add()

    backgroundSprite:add()

    radarSprite:add()

    steeringWheelSprite:add()

    instrumentPanelSprite:add()
    nixieTubeSprite:add()

    healthBarSprite:add()

    Minimap.Init()
end

local lastForwardVelocity = 0
local lastRotationVelocity = 0

local steeringFrameCounter = 0;

local totalCrankDegrees = 0
local crankSendCounter = 0
local crankSendInterval = 300

local steeringFrame = 3

local minigunTimer = 0

function Driver.Update() 
    -- Big Fire

    if playdate.buttonIsPressed(playdate.kButtonA) then
        minigunTimer = minigunTimer + UpdateDeltaTime

        if not Minimap.Deployed and minigunTimer >= 1/5 then
            backgroundLoop.paused = false
            backgroundLoop.frame = 5
            minigunTimer = 0

            Game.Send(Game.SendType.FireSmall, Game.LocalTeam, 0)
        end
    end

    if playdate.buttonJustPressed(playdate.kButtonA) then
        if Minimap.Deployed and Game.TeamPlayers[Game.LocalTeam].reload >= 1 then
            Game.TeamPlayers[Game.LocalTeam].reload = 0

            backgroundLoop.paused = false
            backgroundLoop.frame = 2

            nixieTubeSprite:setVisible(true)
            nixieDisplayThumbsUp = false

            Game.Send(Game.SendType.FireBig, Game.LocalTeam, 0)
        end
    end

    -- Crank actions 

    local change, acceleratedChange = playdate.getCrankChange()

    if Minimap.Deployed then
        -- Crank-to-turret

        -- TODO: turret spinning
    else
        -- Crank-to-reload

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

            if crankSendCounter >= 1.5 and nixieTubeSprite:isVisible() then
                nixieTubeSprite:setVisible(false)
            end

            totalCrankDegrees = 0
        end

        playdate.graphics.setColor(playdate.graphics.kColorBlack)
        playdate.graphics.setLineCapStyle(playdate.graphics.kLineCapStyleRound)
        playdate.graphics.setStrokeLocation(playdate.graphics.kStrokeCentered)
        playdate.graphics.setLineWidth(3)
        local reloadGaugeEnd = Bezier(332, -199.4, 355.7, -172.8, 315.5, -164.46, 304.3, -188.36, math.max(math.min(1 - Game.TeamPlayers[Game.LocalTeam].reload, 1), 0))
        playdate.graphics.drawLine(315, 196, reloadGaugeEnd.x, -reloadGaugeEnd.y)
    end

    -- Movement input

    local newForwardVelocity = 0 
    local newRotationVelocity = 0 
    local shouldUpdatePosition = false

    local steeringFrameDeltaTime = UpdateDeltaTime * 5

    local steeringFrameCounterUpdate = 0

    if playdate.buttonIsPressed(playdate.kButtonUp) then 
        newForwardVelocity = newForwardVelocity - 1
    end
    if playdate.buttonIsPressed(playdate.kButtonDown) then 
        newForwardVelocity = newForwardVelocity + 1
    end
    if playdate.buttonIsPressed(playdate.kButtonLeft) then 
        newRotationVelocity = newRotationVelocity - 1

        steeringFrameCounterUpdate = steeringFrameCounterUpdate - steeringFrameDeltaTime
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then 
        newRotationVelocity = newRotationVelocity + 1

        steeringFrameCounterUpdate = steeringFrameCounterUpdate + steeringFrameDeltaTime
    end

    local newSteeringFrame = 1

    if steeringFrameCounterUpdate == 0 then
        if steeringFrameCounter > 0 then
            steeringFrameCounterUpdate = -math.min(steeringFrameDeltaTime, steeringFrameCounter)
        elseif steeringFrameCounter < 0 then
            steeringFrameCounterUpdate = math.min(steeringFrameDeltaTime, -steeringFrameCounter)
        end
    end
    
    steeringFrameCounter = math.max(math.min(steeringFrameCounter + steeringFrameCounterUpdate, 2), -2)
    newSteeringFrame = math.floor(steeringFrameCounter + 3)

    if newSteeringFrame == 3 then
        newSteeringFrame = 1
    elseif newSteeringFrame == 1 then
        newSteeringFrame = 3
    end

    if newSteeringFrame ~= steeringFrame then
        steeringWheelSprite:setImage(steeringWheelImagetable[newSteeringFrame])

        steeringFrame = newSteeringFrame
    end

    -- Environment Movement
    
    cloudOffset = cloudOffset - (newRotationVelocity * 2)

    -- Health Bar

    displayHealth = Game.TeamPlayers[Game.LocalTeam].health

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

    Minimap.Update()
end

function Driver.Dispose()
    cloudSprite1:remove()
    cloudSprite2:remove()

    backgroundSprite:remove()

    radarSprite:remove()

    steeringWheelSprite:remove()

    instrumentPanelSprite:remove()
    nixieTubeSprite:remove()

    healthBarSprite:remove()

    Minimap.Dispose()
end

function Bezier(x0, y0, x1, y1, x2, y2, x3, y3, t)
    return {
        x = (1-t)*((1-t)*((1-t)*x0+t*x1)+t*((1-t)*x1+t*x2))+t*((1-t)*((1-t)*x1+t*x2)+t*((1-t)*x2+t*x3)),
        y = (1-t)*((1-t)*((1-t)*y0+t*y1)+t*((1-t)*y1+t*y2))+t*((1-t)*((1-t)*y1+t*y2)+t*((1-t)*y2+t*y3))
    }
end