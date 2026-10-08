local Rayfield = loadstring(
    game:HttpGet("https://sirius.menu/gen2")
)()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local ESPEnabled = true
local TeamCheck = true

local AimbotEnabled = false
local AimPart = "Head"
local AimSmoothness = 0.15
local AimFOV = 150
local MaxDistance = 1000
local AimKey = Enum.UserInputType.MouseButton2

local HoldingAim = false

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "TestESP"
ESPFolder.Parent = workspace


local Window = Rayfield:CreateWindow({
    name = "Test Combat Suite",
    subtitle = "ESP + Aimbot",
    sidebarLayout = true,
})

local MainTab = Window:CreateTab({
    name = "Main",
})

local ESPTab = Window:CreateTab({
    name = "ESP",
})

local AimTab = Window:CreateTab({
    name = "Aimbot",
})

local function IsAlive(player)

    if not player.Character then
        return false
    end

    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        return false
    end

    return humanoid.Health > 0
end


local function IsValidTarget(player)

    if player == LocalPlayer then
        return false
    end

    if not IsAlive(player) then
        return false
    end

    if TeamCheck then

        if LocalPlayer.Team ~= nil and player.Team ~= nil then

            if LocalPlayer.Team == player.Team then
                return false
            end

        end

    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root then
        return false
    end

    local myCharacter = LocalPlayer.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")

    if not myRoot then
        return false
    end

    local distance = (root.Position - myRoot.Position).Magnitude

    if distance > MaxDistance then
        return false
    end

    return true
end

local function RemoveESP(player)

    local object = ESPFolder:FindFirstChild(player.Name)

    if object then
        object:Destroy()
    end

end


local function CreateESP(player)

    if player == LocalPlayer then
        return
    end

    if not player.Character then
        return
    end

    RemoveESP(player)

    local container = Instance.new("Folder")
    container.Name = player.Name
    container.Parent = ESPFolder

    local highlight = Instance.new("Highlight")

    highlight.Name = "Highlight"
    highlight.Adornee = player.Character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    highlight.FillColor = Color3.fromRGB(255, 70, 70)
    highlight.FillTransparency = 0.65

    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0

    highlight.Parent = container

    local head = player.Character:FindFirstChild("Head")

    if head then

        local billboard = Instance.new("BillboardGui")

        billboard.Name = "Info"
        billboard.Adornee = head

        billboard.Size = UDim2.new(0, 220, 0, 45)
        billboard.StudsOffset = Vector3.new(0, 3, 0)

        billboard.AlwaysOnTop = true
        billboard.Parent = container

        local label = Instance.new("TextLabel")

        label.Name = "Label"
        label.Size = UDim2.new(1, 0, 1, 0)

        label.BackgroundTransparency = 1

        label.Text = player.Name
        label.TextColor3 = Color3.fromRGB(255, 255, 255)

        label.TextStrokeTransparency = 0
        label.TextSize = 14

        label.Font = Enum.Font.GothamBold

        label.Parent = billboard

    end

end


local function UpdateESP(player)

    if not ESPEnabled then
        RemoveESP(player)
        return
    end

    if not IsValidTarget(player) then
        RemoveESP(player)
        return
    end

    if not ESPFolder:FindFirstChild(player.Name) then
        CreateESP(player)
    end

end

local function GetAimPart(character)

    if not character then
        return nil
    end

    local part = character:FindFirstChild(AimPart)

    if part then
        return part
    end

    -- Fallback
    return character:FindFirstChild("HumanoidRootPart")
end


local function GetClosestTarget()

    local closestPlayer = nil
    local closestDistance = AimFOV

    local viewportSize = Camera.ViewportSize

    local screenCenter = Vector2.new(
        viewportSize.X / 2,
        viewportSize.Y / 2
    )

    for _, player in ipairs(Players:GetPlayers()) do

        if IsValidTarget(player) then

            local character = player.Character
            local aimPart = GetAimPart(character)

            if aimPart then

                local screenPosition, visible =
                    Camera:WorldToViewportPoint(aimPart.Position)

                if visible and screenPosition.Z > 0 then

                    local screenPoint = Vector2.new(
                        screenPosition.X,
                        screenPosition.Y
                    )

                    local distanceFromCenter =
                        (screenPoint - screenCenter).Magnitude

                    if distanceFromCenter < closestDistance then

                        closestDistance = distanceFromCenter
                        closestPlayer = player

                    end

                end

            end

        end

    end

    return closestPlayer
