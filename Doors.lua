-- ═══════════════════════════════════════════════════════════════
--   DOORS HUB v3.0 | Rayfield Interface Suite
--   Estruturas confirmadas via open-source (xDAhmedTry, PenguinManiack, sashaaaaa)
--
--   ✅ workspace.CurrentRooms[tostring(LatestRoom.Value)]:WaitForChild("Door")
--   ✅ KeyObtain.Hitbox, KeyObtain.ModulePrompt
--   ✅ CurrentDoor.Door.Position, CurrentDoor.ClientOpen:FireServer()
--   ✅ room.Assets → "Dresser", "Wardrobe", etc.
--   ✅ workspace.DescendantAdded → Rush, Ambush, Seek_Arm, etc.
-- ═══════════════════════════════════════════════════════════════

-- ─── SERVIÇOS ─────────────────────────────────────────────────
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local Workspace         = workspace

-- ─── PLAYER ───────────────────────────────────────────────────
local LP   = Players.LocalPlayer
local Char = LP.Character or LP.CharacterAdded:Wait()
LP.CharacterAdded:Connect(function(c) Char = c end)

local function getHRP()  return Char and Char:FindFirstChild("HumanoidRootPart") end
local function getHum()  return Char and Char:FindFirstChildOfClass("Humanoid") end

-- ─── GAME DATA ────────────────────────────────────────────────
local GameData   = ReplicatedStorage:WaitForChild("GameData")
local LatestRoom = GameData:WaitForChild("LatestRoom")

local function getRoom(offset)
    offset = offset or 0
    local n = LatestRoom.Value + offset
    return Workspace.CurrentRooms:FindFirstChild(tostring(n))
end

-- ─── FLAGS ────────────────────────────────────────────────────
local F = {
    WalkFarm        = false,
    TPFarm          = false,
    GodMode         = false,
    SafeMode        = "Auto Closet",
    ESP             = false,
    InstantInteract = false,
    FullBright      = false,
    MonsterWarning  = true,
}
local entityActive  = false
local espObjects    = {}
local lightingBkp   = {}

-- ═══════════════════════════════════════════════════════════════
--   NOTIFICAÇÃO DE MONSTRO NA TELA
-- ═══════════════════════════════════════════════════════════════
local warnGui = nil

