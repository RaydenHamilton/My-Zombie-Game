local Module = {}
--//Services
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
function Module.new()
	local self = {
		zombie = ReplicatedStorage.Humanoids.Zombie:Clone(),
		attacking = false,
		aggroRadios = 50,
		attackRange = 4,
		movingAway = false,
	}
	local highlight = Instance.new("Highlight")
	highlight.Parent = self.zombie
	return setmetatable(self, { __index = Module })
end

function Module:setPositon(position: Vector3)
	self.zombie.Parent = workspace.Entities.Humanoids.Zombies
	self.zombie:PivotTo(position)
	self.zombie:WaitForChild("Humanoid")
end

function Module:getTarget()
	self.target = nil
	self.zombie.Highlight.FillColor = Color3.new(0.301961, 1, 0)
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

function Module:IsTargetMoreThen(number)
	if
		self.target
		and (self.target.HumanoidRootPart.Position - self.zombie.HumanoidRootPart.Position).magnitude > number
	then
		return true
	else
		return false
	end
end

function Module:IsTargetLessThen(number)
	if
		self.target
		and (self.target.HumanoidRootPart.Position - self.zombie.HumanoidRootPart.Position).magnitude > number
	then
		return true
	else
		return false
	end
end

function Module:walkToTarget()
	if not self.target or not self.target:WaitForChild("Humanoid") or self.target.Humanoid.Health == 0 then
		self:getTarget()
	end
	local path = PathfindingService:CreatePath({ AgentCanJump = false })

	local character = self.zombie
	local humanoid = character:WaitForChild("Humanoid")

	local TEST_DESTINATION = self.target:GetPivot().Position

	local waypoints
	local nextWaypointIndex
	local reachedConnection
	local blockedConnection
	local function followPath(destination)
		local success, errorMessage = pcall(function()
			path:ComputeAsync(character.PrimaryPart.Position, destination)
		end)

		if success and path.Status == Enum.PathStatus.Success then
			waypoints = path:GetWaypoints()

			blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
				if blockedWaypointIndex >= nextWaypointIndex then
					blockedConnection:Disconnect()
					followPath(destination)
				end
			end)

			if not reachedConnection then
				reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
					if reached and nextWaypointIndex < #waypoints then
						nextWaypointIndex += 1
						humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
					else
						reachedConnection:Disconnect()
						blockedConnection:Disconnect()
					end
				end)
			end
			nextWaypointIndex = 2
			humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
		else
			warn("Path not computed!", errorMessage)
		end
	end
	RunService.RenderStepped:Connect(function()
		if self:IsTargetMoreThen(0) then
			for _, folder in Workspace.Entities.Humanoids:GetChildren() do
				for _, entity in folder:GetChildren() do
					if
						entity ~= self.zombie
						and (entity.HumanoidRootPart.Position - self.zombie.HumanoidRootPart.Position).magnitude < 4
					then
						local offset = self.zombie.HumanoidRootPart.Position - entity.HumanoidRootPart.Position
						self.zombie.Humanoid:MoveTo(self.zombie.HumanoidRootPart.Position + offset.Unit * 6)
					end
				end
			end
		end
		if self:IsTargetLessThen(50) then
			if self:IsTargetMoreThen(self.attackRange) then
				self:attack()
			end
		end
		if self.attacking == false then
			followPath(TEST_DESTINATION)
		end
	end)
end

function Module:attack()
	if self.attacking == true then
		return
	end
	self.attacking = true
	(self.zombie.Highlight :: Highlight).FillColor = Color3.new(0.2, 0, 1)
	task.wait(1)
	local rayOrigin = self.zombie.HumanoidRootPart.Position
	local rayDirection = self.zombie.HumanoidRootPart.CFrame.LookVector * Vector3.new(0, 0, 5)
	local raycastResults = Workspace:Raycast(rayOrigin, rayDirection)
	if raycastResults and Players:GetPlayerFromCharacter(raycastResults.Instance:FindFirstAncestorOfClass("Model")) then
		raycastResults.Instance:FindFirstAncestorOfClass("Model").Humanoid:TakeDamage(29)
	end

	self.zombie.Highlight.FillColor = Color3.new(1, 0, 0)
	self.attacking = false
end

return Module
