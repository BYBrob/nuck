-- ============================================================
--  DOORS HUB - Powered by Rayfield Interface Suite
--  Versão: 2.0 | Compatível com The Hotel+ Update
--  Estrutura verificada:
--    workspace.CurrentRooms[tostring(roomNum)]
--    game.ReplicatedStorage.GameData.LatestRoom.Value
--    Entidades detectadas via workspace.DescendantAdded
-- ============================================================

-- ══════════════════════════════════════════
--  SECURE MODE ANTI-DETECÇÃO (ativar se o jogo crashar)
-- ══════════════════════════════════════════
getgenv().SecureMode = false  -- Mude para `true` se quiser reduzir detecção (leve perda de qualidade visual)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ══════════════════════════════════════════
--  SERVIÇOS
-- ══════════════════════════════════════════
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace       = game:GetService("Workspace")

-- ══════════════════════════════════════════
--  REFERENCIAS DO JOGADOR
-- ══════════════════════════════════════════
local LocalPlayer  = Players.LocalPlayer
local function getChar()   return LocalPlayer.Character end
local function getHRP()    local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()    local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end

-- ══════════════════════════════════════════
--  REFERENCIAS DO JOGO DOORS
-- ══════════════════════════════════════════
local GameData     = ReplicatedStorage:WaitForChild("GameData", 10)
local LatestRoom   = GameData and GameData:FindFirstChild("LatestRoom")

local function getCurrentRoom()
    if not LatestRoom then return nil end
    return Workspace.CurrentRooms:FindFirstChild(tostring(LatestRoom.Value))
end

-- ══════════════════════════════════════════
--  FLAGS / ESTADO GLOBAL
-- ══════════════════════════════════════════
local Flags = {
    WalkFarm        = false,
    TPFarm          = false,
    GodMode         = false,
    SafeMode        = "TP to Roof",   -- "TP to Roof" ou "Auto Closet"
    ESPEnabled      = false,
    InstantInteract = false,
    FullBright      = false,
}

local entityDetected = false          -- bloqueia ações durante rush/ambush
local espObjects     = {}             -- referências de highlights criados pelo ESP
local connections    = {}             -- RunService/DescendantAdded connections para cleanup

-- ══════════════════════════════════════════
--  JANELA PRINCIPAL RAYFIELD
-- ══════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name           = "DOORS Hub 🚪",
    LoadingTitle   = "DOORS Hub",
    LoadingSubtitle = "by DoorsHub • v2.0",
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "DoorsHub",
        FileName   = "config",
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

-- ══════════════════════════════════════════
--  ABA 1: AUTO FARM
-- ══════════════════════════════════════════
local TabFarm = Window:CreateTab("🚶 Auto Farm", 4483362458)

TabFarm:CreateSection("Movimentação")

-- ─── WALK FARM ───────────────────────────────────────────────
-- O personagem usa PathfindingService ou segue a posição da Door
-- atual enquanto não há entidade detectada.