end


local function AimAt(player)

    if not player then
        return
    end

    local character = player.Character

    if not character then
        return
    end

    local aimPart = GetAimPart(character)

    if not aimPart then
        return
    end

    local cameraPosition = Camera.CFrame.Position

    local targetCFrame =
        CFrame.new(cameraPosition, aimPart.Position)

    Camera.CFrame = Camera.CFrame:Lerp(
        targetCFrame,
        AimSmoothness
    )

end


UserInputService.InputBegan:Connect(function(input, processed)

    if processed then
        return
    end

    if input.UserInputType == AimKey then
        HoldingAim = true
    end

end)


UserInputService.InputEnded:Connect(function(input)

    if input.UserInputType == AimKey then
        HoldingAim = false
    end

end)

RunService.RenderStepped:Connect(function()

    -- Atualiza ESP
    for _, player in ipairs(Players:GetPlayers()) do

        if player ~= LocalPlayer then
            UpdateESP(player)
        end

    end

    -- Aimbot
    if AimbotEnabled and HoldingAim then

        local target = GetClosestTarget()

        if target then
            AimAt(target)
        end

    end

end)

local function SetupPlayer(player)

    if player == LocalPlayer then
        return
    end

    player.CharacterAdded:Connect(function()

        task.wait(0.3)

        UpdateESP(player)

    end)

    player:GetPropertyChangedSignal("Team"):Connect(function()

        UpdateESP(player)

    end)

    if player.Character then
        UpdateESP(player)
    end

end


for _, player in ipairs(Players:GetPlayers()) do
    SetupPlayer(player)
end


Players.PlayerAdded:Connect(function(player)

    SetupPlayer(player)

end)


Players.PlayerRemoving:Connect(function(player)

    RemoveESP(player)

end)

MainTab:CreateToggle({
    name = "Team Check",
    callback = function(value)

        TeamCheck = value

        for _, player in ipairs(Players:GetPlayers()) do

            if player ~= LocalPlayer then
                UpdateESP(player)
            end

        end

    end,
})


ESPTab:CreateToggle({
    name = "ESP",
    callback = function(value)

        ESPEnabled = value

        for _, player in ipairs(Players:GetPlayers()) do

            if player ~= LocalPlayer then
                UpdateESP(player)
            end

        end

    end,
})


AimTab:CreateToggle({
    name = "Aimbot",
    callback = function(value)

        AimbotEnabled = value

    end,
})


AimTab:CreateDropdown({
    name = "Aim Part",

    options = {
        "Head",
        "UpperTorso",
        "LowerTorso",
        "HumanoidRootPart"
    },

    default = "Head",

    callback = function(value)

        if type(value) == "table" then
            AimPart = value[1]
        else
            AimPart = value
        end

    end,
})


AimTab:CreateSlider({
    name = "Aim FOV",

    range = {
        25,
        500
    },

    increment = 5,

    default = 150,

    callback = function(value)

        AimFOV = value

    end,
})


AimTab:CreateSlider({
    name = "Smoothness",

    range = {
        0.01,
        1
    },

    increment = 0.01,

    default = 0.15,

    callback = function(value)

        AimSmoothness = value

    end,
})


AimTab:CreateSlider({
    name = "Max Distance",

    range = {
        100,
        3000
    },

    increment = 50,

    default = 1000,

    callback = function(value)

        MaxDistance = value

    end,
})


Rayfield:Notify({
    title = "GuiloHUB",
    content = "ESP + Aimbot carregados.",
    duration = 5,
})
```
