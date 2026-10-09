```lua
--[[
    GuiloHUB
    Author: Guilh3rm3Scr1pter

    Features:
    - ESP
    - Team Check
    - Names / Distance
    - Aimbot
    - Wall Check
    - Aim Part
    - Visible FOV Circle
    - Current Target Indicator
    - Configurable Colors
    - Save / Load Config
    - Player:
        Speed
        Jump Power
        Infinite Jump
        Fly
    - Activation Key:
        Keyboard
        M1
        M2
    - Hold / Toggle mode
]]

--==================================================
-- WINDUI
--==================================================

local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--==================================================
-- CONFIG
--==================================================

local Config = {

    -- ESP
    ESPEnabled = true,
    ESPTeamCheck = true,
    ESPNames = true,
    ESPDistance = true,

    -- Aimbot
    AimbotEnabled = false,
    AimbotTeamCheck = true,
    WallCheck = true,

    AimPart = "Head",
    AimSmoothness = 0.85,
    AimFOV = 150,
    MaxDistance = 1000,

    -- Activation
    ActivationKeyEnabled = true,
    ActivationInputType = "Keyboard",
    ActivationKey = Enum.KeyCode.Q,
    ActivationMode = "Hold",

    -- FOV
    FOVVisible = true,
    FOVThickness = 2,
    FOVTransparency = 0.35,

    -- Target indicator
    TargetIndicator = true,

    -- Colors
    EnemyColor = Color3.fromRGB(255, 70, 70),
    TeamColor = Color3.fromRGB(70, 170, 255),
    FOVColor = Color3.fromRGB(255, 255, 255),
    TargetColor = Color3.fromRGB(255, 220, 80),

    -- Player
    SpeedEnabled = false,
    WalkSpeed = 16,

    JumpPowerEnabled = false,
    JumpPower = 50,

    InfiniteJump = false,

    FlyEnabled = false,
    FlySpeed = 60,
}

--==================================================
-- STATE
--==================================================

local HoldingAim = false
local ToggleAimActive = false

local CurrentTarget = nil

local FlyConnection = nil
local FlyVelocity = nil

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

--==================================================
-- TABS
--==================================================

local ESPTab = Window:Tab({
    Title = "ESP",
    Icon = "eye",
})

local AimTab = Window:Tab({
    Title = "Aimbot",
    Icon = "crosshair",
})

local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user",
})

local VisualTab = Window:Tab({
    Title = "Visuals",
    Icon = "palette",
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
-- FOV CIRCLE
--==================================================

local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "GuiloHUB_FOV"
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true
FOVGui.Parent = game:GetService("CoreGui")

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Parent = FOVGui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = Config.FOVThickness
FOVStroke.Transparency = Config.FOVTransparency
FOVStroke.Color = Config.FOVColor
FOVStroke.Parent = FOVCircle

--==================================================
-- TARGET INDICATOR
--==================================================

local TargetGui = Instance.new("ScreenGui")
TargetGui.Name = "GuiloHUB_Target"
TargetGui.ResetOnSpawn = false
TargetGui.IgnoreGuiInset = true
TargetGui.Parent = game:GetService("CoreGui")

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Name = "TargetLabel"
TargetLabel.AnchorPoint = Vector2.new(0.5, 0)
TargetLabel.Position = UDim2.fromScale(0.5, 0.08)
TargetLabel.Size = UDim2.fromOffset(350, 45)

TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = ""
TargetLabel.TextSize = 18
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.TextStrokeTransparency = 0.5

TargetLabel.Visible = false
TargetLabel.Parent = TargetGui

--==================================================
-- ESP
--==================================================

local ESPObjects = {}

local function RemoveESP(player)
    if ESPObjects[player] then

        if ESPObjects[player].Highlight then
            ESPObjects[player].Highlight:Destroy()
        end

        if ESPObjects[player].Billboard then
            ESPObjects[player].Billboard:Destroy()
        end

        ESPObjects[player] = nil
    end
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

local function CreateESP(player)

    if player == LocalPlayer then
        return
    end

    RemoveESP(player)

    local Character = player.Character

    if not Character then
        return
    end

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local Root = Character:FindFirstChild("HumanoidRootPart")

    if not Humanoid or not Root then
        return
    end

    local Highlight = Instance.new("Highlight")
    Highlight.Name = "GuiloHUB_ESP"
    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Highlight.FillTransparency = 0.55
    Highlight.OutlineTransparency = 0

    local Enemy = IsEnemy(player)

    if Enemy then
        Highlight.FillColor = Config.EnemyColor
        Highlight.OutlineColor = Config.EnemyColor
    else
        Highlight.FillColor = Config.TeamColor
        Highlight.OutlineColor = Config.TeamColor
    end

    Highlight.Parent = Character

    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "GuiloHUB_Info"
    Billboard.Size = UDim2.fromOffset(200, 50)
    Billboard.StudsOffset = Vector3.new(0, 3, 0)
    Billboard.AlwaysOnTop = true
    Billboard.Parent = Root

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.fromScale(1, 1)
    Label.BackgroundTransparency = 1
    Label.TextSize = 14
    Label.Font = Enum.Font.GothamBold
    Label.TextStrokeTransparency = 0.5
    Label.TextColor3 = Enemy and Config.EnemyColor or Config.TeamColor
    Label.Parent = Billboard

    ESPObjects[player] = {
        Highlight = Highlight,
        Billboard = Billboard,
        Label = Label,
    }
end

local function UpdateESP(player)

    if not Config.ESPEnabled then
        RemoveESP(player)
        return
    end

    if not player.Character then
        RemoveESP(player)
        return
    end

    if not ESPObjects[player] then
        CreateESP(player)
        return
    end

    local Data = ESPObjects[player]

    local Character = player.Character
    local Root = Character:FindFirstChild("HumanoidRootPart")

    if not Root then
        return
    end

    local Enemy = IsEnemy(player)

    Data.Highlight.Enabled = true

    if Enemy then
        Data.Highlight.FillColor = Config.EnemyColor
        Data.Highlight.OutlineColor = Config.EnemyColor
        Data.Label.TextColor3 = Config.EnemyColor
    else
        Data.Highlight.FillColor = Config.TeamColor
        Data.Highlight.OutlineColor = Config.TeamColor
        Data.Label.TextColor3 = Config.TeamColor
    end

    local Text = ""

    if Config.ESPNames then
        Text = player.DisplayName
    end

    if Config.ESPDistance then

        local MyCharacter = LocalPlayer.Character
        local MyRoot = MyCharacter and MyCharacter:FindFirstChild("HumanoidRootPart")

        if MyRoot then

            local Distance = math.floor(
                (Root.Position - MyRoot.Position).Magnitude
            )

            if Text ~= "" then
                Text = Text .. " [" .. Distance .. "m]"
            else
                Text = "[" .. Distance .. "m]"
            end
        end
    end

    Data.Label.Text = Text
    Data.Billboard.Enabled = Config.ESPNames or Config.ESPDistance
end

local function SetupPlayer(player)

    if player == LocalPlayer then
        return
    end

    player.CharacterAdded:Connect(function()
        task.wait(0.5)

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

for _, Player in ipairs(Players:GetPlayers()) do
    SetupPlayer(Player)
end

Players.PlayerAdded:Connect(SetupPlayer)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)

    if CurrentTarget == player then
        CurrentTarget = nil
    end
end)

--==================================================
-- AIMBOT
--==================================================

local function IsAlive(player)

    if not player.Character then
        return false
    end

    local Humanoid = player.Character:FindFirstChildOfClass("Humanoid")

    return Humanoid and Humanoid.Health > 0
end

local function IsAimEnemy(player)

    if not Config.AimbotTeamCheck then
        return true
    end

    if not LocalPlayer.Team or not player.Team then
        return true
    end

    return LocalPlayer.Team ~= player.Team
end

local function GetAimPart(player)

    if not player.Character then
        return nil
    end

    return player.Character:FindFirstChild(Config.AimPart)
        or player.Character:FindFirstChild("HumanoidRootPart")
end

local function IsVisible(part, character)

    if not Config.WallCheck then
        return true
    end

    local Origin = Camera.CFrame.Position
    local Direction = part.Position - Origin

    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = {
        LocalPlayer.Character,
        Camera
    }

    local Result = Workspace:Raycast(
        Origin,
        Direction,
        Params
    )

    if not Result then
        return true
    end

    return Result.Instance:IsDescendantOf(character)
end

local function GetClosestTarget()

    local Closest = nil
    local ClosestDistance = Config.AimFOV

    local ViewportSize = Camera.ViewportSize
    local Center = Vector2.new(
        ViewportSize.X / 2,
        ViewportSize.Y / 2
    )

    for _, Player in ipairs(Players:GetPlayers()) do

        if Player ~= LocalPlayer
        and IsAlive(Player)
        and IsAimEnemy(Player) then

            local Part = GetAimPart(Player)

            if Part then

                local Root = Player.Character:FindFirstChild("HumanoidRootPart")

                local MyCharacter = LocalPlayer.Character
                local MyRoot = MyCharacter and MyCharacter:FindFirstChild("HumanoidRootPart")

                if Root and MyRoot then

                    local Distance3D = (
                        Root.Position - MyRoot.Position
                    ).Magnitude

                    if Distance3D <= Config.MaxDistance then

                        local ScreenPosition, OnScreen =
                            Camera:WorldToViewportPoint(Part.Position)

                        if OnScreen then

                            local Distance2D = (
                                Vector2.new(
                                    ScreenPosition.X,
                                    ScreenPosition.Y
                                ) - Center
                            ).Magnitude

                            if Distance2D <= ClosestDistance then

                                if IsVisible(
                                    Part,
                                    Player.Character
                                ) then

                                    ClosestDistance = Distance2D
                                    Closest = Player
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return Closest
end

local function AimAt(player)

    if not player then
        return
    end

    local Part = GetAimPart(player)

    if not Part then
        return
    end

    local CameraPosition = Camera.CFrame.Position

    local Desired = CFrame.lookAt(
        CameraPosition,
        Part.Position
    )

    Camera.CFrame = Camera.CFrame:Lerp(
        Desired,
        math.clamp(Config.AimSmoothness, 0.01, 1)
    )
end

--==================================================
-- ACTIVATION
--==================================================

local function IsActivationInput(input)

    if Config.ActivationInputType == "M1" then

        return input.UserInputType
            == Enum.UserInputType.MouseButton1

    elseif Config.ActivationInputType == "M2" then

        return input.UserInputType
            == Enum.UserInputType.MouseButton2

    else

        return input.UserInputType
            == Enum.UserInputType.Keyboard
            and input.KeyCode == Config.ActivationKey

    end
end

UserInputService.InputBegan:Connect(function(input, processed)

    if processed then
        return
    end

    if not Config.ActivationKeyEnabled then
        return
    end

    if not IsActivationInput(input) then
        return
    end

    if Config.ActivationMode == "Hold" then

        HoldingAim = true

    else

        ToggleAimActive = not ToggleAimActive

    end
end)

UserInputService.InputEnded:Connect(function(input)

    if not Config.ActivationKeyEnabled then
        return
    end

    if not IsActivationInput(input) then
        return
    end

    if Config.ActivationMode == "Hold" then
        HoldingAim = false
    end
end)

local function ShouldAim()

    if not Config.AimbotEnabled then
        return false
    end

    if not Config.ActivationKeyEnabled then
        return true
    end

    if Config.ActivationMode == "Hold" then
        return HoldingAim
    end

    return ToggleAimActive
end

--==================================================
-- PLAYER
--==================================================

local function GetHumanoid()

    local Character = LocalPlayer.Character

    if not Character then
        return nil
    end

    return Character:FindFirstChildOfClass("Humanoid")
end

local function ApplyPlayerStats()

    local Humanoid = GetHumanoid()

    if not Humanoid then
        return
    end

    if Config.SpeedEnabled then
        Humanoid.WalkSpeed = Config.WalkSpeed
    else
        Humanoid.WalkSpeed = 16
    end

    if Config.JumpPowerEnabled then
        Humanoid.UseJumpPower = true
        Humanoid.JumpPower = Config.JumpPower
    else
        Humanoid.UseJumpPower = true
        Humanoid.JumpPower = 50
    end
end

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()

    if not Config.InfiniteJump then
        return
    end

    local Humanoid = GetHumanoid()

    if Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

--==================================================
-- FLY
--==================================================

local function StopFly()

    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end

    if FlyVelocity then
        FlyVelocity:Destroy()
        FlyVelocity = nil
    end

    local Humanoid = GetHumanoid()

    if Humanoid then
        Humanoid.PlatformStand = false
    end
end

local function StartFly()

    StopFly()

    local Character = LocalPlayer.Character

    if not Character then
        return
    end

    local Root = Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")

    if not Root or not Humanoid then
        return
    end

    FlyVelocity = Instance.new("BodyVelocity")
    FlyVelocity.Name = "GuiloHUB_FlyVelocity"
    FlyVelocity.MaxForce = Vector3.new(
        math.huge,
        math.huge,
        math.huge
    )
    FlyVelocity.Velocity = Vector3.zero
    FlyVelocity.Parent = Root

    Humanoid.PlatformStand = true

    FlyConnection = RunService.RenderStepped:Connect(function()

        if not Config.FlyEnabled then
            StopFly()
            return
        end

        if not Character.Parent then
            StopFly()
            return
        end

        local Direction = Vector3.zero

        local HumanoidMove =
            Humanoid.MoveDirection

        Direction += HumanoidMove

        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            Direction += Vector3.new(0, 1, 0)
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            Direction -= Vector3.new(0, 1, 0)
        end

        if Direction.Magnitude > 0 then

            Direction = Direction.Unit

            FlyVelocity.Velocity =
                Direction * Config.FlySpeed

        else

            FlyVelocity.Velocity = Vector3.zero

        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()

    task.wait(1)

    ApplyPlayerStats()

    if Config.FlyEnabled then
        StartFly()
    end

end)

--==================================================
-- RENDER LOOP
--==================================================

RunService.RenderStepped:Connect(function()

    -- FOV

    local ViewportSize = Camera.ViewportSize

    FOVCircle.Position = UDim2.fromOffset(
        ViewportSize.X / 2,
        ViewportSize.Y / 2
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

    for _, Player in ipairs(Players:GetPlayers()) do

        if Player ~= LocalPlayer then
            UpdateESP(Player)
        end

    end

    -- Aimbot

    if ShouldAim() then

        CurrentTarget = GetClosestTarget()

        if CurrentTarget then
            AimAt(CurrentTarget)
        end

    else

        CurrentTarget = nil
    end

    -- Target indicator

    if Config.TargetIndicator and CurrentTarget then

        local Character = CurrentTarget.Character
        local Root = Character and
            Character:FindFirstChild("HumanoidRootPart")

        if Root then

            local MyCharacter = LocalPlayer.Character
            local MyRoot = MyCharacter and
                MyCharacter:FindFirstChild("HumanoidRootPart")

            local Distance = 0

            if MyRoot then
                Distance = math.floor(
                    (Root.Position - MyRoot.Position).Magnitude
                )
            end

            TargetLabel.Text =
                "TARGET: "
                .. CurrentTarget.DisplayName
                .. "  •  "
                .. Distance
                .. "m"

            TargetLabel.TextColor3 = Config.TargetColor
            TargetLabel.Visible = true

        else

            TargetLabel.Visible = false

        end

    else

        TargetLabel.Visible = false

    end

    -- Player stats

    if not Config.FlyEnabled then
        ApplyPlayerStats()
    end
end)

--==================================================
-- ESP TAB
--==================================================

ESPTab:Section({
    Title = "ESP",
})

ESPTab:Toggle({
    Flag = "ESPEnabled",
    Title = "Enable ESP",
    Value = Config.ESPEnabled,

    Callback = function(value)
        Config.ESPEnabled = value

        if not value then
            for Player in pairs(ESPObjects) do
                RemoveESP(Player)
            end
        else
            for _, Player in ipairs(Players:GetPlayers()) do
                if Player ~= LocalPlayer then
                    CreateESP(Player)
                end
            end
        end
    end,
})

ESPTab:Toggle({
    Flag = "ESPTeamCheck",
    Title = "Team Check",
    Value = Config.ESPTeamCheck,

    Callback = function(value)
        Config.ESPTeamCheck = value
    end,
})

ESPTab:Toggle({
    Flag = "ESPNames",
    Title = "Player Names",
    Value = Config.ESPNames,

    Callback = function(value)
        Config.ESPNames = value
    end,
})

ESPTab:Toggle({
    Flag = "ESPDistance",
    Title = "Distance",
    Value = Config.ESPDistance,

    Callback = function(value)
        Config.ESPDistance = value
    end,
})

--==================================================
-- AIMBOT TAB
--==================================================

AimTab:Section({
    Title = "Aimbot",
})

AimTab:Toggle({
    Flag = "AimbotEnabled",
    Title = "Enable Aimbot",
    Value = Config.AimbotEnabled,

    Callback = function(value)
        Config.AimbotEnabled = value
    end,
})

AimTab:Toggle({
    Flag = "AimbotTeamCheck",
    Title = "Team Check",
    Value = Config.AimbotTeamCheck,

    Callback = function(value)
        Config.AimbotTeamCheck = value
    end,
})

AimTab:Toggle({
    Flag = "WallCheck",
    Title = "Wall Check",
    Value = Config.WallCheck,

    Callback = function(value)
        Config.WallCheck = value
    end,
})

AimTab:Dropdown({
    Flag = "AimPart",
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

--==================================================
-- ACTIVATION
--==================================================

AimTab:Section({
    Title = "Activation",
})

AimTab:Toggle({
    Flag = "ActivationKeyEnabled",
    Title = "Enable Activation Key",
    Value = Config.ActivationKeyEnabled,

    Callback = function(value)

        Config.ActivationKeyEnabled = value

        HoldingAim = false
        ToggleAimActive = false

    end,
})

AimTab:Dropdown({
    Flag = "ActivationInputType",
    Title = "Activation Input",

    Values = {
        "Keyboard",
        "M1",
        "M2",
    },

    Value = Config.ActivationInputType,

    Callback = function(value)

        Config.ActivationInputType = value

        HoldingAim = false
        ToggleAimActive = false

    end,
})

AimTab:Dropdown({
    Flag = "ActivationKey",
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

        local Keys = {
            Q = Enum.KeyCode.Q,
            E = Enum.KeyCode.E,
            F = Enum.KeyCode.F,
            R = Enum.KeyCode.R,
            T = Enum.KeyCode.T,

            LeftShift = Enum.KeyCode.LeftShift,
            LeftControl = Enum.KeyCode.LeftControl,
            Space = Enum.KeyCode.Space,
        }

        Config.ActivationKey = Keys[value] or Enum.KeyCode.Q

    end,
})

AimTab:Dropdown({
    Flag = "ActivationMode",
    Title = "Activation Mode",

    Values = {
        "Hold",
        "Toggle",
    },

    Value = Config.ActivationMode,

    Callback = function(value)

        Config.ActivationMode = value

        HoldingAim = false
        ToggleAimActive = false

    end,
})

--==================================================
-- AIM SETTINGS
--==================================================

AimTab:Section({
    Title = "Aim Settings",
})

AimTab:Slider({
    Flag = "AimSmoothness",
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
    Flag = "AimFOV",
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
    Flag = "MaxDistance",
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
-- VISUALS TAB
--==================================================

VisualTab:Section({
    Title = "FOV Circle",
})

VisualTab:Toggle({
    Flag = "FOVVisible",
    Title = "Show FOV",
    Value = Config.FOVVisible,

    Callback = function(value)
        Config.FOVVisible = value
    end,
})

VisualTab:Slider({
    Flag = "FOVThickness",
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
    Flag = "FOVTransparency",
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
    Flag = "FOVColor",
    Title = "FOV Color",
    Default = Config.FOVColor,

    Callback = function(value)
        Config.FOVColor = value
    end,
})

VisualTab:Section({
    Title = "Target",
})

VisualTab:Toggle({
    Flag = "TargetIndicator",
    Title = "Target Indicator",
    Value = Config.TargetIndicator,

    Callback = function(value)
        Config.TargetIndicator = value
    end,
})

VisualTab:Colorpicker({
    Flag = "TargetColor",
    Title = "Target Color",
    Default = Config.TargetColor,

    Callback = function(value)

        Config.TargetColor = value
        TargetLabel.TextColor3 = value

    end,
})

VisualTab:Section({
    Title = "ESP Colors",
})

VisualTab:Colorpicker({
    Flag = "EnemyColor",
    Title = "Enemy Color",
    Default = Config.EnemyColor,

    Callback = function(value)
        Config.EnemyColor = value
    end,
})

VisualTab:Colorpicker({
    Flag = "TeamColor",
    Title = "Team Color",
    Default = Config.TeamColor,

    Callback = function(value)
        Config.TeamColor = value
    end,
})

--==================================================
-- PLAYER TAB
--==================================================

PlayerTab:Section({
    Title = "Movement",
})

PlayerTab:Toggle({
    Flag = "SpeedEnabled",
    Title = "Enable Speed",
    Value = Config.SpeedEnabled,

    Callback = function(value)

        Config.SpeedEnabled = value
        ApplyPlayerStats()

    end,
})

PlayerTab:Slider({
    Flag = "WalkSpeed",
    Title = "Walk Speed",

    Value = {
        Min = 16,
        Max = 150,
        Default = Config.WalkSpeed,
    },

    Step = 1,

    Callback = function(value)

        Config.WalkSpeed = value
        ApplyPlayerStats()

    end,
})

PlayerTab:Toggle({
    Flag = "JumpPowerEnabled",
    Title = "Enable Jump Power",
    Value = Config.JumpPowerEnabled,

    Callback = function(value)

        Config.JumpPowerEnabled = value
        ApplyPlayerStats()

    end,
})

PlayerTab:Slider({
    Flag = "JumpPower",
    Title = "Jump Power",

    Value = {
        Min = 50,
        Max = 200,
        Default = Config.JumpPower,
    },

    Step = 5,

    Callback = function(value)

        Config.JumpPower = value
        ApplyPlayerStats()

    end,
})

PlayerTab:Toggle({
    Flag = "InfiniteJump",
    Title = "Infinite Jump",
    Value = Config.InfiniteJump,

    Callback = function(value)
        Config.InfiniteJump = value
    end,
})

PlayerTab:Section({
    Title = "Fly",
})

PlayerTab:Toggle({
    Flag = "FlyEnabled",
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
    Flag = "FlySpeed",
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
        Config.JumpPowerEnabled = false
        Config.InfiniteJump = false
        Config.FlyEnabled = false

        StopFly()

        local Humanoid = GetHumanoid()

        if Humanoid then
            Humanoid.WalkSpeed = 16
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = 50
            Humanoid.PlatformStand = false
        end

        WindUI:Notify({
            Title = "Player Reset",
            Content = "Player settings reset.",
            Duration = 3,
        })

    end,
})

--==================================================
-- CONFIG TAB
--==================================================

ConfigTab:Paragraph({
    Title = "Configuration Manager",
    Desc = "Save and load your GuiloHUB settings.",
})

local ConfigManager = Window.ConfigManager

local ConfigName = "default"
local CurrentConfig = nil

if ConfigManager then

    ConfigManager:Init(Window)

    ConfigTab:Input({
        Title = "Config Name",
        Value = ConfigName,

        Callback = function(value)

            if value and value ~= "" then
                ConfigName = value
            end

        end,
    })

    ConfigTab:Button({
        Title = "Save Config",
        Icon = "save",

        Callback = function()

            local Success, Result = pcall(function()

                CurrentConfig =
                    ConfigManager:CreateConfig(
                        ConfigName
                    )

                return CurrentConfig:Save()

            end)

            if Success and Result then

                WindUI:Notify({
                    Title = "Config Saved",
                    Content =
                        "Saved: " .. ConfigName,
                    Icon = "check",
                    Duration = 3,
                })

            else

                WindUI:Notify({
                    Title = "Config Error",
                    Content =
                        "Could not save config.",
                    Icon = "x",
                    Duration = 3,
                })

                warn(
                    "[GuiloHUB] Save error:",
                    Result
                )

            end
        end,
    })

    ConfigTab:Button({
        Title = "Load Config",
        Icon = "folder",

        Callback = function()

            local Success, Result =
                pcall(function()

                    CurrentConfig =
                        ConfigManager:CreateConfig(
                            ConfigName
                        )

                    return CurrentConfig:Load()

                end)

            if Success and Result then

                WindUI:Notify({
                    Title = "Config Loaded",
                    Content =
                        "Loaded: " .. ConfigName,
                    Icon = "refresh-cw",
                    Duration = 3,
                })

            else

                WindUI:Notify({
                    Title = "Config Error",
                    Content =
                        "Config not found or invalid.",
                    Icon = "x",
                    Duration = 3,
                })

                warn(
                    "[GuiloHUB] Load error:",
                    Result
                )

            end
        end,
    })

    ConfigTab:Button({
        Title = "Save As Default",

        Callback = function()

            ConfigName = "default"

            local Success, Result =
                pcall(function()

                    CurrentConfig =
                        ConfigManager:CreateConfig(
                            "default"
                        )

                    return CurrentConfig:Save()

                end)

            if Success and Result then

                WindUI:Notify({
                    Title = "Default Saved",
                    Content =
                        "Default configuration saved.",
                    Icon = "check",
                    Duration = 3,
                })

            end

        end,
    })

else

    ConfigTab:Paragraph({
        Title = "Config Manager Unavailable",
        Desc =
            "The current environment does not expose WindUI's config manager.",
    })

end

--==================================================
-- SETTINGS TAB
--==================================================

SettingsTab:Paragraph({
    Title = "GuiloHUB",
    Desc = "Guilh3rm3Scr1pter",
})

SettingsTab:Paragraph({
    Title = "Controls",
    Desc =
        "Aimbot activation can use Keyboard, M1 or M2.\n"
        .. "Hold keeps the aim active while pressed.\n"
        .. "Toggle switches it on/off.",
})

SettingsTab:Button({
    Title = "Disable ESP",

    Callback = function()

        Config.ESPEnabled = false

        for Player in pairs(ESPObjects) do
            RemoveESP(Player)
        end

        WindUI:Notify({
            Title = "ESP",
            Content = "ESP disabled.",
            Duration = 2,
        })

    end,
})

SettingsTab:Button({
    Title = "Enable ESP",

    Callback = function()

        Config.ESPEnabled = true

        for _, Player in ipairs(Players:GetPlayers()) do

            if Player ~= LocalPlayer then
                CreateESP(Player)
            end

        end

        WindUI:Notify({
            Title = "ESP",
            Content = "ESP enabled.",
            Duration = 2,
        })

    end,
})

--==================================================
-- NOTIFICATION
--==================================================

WindUI:Notify({
    Title = "GuiloHUB",
    Content = "Hub carregada com sucesso.",
    Icon = "check",
    Duration = 5,
})

print("[GuiloHUB] Loaded successfully.")
print("[GuiloHUB] Author: Guilh3rm3Scr1pter")
```
