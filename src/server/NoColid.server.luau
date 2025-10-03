local PhysicsService = game:GetService("PhysicsService")
local humanoids = workspace:WaitForChild("Entities"):WaitForChild("Humanoids")

local groupName = "entities"

-- Safely register the group (doesn't error if it already exists)
pcall(function()
	PhysicsService:RegisterCollisionGroup(groupName)
end)

-- Disable collisions within the group
PhysicsService:CollisionGroupSetCollidable(groupName, groupName, false)

-- Function to set parts to the group
local function setCollisionGroup(object)
	if object:IsA("BasePart") then
		object.CollisionGroup = groupName -- new API
	end
	for _, child in ipairs(object:GetChildren()) do
		setCollisionGroup(child)
	end
end

-- Apply to everything already in folder
for _, folder in ipairs(humanoids:GetChildren()) do
	for _, humanoid in folder:GetChildren() do
		setCollisionGroup(humanoid)
	end
	-- Apply to new zombies that spawn later
	folder.ChildAdded:Connect(function(zombie)
		setCollisionGroup(zombie)
	end)
end
