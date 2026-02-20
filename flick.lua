-- ============================================
--       NUCK HUB — FLICK EDITION v4.6
--         by Nuck | Sniper Aimbot
-- ============================================

print("ByNuck - 4.6 - Flick")

-- ============================================
-- SERVICES
-- ============================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ============================================
-- RAYFIELD
-- ============================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ============================================
-- STATE
-- ============================================
local State = {
    Aimbot = {
        Enabled    = false,
        WallCheck  = true,
        TargetPart = "Head",
        Smoothness = 0.12,
        FOV        = 180,
        ShowFOV    = true,

        -- "None"  = instant lock whenever target is in FOV
        -- "RMB"   = hold right mouse button  (default / ads)
        -- "Q"     = hold Q
        -- "E"     = hold E
        -- "Shift" = hold Left Shift
        -- "X"     = hold X
        -- "Z"     = hold Z
        TriggerKey = "RMB",
    },
    ESP = {
        Enabled          = false,
        OutlineColor     = Color3.fromRGB(255, 60, 60),
        FillColor        = Color3.fromRGB(255, 60, 60),
        FillTransparency = 0.8,
    },
}

-- ============================================
-- TRIGGER KEY → held check
-- ============================================
local KeyMap = {
    RMB   = function() return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end,
    Q     = function() return UserInputService:IsKeyDown(Enum.KeyCode.Q)          end,
    E     = function() return UserInputService:IsKeyDown(Enum.KeyCode.E)          end,
    Shift = function() return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)  end,
    X     = function() return UserInputService:IsKeyDown(Enum.KeyCode.X)          end,
    Z     = function() return UserInputService:IsKeyDown(Enum.KeyCode.Z)          end,
    None  = function() return true end, -- always active
}

local function IsTriggerHeld()
    local fn = KeyMap[State.Aimbot.TriggerKey]
    return fn and fn() or false
end

-- ============================================
-- UTILITIES
-- ============================================
local function GetChar(p)
    return p and p.Character
end

local function GetPart(player, partName)
    local char = GetChar(player)
    if not char then return nil end
    if partName == "UpperTorso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    elseif partName == "LowerTorso" then
        return char:FindFirstChild("LowerTorso") or char:FindFirstChild("Torso")
    end
    return char:FindFirstChild(partName)
end

local function GetHum(player)
    local char = GetChar(player)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(player)
    local hum = GetHum(player)
    return hum and hum.Health > 0
end

local function ViewCenter()
    return Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
end

local function ScreenDist(worldPos)
    local sp, onScreen = Camera:WorldToViewportPoint(worldPos)
    if not onScreen then return math.huge end
    return (Vector2.new(sp.X, sp.Y) - ViewCenter()).Magnitude
end

-- ============================================
-- WALL CHECK — Raycast
-- ============================================
local wallParams = RaycastParams.new()
wallParams.FilterType = Enum.RaycastFilterType.Exclude

local function IsVisible(targetPart)
    local char = GetChar(LocalPlayer)
    wallParams.FilterDescendantsInstances = char and { char } or {}
    local origin    = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local result    = workspace:Raycast(origin, direction, wallParams)
    if not result then return true end
    return result.Instance:IsDescendantOf(targetPart.Parent)
        or result.Instance == targetPart
end

-- ============================================
-- BEST TARGET (closest to crosshair in FOV)
-- ============================================
local function GetBestTarget()
    local best, bestDist = nil, math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not IsAlive(player)   then continue end

        local part = GetPart(player, State.Aimbot.TargetPart)
        if not part then continue end

        if State.Aimbot.WallCheck and not IsVisible(part) then continue end

        local d = ScreenDist(part.Position)
        if d < State.Aimbot.FOV and d < bestDist then
            bestDist = d
            best     = player
        end
    end

    return best
end

-- ============================================
-- FOV CIRCLE (Drawing)
-- ============================================
local FOVCircle         = Drawing.new("Circle")
FOVCircle.Visible       = false
FOVCircle.Thickness     = 1.5
FOVCircle.Color         = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled        = false
FOVCircle.NumSides      = 64

