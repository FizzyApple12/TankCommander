import "CoreLibs/sprites"
import "CoreLibs/animation"
import "CoreLibs/frameTimer"

Home = {}

local splashImage = playdate.graphics.image.new("images/SplashScreen.png")
local splashSprite = playdate.graphics.sprite.new(splashImage)
splashSprite:moveTo(200, 120)

function Home.Init()
    splashSprite:add()
end

function Home.Update() 
    
end

function Home.Dispose()
    splashSprite:remove()
end