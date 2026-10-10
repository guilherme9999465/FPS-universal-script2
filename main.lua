--[[
    GuiloHUB
    Author: Guilh3rm3Scr1pter
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

    -- TRACERS
    ESPTracers = true,
    TracerThickness = 1.5,
    TracerTransparency = 0.75,
    TracerOrigin = "Bottom",

    AimbotEnabled = false,
    AimTeamCheck = true,
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
-- ORIGINAL PLAYER VALUES
--==================================================

local OriginalWalkSpeed = nil
local OriginalJumpPower = nil
local OriginalUseJumpPower = nil

local function SaveOriginalMovementValues(humanoid)
    if not humanoid then
        return
    end

    OriginalWalkSpeed = humanoid.WalkSpeed
    OriginalJumpPower = humanoid.JumpPower
    OriginalUseJumpPower = humanoid.UseJumpPower
end

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

--==================================================
-- TEAM CHECK
--==================================================

local function IsEnemy(player)
    if not Config.ESPTeamCheck then
        return true
    end

    if not LocalPlayer.Team or not player.Team then
        return true
    end

    return LocalPlayer.Team ~= player.Team
end

local function IsAimTarget(player)
    if not Config.AimTeamCheck then
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

--==================================================
-- TRACERS
--==================================================

local Tracers = {}

local DrawingAvailable =
    typeof(Drawing) == "table"
    and typeof(Drawing.new) == "function"

local function GetTracerOrigin(viewport)
    if Config.TracerOrigin == "Top" then
        return Vector2.new(
            viewport.X / 2,
            0
        )
    end

    if Config.TracerOrigin == "Middle" then
        return Vector2.new(
            viewport.X / 2,
            viewport.Y / 2
        )
    end

    return Vector2.new(
        viewport.X / 2,
        viewport.Y
    )
end

local function RemoveTracer(player)
    local tracer = Tracers[player]

    if not tracer then
        return
    end

    pcall(function()
        tracer:Remove()
    end)

    pcall(function()
        tracer:Destroy()
    end)

    Tracers[player] = nil
end

local function CreateTracer(player)
    if not DrawingAvailable then
        return
    end

    if player == LocalPlayer then
        return
    end

    RemoveTracer(player)

    local tracer = Drawing.new("Line")

    tracer.Visible = false
    tracer.Thickness = Config.TracerThickness
    tracer.Transparency = Config.TracerTransparency
    tracer.Color = Color3.fromRGB(255, 255, 255)

    Tracers[player] = tracer
end

local function UpdateTracer(player)
    if not DrawingAvailable then
        return
    end

    if player == LocalPlayer then
        return
    end

    if not Config.ESPEnabled or not Config.ESPTracers then
        RemoveTracer(player)
        return
    end

    local root = GetRoot(player)

    if not root or not Alive(player) then
        if Tracers[player] then
            Tracers[player].Visible = false
        end

        return
    end

    if not Tracers[player] then
        CreateTracer(player)
    end

    local tracer = Tracers[player]

    if not tracer then
        return
    end

    local viewport = Camera.ViewportSize

    local screenPosition, onScreen =
        Camera:WorldToViewportPoint(root.Position)

    if not onScreen or screenPosition.Z <= 0 then
        tracer.Visible = false
        return
    end

    local origin = GetTracerOrigin(viewport)

    tracer.From = origin
    tracer.To = Vector2.new(
        screenPosition.X,
        screenPosition.Y
    )

    tracer.Thickness = Config.TracerThickness
    tracer.Transparency = Config.TracerTransparency

    local color = player.Team
        and player.Team.TeamColor.Color
        or player.TeamColor.Color

    tracer.Color = color
    tracer.Visible = true
end

local function RemoveESP(player)
    local data = ESP[player]

    if data then
        if data.Highlight then
            data.Highlight:Destroy()
        end

        if data.Billboard then
            data.Billboard:Destroy()
        end
    end

    ESP[player] = nil

    RemoveTracer(player)
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

    if Config.ESPTracers then
        CreateTracer(player)
    end
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

    local color = player.Team
        and player.Team.TeamColor.Color
        or player.TeamColor.Color

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
-- AIM
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
        if player ~= LocalPlayer
            and Alive(player)
            and IsAimTarget(player) then

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
                            (
                                Vector2.new(screen.X, screen.Y)
                                - center
                            ).Magnitude

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
-- PLAYER
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

--==================================================
-- MOVEMENT SETTINGS
--==================================================

local function ApplyPlayerSettings()
    local humanoid = GetHumanoid(LocalPlayer)

    if not humanoid then
        return
    end

    if Config.SpeedEnabled then
        humanoid.WalkSpeed = Config.WalkSpeed
    elseif OriginalWalkSpeed ~= nil then
        humanoid.WalkSpeed = OriginalWalkSpeed
    end

    if Config.JumpEnabled then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = Config.JumpPower
    else
        if OriginalUseJumpPower ~= nil then
            humanoid.UseJumpPower = OriginalUseJumpPower
        end

        if OriginalJumpPower ~= nil then
            humanoid.JumpPower = OriginalJumpPower
        end
    end
end

--==================================================
-- FLY
--==================================================

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

--==================================================
-- INFINITE JUMP
--==================================================

UserInputService.JumpRequest:Connect(function()
    if not Config.InfiniteJump then
        return
    end

    local humanoid = GetHumanoid(LocalPlayer)

    if humanoid then
        humanoid:ChangeState(
            Enum.HumanoidStateType.Jumping
        )
    end
end)

--==================================================
-- CHARACTER
--==================================================

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)

    local humanoid = GetHumanoid(LocalPlayer)

    if humanoid then
        SaveOriginalMovementValues(humanoid)
    end

    ApplyPlayerSettings()

    if Config.FlyEnabled then
        StartFly()
    end
end)

