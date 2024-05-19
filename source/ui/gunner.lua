Gunner = {}

function Gunner.Init()
end

function Gunner.Update() 
end

function Gunner.Dispose()
end

function Gunner.DrawTank(position, bodyRotation, turretRotation)
    
end

function Gunner.SetCamera(position) 
    playdate.graphics.setDrawOffset(position.x + 200, position.y + 120)
end