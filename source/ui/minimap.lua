import "CoreLibs/sprites"
import "CoreLibs/animation"
import "CoreLibs/frameTimer"

Minimap = {}

Minimap.Deployed = false

-- minimap frame
local minimapFrameFrameTime = 1000 / 12
local minimapFrameImagetable = playdate.graphics.imagetable.new("images/Map-table-340-210.png")
local minimapFrameBackground = playdate.graphics.image.new("images/Map-table-Background.png")

local minimapFrameDeployLoop = playdate.graphics.animation.loop.new(minimapFrameFrameTime, minimapFrameImagetable, false)
minimapFrameDeployLoop.startFrame = 1
minimapFrameDeployLoop.endFrame = 11
minimapFrameDeployLoop.paused = true

local minimapFrameRetractLoop = playdate.graphics.animation.loop.new(minimapFrameFrameTime, minimapFrameImagetable, false)
minimapFrameRetractLoop.startFrame = 11
minimapFrameRetractLoop.endFrame = 16
minimapFrameRetractLoop.paused = true

local minimapFrameDeploying = false
local minimapFrameRetracting = false
local minimapFrameShowing = false

local minimapFrameBackgroundSprite = playdate.graphics.sprite.new(minimapFrameBackground)
minimapFrameBackgroundSprite:moveTo(200, 105)
minimapFrameBackgroundSprite:setZIndex(10000)
minimapFrameBackgroundSprite:setVisible(false)

local minimapFrameSprite = playdate.graphics.sprite.new(minimapFrameImagetable[0])
minimapFrameSprite:moveTo(200, 105)
minimapFrameSprite:setZIndex(30000)
minimapFrameSprite.update = function()
    if minimapFrameShowing then
        minimapFrameSprite:setVisible(true)

        if minimapFrameDeploying then
            minimapFrameSprite:setImage(minimapFrameDeployLoop:image())

            if minimapFrameDeployLoop.frame == 6 then
                Minimap.Deployed = true
                minimapFrameBackgroundSprite:setVisible(true)
            end

            if minimapFrameDeployLoop.frame == 11 then
                minimapFrameDeployLoop.paused = true
                minimapFrameDeploying = false
            end
        elseif minimapFrameRetracting then
            minimapFrameSprite:setImage(minimapFrameRetractLoop:image())

            if minimapFrameRetractLoop.frame == 12 then
                Minimap.Deployed = false
                minimapFrameBackgroundSprite:setVisible(false)
            end

            if minimapFrameRetractLoop.frame == 16 then
                minimapFrameRetractLoop.paused = true
                minimapFrameRetracting = false
                minimapFrameShowing = false
            end
        else
            minimapFrameSprite:setImage(minimapFrameImagetable[11])
        end
    else
        minimapFrameSprite:setVisible(false)
    end
end

function Minimap.Deploy() 
    minimapFrameDeployLoop.paused = false
    minimapFrameDeployLoop.frame = 1

    minimapFrameShowing = true
    minimapFrameDeploying = true
    minimapFrameRetracting = false
end

function Minimap.Retract()
    minimapFrameRetractLoop.paused = false
    minimapFrameRetractLoop.frame = 11

    minimapFrameShowing = true
    minimapFrameDeploying = false
    minimapFrameRetracting = true
end

function Minimap.Init()
    minimapFrameBackgroundSprite:add()
    minimapFrameSprite:add()
end

function Minimap.Update() 
    if playdate.buttonIsPressed(playdate.kButtonB) then
        if not minimapFrameShowing then
            Minimap.Deploy();
        end
        if minimapFrameShowing and (not minimapFrameDeploying) and (not minimapFrameRetracting) then
            Minimap.Retract();
        end
    end
end

function Minimap.Dispose()
    minimapFrameBackgroundSprite:remove()
    minimapFrameSprite:remove()
end