do
    local humanoid = GetHumanoid(LocalPlayer)

    if humanoid then
        SaveOriginalMovementValues(humanoid)
    end
end

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
            UpdateTracer(player)
        end
    end

    -- TARGET
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

    -- AIM
    if ShouldAim() and CurrentTarget then
        local part = GetAimPart(CurrentTarget)

        if part then
            local desired = CFrame.lookAt(
                Camera.CFrame.Position,
                part.Position
            )

            Camera.CFrame = Camera.CFrame:Lerp(
                desired,
                math.clamp(
                    Config.AimSmoothness,
                    0.01,
                    1
                )
            )
        end
    end

    -- MOVEMENT
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
-- TRACER UI
--==================================================

ESPTab:Section({
    Title = "Tracers",
})

ESPTab:Toggle({
    Title = "Enable Tracers",
    Value = Config.ESPTracers,

    Callback = function(value)
        Config.ESPTracers = value

        if not value then
            for player in pairs(Tracers) do
                RemoveTracer(player)
            end
        else
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer
                    and Config.ESPEnabled then

                    CreateTracer(player)
                end
            end
        end
    end,
})

ESPTab:Dropdown({
    Title = "Tracer Origin",

    Values = {
        "Top",
        "Middle",
        "Bottom",
    },

    Value = Config.TracerOrigin,

    Callback = function(value)
        Config.TracerOrigin = value
    end,
})

ESPTab:Slider({
    Title = "Tracer Thickness",

    Value = {
        Min = 1,
        Max = 5,
        Default = Config.TracerThickness,
    },

    Step = 0.5,

    Callback = function(value)
        Config.TracerThickness = value
    end,
})

ESPTab:Slider({
    Title = "Tracer Transparency",

    Value = {
        Min = 0,
        Max = 1,
        Default = Config.TracerTransparency,
    },

    Step = 0.05,

    Callback = function(value)
        Config.TracerTransparency = value
    end,
})

--==================================================
-- AIM UI
--==================================================

AimTab:Section({
    Title = "Aimbot",
})

AimTab:Toggle({
    Title = "Enable Aimbot",
    Value = Config.AimbotEnabled,

    Callback = function(value)
        Config.AimbotEnabled = value
    end,
})

AimTab:Toggle({
    Title = "Team Check",
    Desc = "Ignore players on your team.",
    Value = Config.AimTeamCheck,

    Callback = function(value)
        Config.AimTeamCheck = value
        CurrentTarget = nil
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

        Config.ActivationKey =
            keys[value] or Enum.KeyCode.Q
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
    Title = "Player",
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

        if Config.JumpEnabled then
            ApplyPlayerSettings()
        end
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
    Title = "Fly",
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
            if OriginalWalkSpeed ~= nil then
                humanoid.WalkSpeed = OriginalWalkSpeed
            end

            if OriginalUseJumpPower ~= nil then
                humanoid.UseJumpPower = OriginalUseJumpPower
            end

            if OriginalJumpPower ~= nil then
                humanoid.JumpPower = OriginalJumpPower
            end

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
                Content = ok
                    and "Configuration saved."
                    or tostring(err),
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
                Content = ok
                    and "Configuration loaded."
                    or tostring(err),
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