local function showEntityWarning(entityName, duration)
    if not F.MonsterWarning then return end

    -- Remove aviso anterior
    if warnGui and warnGui.Parent then warnGui:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name           = "DoorsWarning"
    sg.ResetOnSpawn   = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent         = LP.PlayerGui
    warnGui           = sg

    -- Fundo vermelho
    local bg = Instance.new("Frame")
    bg.Size              = UDim2.new(1, 0, 0, 110)
    bg.Position          = UDim2.new(0, 0, 0.33, 0)
    bg.BackgroundColor3  = Color3.fromRGB(160, 0, 0)
    bg.BackgroundTransparency = 0.15
    bg.BorderSizePixel   = 0
    bg.Parent            = sg

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextColor3             = Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeTransparency = 0.2
    lbl.TextSize               = 40
    lbl.Text                   = "⚠️  " .. entityName:upper() .. "  ⚠️"
    lbl.Parent                 = bg

    -- Sub-texto
    local sub = Instance.new("TextLabel")
    sub.Size                   = UDim2.new(1, 0, 0, 30)
    sub.Position               = UDim2.new(0, 0, 0.68, 0)
    sub.BackgroundTransparency = 1
    sub.Font                   = Enum.Font.Gotham
    sub.TextColor3             = Color3.fromRGB(255, 220, 220)
    sub.TextSize               = 20
    sub.Text                   = "SE ESCONDA IMEDIATAMENTE!"
    sub.Parent                 = bg

    -- Pisca
    task.spawn(function()
        for _ = 1, 5 do
            lbl.TextTransparency = 0.75
            task.wait(0.14)
            lbl.TextTransparency = 0
            task.wait(0.14)
        end
    end)

    task.delay(duration or 5, function()
        if sg and sg.Parent then sg:Destroy() end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--   ARMÁRIOS  (confirmado: room.Assets → Dresser, Wardrobe, etc.)
-- ═══════════════════════════════════════════════════════════════
local CLOSET_NAMES = {
    "Dresser", "Wardrobe", "Wardrobe2", "Closet",
    "Locker", "Bed", "Cabinet", "HidingSpot",
}

local function findNearestCloset()
    local hrp  = getHRP()
    local room = getRoom()
    if not hrp or not room then return nil end

    local nearest, nearDist = nil, math.huge
    local sources = {}

    -- Prioridade: pasta Assets (local confirmado)
    local assets = room:FindFirstChild("Assets")
    if assets then
        for _, v in ipairs(assets:GetChildren()) do table.insert(sources, v) end
    end
    -- Fallback: quarto inteiro
    if #sources == 0 then
        for _, v in ipairs(room:GetDescendants()) do table.insert(sources, v) end
    end

    for _, v in ipairs(sources) do
        for _, n in ipairs(CLOSET_NAMES) do
            if v.Name == n or v.Name:lower():find(n:lower()) then
                local part = v:IsA("BasePart") and v
                    or v.PrimaryPart
                    or v:FindFirstChildWhichIsA("BasePart")
                if part then
                    local d = (hrp.Position - part.Position).Magnitude
                    if d < nearDist then nearest = part; nearDist = d end
                end
                break
            end
        end
    end
    return nearest
end

local function tpToCloset()
    local hrp  = getHRP()
    local spot = findNearestCloset()
    if hrp and spot then
        hrp.CFrame = CFrame.new(spot.Position + Vector3.new(0, 3, 0))
    end
end

-- ═══════════════════════════════════════════════════════════════
--   AUTO FARM
--   Confirmado: room.Door → Model com sub-part "Door"
--   KeyObtain.Hitbox + ModulePrompt
--   Door.ClientOpen:FireServer()
-- ═══════════════════════════════════════════════════════════════
local function skipToNextDoor()
    local hrp = getHRP()
    if not hrp then return end

    pcall(function()
        local room = getRoom()
        if not room then return end

        local DoorModel = room:WaitForChild("Door", 5)
        if not DoorModel then return end

        -- Verifica chave necessária
        local HasKey = nil
        for _, v in ipairs(DoorModel.Parent:GetDescendants()) do
            if v.Name == "KeyObtain" then HasKey = v; break end
        end

        if HasKey then
            local hitbox = HasKey:FindFirstChild("Hitbox")
            if hitbox then
                hrp.CFrame = CFrame.new(hitbox.Position + Vector3.new(0, 3, 0))
                task.wait(0.25)
            end
            local modPrompt = HasKey:FindFirstChild("ModulePrompt")
            if modPrompt and fireproximityprompt then
                fireproximityprompt(modPrompt, 0)
                task.wait(0.25)
            end
            -- Desbloqueia
            local lockPrompt = DoorModel:FindFirstChild("Lock")
                and DoorModel.Lock:FindFirstChild("UnlockPrompt")
            if lockPrompt and fireproximityprompt then
                local dp = DoorModel:FindFirstChild("Door")
                if dp then hrp.CFrame = CFrame.new(dp.Position + Vector3.new(0, 3, -3)) end
                task.wait(0.2)
                fireproximityprompt(lockPrompt, 0)
                task.wait(0.25)
            end
        end

        -- TP para a porta
        local doorPart = DoorModel:FindFirstChild("Door")
        if doorPart then
            hrp.CFrame = CFrame.new(doorPart.Position + Vector3.new(0, 3, -3))
            task.wait(0.25)
        end

        -- Abre via RemoteEvent (método real)
        local openEvent = DoorModel:FindFirstChild("ClientOpen")
        if openEvent then
            openEvent:FireServer()
        end
    end)
end

local function walkToNextDoor()
    local hrp  = getHRP()
    local hum  = getHum()
    local room = getRoom()
    if not hrp or not hum or not room then return end

    local DoorModel = room:FindFirstChild("Door")
    if not DoorModel then return end
    local doorPart = DoorModel:FindFirstChild("Door")
    if not doorPart then return end

    local goal = doorPart.Position + Vector3.new(0, 0, -3)
    hum:MoveTo(goal)

    local t = 0
    repeat
        task.wait(0.1); t += 0.1
        if not Char or not Char.Parent then break end
    until (hrp.Position - goal).Magnitude < 4 or t >= 12
end

-- ═══════════════════════════════════════════════════════════════
--   DETECÇÃO DE ENTIDADES  (DescendantAdded + polling)
-- ═══════════════════════════════════════════════════════════════
local ENTITY_MAP = {
    Rush                  = "💨 RUSH",
    Ambush                = "💚 AMBUSH",
    Seek_Arm              = "👁 SEEK",
    ChandelierObstruction = "👁 SEEK",
    Screech               = "🔊 SCREECH",
    Eyes                  = "👀 EYES",
    Halt                  = "🔵 HALT",
    Glitch                = "⚡ GLITCH",
    Blitz                 = "🟢 BLITZ",
    Figure                = "🎭 FIGURE",
    Dupe                  = "🚪 DUPE",
    Snare                 = "🪤 SNARE",
    ["A-60"]              = "💀 A-60",
    ["A-90"]              = "❓ A-90",
    ["A-120"]             = "🔴 A-120",
    Haste                 = "⏱ HASTE",
    Dread                 = "😱 DREAD",
    Void                  = "🌑 VOID",
    Surge                 = "⚡ SURGE",
}

local alerted = {}

local function onEntityDetected(inst)
    local name = inst.Name
    if not ENTITY_MAP[name] then return end
    if alerted[name] then return end
    alerted[name] = true
    task.delay(12, function() alerted[name] = nil end)

    entityActive = true

    -- Aviso na tela sempre (independente do God Mode)
    showEntityWarning(ENTITY_MAP[name], 5)

    -- Evasão (só se God Mode ativo)
    if F.GodMode then
        local hrp = getHRP()
        if not hrp then return end

        if F.SafeMode == "Auto Closet" then
            tpToCloset()
            local t = 0
            repeat task.wait(0.5); t += 0.5
            until not (inst and inst.Parent) or t >= 16
            entityActive = false

        elseif F.SafeMode == "TP to Roof" then
            local savedCF = hrp.CFrame
            hrp.CFrame    = hrp.CFrame + Vector3.new(0, 80, 0)
            local t = 0
            repeat task.wait(0.5); t += 0.5
            until not (inst and inst.Parent) or t >= 16
            hrp.CFrame    = savedCF
            entityActive  = false
        end
    else
        task.delay(7, function() entityActive = false end)
    end
end

local entityConn = nil
local function startMonitor()
    if entityConn then return end

    entityConn = Workspace.DescendantAdded:Connect(function(inst)
        task.spawn(onEntityDetected, inst)
    end)

    -- Polling para entidades já presentes
    task.spawn(function()
        while entityConn do
            for name in pairs(ENTITY_MAP) do
                local found = Workspace:FindFirstChild(name, true)
                if found then task.spawn(onEntityDetected, found) end
            end
            task.wait(0.4)
        end
    end)
end

local function stopMonitor()
    if entityConn then entityConn:Disconnect(); entityConn = nil end
    entityActive = false
end

-- ═══════════════════════════════════════════════════════════════
--   ESP  (estrutura correta por pasta)
-- ═══════════════════════════════════════════════════════════════
local function clearESP()
    for _, obj in ipairs(espObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    espObjects = {}
end

local function addHL(adornee, fill, outline, label)
    if not adornee then return end
    local h = Instance.new("Highlight")
    h.FillColor           = fill
    h.OutlineColor        = outline
    h.FillTransparency    = 0.4
    h.OutlineTransparency = 0
    h.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee             = adornee
    h.Parent              = adornee
    table.insert(espObjects, h)

    local bb = Instance.new("BillboardGui")
    bb.Size          = UDim2.new(0, 130, 0, 28)
    bb.StudsOffset   = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop   = true
    bb.MaxDistance   = 200
    bb.Adornee       = adornee
    bb.Parent        = adornee
    local tl = Instance.new("TextLabel")
    tl.Size                   = UDim2.fromScale(1, 1)
    tl.BackgroundTransparency = 1
    tl.Font                   = Enum.Font.GothamBold
    tl.TextColor3             = Color3.fromRGB(255, 255, 255)
    tl.TextStrokeTransparency = 0
    tl.TextSize               = 14
    tl.Text                   = label
    tl.Parent                 = bb
    table.insert(espObjects, bb)
end

local ITEM_KW = {
    "lighter", "flashlight", "vitamins", "bandage",
    "lockpick", "medkit", "painkiller", "crucifix",
    "candle", "starlight", "knob",
}

local function buildESP()
    clearESP()
    if not F.ESP then return end
    local room = getRoom()
    if not room then return end

    -- ── PORTA ──
    local DM = room:FindFirstChild("Door")
    if DM then
        local dp = DM:FindFirstChild("Door")
        if dp then
            addHL(dp, Color3.fromRGB(0,110,255), Color3.fromRGB(100,200,255),
                "🚪 PORTA #" .. LatestRoom.Value + 1)
        end
    end

    -- ── CHAVE ──
    for _, v in ipairs(room:GetDescendants()) do
        if v.Name == "KeyObtain" then
            local hb = v:FindFirstChild("Hitbox") or v:FindFirstChildWhichIsA("BasePart")
            if hb then addHL(hb, Color3.fromRGB(255,215,0), Color3.fromRGB(255,255,50), "🗝️ CHAVE") end
        end
    end

    -- ── ARMÁRIOS (room.Assets) ──
    local assets = room:FindFirstChild("Assets")
    if assets then
        for _, v in ipairs(assets:GetChildren()) do
            for _, n in ipairs(CLOSET_NAMES) do
                if v.Name == n or v.Name:lower():find(n:lower()) then
                    local part = v:IsA("BasePart") and v or v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                    if part then addHL(part, Color3.fromRGB(0,220,90), Color3.fromRGB(50,255,140), "🚪 " .. v.Name) end
                    break
                end
            end
        end
    end

    -- ── ITENS ──
    for _, v in ipairs(room:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Model") then
            local lname = v.Name:lower()
            for _, kw in ipairs(ITEM_KW) do
                if lname:find(kw) then
                    local part = v:IsA("BasePart") and v or v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                    if part then addHL(part, Color3.fromRGB(200,150,255), Color3.fromRGB(230,200,255), "📦 " .. v.Name) end
                    break
                end
            end
        end
    end
end

LatestRoom.Changed:Connect(function()
    task.wait(1.5)
    if F.ESP then buildESP() end
end)

-- ═══════════════════════════════════════════════════════════════
--   FULLBRIGHT
-- ═══════════════════════════════════════════════════════════════
local function enableFB()
    lightingBkp = {
        Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient,
        Brightness=Lighting.Brightness, FogEnd=Lighting.FogEnd, ClockTime=Lighting.ClockTime
    }
    for _, fx in ipairs(Lighting:GetChildren()) do
        if fx:IsA("ColorCorrectionEffect") or fx:IsA("BlurEffect")
            or fx:IsA("SunRaysEffect") or fx:IsA("BlackAndWhiteEffect") then fx.Enabled = false end
    end
    Lighting.Ambient=Color3.fromRGB(255,255,255); Lighting.OutdoorAmbient=Color3.fromRGB(255,255,255)
    Lighting.Brightness=2; Lighting.FogEnd=100000; Lighting.ClockTime=14
end

local function disableFB()
    if not lightingBkp.Ambient then return end
    Lighting.Ambient=lightingBkp.Ambient; Lighting.OutdoorAmbient=lightingBkp.OutdoorAmbient
    Lighting.Brightness=lightingBkp.Brightness; Lighting.FogEnd=lightingBkp.FogEnd; Lighting.ClockTime=lightingBkp.ClockTime
    for _, fx in ipairs(Lighting:GetChildren()) do
        if fx:IsA("ColorCorrectionEffect") or fx:IsA("BlurEffect")
            or fx:IsA("SunRaysEffect") or fx:IsA("BlackAndWhiteEffect") then fx.Enabled = true end
    end
end

-- ═══════════════════════════════════════════════════════════════
--   COLLECT ITEMS  (ProximityPrompt via fireproximityprompt)
-- ═══════════════════════════════════════════════════════════════
local function collectItems()
    local room = getRoom()
    if not room then return end
    for _, v in ipairs(room:GetDescendants()) do
        if v:IsA("ProximityPrompt") and not v.Disabled then
            pcall(function()
                if fireproximityprompt then fireproximityprompt(v, 0) end
            end)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
--   RAYFIELD UI
-- ═══════════════════════════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name           = "DOORS Hub 🚪",
    LoadingTitle   = "DOORS Hub",
    LoadingSubtitle = "v3.0 | Estruturas Verificadas",
    ConfigurationSaving = { Enabled=true, FolderName="DoorsHub", FileName="cfg_v3" },
    KeySystem      = false,
})

-- ── TAB 1: AUTO FARM ──────────────────────────────────────────
local T1 = Window:CreateTab("🚶 Auto Farm", 4483362458)

T1:CreateSection("Movimentação")

T1:CreateToggle({
    Name="Walk Farm", CurrentValue=false, Flag="WalkFarm",
    Callback = function(v)
        F.WalkFarm = v
        if v then task.spawn(function()
            while F.WalkFarm do
                if not entityActive then walkToNextDoor() end
                task.wait(0.5)
            end
        end) end
    end,
})

T1:CreateToggle({
    Name="TP Farm (RISK) ⚠️", CurrentValue=false, Flag="TPFarm",
    Callback = function(v)
        F.TPFarm = v
        if v then task.spawn(function()
            while F.TPFarm do
                if not entityActive then skipToNextDoor() end
                task.wait(1.2)
            end
        end) end
    end,
})

T1:CreateButton({
    Name="⬆️ Skip Porta Agora",
    Callback = function() skipToNextDoor() end,
})

T1:CreateSection("Velocidade & Itens")

T1:CreateSlider({
    Name="Walk Speed", Range={16,100}, Increment=2, CurrentValue=16, Flag="WS", Suffix=" st/s",
    Callback = function(v) local h=getHum(); if h then h.WalkSpeed=v end end,
})

T1:CreateToggle({
    Name="Instant Interact (Loop de Itens)", CurrentValue=false, Flag="II",
    Callback = function(v)
        F.InstantInteract = v
        if v then task.spawn(function()
            while F.InstantInteract do collectItems(); task.wait(1) end
        end) end
    end,
})

T1:CreateButton({
    Name="💰 Coletar Itens do Quarto Agora",
    Callback = function()
        collectItems()
        Rayfield:Notify({Title="✅ Coletado",Content="Todos os prompts do quarto disparados.",Duration=2})
    end,
})

-- ── TAB 2: GOD MODE ───────────────────────────────────────────
local T2 = Window:CreateTab("🛡️ God Mode", 4483362458)

T2:CreateSection("Evasão Automática")

T2:CreateToggle({
    Name="Smart God Mode", CurrentValue=false, Flag="GodMode",
    Callback = function(v)
        F.GodMode = v
        if v then startMonitor() else stopMonitor() end
    end,
})

T2:CreateDropdown({
    Name="Modo de Evasão",
    Options={"Auto Closet","TP to Roof"},
    CurrentOption={"Auto Closet"},
    Flag="SafeMode",
    Callback = function(opt)
        F.SafeMode = type(opt)=="table" and opt[1] or opt
    end,
})

T2:CreateSection("⚠️ Notificação de Monstro")

T2:CreateToggle({
    Name="Monster Warning (aviso na tela)", CurrentValue=true, Flag="MonWarn",
    Callback = function(v)
        F.MonsterWarning = v
    end,
})

T2:CreateButton({
    Name="🧪 Testar Aviso (Rush simulado)",
    Callback = function() showEntityWarning("💨 RUSH", 4) end,
})

T2:CreateSection("Entidades Monitoradas")
T2:CreateParagraph({
    Title="Todas as Entidades",
    Content="Rush · Ambush · Seek · Screech · Eyes · Figure · Halt · Glitch · Blitz · Dupe · Snare · A-60 · A-90 · A-120 · Haste · Dread · Void · Surge"
})

T2:CreateButton({
    Name="🚪 TP para Armário Mais Próximo",
    Callback = function()
        local spot = findNearestCloset()
        if spot then
            local hrp = getHRP()
            if hrp then
                hrp.CFrame = CFrame.new(spot.Position + Vector3.new(0,3,0))
                Rayfield:Notify({Title="✅ Teleportado!",Content="Armário: "..spot.Name,Duration=2})
            end
        else
            Rayfield:Notify({Title="❌ Nenhum Armário",Content="Não encontrado neste quarto.",Duration=2})
        end
    end,
})

-- ── TAB 3: VISUAIS ────────────────────────────────────────────
local T3 = Window:CreateTab("👁️ Visuais", 4483362458)

T3:CreateSection("ESP")

T3:CreateToggle({
    Name="ESP (Portas, Chaves, Armários, Itens)", CurrentValue=false, Flag="ESP",
    Callback = function(v)
        F.ESP = v
        if v then buildESP() else clearESP() end
    end,
})

T3:CreateButton({
    Name="🔄 Forçar Atualização ESP",
    Callback = function()
        if F.ESP then buildESP()
        else Rayfield:Notify({Title="ESP Inativo",Content="Ative o ESP primeiro.",Duration=2}) end
    end,
})

T3:CreateSection("Lighting")

T3:CreateToggle({
    Name="FullBright 🌟", CurrentValue=false, Flag="FB",
    Callback = function(v)
        F.FullBright = v
        if v then enableFB() else disableFB() end
    end,
})

-- ── TAB 4: CONFIG ─────────────────────────────────────────────
local T4 = Window:CreateTab("⚙️ Config", 4483362458)

T4:CreateSection("Controle Global")

T4:CreateButton({
    Name="🔌 Desligar Tudo",
    Callback = function()
        F.WalkFarm=false; F.TPFarm=false; F.GodMode=false
        F.ESP=false; F.InstantInteract=false; F.FullBright=false
        stopMonitor(); clearESP(); disableFB()
        local h=getHum(); if h then h.WalkSpeed=16 end
        Rayfield:Notify({Title="Desligado",Content="Todos os módulos desativados.",Duration=3})
    end,
})

T4:CreateButton({
    Name="🗑️ Limpar ESP",
    Callback = function()
        clearESP()
        Rayfield:Notify({Title="ESP Limpo",Content="Todos os highlights removidos.",Duration=2})
    end,
})

T4:CreateSection("Info Técnica")
T4:CreateParagraph({
    Title="Caminhos Confirmados (Open Source)",
    Content="Porta: room.Door.Door\nChave: KeyObtain.Hitbox | KeyObtain.ModulePrompt\nArmários: room.Assets → Dresser, Wardrobe\nAbrir: Door.ClientOpen:FireServer()\nUnlock: Door.Lock.UnlockPrompt"
})
T4:CreateParagraph({
    Title="⚠️ Segurança",
    Content="• TP Farm pode causar kick em servidores públicos\n• Use servidor privado para testes\n• Auto Closet é mais seguro que TP to Roof\n• Monster Warning funciona sem God Mode"
})

-- ═══════════════════════════════════════════════════════════════
--   INIT — Monster Warning ativo por padrão
-- ═══════════════════════════════════════════════════════════════
startMonitor()  -- sempre monitora para avisos na tela

Rayfield:LoadConfiguration()

Rayfield:Notify({
    Title   = "✅ DOORS Hub v3.0 Carregado",
    Content = "Monster Warning: ATIVO | ESP pronto | Estruturas verificadas via open-source",
    Duration = 5,
    Image   = 4483362458,
})
