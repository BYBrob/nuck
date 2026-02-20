local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Nuck Hub",
    LoadingTitle = "Nuck Hub",
    LoadingSubtitle = "Nuck Hub | Versão VIP",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "NuckHub"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

-- ══════════════════════════════════════════
--              SERVIÇOS & VARIÁVEIS
-- ══════════════════════════════════════════

local Players         = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer     = Players.LocalPlayer

-- ══════════════════════════════════════════
--                   ABAS
-- ══════════════════════════════════════════

local tabMain   = Window:CreateTab("Main",       6026568198)
local tabFarm   = Window:CreateTab("Auto Farm",  7044284832)
local tabTP     = Window:CreateTab("Teleport",   6035190846)
local tabCrystal= Window:CreateTab("Crystal",    6031265976)
local tabMisc   = Window:CreateTab("Misc",       6034509993)

-- ══════════════════════════════════════════
--              ABA: MAIN — Labels
-- ══════════════════════════════════════════

local TimeLabel = tabMain:CreateLabel("[GameTime] : Carregando...")
local FpsLabel  = tabMain:CreateLabel("[Fps] : Carregando...")
local PingLabel = tabMain:CreateLabel("[Ping] : Carregando...")

-- Labels atualizados com task.spawn (sem lag)
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local gt  = math.floor(workspace.DistributedGameTime + 0.5)
            local h   = math.floor(gt / 3600) % 24
            local m   = math.floor(gt / 60)   % 60
            local s   = gt % 60
            TimeLabel:Set(string.format("[GameTime] : %02dh %02dm %02ds", h, m, s))
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            FpsLabel:Set("[Fps] : " .. math.floor(workspace:GetRealPhysicsFPS()))
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
            PingLabel:Set("[Ping] : " .. ping)
        end)
    end
end)

-- ══════════════════════════════════════════
--              ABA: MAIN — Funções
-- ══════════════════════════════════════════

tabMain:CreateSection("Configurações")

tabMain:CreateButton({
    Name = "Desativar Trading",
    Callback = function()
        ReplicatedStorage.rEvents.tradingEvent:FireServer("disableTrading")
    end
})

tabMain:CreateButton({
    Name = "Ativar Trading",
    Callback = function()
        ReplicatedStorage.rEvents.tradingEvent:FireServer("enableTrading")
    end
})

tabMain:CreateSection("Teleporte para Player")

local function GetPlayerListWithDisplay()
    local list, mapping = {}, {}
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then
            local label = v.DisplayName .. " (@" .. v.Name .. ")"
            table.insert(list, label)
            mapping[label] = v.Name
        end
    end
    return list, mapping
end

local PlayerList, PlayerMapping = GetPlayerListWithDisplay()
local TpPlayer = nil

local PlayerDropdown = tabMain:CreateDropdown({
    Name = "Selecionar Player",
    Options = PlayerList,
    CurrentOption = {},
    MultipleOptions = false,
    Callback = function(Option)
        TpPlayer = PlayerMapping[Option]
    end
})

local function RefreshDropdown()
    task.wait(0.5)
    PlayerList, PlayerMapping = GetPlayerListWithDisplay()
    pcall(function() PlayerDropdown:Refresh(PlayerList) end)
end

Players.PlayerAdded:Connect(RefreshDropdown)
Players.PlayerRemoving:Connect(function(plr)
    if TpPlayer == plr.Name then TpPlayer = nil end
    RefreshDropdown()
end)

tabMain:CreateButton({
    Name = "Atualizar Lista de Players",
    Callback = function()
        RefreshDropdown()
        Rayfield:Notify({ Title = "Sucesso", Content = "Lista atualizada!", Duration = 2 })
    end
})

tabMain:CreateButton({
    Name = "Teleportar para Player",
    Callback = function()
        if not TpPlayer then
            Rayfield:Notify({ Title = "Erro", Content = "Selecione um player primeiro!", Duration = 3 })
            return
        end
        local target = Players:FindFirstChild(TpPlayer)
        if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
            Rayfield:Notify({ Title = "Erro", Content = "Player não encontrado ou sem personagem.", Duration = 3 })
            return
        end
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            Rayfield:Notify({ Title = "Erro", Content = "Seu personagem não foi encontrado.", Duration = 3 })
            return
        end
        local ok, err = pcall(function()
            char.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 5, 1)
        end)
        if ok then
            Rayfield:Notify({ Title = "Sucesso", Content = "Teleportado para " .. target.DisplayName, Duration = 2 })
        else
            Rayfield:Notify({ Title = "Erro", Content = tostring(err), Duration = 3 })
        end
    end
})

tabMain:CreateSection("Personagem")

