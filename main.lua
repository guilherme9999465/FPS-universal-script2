local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

assert(WindUI, "WindUI não carregou")


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Config = {
    ESPEnabled = true,
    ESPTeamCheck = true,
    ESPNames = true,
    ESPDistance = true,

    AimbotEnabled = false,
    AimbotTeamCheck = true,
    AimPart = "Head",
    AimFOV = 150,
    AimSmoothness = 0.15,
    MaxDistance = 1000,
}

local ESPObjects = {}
local HoldingAim = false


local Window = WindUI:CreateWindow({
    Title = "GuiloHUB",
    Icon = "crosshair",
    Author = "Combat Testing Suite",
    Folder = "GuiloHUB",
    Size = UDim2.fromOffset(650, 500),
    Transparent = false,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 180,

    OpenButton = {
        Title = "GuiloHUB",
        Icon = "crosshair",
        Draggable = true,
        OnlyIcon = false,
    },
})

local ESPTab = Window:CreateTab("ESP", "eye")
local AimTab = Window:CreateTab("Aimbot", "crosshair")
local SettingsTab = Window:CreateTab("Settings", "settings")

Window:SelectTab(1)


local function IsAlive(character)
    if not character then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    return humanoid and humanoid.Health > 0
end

local function IsValidTarget(player, teamCheck)
    if player == LocalPlayer then
        return false
    end

    if teamCheck and LocalPlayer.Team ~= nil then
        if player.Team == LocalPlayer.Team then
            return false
        end
    end

    local character = player.Character

    if not IsAlive(character) then
        return false
    end

    local root = character:FindFirstChild("HumanoidRootPart")

    if not root then
        return false
    end

    return true
end

local function RemoveESP(player)
    local data = ESPObjects[player]

    if not data then
        return
    end

    if data.Highlight then
        data.Highlight:Destroy()
    end

    if data.Billboard then
        data.Billboard:Destroy()
    end

    ESPObjects[player] = nil
end

local function CreateESP(player)

    if player == LocalPlayer then
        return
    end

    RemoveESP(player)

    local character = player.Character

    if not character then
        return
    end


    local Highlight = Instance.new("Highlight")

    Highlight.Name = "GuiloESP"
    Highlight.Adornee = character
    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    if player.Team and player.Team.TeamColor then
        Highlight.FillColor = player.Team.TeamColor.Color
        Highlight.OutlineColor = player.Team.TeamColor.Color
    else
        Highlight.FillColor = Color3.fromRGB(255, 80, 80)
        Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    end

    Highlight.FillTransparency = 0.45
    Highlight.OutlineTransparency = 0

    Highlight.Parent = character

    local Billboard = Instance.new("BillboardGui")

    Billboard.Name = "GuiloESPInfo"
    Billboard.Adornee = character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")

    Billboard.Size = UDim2.fromOffset(200, 45)
    Billboard.StudsOffset = Vector3.new(0, 3, 0)
    Billboard.AlwaysOnTop = true

    local Text = Instance.new("TextLabel")

    Text.Size = UDim2.fromScale(1, 1)
    Text.BackgroundTransparency = 1
    Text.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text.TextStrokeTransparency = 0
    Text.TextSize = 13
    Text.Font = Enum.Font.GothamBold

    Text.Parent = Billboard
    Billboard.Parent = character

    ESPObjects[player] = {
        Highlight = Highlight,
        Billboard = Billboard,
        Text = Text,
    }
end

local function UpdateESP(player)

    local data = ESPObjects[player]

    if not data then
        return
    end

    local character = player.Character

    if not character then
        RemoveESP(player)
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")

    if not root then
        return
    end

    local valid = IsValidTarget(player, Config.ESPTeamCheck)

    if not Config.ESPEnabled or not valid then
        data.Highlight.Enabled = false
        data.Billboard.Enabled = false
        return
    end

    data.Highlight.Enabled = true
    data.Billboard.Enabled = true

    local distance = (
        Camera.CFrame.Position - root.Position
    ).Magnitude

    local nameText = ""

    if Config.ESPNames then
        nameText = player.DisplayName
    else
        nameText = ""
    end

    if Config.ESPDistance then

        if nameText ~= "" then
            nameText = nameText .. "\n"
        end

        nameText = nameText .. math.floor(distance) .. " studs"
    end

    data.Text.Text = nameText

    if player.Team and player.Team.TeamColor then
        data.Highlight.FillColor = player.Team.TeamColor.Color
        data.Highlight.OutlineColor = player.Team.TeamColor.Color
    end
end

local function SetupPlayer(player)

    if player == LocalPlayer then
        return
    end

    player.CharacterAdded:Connect(function()
        task.wait(0.25)

        if player.Character then
            CreateESP(player)
        end
    end)

    player:GetPropertyChangedSignal("Team"):Connect(function()
        task.wait()

        if player.Character then
            CreateESP(player)
        end
    end)

    if player.Character then
        CreateESP(player)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    SetupPlayer(player)
