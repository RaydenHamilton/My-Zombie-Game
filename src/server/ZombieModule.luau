local Module = {}
--//Services
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Data Tables
local entitiesPositions = {}
local neighborOffsets = {
	{ -1, -1 },
	{ 0, -1 },
	{ 1, -1 }, -- NW, N, NE
	{ -1, 0 },
	{ 1, 0 }, -- W,      E
	{ -1, 1 },
	{ 0, 1 },
	{ 1, 1 }, -- SW, S, SE
}

function Module.new(humanoid)
	local self = {
		zombie = ReplicatedStorage.Humanoids[humanoid]:Clone(),
		attacking = false,
		aggroRadios = 50,
		attackRange = 4,
		movingAway = false,
		steps = 4,
	}
	self.humanoid = self.zombie.Humanoid
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

function Module:getGridPosition()
	local rawPosition = self.zombie.HumanoidRootPart.Position
	local function cutUpNumber(number)
		return math.round(number / self.steps) * self.steps
	end
	return Vector3.new(cutUpNumber(rawPosition.X), cutUpNumber(rawPosition.Y), cutUpNumber(rawPosition.Z))
end

function Module:getTestPosition(index)
	local Xoffset = neighborOffsets[index][1] * self.steps
	local Zoffset = neighborOffsets[index][2] * self.steps
	return self:getGridPosition() + Vector3.new(Xoffset, 0, Zoffset)
end

function Module:getTestMagnitude(index)
	local testPosition = self:getTestPosition(index)
	return (testPosition - self.target.HumanoidRootPart.Position).Magnitude
end

function getKey(position)
	return tostring(math.round(position.X)) .. "," .. tostring(math.round(position.Z))
end

function Module:walkToTarget()
	while true do
		local position = self:getGridPosition()
		local key = getKey(position)
		local bestPosition
		for i in neighborOffsets do
			if not entitiesPositions[getKey(self:getTestPosition(i))] then
				if not bestPosition or self:getTestMagnitude(i) < self:getTestMagnitude(bestPosition) then
					bestPosition = i
				end
			end
		end
		if
			bestPosition
			and self:getTestMagnitude(bestPosition)
				< (self:getGridPosition() - self.target.HumanoidRootPart.Position).Magnitude
		then
			self.humanoid:MoveTo(self:getTestPosition(bestPosition))
			entitiesPositions[getKey(self:getTestPosition(bestPosition))] = true
			self.humanoid.MoveToFinished:Wait()
			entitiesPositions[key] = nil
		else
			task.wait(1)
		end
	end
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