tabMain:CreateSlider({
    Name = "Velocidade",
    Range = {0, 1000},
    Increment = 1,
    Suffix = "",
    CurrentValue = 16,
    Callback = function(v)
        pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = v end)
    end
})

tabMain:CreateSlider({
    Name = "Pulo",
    Range = {0, 1000},
    Increment = 1,
    Suffix = "",
    CurrentValue = 50,
    Callback = function(v)
        pcall(function() LocalPlayer.Character.Humanoid.JumpPower = v end)
    end
})

tabMain:CreateToggle({
    Name = "Invisibilidade",
    CurrentValue = false,
    Callback = function(state)
        _G.invis = state
        if state then
            task.spawn(function()
                while _G.invis do
                    task.wait(0.1)
                    pcall(function()
                        LocalPlayer.ninjaEvent:FireServer("goInvisible")
                    end)
                end
            end)
        end
    end
})

tabMain:CreateToggle({
    Name = "Desativar PopUp Coin & Chi",
    CurrentValue = false,
    Callback = function(state)
        pcall(function()
            LocalPlayer.PlayerGui.statEffectsGui.Enabled = not state
            LocalPlayer.PlayerGui.hoopGui.Enabled        = not state
        end)
    end
})

-- ══════════════════════════════════════════
--              ABA: AUTO FARM
-- ══════════════════════════════════════════

tabFarm:CreateSection("Farming")

tabFarm:CreateToggle({
    Name = "Auto Swing",
    CurrentValue = false,
    Callback = function(state)
        _G.swing = state
        if state then
            task.spawn(function()
                while _G.swing do
                    task.wait()
                    pcall(function()
                        LocalPlayer.ninjaEvent:FireServer("swingKatana")
                    end)
                end
            end)
        end
    end
})

-- ════ AUTO SELL MELHORADO (Remote direto, sem teleportar peça) ════
tabFarm:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = false,
    Callback = function(state)
        _G.sell = state
        if state then
            task.spawn(function()
                while _G.sell do
                    task.wait(0.5)
                    pcall(function()
                        ReplicatedStorage.rEvents.sellEvent:FireServer("sellNinjas")
                    end)
                end
            end)
        end
    end
})

tabFarm:CreateToggle({
    Name = "Auto Sell Quando Cheio",
    CurrentValue = false,
    Callback = function(state)
        _G.sellFull = state
        if state then
            task.spawn(function()
                while _G.sellFull do
                    task.wait(0.5)
                    pcall(function()
                        if LocalPlayer.PlayerGui.gameGui.maxNinjitsuMenu.Visible == true then
                            ReplicatedStorage.rEvents.sellEvent:FireServer("sellNinjas")
                        end
                    end)
                end
            end)
        end
    end
})

tabFarm:CreateSection("Compras Automáticas")

tabFarm:CreateToggle({
    Name = "Auto Comprar Espadas",
    CurrentValue = false,
    Callback = function(state)
        _G.sw = state
        if state then
            task.spawn(function()
                while _G.sw do
                    task.wait(0.5)
                    pcall(function()
                        LocalPlayer.ninjaEvent:FireServer("buyAllSwords", "Blazing Vortex Island")
                    end)
                end
            end)
        end
    end
})

tabFarm:CreateToggle({
    Name = "Auto Comprar Belts",
    CurrentValue = false,
    Callback = function(state)
        _G.belt = state
        if state then
            task.spawn(function()
                while _G.belt do
                    task.wait(0.5)
                    pcall(function()
                        LocalPlayer.ninjaEvent:FireServer("buyAllBelts", "Blazing Vortex Island")
                    end)
                end
            end)
        end
    end
})

tabFarm:CreateToggle({
    Name = "Auto Comprar Skills",
    CurrentValue = false,
    Callback = function(state)
        _G.sk = state
        if state then
            task.spawn(function()
                while _G.sk do
                    task.wait(0.5)
                    pcall(function()
                        LocalPlayer.ninjaEvent:FireServer("buyAllSkills", "Blazing Vortex Island")
                    end)
                end
            end)
        end
    end
})

tabFarm:CreateToggle({
    Name = "Auto Comprar Ranks",
    CurrentValue = false,
    Callback = function(state)
        _G.r = state
        if state then
            task.spawn(function()
                while _G.r do
                    task.wait(0.5)
                    pcall(function()
                        local ranks = ReplicatedStorage.Ranks.Ground:GetChildren()
                        for _, v in ipairs(ranks) do
                            LocalPlayer.ninjaEvent:FireServer("buyRank", v.Name)
                        end
                    end)
                end
            end)
        end
    end
})

