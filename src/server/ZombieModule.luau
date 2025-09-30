local Module = {}
--//Services
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

function Module.new()
	local self = {
		zombie = ServerStorage.zombie:Clone(),
		aggroRadios = 50,
		attackRange = 4,
	}
	return setmetatable(self, { __index = Module })
end

function Module:setPositon(position: Vector3)
	self.zombie.Parent = game.Workspace
	self.zombie:PivotTo(position)
	self.zombie:WaitForChild("Humanoid")
end

function Module:getTarget()
	-- look for targets
	while not self.target and task.wait(1) do
		for _, player in Players:GetChildren() do
			if not player.character or player.character.Humanoid.Health <= 0 then
				continue
			end
			if
				(self.zombie:GetPivot().Position - player.character:GetPivot().Position).magnitude
				< self.aggroRadios
			then
				if
					not self.target
					or (self.target:GetPivot().Position - player.character:GetPivot().Position).magnitude
						> (self.zombie:GetPivot().Position - player.character:GetPivot().Position).magnitude
				then
					self.target = player.character
				end
			end
		end
	end
end

function Module:walkToTarget()
	if not self.target or not self.target:WaitForChild("Humanoid") or self.target.Humanoid.Health <= 0 then
		self:getTarget()
		return
	end

	while (self.target:GetPivot().Position - self.zombie:GetPivot().Position).magnitude > self.attackRange do
		if not self.target or not self.target:WaitForChild("Humanoid") or self.target.Humanoid.Health <= 0 then
			self:getTarget()
			return
		end
		local PathfindingService = game:GetService("PathfindingService")

		local path = PathfindingService:CreatePath()

		local character = self.zombie
		local humanoid = character:WaitForChild("Humanoid")

		local TEST_DESTINATION = self.target:GetPivot().Position

		local waypoints
		local nextWaypointIndex
		local reachedConnection
		local blockedConnection

		local function followPath(destination)
			-- Compute the path
			local success, errorMessage = pcall(function()
				path:ComputeAsync(character.PrimaryPart.Position, destination)
			end)

			if success and path.Status == Enum.PathStatus.Success then
				-- Get the path waypoints
				waypoints = path:GetWaypoints()

				-- Detect if path becomes blocked
				blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
					-- Check if the obstacle is further down the path
					if blockedWaypointIndex >= nextWaypointIndex then
						-- Stop detecting path blockage until path is re-computed
						blockedConnection:Disconnect()
						-- Call function to re-compute new path
						followPath(destination)
					end
				end)

				-- Detect when movement to next waypoint is complete
				if not reachedConnection then
					reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
						if reached and nextWaypointIndex < #waypoints then
							-- Increase waypoint index and move to next waypoint
							nextWaypointIndex += 1
							humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
						else
							reachedConnection:Disconnect()
							blockedConnection:Disconnect()
						end
					end)
				end

				-- Initially move to second waypoint (first waypoint is path start; skip it)
				nextWaypointIndex = 2
				humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
			else
				warn("Path not computed!", errorMessage)
			end
		end

		followPath(TEST_DESTINATION)
	end
end

function Module:attack() end

return Module
