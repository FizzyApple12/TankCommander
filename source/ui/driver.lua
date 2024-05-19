import "CoreLibs/sprites"
import "CoreLibs/animation"
import "CoreLibs/frameTimer"

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
-- local steeringWheelImagetable = playdate.graphics.imagetable.new("images/SteeringWheel-table-128-128.png")
-- local steeringWheelSprite = playdate.graphics.sprite.new(steeringWheelImagetable[1])
-- steeringWheelSprite:moveTo(200, 181)

-- health bar
local healthBarImagetable = playdate.graphics.imagetable.new("images/HealthBar-table-128-64.png")
local healthBarSprite = playdate.graphics.sprite.new(healthBarImagetable[1])
healthBarSprite:moveTo(319, 152)

function Init()
    backgroundSprite:add()
    radarSprite:add()
    steeringWheelSprite:add()
    instrumentPanelSprite:add()
    healthBarSprite:add()
end

function Update() 
    if playdate.buttonJustPressed(playdate.kButtonA) and backgroundLoop.frame == 1 then
        backgroundLoop.paused = false
        backgroundLoop.frame = 2

        Game.Send(Game.SendType.FireBig, LocalTeam, 0)
    end
end

function Dispose()
    backgroundSprite:remove()
    radarSprite:remove()
    steeringWheelSprite:remove()
    instrumentPanelSprite:remove()
    healthBarSprite:remove()
end

return {
    Init = Init,
    Update = Update,
    Dispose = Dispose,
}