tabFarm:CreateToggle({
    Name = "Auto Comprar Shurikens",
    CurrentValue = false,
    Callback = function(state)
        _G.sh = state
        if state then
            task.spawn(function()
                while _G.sh do
                    task.wait(0.5)
                    pcall(function()
                        LocalPlayer.ninjaEvent:FireServer("buyAllShurikens", "Blazing Vortex Island")
                    end)
                end
            end)
        end
    end
})

tabFarm:CreateSection("Coletar Recursos")

tabFarm:CreateToggle({
    Name = "Auto Farm Chi",
    CurrentValue = false,
    Callback = function(state)
        _G.c = state
        if state then
            task.spawn(function()
                while _G.c do
                    task.wait()
                    pcall(function()
                        for _, v in pairs(workspace.spawnedCoins.Valley:GetChildren()) do
                            if v.Name == "Blue Chi Crate" and _G.c then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(v.Position)
                                task.wait(0.3)
                            end
                        end
                    end)
                end
            end)
        end
    end
})

tabFarm:CreateToggle({
    Name = "Auto Farm Coins",
    CurrentValue = false,
    Callback = function(state)
        _G.co = state
        if state then
            task.spawn(function()
                while _G.co do
                    task.wait()
                    pcall(function()
                        for _, v in pairs(workspace.spawnedCoins.Valley:GetChildren()) do
                            if v.Name == "Purple Coin Crate" and _G.co then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(v.Position)
                                task.wait(0.3)
                            end
                        end
                    end)
                end
            end)
        end
    end
})

tabFarm:CreateToggle({
    Name = "Auto Hoops",
    CurrentValue = false,
    Callback = function(state)
        _G.hoops = state
        if state then
            task.spawn(function()
                while _G.hoops do
                    task.wait()
                    pcall(function()
                        for _, v in pairs(workspace.Hoops:GetDescendants()) do
                            if v.ClassName == "MeshPart" then
                                v.touchPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                            end
                        end
                    end)
                end
            end)
        end
    end
})

-- ════ AUTO CHEST — Coleta todos os baús de todas as ilhas ════
tabFarm:CreateSection("Baús")

tabFarm:CreateButton({
    Name = "Coletar Todos os Baús (Uma vez)",
    Callback = function()
        task.spawn(function()
            local count = 0
            pcall(function()
                for _, island in pairs(workspace:GetChildren()) do
                    for _, obj in pairs(island:GetDescendants()) do
                        if obj.Name:lower():find("chest") or obj.Name:lower():find("bau") or obj.Name:lower():find("treasure") then
                            pcall(function()
                                LocalPlayer.Character.HumanoidRootPart.CFrame = obj.CFrame
                                task.wait(0.15)
                                count = count + 1
                            end)
                        end
                    end
                end
            end)
            Rayfield:Notify({ Title = "Auto Chest", Content = "Coletou " .. count .. " baú(s)!", Duration = 3 })
        end)
    end
})

tabFarm:CreateToggle({
    Name = "Auto Chest (Loop)",
    CurrentValue = false,
    Callback = function(state)
        _G.autoChest = state
        if state then
            task.spawn(function()
                while _G.autoChest do
                    pcall(function()
                        for _, island in pairs(workspace:GetChildren()) do
                            for _, obj in pairs(island:GetDescendants()) do
                                if obj.Name:lower():find("chest") or obj.Name:lower():find("treasure") then
                                    if not _G.autoChest then return end
                                    pcall(function()
                                        LocalPlayer.Character.HumanoidRootPart.CFrame = obj.CFrame
                                        task.wait(0.15)
                                    end)
                                end
                            end
                        end
                    end)
                    task.wait(1)
                end
            end)
        end
    end
})

-- ══════════════════════════════════════════
--              ABA: TELEPORTE
-- ══════════════════════════════════════════

local ISLAND = {}
for _, v in pairs(workspace.islandUnlockParts:GetChildren()) do
    table.insert(ISLAND, v.Name)
end

tabTP:CreateSection("Ilhas")

tabTP:CreateDropdown({
    Name = "Teleportar para Ilha",
    Options = ISLAND,
    CurrentOption = {},
    MultipleOptions = false,
    Callback = function(a)
        pcall(function()
            LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.islandUnlockParts[a].islandSignPart.CFrame
        end)
    end
})

tabTP:CreateButton({
    Name = "Desbloquear Todas as Ilhas",
    Callback = function()
        task.spawn(function()
            for _, v in ipairs(workspace.islandUnlockParts:GetChildren()) do
                pcall(function()
                    LocalPlayer.Character.HumanoidRootPart.CFrame = v.islandSignPart.CFrame
                end)
                task.wait(0.2)
            end
            Rayfield:Notify({ Title = "Sucesso", Content = "Todas as ilhas desbloqueadas!", Duration = 3 })
        end)
    end
})