-- ============================================
-- AIMBOT LOOP
-- ============================================
local aimbotConn = nil

local function StartAimbotLoop()
    if aimbotConn then aimbotConn:Disconnect() end

    aimbotConn = RunService.Heartbeat:Connect(function()
        -- FOV circle update
        FOVCircle.Position = ViewCenter()
        FOVCircle.Radius   = State.Aimbot.FOV
        FOVCircle.Visible  = State.Aimbot.ShowFOV

        if not State.Aimbot.Enabled  then return end
        if not IsTriggerHeld()       then return end

        local target = GetBestTarget()
        if not target then return end

        local part = GetPart(target, State.Aimbot.TargetPart)
        if not part then return end

        -- "None" = instant snap (no smoothness)
        if State.Aimbot.TriggerKey == "None" then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
        else
            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(Camera.CFrame.Position, part.Position),
                State.Aimbot.Smoothness
            )
        end
    end)
end

-- ============================================
-- ESP — Highlight (CS style)
-- ============================================
local ESPHighlights = {}

local function ApplyHighlight(player)
    if player == LocalPlayer           then return end
    if ESPHighlights[player]           then return end
    local char = GetChar(player)
    if not char                        then return end

    local hl                    = Instance.new("Highlight")
    hl.Name                     = "NuckESP"
    hl.DepthMode                = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency         = State.ESP.FillTransparency
    hl.OutlineTransparency      = 0
    hl.FillColor                = State.ESP.FillColor
    hl.OutlineColor             = State.ESP.OutlineColor
    hl.Adornee                  = char
    hl.Parent                   = char
    ESPHighlights[player]       = hl
end

local function RemoveHighlight(player)
    if ESPHighlights[player] then
        ESPHighlights[player]:Destroy()
        ESPHighlights[player] = nil
    end
end

local function EnableESP()
    for _, p in ipairs(Players:GetPlayers()) do ApplyHighlight(p) end
end

local function DisableESP()
    for p in pairs(ESPHighlights) do RemoveHighlight(p) end
end

local function RefreshESPColors()
    for _, hl in pairs(ESPHighlights) do
        hl.OutlineColor     = State.ESP.OutlineColor
        hl.FillColor        = State.ESP.FillColor
        hl.FillTransparency = State.ESP.FillTransparency
    end
end

local function WatchPlayer(player)
    player.CharacterAdded:Connect(function()
        RemoveHighlight(player)
        task.wait(0.5)
        if State.ESP.Enabled then ApplyHighlight(player) end
    end)
    player.CharacterRemoving:Connect(function() RemoveHighlight(player) end)
end

local function InitESP()
    for _, p in ipairs(Players:GetPlayers()) do WatchPlayer(p) end
    Players.PlayerAdded:Connect(function(p)
        WatchPlayer(p)
        if State.ESP.Enabled then task.wait(1); ApplyHighlight(p) end
    end)
    Players.PlayerRemoving:Connect(RemoveHighlight)
end

-- ============================================
-- ============================================
--           RAYFIELD UI
-- ============================================
-- ============================================
local Window = Rayfield:CreateWindow({
    Name            = "Nuck Hub — Flick",
    LoadingTitle    = "Nuck Hub",
    LoadingSubtitle = "Flick Edition  •  by Nuck",
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "NuckHub",
        FileName   = "FlickConfig",
    },
    KeySystem = false,
})

local TabAimbot = Window:CreateTab("🎯  Aimbot", 4483362458)
local TabVisual = Window:CreateTab("👁  Visual",  4483362458)

-- ==================== AIMBOT TAB ====================

TabAimbot:CreateSection("Lock Settings")

TabAimbot:CreateToggle({
    Name         = "Enable Aimbot",
    CurrentValue = false,
    Flag         = "AimbotEnabled",
    Callback     = function(v) State.Aimbot.Enabled = v end,
})

TabAimbot:CreateToggle({
    Name         = "Wall Check — Visible targets only",
    CurrentValue = true,
    Flag         = "AimbotWallCheck",
    Callback     = function(v) State.Aimbot.WallCheck = v end,
})

