local ServerScriptService = game:GetService("ServerScriptService")

local zombieModule = require(ServerScriptService.ZombieModule)

for i =  1,  25 do
local zombie = zombieModule.new()
zombie:setPositon(CFrame.new(i, 0, 0))
task.spawn(function() zombie:walkToTarget() end)
end