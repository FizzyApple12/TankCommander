
import "CoreLibs/sprites"
import "CoreLibs/animation"
import "CoreLibs/frameTimer"

local splashImage = playdate.graphics.image.new("images/SplashScreen.png")
local splashSprite = playdate.graphics.sprite.new(splashImage)
splashSprite:moveTo(200, 120)

function Init()
    splashSprite:add()
end

function Update() 
    
end

function Dispose()
    splashSprite:remove()
end

function SetCamera(position) 
    playdate.graphics.setDrawOffset(position.x, position.y)
end

return {
    Init = Init,
    Update = Update,
    Dispose = Dispose,
}