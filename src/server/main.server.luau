local ServerScriptService = game:GetService("ServerScriptService")

local zombieModule = require(ServerScriptService.ZombieModule)

local zombie = zombieModule.new()
zombie:setPositon(CFrame.new(0, 0, 0))

zombie:getTarget()
task.wait()
zombie:walkToTarget()
