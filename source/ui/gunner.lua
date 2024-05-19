Gunner = {}

Gunner.Tank = {}

Gunner.Tank.remoteTankImagetable = playdate.graphics.imagetable.new("images/Tank-Enemy-table-32-32.png")
Gunner.Tank.localTankImagetable = playdate.graphics.imagetable.new("images/Tank-Player-table-32-32.png")

function Gunner.Tank.New()
    return {
        sprite = playdate.graphics.sprite.new(),
        rollTime = 0
    }
end

function Gunner.Tank.Draw(tank, position, bodyRotation, turretRotation, moving, type)
    local PI = 3.14159

    local bodyRot = math.fmod(bodyRotation, 2 * PI)

    local animationSet = 1

    if bodyRot <= (PI / 4) or bodyRot > ((7 * PI) / 4) then
        animationSet = 3
    elseif bodyRot > (PI / 4) and bodyRot <= ((3 * PI) / 4) then
        animationSet = 2
    elseif bodyRot > ((3 * PI) / 4) and bodyRot <= ((5 * PI) / 4) then
        animationSet = 1
    elseif bodyRot > ((5 * PI) / 4) and bodyRot <= ((7 * PI) / 4) then
        animationSet = 4
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
    tank.sprite:moveTo(position.x, position.y)

    local imageIndex = animationSet + (subframe * 4)

    if type then 
        tank.sprite:setImage(Gunner.Tank.localTankImagetable[imageIndex])
    else
        tank.sprite:setImage(Gunner.Tank.remoteTankImagetable[imageIndex])
    end
end

local vignetteImage = playdate.graphics.image.new("images/GunnerVignette.png")
local vignetteSprite = playdate.graphics.sprite.new(vignetteImage)
vignetteSprite:moveTo(0, 0)

Gunner.TankSprites = {
    Gunner.Tank.New(),
    Gunner.Tank.New()
}

function Gunner.Init()
    vignetteSprite:add()

    for i=1,#Gunner.TankSprites do
        Gunner.TankSprites[i].sprite:add()
    end
end

cameraX = 0
cameraY = 1 

function Gunner.Update() 

    Gunner.SetCamera(0, 0)

    for i=1,#Game.TeamPlayers do
        -- Game.TeamPlayers[i].position.x
        local moving = Game.TeamPlayers[i].position.vf ~= 0 or Game.TeamPlayers[i].position.vr ~= 0

        if i == Game.LocalTeam then
            Gunner.Tank.Draw(Gunner.TankSprites[i], Game.TeamPlayers[i].position, Game.TeamPlayers[i].position.r, Game.TeamPlayers[i].position.tr, moving, true)
        else
            Gunner.Tank.Draw(Gunner.TankSprites[i], Game.TeamPlayers[i].position, Game.TeamPlayers[i].position.r, Game.TeamPlayers[i].position.tr, moving, false)
        end
    end
end

function Gunner.Dispose()
    vignetteSprite:remove()

    for i=1,#Gunner.TankSprites do
        Gunner.TankSprites[i].sprite:remove()
    end
end

function Gunner.SetCamera(x, y) 
    playdate.graphics.setDrawOffset(x + 200, y + 120)
    vignetteSprite:moveTo(x, y)
end