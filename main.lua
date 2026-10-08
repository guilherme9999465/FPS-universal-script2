--==================================================
-- GUILOHUB
-- Author: Guilh3rm3Scr1pter
-- WindUI + ESP + Aimbot
--==================================================

local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

assert(WindUI, "WindUI nao carregou")

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- CONFIG
--==================================================

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
    Resizable = true,
    SideBarWidth = 180,

    OpenButton = {
        Title = "GuiloHUB",
        Icon = "crosshair",
        Draggable = true,
        OnlyIcon = false,
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

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
})

--==================================================
-- ESP FUNCTIONS
--==================================================

local function IsAlive(character)
    if not character then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    return humanoid ~= nil and humanoid.Health > 0
end

local function IsValidTarget(player, teamCheck)
    if player == LocalPlayer then
        return false
    end

    if teamCheck then
        if LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
            return false
        end
    end

    local character = player.Character

    if not IsAlive(character) then
        return false
    end

    if not character:FindFirstChild("HumanoidRootPart") then
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

    --==================================================
    -- HIGHLIGHT
    --==================================================

    local Highlight = Instance.new("Highlight")

    Highlight.Name = "GuiloESP"
    Highlight.Adornee = character
    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    Highlight.FillTransparency = 0.45
    Highlight.OutlineTransparency = 0

    Highlight.FillColor = Color3.fromRGB(255, 80, 80)
    Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)

    if player.Team and player.Team.TeamColor then
        Highlight.FillColor = player.Team.TeamColor.Color
        Highlight.OutlineColor = player.Team.TeamColor.Color
    end

    Highlight.Parent = character

    --==================================================
    -- NAME / DISTANCE
    --==================================================

    local Billboard = Instance.new("BillboardGui")

    Billboard.Name = "GuiloESPInfo"

    Billboard.Adornee =
        character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")

    Billboard.Size = UDim2.fromOffset(220, 50)
    Billboard.StudsOffset = Vector3.new(0, 3, 0)
    Billboard.AlwaysOnTop = true

    Billboard.Parent = character

    local Text = Instance.new("TextLabel")

    Text.Size = UDim2.fromScale(1, 1)

    Text.BackgroundTransparency = 1

    Text.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text.TextStrokeTransparency = 0

    Text.TextSize = 13
    Text.Font = Enum.Font.GothamBold

    Text.Parent = Billboard

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

    local root =
        character
        and character:FindFirstChild("HumanoidRootPart")

    if not root then

        data.Highlight.Enabled = false
        data.Billboard.Enabled = false

        return
    end

    local valid =
        IsValidTarget(
            player,
            Config.ESPTeamCheck
        )

    local enabled =
        Config.ESPEnabled
        and valid

    data.Highlight.Enabled = enabled
    data.Billboard.Enabled = enabled

    if not enabled then
        return
    end

    -- Distance

    local distance =
        (
            Camera.CFrame.Position
            - root.Position
        ).Magnitude

    -- Text

    local text = ""

    if Config.ESPNames then
        text = player.DisplayName
    end

    if Config.ESPDistance then

        if text ~= "" then
            text = text .. "\n"
        end

        text =
            text
            .. math.floor(distance)
            .. " studs"
    end

    data.Text.Text = text

    -- Team Color

    if player.Team
        and player.Team.TeamColor then

        data.Highlight.FillColor =
            player.Team.TeamColor.Color

        data.Highlight.OutlineColor =
            player.Team.TeamColor.Color
    end
end

--==================================================
-- PLAYER SETUP
--==================================================

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

    player:GetPropertyChangedSignal(
        "Team"
    ):Connect(function()

        if player.Character then
            CreateESP(player)
        end
    end)

    if player.Character then
        CreateESP(player)
    end
end

for _, player in ipairs(
    Players:GetPlayers()
) do

    SetupPlayer(player)
end

Players.PlayerAdded:Connect(
    SetupPlayer
)

Players.PlayerRemoving:Connect(
    RemoveESP
)

--==================================================
-- AIMBOT
--==================================================

local function GetAimPart(character)

    if not character then
        return nil
    end

    return
        character:FindFirstChild(
            Config.AimPart
        )
        or character:FindFirstChild(
            "HumanoidRootPart"
        )
end

