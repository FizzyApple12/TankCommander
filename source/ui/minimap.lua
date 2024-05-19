import 'game'

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

-- Tank Icons

Minimap.Tank = {}

Minimap.Tank.remoteTankImagetable = playdate.graphics.imagetable.new("images/Tank-Enemy-table-32-32.png")
Minimap.Tank.localTankImagetable = playdate.graphics.imagetable.new("images/Tank-Player-table-32-32.png")

function Minimap.Tank.New(zindex)
    local sprite = playdate.graphics.sprite.new(Minimap.Tank.remoteTankImagetable[1])

    sprite:setZIndex(20000 + zindex)

    return {
        sprite = sprite,
        rollTime = 0
    }
end

function Minimap.Tank.Draw(tank, position, bodyRotation, turretRotation, moving, tankType)
    local PI = 3.14159

    local bodyRot = math.fmod(bodyRotation, 2 * PI)

    if bodyRot < 0 then
        bodyRot = bodyRot + (2 * PI)
    end

    local animationSet = 1

    if bodyRot <= (PI / 4) or bodyRot > ((7 * PI) / 4) then
        animationSet = 3
    elseif bodyRot > (PI / 4) and bodyRot <= ((3 * PI) / 4) then
        animationSet = 4
    elseif bodyRot > ((3 * PI) / 4) and bodyRot <= ((5 * PI) / 4) then
        animationSet = 1
    elseif bodyRot > ((5 * PI) / 4) and bodyRot <= ((7 * PI) / 4) then
        animationSet = 2
    end
    
    local subframe = 0

    if moving then
        tank.rollTime = tank.rollTime + UpdateDeltaTime

        subframe = math.floor(math.fmod(tank.rollTime * 6, 3))

        if subframe == 0 then
            subframe = 2
        elseif subframe == 2 then
            subframe = 0
        end
    else
        tank.rollTime = 0
    end
    tank.sprite:moveTo(200 + position.x, 172 + position.y)

    local imageIndex = animationSet + (subframe * 4)

    if tankType then 
        tank.sprite:setImage(Minimap.Tank.localTankImagetable[imageIndex])
    else
        tank.sprite:setImage(Minimap.Tank.remoteTankImagetable[imageIndex])
    end
end

Minimap.TankSprites = {
    Minimap.Tank.New(1),
    Minimap.Tank.New(2)
}

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
    
    for i=1, #(Minimap.TankSprites) do
        Minimap.TankSprites[i].sprite:add()
    end

    playdate.graphics.sprite.setClipRectsInRange(35, 4, 330, 199, 15000, 25000) 

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
    
    local baseMinimapPosition = Game.TeamPlayers[Game.LocalTeam].position

    for i=1, #(Minimap.TankSprites) do

        Minimap.TankSprites[i].sprite:setVisible(Minimap.Deployed)
        -- Minimap.TankSprites[i].sprite:setClipRect(35, 4, 330, 199) 

        local moving = Game.TeamPlayers[i].position.vf ~= 0 or Game.TeamPlayers[i].position.vr ~= 0


        local offsetRotation = Game.TeamPlayers[i].position.r - baseMinimapPosition.r
        local offsetTurretRotation = Game.TeamPlayers[i].position.tr - baseMinimapPosition.tr

        local offsetPosition = {
            x = Game.TeamPlayers[i].position.x - baseMinimapPosition.x,
            y = Game.TeamPlayers[i].position.y - baseMinimapPosition.y
        }

        local dx = 0
        local dy = 0

        local x = offsetPosition.x
        local y = offsetPosition.y

        local angle = baseMinimapPosition.r

        -- offsetPosition.x =      ((x - dx) * math.cos(angle)) - ((dy - y) * math.sin(angle)) + dx
        -- offsetPosition.y = dy - ((dy - y) * math.cos(angle)) + ((x - dx) * math.sin(angle))

        offsetPosition.x = ((x - dx) * math.cos(angle)) - ((y - dy) * math.sin(angle)) + dx
        offsetPosition.y = ((x - dx) * math.sin(angle)) + ((y - dy) * math.cos(angle)) + dy

        if i == Game.LocalTeam then
            Minimap.Tank.Draw(Minimap.TankSprites[i], offsetPosition, offsetRotation, offsetTurretRotation, moving, true)
        else
            Minimap.Tank.Draw(Minimap.TankSprites[i], offsetPosition, offsetRotation, offsetTurretRotation, moving, false)
        end
    end

end

function Minimap.Dispose()
    minimapFrameBackgroundSprite:remove()

    for i=1, #(Minimap.TankSprites) do
        Minimap.TankSprites[i].sprite:remove()
    end

    playdate.graphics.sprite.clearClipRectsInRange(15000, 25000) 

    minimapFrameSprite:remove()
end