lua = r'''--[[
    GuiloHUB
    Author: Guilh3rm3Scr1pter

    TEST BUILD
    WindUI + ESP/target testing + visual settings + player testing.
    Intended for experiences you control / authorized testing.
]]

--==================================================
-- WINDUI
--==================================================

local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

if not WindUI then
    error("GuiloHUB: WindUI failed to load.")
end

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--==================================================
-- CONFIG
--==================================================

local Config = {
    ESPEnabled = true,
    ESPNames = true,
    ESPDistance = true,
    ESPTeamCheck = true,

    AimbotEnabled = false,
    AimPart = "Head",
    AimSmoothness = 0.85,
    AimFOV = 150,
    MaxDistance = 1000,
    WallCheck = true,

    ActivationEnabled = true,
    ActivationInput = "Keyboard",
    ActivationKey = Enum.KeyCode.Q,
    ActivationMode = "Hold",

    FOVVisible = true,
    FOVThickness = 2,
    FOVTransparency = 0.35,

    EnemyColor = Color3.fromRGB(255, 70, 70),
    TeamColor = Color3.fromRGB(70, 170, 255),
    FOVColor = Color3.fromRGB(255, 255, 255),
    TargetColor = Color3.fromRGB(255, 220, 80),

    TargetIndicator = true,

    SpeedEnabled = false,
    WalkSpeed = 16,

    JumpEnabled = false,
    JumpPower = 50,

    InfiniteJump = false,

    FlyEnabled = false,
    FlySpeed = 60,
}

local HoldingAim = false
local ToggleAim = false
local CurrentTarget = nil

--==================================================
-- WINDOW
--==================================================

local Window = WindUI:CreateWindow({
    Title = "GuiloHUB",
    Icon = "crosshair",
    Author = "Guilh3rm3Scr1pter",
    Folder = "GuiloHUB",
    Size = UDim2.fromOffset(650, 500),
    Theme = "Dark",
    Transparent = false,
    Resizable = true,
    SideBarWidth = 200,

    OpenButton = {
        Enabled = true,
        Title = "GuiloHUB",
        CornerRadius = UDim.new(0, 8),
        StrokeThickness = 2,
    },
})

local ESPTab = Window:Tab({
    Title = "ESP",
    Icon = "eye",
})

local AimTab = Window:Tab({
    Title = "Aimbot",
    Icon = "crosshair",
})

local VisualTab = Window:Tab({
    Title = "Visuals",
    Icon = "palette",
})

local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user",
})

local ConfigTab = Window:Tab({
    Title = "Configs",
    Icon = "save",
})

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
})

--==================================================
-- FOV
--==================================================

local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "GuiloHUB_FOV"
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true
FOVGui.Parent = CoreGui

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "Circle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Parent = FOVGui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Parent = FOVCircle

--==================================================
-- TARGET INDICATOR
--==================================================

local TargetGui = Instance.new("ScreenGui")
TargetGui.Name = "GuiloHUB_Target"
TargetGui.ResetOnSpawn = false
TargetGui.IgnoreGuiInset = true
TargetGui.Parent = CoreGui

local TargetLabel = Instance.new("TextLabel")
TargetLabel.AnchorPoint = Vector2.new(0.5, 0)
TargetLabel.Position = UDim2.fromScale(0.5, 0.08)
TargetLabel.Size = UDim2.fromOffset(400, 40)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.TextSize = 18
TargetLabel.TextStrokeTransparency = 0.5
TargetLabel.Visible = false
TargetLabel.Parent = TargetGui

--==================================================
-- HELPERS
--==================================================

local function GetCharacter(player)
    return player and player.Character
end

local function GetHumanoid(player)
    local character = GetCharacter(player)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function GetRoot(player)
    local character = GetCharacter(player)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function Alive(player)
    local humanoid = GetHumanoid(player)
    return humanoid and humanoid.Health > 0
end

local function IsEnemy(player)
    if not Config.ESPTeamCheck then
        return true
    end

    if not LocalPlayer.Team or not player.Team then
        return true
    end

    return LocalPlayer.Team ~= player.Team
end

--==================================================
-- ESP
--==================================================

local ESP = {}

local function RemoveESP(player)
    local data = ESP[player]
    if not data then
        return
    end

    if data.Highlight then
        data.Highlight:Destroy()
    end

    if data.Billboard then
        data.Billboard:Destroy()
    end

    ESP[player] = nil
end

local function CreateESP(player)
    if player == LocalPlayer then
        return
    end

    RemoveESP(player)

    local character = player.Character
    local root = GetRoot(player)

    if not character or not root then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "GuiloHUB_ESP"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.55
    highlight.OutlineTransparency = 0
    highlight.Parent = character

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "GuiloHUB_Info"
    billboard.Size = UDim2.fromOffset(220, 45)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = root

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextStrokeTransparency = 0.5
    label.Parent = billboard

    ESP[player] = {
        Highlight = highlight,
        Billboard = billboard,
        Label = label,
    }
end

local function UpdateESP(player)
    if player == LocalPlayer then
        return
    end

    if not Config.ESPEnabled then
        RemoveESP(player)
        return
    end

    local root = GetRoot(player)
    if not root then
        RemoveESP(player)
        return
    end

    if not ESP[player] then
        CreateESP(player)
    end

    local data = ESP[player]
    if not data then
        return
    end

    local enemy = IsEnemy(player)
    local color = enemy and Config.EnemyColor or Config.TeamColor

    data.Highlight.FillColor = color
    data.Highlight.OutlineColor = color
    data.Label.TextColor3 = color

    local text = ""

    if Config.ESPNames then
        text = player.DisplayName
    end

    if Config.ESPDistance then
        local myRoot = GetRoot(LocalPlayer)

        if myRoot then
            local distance = math.floor(
                (root.Position - myRoot.Position).Magnitude
            )

            if text ~= "" then
                text = text .. " [" .. distance .. "m]"
            else
                text = "[" .. distance .. "m]"
            end
        end
    end

    data.Label.Text = text
    data.Billboard.Enabled = text ~= ""
end

local function SetupESPPlayer(player)
    if player == LocalPlayer then
        return
    end

    player.CharacterAdded:Connect(function()
        task.wait(0.25)

        if Config.ESPEnabled then
            CreateESP(player)
        end
    end)

    player:GetPropertyChangedSignal("Team"):Connect(function()
        if Config.ESPEnabled then
            CreateESP(player)
        end
    end)

    if player.Character then
        CreateESP(player)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    SetupESPPlayer(player)
end

Players.PlayerAdded:Connect(SetupESPPlayer)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)

    if CurrentTarget == player then
        CurrentTarget = nil
    end
end)

--==================================================
-- AIM TEST
--==================================================

local function GetAimPart(player)
    local character = GetCharacter(player)
    if not character then
        return nil
    end

    return character:FindFirstChild(Config.AimPart)
        or character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")
end

local function Visible(part, character)
    if not Config.WallCheck then
        return true
    end

    local origin = Camera.CFrame.Position
    local direction = part.Position - origin

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        LocalPlayer.Character,
        Camera,
    }

    local result = Workspace:Raycast(
        origin,
        direction,
        params
    )

    if not result then
        return true
    end

    return result.Instance:IsDescendantOf(character)
end

local function GetClosestTarget()
    local closest = nil
    local bestDistance = Config.AimFOV

    local viewport = Camera.ViewportSize
    local center = Vector2.new(
        viewport.X / 2,
        viewport.Y / 2
    )

    local myRoot = GetRoot(LocalPlayer)
    if not myRoot then
        return nil
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and Alive(player) and IsEnemy(player) then
            local part = GetAimPart(player)
            local root = GetRoot(player)

            if part and root then
                local distance3D =
                    (root.Position - myRoot.Position).Magnitude

                if distance3D <= Config.MaxDistance then
                    local screen, onScreen =
                        Camera:WorldToViewportPoint(part.Position)

                    if onScreen then
                        local screenDistance =
                            (Vector2.new(screen.X, screen.Y) - center).Magnitude

                        if screenDistance <= bestDistance
                            and Visible(part, player.Character) then

                            bestDistance = screenDistance
                            closest = player
                        end
                    end
                end
            end
        end
    end

    return closest
end

local function ShouldAim()
    if not Config.AimbotEnabled then
        return false
    end

    if not Config.ActivationEnabled then
        return true
    end

    if Config.ActivationMode == "Hold" then
        return HoldingAim
    end

    return ToggleAim
end

local function IsActivationInput(input)
    if Config.ActivationInput == "M1" then
        return input.UserInputType == Enum.UserInputType.MouseButton1
    end

    if Config.ActivationInput == "M2" then
        return input.UserInputType == Enum.UserInputType.MouseButton2
    end

    return input.UserInputType == Enum.UserInputType.Keyboard
        and input.KeyCode == Config.ActivationKey
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not Config.ActivationEnabled then
        return
    end

    if not IsActivationInput(input) then
        return
    end

    if Config.ActivationMode == "Hold" then
        HoldingAim = true
    else
        ToggleAim = not ToggleAim
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not Config.ActivationEnabled then
        return
    end

    if Config.ActivationMode == "Hold"
        and IsActivationInput(input) then

        HoldingAim = false
    end
end)

--==================================================
-- PLAYER TEST
--==================================================

local FlyConnection = nil
local FlyVelocity = nil

local function StopFly()
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end

    if FlyVelocity then
        FlyVelocity:Destroy()
        FlyVelocity = nil
    end

    local humanoid = GetHumanoid(LocalPlayer)
    if humanoid then
        humanoid.PlatformStand = false
    end
end

local function ApplyPlayerSettings()
    local humanoid = GetHumanoid(LocalPlayer)
    if not humanoid then
        return
    end

    humanoid.WalkSpeed =
        Config.SpeedEnabled and Config.WalkSpeed or 16

    humanoid.UseJumpPower = true

    humanoid.JumpPower =
        Config.JumpEnabled and Config.JumpPower or 50
end

local function StartFly()
    StopFly()

    local character = GetCharacter(LocalPlayer)
    local root = GetRoot(LocalPlayer)
    local humanoid = GetHumanoid(LocalPlayer)

    if not character or not root or not humanoid then
        return
    end

    FlyVelocity = Instance.new("BodyVelocity")
    FlyVelocity.Name = "GuiloHUB_Fly"
    FlyVelocity.MaxForce = Vector3.new(
        math.huge,
        math.huge,
        math.huge
    )
    FlyVelocity.Velocity = Vector3.zero
    FlyVelocity.Parent = root

    humanoid.PlatformStand = true

    FlyConnection = RunService.RenderStepped:Connect(function()
        if not Config.FlyEnabled
            or not character.Parent
            or not root.Parent then

            StopFly()
            return
        end

        local direction = humanoid.MoveDirection

        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction += Vector3.new(0, 1, 0)
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction -= Vector3.new(0, 1, 0)
        end

        if direction.Magnitude > 0 then
            FlyVelocity.Velocity =
                direction.Unit * Config.FlySpeed
        else
            FlyVelocity.Velocity = Vector3.zero
        end
    end)
end

UserInputService.JumpRequest:Connect(function()
    if not Config.InfiniteJump then
        return
    end

    local humanoid = GetHumanoid(LocalPlayer)

    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    ApplyPlayerSettings()

    if Config.FlyEnabled then
        StartFly()
    end
end)

--==================================================
-- RENDER
--==================================================

RunService.RenderStepped:Connect(function()
    Camera = Workspace.CurrentCamera or Camera

    -- FOV
    local viewport = Camera.ViewportSize

    FOVCircle.Position = UDim2.fromOffset(
        viewport.X / 2,
        viewport.Y / 2
    )

    FOVCircle.Size = UDim2.fromOffset(
        Config.AimFOV * 2,
        Config.AimFOV * 2
    )

    FOVCircle.Visible =
        Config.FOVVisible
        and Config.AimbotEnabled

    FOVStroke.Color = Config.FOVColor
    FOVStroke.Thickness = Config.FOVThickness
    FOVStroke.Transparency = Config.FOVTransparency

    -- ESP
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            UpdateESP(player)
        end
    end

    -- Target
    if ShouldAim() then
        CurrentTarget = GetClosestTarget()
    else
        CurrentTarget = nil
    end

    if Config.TargetIndicator and CurrentTarget then
        local root = GetRoot(CurrentTarget)
        local myRoot = GetRoot(LocalPlayer)

        if root then
            local distance = 0

            if myRoot then
                distance = math.floor(
                    (root.Position - myRoot.Position).Magnitude
                )
            end

            TargetLabel.Text =
                "TARGET: "
                .. CurrentTarget.DisplayName
                .. "  •  "
                .. distance
                .. "m"

            TargetLabel.TextColor3 = Config.TargetColor
            TargetLabel.Visible = true
        else
            TargetLabel.Visible = false
        end
    else
        TargetLabel.Visible = false
    end

    -- Aim
    if ShouldAim() and CurrentTarget then
        local part = GetAimPart(CurrentTarget)

        if part then
            local desired = CFrame.lookAt(
                Camera.CFrame.Position,
                part.Position
            )

            Camera.CFrame = Camera.CFrame:Lerp(
                desired,
                math.clamp(Config.AimSmoothness, 0.01, 1)
            )
        end
    end

    if not Config.FlyEnabled then
        ApplyPlayerSettings()
    end
end)

--==================================================
-- ESP UI
--==================================================

ESPTab:Section({
    Title = "ESP",
})

ESPTab:Toggle({
    Title = "Enable ESP",
    Value = Config.ESPEnabled,
    Callback = function(value)
        Config.ESPEnabled = value

        if not value then
            for player in pairs(ESP) do
                RemoveESP(player)
            end
        else
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    CreateESP(player)
                end
            end
        end
    end,
})

ESPTab:Toggle({
    Title = "Team Check",
    Value = Config.ESPTeamCheck,
    Callback = function(value)
        Config.ESPTeamCheck = value
    end,
})

ESPTab:Toggle({
    Title = "Names",
    Value = Config.ESPNames,
    Callback = function(value)
        Config.ESPNames = value
    end,
})

ESPTab:Toggle({
    Title = "Distance",
    Value = Config.ESPDistance,
    Callback = function(value)
        Config.ESPDistance = value
    end,
})

--==================================================
-- AIM UI
--==================================================

AimTab:Section({
    Title = "Aim Test",
})

AimTab:Toggle({
    Title = "Enable Aimbot",
    Value = Config.AimbotEnabled,
    Callback = function(value)
        Config.AimbotEnabled = value
    end,
})

AimTab:Toggle({
    Title = "Wall Check",
    Value = Config.WallCheck,
    Callback = function(value)
        Config.WallCheck = value
    end,
})

AimTab:Dropdown({
    Title = "Aim Part",
    Values = {
        "Head",
        "UpperTorso",
        "LowerTorso",
        "HumanoidRootPart",
    },
    Value = Config.AimPart,
    Callback = function(value)
        Config.AimPart = value
    end,
})

AimTab:Section({
    Title = "Activation",
})

AimTab:Toggle({
    Title = "Enable Activation",
    Value = Config.ActivationEnabled,
    Callback = function(value)
        Config.ActivationEnabled = value
        HoldingAim = false
        ToggleAim = false
    end,
})

AimTab:Dropdown({
    Title = "Input",
    Values = {
        "Keyboard",
        "M1",
        "M2",
    },
    Value = Config.ActivationInput,
    Callback = function(value)
        Config.ActivationInput = value
        HoldingAim = false
        ToggleAim = false
    end,
})

AimTab:Dropdown({
    Title = "Keyboard Key",
    Values = {
        "Q",
        "E",
        "F",
        "R",
        "T",
        "LeftShift",
        "LeftControl",
        "Space",
    },
    Value = "Q",
    Callback = function(value)
        local keys = {
            Q = Enum.KeyCode.Q,
            E = Enum.KeyCode.E,
            F = Enum.KeyCode.F,
            R = Enum.KeyCode.R,
            T = Enum.KeyCode.T,
            LeftShift = Enum.KeyCode.LeftShift,
            LeftControl = Enum.KeyCode.LeftControl,
            Space = Enum.KeyCode.Space,
        }

        Config.ActivationKey = keys[value] or Enum.KeyCode.Q
    end,
})

AimTab:Dropdown({
    Title = "Mode",
    Values = {
        "Hold",
        "Toggle",
    },
    Value = Config.ActivationMode,
    Callback = function(value)
        Config.ActivationMode = value
        HoldingAim = false
        ToggleAim = false
    end,
})

AimTab:Slider({
    Title = "Smoothness",
    Value = {
        Min = 0.10,
        Max = 1,
        Default = Config.AimSmoothness,
    },
    Step = 0.01,
    Callback = function(value)
        Config.AimSmoothness = value
    end,
})

AimTab:Slider({
    Title = "FOV",
    Value = {
        Min = 50,
        Max = 500,
        Default = Config.AimFOV,
    },
    Step = 5,
    Callback = function(value)
        Config.AimFOV = value
    end,
})

AimTab:Slider({
    Title = "Max Distance",
    Value = {
        Min = 100,
        Max = 3000,
        Default = Config.MaxDistance,
    },
    Step = 50,
    Callback = function(value)
        Config.MaxDistance = value
    end,
})

--==================================================
-- VISUAL UI
--==================================================

VisualTab:Section({
    Title = "FOV Circle",
})

VisualTab:Toggle({
    Title = "Show FOV",
    Value = Config.FOVVisible,
    Callback = function(value)
        Config.FOVVisible = value
    end,
})

VisualTab:Slider({
    Title = "FOV Thickness",
    Value = {
        Min = 1,
        Max = 6,
        Default = Config.FOVThickness,
    },
    Step = 1,
    Callback = function(value)
        Config.FOVThickness = value
    end,
})

VisualTab:Slider({
    Title = "FOV Transparency",
    Value = {
        Min = 0,
        Max = 1,
        Default = Config.FOVTransparency,
    },
    Step = 0.05,
    Callback = function(value)
        Config.FOVTransparency = value
    end,
})

VisualTab:Colorpicker({
    Title = "FOV Color",
    Default = Config.FOVColor,
    Callback = function(value)
        Config.FOVColor = value
    end,
})

VisualTab:Section({
    Title = "Target Indicator",
})

VisualTab:Toggle({
    Title = "Show Target",
    Value = Config.TargetIndicator,
    Callback = function(value)
        Config.TargetIndicator = value
    end,
})

VisualTab:Colorpicker({
    Title = "Target Color",
    Default = Config.TargetColor,
    Callback = function(value)
        Config.TargetColor = value
    end,
})

VisualTab:Section({
    Title = "ESP Colors",
})

VisualTab:Colorpicker({
    Title = "Enemy Color",
    Default = Config.EnemyColor,
    Callback = function(value)
        Config.EnemyColor = value
    end,
})

VisualTab:Colorpicker({
    Title = "Team Color",
    Default = Config.TeamColor,
    Callback = function(value)
        Config.TeamColor = value
    end,
})

--==================================================
-- PLAYER UI
--==================================================

PlayerTab:Section({
    Title = "Movement Test",
})

PlayerTab:Toggle({
    Title = "Enable Speed",
    Value = Config.SpeedEnabled,
    Callback = function(value)
        Config.SpeedEnabled = value
        ApplyPlayerSettings()
    end,
})

PlayerTab:Slider({
    Title = "Walk Speed",
    Value = {
        Min = 16,
        Max = 150,
        Default = Config.WalkSpeed,
    },
    Step = 1,
    Callback = function(value)
        Config.WalkSpeed = value
        ApplyPlayerSettings()
    end,
})

PlayerTab:Toggle({
    Title = "Enable Jump Power",
    Value = Config.JumpEnabled,
    Callback = function(value)
        Config.JumpEnabled = value
        ApplyPlayerSettings()
    end,
})

PlayerTab:Slider({
    Title = "Jump Power",
    Value = {
        Min = 50,
        Max = 200,
        Default = Config.JumpPower,
    },
    Step = 5,
    Callback = function(value)
        Config.JumpPower = value
        ApplyPlayerSettings()
    end,
})

PlayerTab:Toggle({
    Title = "Infinite Jump",
    Value = Config.InfiniteJump,
    Callback = function(value)
        Config.InfiniteJump = value
    end,
})

PlayerTab:Section({
    Title = "Fly Test",
})

PlayerTab:Toggle({
    Title = "Enable Fly",
    Value = Config.FlyEnabled,
    Callback = function(value)
        Config.FlyEnabled = value

        if value then
            StartFly()
        else
            StopFly()
        end
    end,
})

PlayerTab:Slider({
    Title = "Fly Speed",
    Value = {
        Min = 10,
        Max = 200,
        Default = Config.FlySpeed,
    },
    Step = 5,
    Callback = function(value)
        Config.FlySpeed = value
    end,
})

PlayerTab:Button({
    Title = "Reset Player",
    Callback = function()
        Config.SpeedEnabled = false
        Config.JumpEnabled = false
        Config.InfiniteJump = false
        Config.FlyEnabled = false

        StopFly()

        local humanoid = GetHumanoid(LocalPlayer)

        if humanoid then
            humanoid.WalkSpeed = 16
            humanoid.UseJumpPower = true
            humanoid.JumpPower = 50
            humanoid.PlatformStand = false
        end

        WindUI:Notify({
            Title = "Player",
            Content = "Player settings reset.",
            Duration = 3,
        })
    end,
})

--==================================================
-- CONFIG UI
--==================================================

ConfigTab:Paragraph({
    Title = "Configuration",
    Desc = "WindUI configuration controls.",
})

ConfigTab:Button({
    Title = "Save Current Config",
    Callback = function()
        if Window.ConfigManager then
            local ok, err = pcall(function()
                Window.ConfigManager:Save()
            end)

            WindUI:Notify({
                Title = ok and "Config Saved" or "Config Error",
                Content = ok and "Configuration saved." or tostring(err),
                Duration = 3,
            })
        else
            WindUI:Notify({
                Title = "Config",
                Content = "ConfigManager unavailable in this environment.",
                Duration = 3,
            })
        end
    end,
})

ConfigTab:Button({
    Title = "Load Config",
    Callback = function()
        if Window.ConfigManager then
            local ok, err = pcall(function()
                Window.ConfigManager:Load()
            end)

            WindUI:Notify({
                Title = ok and "Config Loaded" or "Config Error",
                Content = ok and "Configuration loaded." or tostring(err),
                Duration = 3,
            })
        else
            WindUI:Notify({
                Title = "Config",
                Content = "ConfigManager unavailable in this environment.",
                Duration = 3,
            })
        end
    end,
})

--==================================================
-- SETTINGS
--==================================================

SettingsTab:Paragraph({
    Title = "GuiloHUB",
    Desc = "Author: Guilh3rm3Scr1pter",
})

SettingsTab:Paragraph({
    Title = "Test Build",
    Desc = "Movement and targeting features are intended for authorized testing.",
})

SettingsTab:Button({
    Title = "Disable ESP",
    Callback = function()
        Config.ESPEnabled = false

        for player in pairs(ESP) do
            RemoveESP(player)
        end
    end,
})

SettingsTab:Button({
    Title = "Enable ESP",
    Callback = function()
        Config.ESPEnabled = true

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                CreateESP(player)
            end
        end
    end,
})

--==================================================
-- FINAL
--==================================================

WindUI:Notify({
    Title = "GuiloHUB",
    Content = "Loaded successfully.",
    Icon = "check",
    Duration = 5,
})

print("[GuiloHUB] Loaded successfully.")
print("[GuiloHUB] Author: Guilh3rm3Scr1pter")
'''
path = "/mnt/data/GuiloHUB.lua"
with open(path, "w", encoding="utf-8", newline="\n") as f:
    f.write(lua)
print(path)
print("Lua characters:", len(lua))
print("Lines:", len(lua.splitlines()))