local function GetClosestTarget()

    local closestPlayer = nil

    local closestScreenDistance =
        math.huge

    local center =
        Camera.ViewportSize / 2

    for _, player in ipairs(
        Players:GetPlayers()
    ) do

        if IsValidTarget(
            player,
            Config.AimbotTeamCheck
        ) then

            local character =
                player.Character

            local aimPart =
                GetAimPart(character)

            if aimPart then

                local worldDistance =
                    (
                        Camera.CFrame.Position
                        - aimPart.Position
                    ).Magnitude

                if worldDistance
                    <= Config.MaxDistance then

                    local screenPosition, visible =
                        Camera:WorldToViewportPoint(
                            aimPart.Position
                        )

                    if visible then

                        local screenDistance =
                            (
                                Vector2.new(
                                    screenPosition.X,
                                    screenPosition.Y
                                )
                                - center
                            ).Magnitude

                        if screenDistance
                            <= Config.AimFOV
                            and screenDistance
                            < closestScreenDistance then

                            closestScreenDistance =
                                screenDistance

                            closestPlayer =
                                player
                        end
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

    local character =
        player.Character

    if not character then
        return
    end

    local aimPart =
        GetAimPart(character)

    if not aimPart then
        return
    end

    local targetCFrame =
        CFrame.lookAt(
            Camera.CFrame.Position,
            aimPart.Position
        )

    Camera.CFrame =
        Camera.CFrame:Lerp(
            targetCFrame,
            math.clamp(
                Config.AimSmoothness,
                0.01,
                1
            )
        )
end

--==================================================
-- AIM INPUT
--==================================================

UserInputService.InputBegan:Connect(
    function(input, processed)

        if processed then
            return
        end

        if input.UserInputType
            == Enum.UserInputType.MouseButton2 then

            HoldingAim = true
        end
    end
)

UserInputService.InputEnded:Connect(
    function(input)

        if input.UserInputType
            == Enum.UserInputType.MouseButton2 then

            HoldingAim = false
        end
    end
)

--==================================================
-- MAIN LOOP
--==================================================

RunService.RenderStepped:Connect(
    function()

        for player in pairs(
            ESPObjects
        ) do

            UpdateESP(player)
        end

        if Config.AimbotEnabled
            and HoldingAim then

            local target =
                GetClosestTarget()

            if target then
                AimAt(target)
            end
        end
    end
)

--==================================================
-- ESP TAB
--==================================================

ESPTab:Section({
    Title = "ESP Settings",
    TextSize = 16,
})

ESPTab:Toggle({
    Title = "Enable ESP",

    Value = Config.ESPEnabled,

    Callback = function(value)

        Config.ESPEnabled = value
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
    Title = "Player Names",

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
-- AIMBOT TAB
--==================================================

AimTab:Section({
    Title = "Aimbot Settings",
    TextSize = 16,
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

    Value = Config.AimbotTeamCheck,

    Callback = function(value)

        Config.AimbotTeamCheck = value
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

    Value = "Head",

    Callback = function(value)

        Config.AimPart = value
    end,
})

AimTab:Slider({

    Title = "FOV",

    Step = 5,

    Value = {
        Min = 50,
        Max = 500,
        Default = Config.AimFOV,
    },

    Callback = function(value)

        Config.AimFOV = value
    end,
})

AimTab:Slider({

    Title = "Smoothness",

    Step = 0.01,

    Value = {
        Min = 0.01,
        Max = 1,
        Default = Config.AimSmoothness,
    },

    Callback = function(value)

        Config.AimSmoothness = value
    end,
})

AimTab:Slider({

    Title = "Max Distance",

    Step = 50,

    Value = {
        Min = 100,
        Max = 3000,
        Default = Config.MaxDistance,
    },

    Callback = function(value)

        Config.MaxDistance = value
    end,
})

--==================================================
-- SETTINGS
--==================================================

SettingsTab:Section({
    Title = "GuiloHUB",
    TextSize = 16,
})

SettingsTab:Paragraph({

    Title = "Combat Test Suite",

    Desc =
        "ESP e Aimbot configuraveis "
        .. "pelas abas acima.",

})

SettingsTab:Button({

    Title = "Disable ESP",

    Icon = "eye-off",

    Callback = function()

        Config.ESPEnabled = false

        for _, data in pairs(
            ESPObjects
        ) do

            data.Highlight.Enabled = false
            data.Billboard.Enabled = false
        end
    end,
})

--==================================================
-- NOTIFICATION
--==================================================

WindUI:Notify({

    Title = "GuiloHUB",

    Content =
        "Interface carregada com sucesso.",

    Duration = 5,
})