-- ══════════════════════════════════════════
--              ABA: CRYSTAL
-- ══════════════════════════════════════════

egg:CreateSection("Cristais")  -- mantendo compatibilidade (tabCrystal = egg no original)

local Crystal = {}
for _, v in pairs(workspace.mapCrystalsFolder:GetChildren()) do
    table.insert(Crystal, v.Name)
end

tabCrystal:CreateDropdown({
    Name = "Selecionar Cristal",
    Options = Crystal,
    CurrentOption = {},
    MultipleOptions = false,
    Callback = function(value)
        _G.cryEgg = value
    end
})

tabCrystal:CreateToggle({
    Name = "Abrir Cristal",
    CurrentValue = false,
    Callback = function(state)
        _G.cCry = state
        if state then
            task.spawn(function()
                while _G.cCry do
                    task.wait(0.1)
                    pcall(function()
                        ReplicatedStorage.rEvents.openCrystalRemote:InvokeServer("openCrystal", _G.cryEgg)
                    end)
                end
            end)
        end
    end
})

-- ════ AUTO EVOLVE PETS MELHORADO (mais rápido, sem delay desnecessário) ════
tabCrystal:CreateToggle({
    Name = "Auto Evoluir Pets",
    CurrentValue = false,
    Callback = function(state)
        _G.ePet = state
        if state then
            task.spawn(function()
                while _G.ePet do
                    task.wait(0.05) -- delay menor para maior velocidade
                    pcall(function()
                        for _, folder in pairs(LocalPlayer.petsFolder:GetChildren()) do
                            for _, pet in pairs(folder:GetChildren()) do
                                if not _G.ePet then return end
                                ReplicatedStorage.rEvents.petEvolveEvent:FireServer("evolvePet", pet.Name)
                            end
                        end
                    end)
                end
            end)
        end
    end
})

-- ══════════════════════════════════════════
--              ABA: MISC
-- ══════════════════════════════════════════

tabMisc:CreateSection("Movimentação")

tabMisc:CreateToggle({
    Name = "Pulo Infinito (Double Jump)",
    CurrentValue = false,
    Callback = function(state)
        _G.iJump = state
        if state then
            pcall(function()
                LocalPlayer.multiJumpCount.Value = "99999999999999999"
            end)
        end
    end
})

local InfiniteJumpEnabled = false
tabMisc:CreateToggle({
    Name = "Pulo Infinito (Geral)",
    CurrentValue = false,
    Callback = function(state)
        InfiniteJumpEnabled = state
    end
})

UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled then
        pcall(function()
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
        end)
    end
end)

tabMisc:CreateSection("Elementos")

tabMisc:CreateButton({
    Name = "Pegar Todos os Elementos",
    Callback = function()
        local elementos = {
            "Frost", "Inferno", "Lightning", "Electral Chaos",
            "Masterful Wrath", "Shadow Charge", "Shadowfire",
            "Eternity Storm", "Blazing Entity"
        }
        task.spawn(function()
            for _, el in ipairs(elementos) do
                pcall(function()
                    ReplicatedStorage.rEvents.elementMasteryEvent:FireServer(el)
                end)
                task.wait(0.1)
            end
            Rayfield:Notify({ Title = "Sucesso", Content = "Todos os elementos obtidos!", Duration = 3 })
        end)
    end
})

tabMisc:CreateSection("Utilidades")

-- ════ ANTI-AFK — Previne desconexão por inatividade ════
local antiAfkConnection
tabMisc:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = true, -- Ligado por padrão
    Callback = function(state)
        if state then
            antiAfkConnection = RunService.Heartbeat:Connect(function()
                pcall(function()
                    -- Simula input para enganar o detector de AFK do Roblox
                    local VirtualUser = game:GetService("VirtualUser")
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            end)
        else
            if antiAfkConnection then
                antiAfkConnection:Disconnect()
                antiAfkConnection = nil
            end
        end
    end
})

-- Ativa Anti-AFK automaticamente ao carregar
task.spawn(function()
    task.wait(1)
    pcall(function()
        -- Método alternativo de Anti-AFK (dispara evento de movimento virtual)
        LocalPlayer.Idled:Connect(function()
            pcall(function()
                local VirtualUser = game:GetService("VirtualUser")
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end)
end)

tabMisc:CreateButton({
    Name = "Rejoinar",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

-- ══════════════════════════════════════════
--          CARREGAMENTO DE CONFIGURAÇÕES
-- ══════════════════════════════════════════

Rayfield:LoadConfiguration()

Rayfield:Notify({
    Title = "Nuck Hub",
    Content = "Script carregado com sucesso! Versão VIP ✓",
    Duration = 5,
    Image = 6026568198,
})
