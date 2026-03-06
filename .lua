local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local localPlayer = Players.LocalPlayer

-- Configuration
local TOGGLE_KEY = Enum.KeyCode.P -- Change this to your preferred key
local isEnabled = false

-- Create GUI
local function createGUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CameraTrackerGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	
	-- Main frame
	local frame = Instance.new("Frame")
	frame.Name = "TrackerFrame"
	frame.Size = UDim2.new(0, 200, 0, 80)
	frame.Position = UDim2.new(0.85, 0, 0, 20) -- Top right corner
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Active = true -- Required for dragging
	frame.Draggable = false -- We'll handle dragging manually
	frame.Parent = screenGui
	
	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 5)
	title.BackgroundTransparency = 1
	title.Text = "Camera Tracker"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.Parent = frame
	
	-- Status label
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, 0, 0, 25)
	status.Position = UDim2.new(0, 0, 0, 35)
	status.BackgroundTransparency = 1
	status.Text = "Status: OFF"
	status.TextColor3 = Color3.fromRGB(255, 100, 100)
	status.TextSize = 14
	status.Font = Enum.Font.Gotham
	status.Parent = frame
	
	-- Keybind hint
	local keybind = Instance.new("TextLabel")
	keybind.Name = "Keybind"
	keybind.Size = UDim2.new(1, 0, 0, 20)
	keybind.Position = UDim2.new(0, 0, 0, 60)
	keybind.BackgroundTransparency = 1
	keybind.Text = "Press " .. TOGGLE_KEY.Name .. " to toggle"
	keybind.TextColor3 = Color3.fromRGB(150, 150, 150)
	keybind.TextSize = 12
	keybind.Font = Enum.Font.Gotham
	keybind.Parent = frame
	
	return screenGui, status, frame
end

-- Create the GUI
local gui, statusLabel, trackerFrame = createGUI()

-- Dragging functionality
local isDragging = false
local dragStartPos = Vector2.new(0, 0)
local frameStartPos = Vector2.new(0, 0)

trackerFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDragging = true
		dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
		frameStartPos = Vector2.new(trackerFrame.Position.X.Offset, trackerFrame.Position.Y.Offset)
	end
end)

trackerFrame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartPos
		local newPos = frameStartPos + delta
		
		-- Clamp position to keep frame on screen
		local screenSize = workspace.CurrentCamera.ViewportSize
		local frameSize = trackerFrame.AbsoluteSize
		
		newPos = Vector2.new(
			math.clamp(newPos.X, 0, screenSize.X - frameSize.X),
			math.clamp(newPos.Y, 0, screenSize.Y - frameSize.Y)
		)
		
		trackerFrame.Position = UDim2.new(0, newPos.X, 0, newPos.Y)
	end
end)

-- Toggle function
local function toggleTracker()
	isEnabled = not isEnabled
	
	if isEnabled then
		statusLabel.Text = "Status: ON"
		statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	else
		statusLabel.Text = "Status: OFF"
		statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	end
end

-- Handle key press
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == TOGGLE_KEY then
		toggleTracker()
	end
end)

local function getNearestHumanoid()
	local nearestHumanoid = nil
	local nearestDistance = math.huge
	
	-- Get local player's character and position
	local character = localPlayer.Character
	if not character then return nil end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	
	local myPosition = hrp.Position
	
	-- Search through all descendants for humanoids
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("Humanoid") then
			local humanoid = descendant
			local character = humanoid.Parent
			if not character then continue end
			
			-- Skip if it's the local player's humanoid
			local player = Players:GetPlayerFromCharacter(character)
			if player == localPlayer then continue end
			
			-- Skip if humanoid is dead
			if humanoid.Health <= 0 then continue end
			
			-- Get the HumanoidRootPart for position
			local otherHrp = character:FindFirstChild("HumanoidRootPart")
			if not otherHrp then continue end
			
			-- Calculate distance
			local distance = (myPosition - otherHrp.Position).Magnitude
			
			-- Update nearest if this is closer
			if distance < nearestDistance then
				nearestDistance = distance
				nearestHumanoid = humanoid
			end
		end
	end
	
	return nearestHumanoid
end

-- Update camera every frame to look at nearest humanoid (only when enabled)
RunService.RenderStepped:Connect(function()
	if not isEnabled then return end
	
	local nearestHumanoid = getNearestHumanoid()
	
	if nearestHumanoid then
		local character = nearestHumanoid.Parent
		local hrp = character:FindFirstChild("HumanoidRootPart")
		
		if hrp then
			-- Keep camera at current position but look at the humanoid
			Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, hrp.Position)
		end
	end
end)