end

Players.PlayerAdded:Connect(SetupPlayer)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)


local function GetAimPart(character)

    local part = character:FindFirstChild(Config.AimPart)

    if part then
        return part
    end

    return character:FindFirstChild("HumanoidRootPart")
end

local function GetClosestTarget()

    local closestPlayer = nil
    local closestDistance = math.huge

    local center = Camera.ViewportSize / 2

    for _, player in ipairs(Players:GetPlayers()) do

        if IsValidTarget(player, Config.AimbotTeamCheck) then

            local character = player.Character
            local aimPart = GetAimPart(character)

            if aimPart then

                local distance3D = (
                    Camera.CFrame.Position - aimPart.Position
                ).Magnitude

                if distance3D <= Config.MaxDistance then

                    local screenPosition, visible = Camera:WorldToViewportPoint(
                        aimPart.Position
                    )

                    if visible then

                        local screenDistance = (
                            Vector2.new(screenPosition.X, screenPosition.Y) - center
                        ).Magnitude

                        if screenDistance <= Config.AimFOV
                            and screenDistance < closestDistance then

                            closestDistance = screenDistance
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end

    return closestPlayer
end

local function AimAt(player)

    if not player or not player.Character then
        return
    end

    local aimPart = GetAimPart(player.Character)

    if not aimPart then
        return
    end

    local targetPosition = aimPart.Position

    local direction = (
        targetPosition - Camera.CFrame.Position
    ).Unit

    local targetCFrame = CFrame.lookAt(
        Camera.CFrame.Position,
        Camera.CFrame.Position + direction
    )

    Camera.CFrame = Camera.CFrame:Lerp(
        targetCFrame,
        Config.AimSmoothness
    )
end


UserInputService.InputBegan:Connect(function(input, gameProcessed)

    if gameProcessed then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        HoldingAim = true
    end
end)

UserInputService.InputEnded:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        HoldingAim = false
    end
end)


RunService.RenderStepped:Connect(function()

    for player in pairs(ESPObjects) do
        UpdateESP(player)
    end

    if Config.AimbotEnabled and HoldingAim then

        local target = GetClosestTarget()

        if target then
            AimAt(target)
        end
    end
end)


local ESPSection = ESPTab:CreateSection("ESP Settings")

ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = Config.ESPEnabled,

    Callback = function(value)
        Config.ESPEnabled = value
    end,
})

ESPTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = Config.ESPTeamCheck,

    Callback = function(value)
        Config.ESPTeamCheck = value
    end,
})

ESPTab:CreateToggle({
    Name = "Player Names",
    CurrentValue = Config.ESPNames,

    Callback = function(value)
        Config.ESPNames = value
    end,
})

ESPTab:CreateToggle({
    Name = "Distance",
    CurrentValue = Config.ESPDistance,

    Callback = function(value)
        Config.ESPDistance = value
    end,
})

local AimSection = AimTab:CreateSection("Aimbot Settings")

AimTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = Config.AimbotEnabled,

    Callback = function(value)
        Config.AimbotEnabled = value
    end,
})

AimTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = Config.AimbotTeamCheck,

    Callback = function(value)
        Config.AimbotTeamCheck = value
    end,
})

AimTab:CreateDropdown({
    Name = "Aim Part",
    Options = {
        "Head",
        "UpperTorso",
        "LowerTorso",
        "HumanoidRootPart",
    },

    CurrentOption = {Config.AimPart},

    Callback = function(option)

        if type(option) == "table" then
            Config.AimPart = option[1]
        else
            Config.AimPart = option
        end
    end,
})

AimTab:CreateSlider({
    Name = "FOV",
    Range = {50, 500},
    Increment = 5,
    CurrentValue = Config.AimFOV,

    Callback = function(value)
        Config.AimFOV = value
    end,
})

AimTab:CreateSlider({
    Name = "Smoothness",
    Range = {0.01, 1},
    Increment = 0.01,
    CurrentValue = Config.AimSmoothness,

    Callback = function(value)
        Config.AimSmoothness = value
    end,
})

AimTab:CreateSlider({
    Name = "Max Distance",
    Range = {100, 3000},
    Increment = 50,
    CurrentValue = Config.MaxDistance,

    Callback = function(value)
        Config.MaxDistance = value
    end,
})

SettingsTab:CreateSection("Information")

SettingsTab:CreateParagraph({
    Title = "GuiloHUB",
    Content = "Combat testing interface using WindUI.\n\nESP and target-selection tools are configured through the tabs.",
})

SettingsTab:CreateButton({
    Name = "Destroy UI",

    Callback = function()
        ScreenGui = nil

        for player in pairs(ESPObjects) do
            RemoveESP(player)
        end
            
        pcall(function()
            Window:Destroy()
        end)
    end,
})

WindUI:Notify({
    Title = "GuiloHUB",
    Content = "Interface carregada com sucesso.",
    Duration = 5,
})