local function walkToNextDoor()
    local hrp = getHRP()
    local hum = getHum()
    local room = getCurrentRoom()
    if not hrp or not hum or not room then return end

    local door = room:FindFirstChild("Door") or room:FindFirstChildWhichIsA("Model", true)
    if not door then
        -- Tenta achar qualquer objeto com "Door" no nome
        for _, v in ipairs(room:GetDescendants()) do
            if v.Name:lower():find("door") and v:IsA("BasePart") then
                door = v; break
            end
        end
    end
    if not door then return end

    local doorPart = door:IsA("BasePart") and door
        or door:FindFirstChildWhichIsA("BasePart")
        or door.PrimaryPart
    if not doorPart then return end

    -- PathfindingService
    local path = PathfindingService:CreatePath({
        AgentRadius    = 2,
        AgentHeight    = 5,
        AgentCanJump   = true,
        AgentMaxSlope  = 60,
    })

    local success, err = pcall(function()
        path:ComputeAsync(hrp.Position, doorPart.Position)
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        -- Fallback: movimento direto suavizado com Tween
        local goal = doorPart.Position + Vector3.new(0, 0, -3)
        local tween = TweenService:Create(hrp, TweenInfo.new(
            (hrp.Position - goal).Magnitude / hum.WalkSpeed,
            Enum.EasingStyle.Linear
        ), {CFrame = CFrame.new(goal)})
        tween:Play()
        tween.Completed:Wait()
        return
    end

    local waypoints = path:GetWaypoints()
    for _, wp in ipairs(waypoints) do
        if entityDetected or not Flags.WalkFarm then break end
        if wp.Action == Enum.PathWaypointAction.Jump then
            hum.Jump = true
        end
        hum:MoveTo(wp.Position)
        local reached = hum.MoveToFinished:Wait(2)
        if not reached then break end
    end
end

TabFarm:CreateToggle({
    Name  = "Walk Farm",
    CurrentValue = false,
    Flag  = "WalkFarm",
    Callback = function(val)
        Flags.WalkFarm = val
        if val then
            task.spawn(function()
                while Flags.WalkFarm do
                    if not entityDetected then
                        walkToNextDoor()
                    end
                    task.wait(0.5)
                end
            end)
        end
    end,
})

-- ─── TP FARM (RISK) ──────────────────────────────────────────
-- Teleporta diretamente para a porta do quarto atual.
-- ⚠️ RISK: movimento abrupto pode ser detectado por anticheats.

local function tpToNextDoor()
    local hrp  = getHRP()
    local room = getCurrentRoom()
    if not hrp or not room then return end

    local doorPart = nil
    for _, v in ipairs(room:GetDescendants()) do
        if v.Name == "Door" and v:IsA("BasePart") then
            doorPart = v; break
        end
    end

    -- Se não achou por nome exato, tenta heurística
    if not doorPart then
        for _, v in ipairs(room:GetDescendants()) do
            if v.Name:lower():find("door") and v:IsA("BasePart") then
                doorPart = v; break
            end
        end
    end

    if doorPart then
        -- Offset de segurança para não ficar preso na geometria
        hrp.CFrame = CFrame.new(doorPart.Position + Vector3.new(0, 3, -4))
        task.wait(0.1)
    end
end

TabFarm:CreateToggle({
    Name  = "TP Farm (RISK) ⚠️",
    CurrentValue = false,
    Flag  = "TPFarm",
    Callback = function(val)
        Flags.TPFarm = val
        if val then
            task.spawn(function()
                while Flags.TPFarm do
                    if not entityDetected then
                        tpToNextDoor()
                    end
                    task.wait(1.5)  -- delay maior para reduzir risco de detecção
                end
            end)
        end
    end,
})

-- ══════════════════════════════════════════
--  ABA 2: SMART GOD MODE
-- ══════════════════════════════════════════
local TabGod = Window:CreateTab("🛡️ God Mode", 4483362458)

TabGod:CreateSection("Evasão de Entidades")

-- ─── DETECÇÃO DE ENTIDADES ───────────────────────────────────
-- Monitora workspace.DescendantAdded em tempo real via task.spawn.
-- Entidades conhecidas: Rush, Ambush, Seek, Eyes, Halt, Glitch, Blitz

local ENTITY_NAMES = {
    "Rush", "Ambush", "Seek", "Eyes", "Halt", "Glitch", "Blitz", "Timothy",
    "Shadow", "Void", "Dupe", "Figure", "Screech", "Jack",
    -- Nomes alternativos/internos que às vezes aparecem no workspace:
    "RushModel", "AmbushModel", "EntityRush", "EntityAmbush",
}

local function isEntityName(name)
    for _, n in ipairs(ENTITY_NAMES) do
        if name:lower():find(n:lower()) then return true end
    end
    return false
end

-- ─── TP TO ROOF ──────────────────────────────────────────────
local ROOF_OFFSET = Vector3.new(0, 80, 0)  -- 80 studs acima

local function tpToRoof()
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = hrp.CFrame + ROOF_OFFSET
    end
end

local function tpBack()
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = hrp.CFrame - ROOF_OFFSET
    end
end

-- ─── AUTO CLOSET ─────────────────────────────────────────────
local CLOSET_NAMES = {
    "Wardrobe", "HidingSpot", "Closet", "Locker",
    "Dresser", "Drawer", "HideSpot", "HidingSpotModel",
    "Armoire", "Cabinet",
}

local function findNearestCloset()
    local hrp = getHRP()
    local room = getCurrentRoom()
    if not hrp or not room then return nil end

    local nearest, nearDist = nil, math.huge

    for _, v in ipairs(room:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Model") then
            for _, n in ipairs(CLOSET_NAMES) do
                if v.Name:lower():find(n:lower()) then
                    local part = v:IsA("BasePart") and v
                        or v:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local dist = (hrp.Position - part.Position).Magnitude
                        if dist < nearDist then
                            nearest  = part
                            nearDist = dist
                        end
                    end
                    break
                end
            end
        end
    end
    return nearest
end

local function autoCloset()
    local hrp   = getHRP()
    local spot  = findNearestCloset()
    if hrp and spot then
        hrp.CFrame = CFrame.new(spot.Position + Vector3.new(0, 3, 0))
    end
end

-- ─── LÓGICA CENTRAL DO GOD MODE ──────────────────────────────
-- task.spawn para não bloquear a thread principal.
-- Dupla camada: DescendantAdded (reação instantânea) + heartbeat polling.

local function onEntityAppeared(instance)
    if not Flags.GodMode then return end
    if not isEntityName(instance.Name) then return end

    entityDetected = true

    Rayfield:Notify({
        Title   = "⚠️ Entidade Detectada!",
        Content = instance.Name .. " apareceu! Evadindo...",
        Duration = 4,
        Image   = 4483362458,
    })

    if Flags.SafeMode == "TP to Roof" then
        tpToRoof()
        -- Espera entidade sumir (máx 15s)
        local timeout = 0
        repeat
            task.wait(0.5)
            timeout += 0.5
        until not instance or not instance.Parent or timeout >= 15

        tpBack()
        task.wait(0.5)
        entityDetected = false

    elseif Flags.SafeMode == "Auto Closet" then
        autoCloset()
        local timeout = 0
        repeat
            task.wait(0.5)
            timeout += 0.5
        until not instance or not instance.Parent or timeout >= 15

        entityDetected = false
    end
end

-- Conecta o listener de entidades (ligado/desligado pelo toggle)
local entityConnection = nil

local function startEntityMonitor()
    if entityConnection then return end
    entityConnection = Workspace.DescendantAdded:Connect(function(inst)
        if Flags.GodMode then
            task.spawn(onEntityAppeared, inst)
        end
    end)

    -- Polling de segurança: varre workspace a cada 0.3s
    -- Detecta entidades que já estavam antes do listener ser ativado
    task.spawn(function()
        while Flags.GodMode do
            for _, inst in ipairs(Workspace:GetDescendants()) do
                if isEntityName(inst.Name) and inst.Parent then
                    task.spawn(onEntityAppeared, inst)
                    break
                end
            end
            task.wait(0.3)
        end
    end)
end

local function stopEntityMonitor()
    if entityConnection then
        entityConnection:Disconnect()
        entityConnection = nil
    end
    entityDetected = false
end

-- ─── TOGGLE: SMART GOD MODE ──────────────────────────────────
TabGod:CreateToggle({
    Name  = "Smart God Mode",
    CurrentValue = false,
    Flag  = "GodMode",
    Callback = function(val)
        Flags.GodMode = val
        if val then
            startEntityMonitor()
        else
            stopEntityMonitor()
        end
    end,
})

-- ─── OPÇÃO DE SAFE MODE ──────────────────────────────────────
TabGod:CreateDropdown({
    Name    = "Safe Mode",
    Options = { "TP to Roof", "Auto Closet" },
    CurrentOption = { "TP to Roof" },
    Flag    = "SafeModeDropdown",
    Callback = function(opt)
        Flags.SafeMode = opt[1] or opt
    end,
})

TabGod:CreateSection("Info de Entidades")

TabGod:CreateParagraph({
    Title   = "Entidades Monitoradas",
    Content = "Rush · Ambush · Seek · Halt · Glitch · Eyes · Figure · Screech · Blitz · Dupe · Jack · Timothy · Shadow · Void"
})

-- ══════════════════════════════════════════
--  ABA 3: VISUAL & UTILITÁRIOS
-- ══════════════════════════════════════════
local TabUtil = Window:CreateTab("👁️ Visuais & Utils", 4483362458)

TabUtil:CreateSection("ESP")

-- ─── ESP DOORS & KEYS ────────────────────────────────────────
-- Cria Highlights nos objetos de interesse.

local function clearESP()
    for _, h in ipairs(espObjects) do
        if h and h.Parent then h:Destroy() end
    end
    espObjects = {}
end

local function addHighlight(instance, fillColor, outlineColor, label)
    local h = Instance.new("Highlight")
    h.FillColor    = fillColor
    h.OutlineColor = outlineColor
    h.FillTransparency = 0.4
    h.OutlineTransparency = 0
    h.Adornee = instance
    h.Parent  = instance

    -- Billboard label
    if label then
        local bb = Instance.new("BillboardGui")
        bb.Size        = UDim2.new(0, 100, 0, 40)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent      = instance

        local tl = Instance.new("TextLabel")
        tl.Size            = UDim2.fromScale(1, 1)
        tl.BackgroundTransparency = 1
        tl.TextColor3      = Color3.fromRGB(255, 255, 255)
        tl.TextStrokeTransparency = 0
        tl.Font            = Enum.Font.GothamBold
        tl.TextSize        = 14
        tl.Text            = label
        tl.Parent          = bb

        table.insert(espObjects, bb)
    end

    table.insert(espObjects, h)
    return h
end

local function updateESP()
    clearESP()
    if not Flags.ESPEnabled then return end

    local room = getCurrentRoom()
    if not room then return end

    for _, v in ipairs(room:GetDescendants()) do
        -- Portas
        if v.Name:lower():find("door") and v:IsA("BasePart") then
            addHighlight(v, Color3.fromRGB(0, 120, 255), Color3.fromRGB(0, 200, 255), "🚪 Porta")
        end

        -- Chaves
        if v.Name:lower():find("key") and (v:IsA("BasePart") or v:IsA("Model")) then
            addHighlight(
                v:IsA("BasePart") and v or (v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")) or v,
                Color3.fromRGB(255, 215, 0),
                Color3.fromRGB(255, 255, 100),
                "🗝️ Chave"
            )
        end

        -- Alavancas / Levers
        if v.Name:lower():find("lever") and v:IsA("BasePart") then
            addHighlight(v, Color3.fromRGB(255, 100, 0), Color3.fromRGB(255, 180, 0), "🔧 Lever")
        end

        -- Armários / Closets
        for _, n in ipairs(CLOSET_NAMES) do
            if v.Name:lower():find(n:lower()) and (v:IsA("BasePart") or v:IsA("Model")) then
                local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                if part then
                    addHighlight(part, Color3.fromRGB(100, 200, 100), Color3.fromRGB(0, 255, 100), "🚪 Armário")
                end
                break
            end
        end

        -- Itens (lighters, flashlights, medkits etc)
        local itemKeywords = {"lighter", "flashlight", "vitamins", "bandage", "lockpick", "medkit", "painkiller"}
        for _, kw in ipairs(itemKeywords) do
            if v.Name:lower():find(kw) and (v:IsA("BasePart") or v:IsA("Model")) then
                local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                if part then
                    addHighlight(part, Color3.fromRGB(200, 200, 255), Color3.fromRGB(180, 180, 255), "📦 " .. v.Name)
                end
                break
            end
        end
    end
end

TabUtil:CreateToggle({
    Name  = "ESP Portas, Chaves & Itens",
    CurrentValue = false,
    Flag  = "ESPEnabled",
    Callback = function(val)
        Flags.ESPEnabled = val
        if val then
            updateESP()
            -- Atualiza ESP a cada novo quarto
            local conn = LatestRoom and LatestRoom.Changed:Connect(function()
                task.wait(1)  -- aguarda quarto carregar
                if Flags.ESPEnabled then updateESP() end
            end)
            if conn then table.insert(connections, conn) end
        else
            clearESP()
        end
    end,
})

TabUtil:CreateButton({
    Name     = "🔄 Atualizar ESP Agora",
    Callback = function()
        if Flags.ESPEnabled then
            updateESP()
            Rayfield:Notify({Title = "ESP Atualizado", Content = "Highlights regenerados para o quarto atual.", Duration = 2})
        else
            Rayfield:Notify({Title = "ESP Inativo", Content = "Ative o ESP primeiro.", Duration = 2})
        end
    end,
})

TabUtil:CreateSection("Utilitários")

-- ─── INSTANT INTERACT ────────────────────────────────────────
-- Dispara ProximityPrompts de gavetas/baús próximos automaticamente.

local function triggerProximityPrompts()
    local hrp = getHRP()
    if not hrp then return end
    local room = getCurrentRoom()
    if not room then return end

    for _, prompt in ipairs(room:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and not prompt.Disabled then
            local dist = (hrp.Position - prompt.Parent.AbsolutePosition or Vector3.zero).Magnitude
            -- FireProximityPrompt é uma função de exploits que aciona prompts sem range limit
            if fireproximityprompt then
                fireproximityprompt(prompt)
            end
        end
    end
end

TabUtil:CreateToggle({
    Name  = "Instant Interact (gavetas/baús)",
    CurrentValue = false,
    Flag  = "InstantInteract",
    Callback = function(val)
        Flags.InstantInteract = val
        if val then
            task.spawn(function()
                while Flags.InstantInteract do
                    triggerProximityPrompts()
                    task.wait(0.8)
                end
            end)
        end
    end,
})

-- ─── FULLBRIGHT ───────────────────────────────────────────────
-- Remove a escuridão aumentando o Ambient e OutdoorAmbient do Lighting.

local originalLighting = {}

local function enableFullBright()
    local Lighting = game:GetService("Lighting")
    -- Salva valores originais
    originalLighting.Ambient        = Lighting.Ambient
    originalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
    originalLighting.Brightness     = Lighting.Brightness
    originalLighting.FogEnd         = Lighting.FogEnd
    originalLighting.ClockTime      = Lighting.ClockTime

    -- Remove todas as ColorCorrection e Blur effects para fullbright completo
    for _, fx in ipairs(Lighting:GetChildren()) do
        if fx:IsA("ColorCorrectionEffect") or fx:IsA("BlurEffect")
            or fx:IsA("SunRaysEffect") or fx:IsA("BlackAndWhiteEffect") then
            fx.Enabled = false
        end
    end

    Lighting.Ambient        = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.Brightness     = 2
    Lighting.FogEnd         = 100000
    Lighting.ClockTime      = 14  -- meio-dia forçado
end

local function disableFullBright()
    local Lighting = game:GetService("Lighting")
    if originalLighting.Ambient then
        Lighting.Ambient        = originalLighting.Ambient
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        Lighting.Brightness     = originalLighting.Brightness
        Lighting.FogEnd         = originalLighting.FogEnd
        Lighting.ClockTime      = originalLighting.ClockTime
    end
    for _, fx in ipairs(Lighting:GetChildren()) do
        if fx:IsA("ColorCorrectionEffect") or fx:IsA("BlurEffect")
            or fx:IsA("SunRaysEffect") or fx:IsA("BlackAndWhiteEffect") then
            fx.Enabled = true
        end
    end
end

TabUtil:CreateToggle({
    Name  = "FullBright 🌟",
    CurrentValue = false,
    Flag  = "FullBright",
    Callback = function(val)
        Flags.FullBright = val
        if val then enableFullBright() else disableFullBright() end
    end,
})

-- ─── WALK SPEED ──────────────────────────────────────────────
TabUtil:CreateSlider({
    Name    = "Walk Speed",
    Range   = {16, 120},
    Increment = 2,
    CurrentValue = 16,
    Flag    = "WalkSpeed",
    Suffix  = " studs/s",
    Callback = function(val)
        local hum = getHum()
        if hum then hum.WalkSpeed = val end
    end,
})

-- ═══════════════════════════════════════════
--  ABA 4: CONFIGURAÇÕES AVANÇADAS
-- ═══════════════════════════════════════════
local TabCfg = Window:CreateTab("⚙️ Config", 4483362458)

TabCfg:CreateSection("Anti-Detecção")

TabCfg:CreateParagraph({
    Title   = "Dicas de Segurança",
    Content = "• Use TP Farm (RISK) apenas em servidores privados.\n• TP to Roof é mais seguro que Auto Closet em runs rápidos.\n• Desative o Walk Farm antes de entrar no quarto 50 (Figure).\n• SecureMode no topo do script reduz traces da UI."
})

TabCfg:CreateSection("Informações")

TabCfg:CreateParagraph({
    Title   = "Caminhos do Jogo",
    Content = "Quarto atual: workspace.CurrentRooms[LatestRoom.Value]\nEntidades detectadas via: workspace.DescendantAdded\nPortas: room:FindFirstChild('Door')\nChaves: descendentes com 'Key' no nome"
})

TabCfg:CreateButton({
    Name     = "🗑️ Limpar ESP & Highlights",
    Callback = function()
        clearESP()
        Rayfield:Notify({Title = "Limpeza Concluída", Content = "Todos os highlights foram removidos.", Duration = 2})
    end,
})

TabCfg:CreateButton({
    Name     = "🔌 Desligar Tudo",
    Callback = function()
        Flags.WalkFarm        = false
        Flags.TPFarm          = false
        Flags.GodMode         = false
        Flags.ESPEnabled      = false
        Flags.InstantInteract = false
        Flags.FullBright      = false

        stopEntityMonitor()
        clearESP()
        disableFullBright()

        local hum = getHum()
        if hum then hum.WalkSpeed = 16 end

        -- Cleanup de connections
        for _, c in ipairs(connections) do
            if c then pcall(function() c:Disconnect() end) end
        end
        connections = {}

        Rayfield:Notify({
            Title   = "Tudo Desligado",
            Content = "Todos os módulos foram desativados com segurança.",
            Duration = 3,
        })
    end,
})

-- ══════════════════════════════════════════
--  INICIALIZAÇÃO
-- ══════════════════════════════════════════
Rayfield:LoadConfiguration()

Rayfield:Notify({
    Title   = "DOORS Hub Carregado ✅",
    Content = "Bem-vindo! Versão 2.0 — Use com responsabilidade.",
    Duration = 5,
    Image   = 4483362458,
})