TabAimbot:CreateDropdown({
    Name            = "Target Part",
    Options         = { "Head", "UpperTorso", "LowerTorso", "LeftArm", "RightArm" },
    CurrentOption   = { "Head" },
    MultipleOptions = false,
    Flag            = "AimbotPart",
    Callback        = function(opt) State.Aimbot.TargetPart = opt[1] end,
})

TabAimbot:CreateSection("Trigger Key")

TabAimbot:CreateDropdown({
    Name            = "Activation Key",
    Options         = {
        "None — Instant (no key)",
        "RMB — Hold Right Click",
        "Q — Hold Q",
        "E — Hold E",
        "Shift — Hold Left Shift",
        "X — Hold X",
        "Z — Hold Z",
    },
    CurrentOption   = { "RMB — Hold Right Click" },
    MultipleOptions = false,
    Flag            = "AimbotTrigger",
    Callback        = function(opt)
        local label = opt[1]
        -- Extract key prefix before " — "
        local key = label:match("^([^%s]+)")
        State.Aimbot.TriggerKey = key
    end,
})

TabAimbot:CreateLabel("  ⚡  None = instant snap as soon as target enters FOV.")
TabAimbot:CreateLabel("  🖱  Other keys = smooth lock while held.")

TabAimbot:CreateSection("Smoothness & FOV")

TabAimbot:CreateSlider({
    Name         = "Smoothness",
    Range        = { 1, 100 },
    Increment    = 1,
    Suffix       = "%",
    CurrentValue = 12,
    Flag         = "AimbotSmooth",
    Callback     = function(v)
        -- 1% ≈ very fast | 100% ≈ very slow
        State.Aimbot.Smoothness = 0.02 + (v / 100) * 0.58
    end,
})

TabAimbot:CreateLabel("  ℹ  Smoothness ignored when key is set to None.")

TabAimbot:CreateSlider({
    Name         = "FOV Radius",
    Range        = { 30, 700 },
    Increment    = 5,
    Suffix       = " px",
    CurrentValue = 180,
    Flag         = "AimbotFOV",
    Callback     = function(v) State.Aimbot.FOV = v end,
})

TabAimbot:CreateToggle({
    Name         = "Show FOV Circle",
    CurrentValue = true,
    Flag         = "AimbotShowFOV",
    Callback     = function(v)
        State.Aimbot.ShowFOV = v
        if not v then FOVCircle.Visible = false end
    end,
})

-- ==================== VISUAL TAB ====================

TabVisual:CreateSection("ESP — Highlight (CS Style)")

TabVisual:CreateToggle({
    Name         = "Enable ESP",
    CurrentValue = false,
    Flag         = "ESPEnabled",
    Callback     = function(v)
        State.ESP.Enabled = v
        if v then EnableESP() else DisableESP() end
    end,
})

TabVisual:CreateLabel("  ℹ  Outline visible through walls (AlwaysOnTop).")

TabVisual:CreateSection("Colors")

TabVisual:CreateColorPicker({
    Name     = "Outline Color",
    Color    = Color3.fromRGB(255, 60, 60),
    Flag     = "ESPOutline",
    Callback = function(v)
        State.ESP.OutlineColor = v
        RefreshESPColors()
    end,
})

TabVisual:CreateColorPicker({
    Name     = "Fill Color",
    Color    = Color3.fromRGB(255, 60, 60),
    Flag     = "ESPFill",
    Callback = function(v)
        State.ESP.FillColor = v
        RefreshESPColors()
    end,
})

TabVisual:CreateSlider({
    Name         = "Fill Transparency",
    Range        = { 0, 10 },
    Increment    = 1,
    Suffix       = " x0.1",
    CurrentValue = 8,
    Flag         = "ESPFillTransp",
    Callback     = function(v)
        State.ESP.FillTransparency = v * 0.1
        RefreshESPColors()
    end,
})

-- ============================================
-- INIT
-- ============================================
InitESP()
StartAimbotLoop()

Rayfield:Notify({
    Title    = "Nuck Hub — Flick 💜",
    Content  = "Loaded successfully. Aimbot + ESP ready.",
    Duration = 5,
    Image    = 4483362458,
})
