function Init()
end

function Update() 
end

function Dispose()
end

function DrawTank(position, bodyRotation, turretRotation)
    
end

function SetCamera(position) 
    playdate.graphics.setDrawOffset(position.x, position.y)
end

return {
    Init = Init,
    Update = Update,
    Dispose = Dispose,
}