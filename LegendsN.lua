-- ╔══════════════════════════════════════════════════════╗
-- ║              NUCK HUB - NINJA LEGENDS               ║
-- ║              Versão VIP | by Nuck                   ║
-- ╚══════════════════════════════════════════════════════╝

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
    Discord = { Enabled = false, Invite = "", RememberJoins = true },
    KeySystem = false
})

-- ═══════════════════════════════════════════════════════
--              SERVIÇOS & VARIÁVEIS GLOBAIS
-- ═══════════════════════════════════════════════════════

local Players           = game:GetService("Players")
local RS                = game:GetService("ReplicatedStorage")
local UIS               = game:GetService("UserInputService")
local TeleportService   = game:GetService("TeleportService")
local VirtualUser       = game:GetService("VirtualUser")
local LocalPlayer       = Players.LocalPlayer

-- Atalho para eventos mais usados
local rEvents           = RS:WaitForChild("rEvents")
local ninjaEvent        = LocalPlayer:WaitForChild("ninjaEvent")

-- Todas as ilhas para Auto-Buy (cobre TUDO, não só uma)
local ALL_ISLANDS = {
    "Ground", "Astral Island", "Space Island", "Tundra Island",
    "Eternal Island", "Sandstorm", "Thunderstorm", "Ancient Inferno Island",
    "Midnight Shadow Island", "Mythical Souls Island", "Winter Wonderland Island",
    "Dragon Legend Island", "Cybernetic Legends Island", "Skystorm Ultraus Island",
    "Chaos Legends Island", "Blazing Vortex Island"
}

-- ═══════════════════════════════════════════════════════
--                       ABAS
-- ═══════════════════════════════════════════════════════

local tabMain    = Window:CreateTab("Main",        6026568198)
local tabFarm    = Window:CreateTab("Auto Farm",   7044284832)
local tabBoss    = Window:CreateTab("Boss Farm",   6031265976)
local tabPets    = Window:CreateTab("Pets",        6034509993)
local tabTP      = Window:CreateTab("Teleport",    6035190846)
local tabMisc    = Window:CreateTab("Misc",        6026568198)

-- ═══════════════════════════════════════════════════════
--                  ABA: MAIN — Labels
-- ═══════════════════════════════════════════════════════

local TimeLabel = tabMain:CreateLabel("[GameTime] : Carregando...")
local FpsLabel  = tabMain:CreateLabel("[Fps] : Carregando...")
local PingLabel = tabMain:CreateLabel("[Ping] : Carregando...")

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local gt = math.floor(workspace.DistributedGameTime + 0.5)
            TimeLabel:Set(string.format("[GameTime] : %02dh %02dm %02ds",
                math.floor(gt/3600)%24, math.floor(gt/60)%60, gt%60))
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
            PingLabel:Set("[Ping] : " .. game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString())
        end)
    end
end)

-- ═══════════════════════════════════════════════════════
--                ABA: MAIN — Controles
-- ═══════════════════════════════════════════════════════

tabMain:CreateSection("Trading")

tabMain:CreateButton({
    Name = "Desativar Trading",
    Callback = function()
        rEvents.tradingEvent:FireServer("disableTrading")
        Rayfield:Notify({ Title = "Trading", Content = "Trading desativado!", Duration = 2 })
    end
})

tabMain:CreateButton({
    Name = "Ativar Trading",
    Callback = function()
        rEvents.tradingEvent:FireServer("enableTrading")
        Rayfield:Notify({ Title = "Trading", Content = "Trading ativado!", Duration = 2 })
    end
})

tabMain:CreateSection("Personagem")

tabMain:CreateSlider({
    Name = "Velocidade",
    Range = {0, 1000}, Increment = 1, Suffix = "", CurrentValue = 16,
    Callback = function(v)
        pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = v end)
    end
})

tabMain:CreateSlider({
    Name = "Pulo",
    Range = {0, 1000}, Increment = 1, Suffix = "", CurrentValue = 50,
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
                    task.wait(0.05)
                    pcall(function() ninjaEvent:FireServer("goInvisible") end)
                end
            end)
        end
    end
})

tabMain:CreateToggle({
    Name = "Desativar PopUps (Coin & Chi)",
    CurrentValue = false,
    Callback = function(state)
        pcall(function()
            LocalPlayer.PlayerGui.statEffectsGui.Enabled = not state
            LocalPlayer.PlayerGui.hoopGui.Enabled = not state
        end)
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
    Options = PlayerList, CurrentOption = {}, MultipleOptions = false,
    Callback = function(Option) TpPlayer = PlayerMapping[Option] end
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
    Name = "Atualizar Lista",
    Callback = function()
        RefreshDropdown()
        Rayfield:Notify({ Title = "OK", Content = "Lista atualizada!", Duration = 2 })
    end
})

tabMain:CreateButton({
    Name = "Teleportar para Player",
    Callback = function()
        if not TpPlayer then
            Rayfield:Notify({ Title = "Erro", Content = "Selecione um player!", Duration = 3 }) return
        end
        local target = Players:FindFirstChild(TpPlayer)
        if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
            Rayfield:Notify({ Title = "Erro", Content = "Player não encontrado.", Duration = 3 }) return
        end
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            Rayfield:Notify({ Title = "Erro", Content = "Seu personagem não foi encontrado.", Duration = 3 }) return
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

-- ═══════════════════════════════════════════════════════
--                  ABA: AUTO FARM
-- ═══════════════════════════════════════════════════════

tabFarm:CreateSection("Farming Principal")

-- AUTO SWING com equip automático de katana
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
                        local char = LocalPlayer.Character
                        if char then
                            if char:FindFirstChildOfClass("Tool") then
                                ninjaEvent:FireServer("swingKatana")
                            else
                                for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
                                    if v.ClassName == "Tool" and v:FindFirstChild("attackKatanaScript") then
                                        char.Humanoid:EquipTool(v)
                                        break
                                    end
                                end
                            end
                        end
                    end)
                end
            end)
        end
    end
})

-- AUTO SELL — método correto confirmado em múltiplos scripts do jogo
-- Move o círculo de venda até o player (sellAreaCircle7 = sell area padrão)
tabFarm:CreateToggle({
    Name = "Auto Sell (Sempre)",
    CurrentValue = false,
    Callback = function(state)
        _G.sell = state
        if state then
            task.spawn(function()
                while _G.sell do
                    task.wait(0.05)
                    pcall(function()
                        local hrp = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
                        workspace.sellAreaCircles["sellAreaCircle7"].circleInner.CFrame = hrp.CFrame
                        task.wait(0.05)
                        workspace.sellAreaCircles["sellAreaCircle7"].circleInner.CFrame = workspace.Part.CFrame
                    end)
                end
            end)
        end
    end
})

tabFarm:CreateToggle({
    Name = "Auto Sell (Somente Quando Cheio)",
    CurrentValue = false,
    Callback = function(state)
        _G.sellFull = state
        if state then
            task.spawn(function()
                while _G.sellFull do
                    task.wait(0.05)
                    pcall(function()
                        if LocalPlayer.PlayerGui.gameGui.maxNinjitsuMenu.Visible == true then
                            local hrp = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
                            workspace.sellAreaCircles["sellAreaCircle7"].circleInner.CFrame = hrp.CFrame
                            task.wait(0.05)
                            workspace.sellAreaCircles["sellAreaCircle7"].circleInner.CFrame = workspace.Part.CFrame
                        end
                    end)
                end
            end)
        end
    end
})

tabFarm:CreateSection("Coletar Recursos")

tabFarm:CreateToggle({
    Name = "Auto Farm Chi (Valley)",
    CurrentValue = false,
    Callback = function(state)
        _G.farmChi = state
        if state then
            task.spawn(function()
                while _G.farmChi do
                    task.wait()
                    pcall(function()
                        for _, v in pairs(workspace.spawnedCoins.Valley:GetChildren()) do
                            if not _G.farmChi then break end
                            if v.Name == "Blue Chi Crate" then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(v.Position)
                                task.wait(0.16)
                            end
                        end
                    end)
                end
            end)
        end
    end
})

tabFarm:CreateToggle({
    Name = "Auto Farm Coins (Valley)",
    CurrentValue = false,
    Callback = function(state)
        _G.farmCoins = state
        if state then
            task.spawn(function()
                while _G.farmCoins do
                    task.wait()
                    pcall(function()
                        for _, v in pairs(workspace.spawnedCoins.Valley:GetChildren()) do
                            if not _G.farmCoins then break end
                            if v.Name == "Purple Coin Crate" then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(v.Position)
                                task.wait(0.16)
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
                    task.wait(0.00011)
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

tabFarm:CreateSection("Compras Automáticas (Todas as Ilhas)")

local function AutoBuyLoop(flagGetter, remote)
    task.spawn(function()
        while flagGetter() do
            task.wait(0.5)
            pcall(function()
                for _, island in ipairs(ALL_ISLANDS) do
                    ninjaEvent:FireServer(remote, island)
                end
            end)
        end
    end)
end

tabFarm:CreateToggle({
    Name = "Auto Comprar Espadas",
    CurrentValue = false,
    Callback = function(state)
        _G.buyS = state
        if state then AutoBuyLoop(function() return _G.buyS end, "buyAllSwords") end
    end
})

tabFarm:CreateToggle({
    Name = "Auto Comprar Belts",
    CurrentValue = false,
    Callback = function(state)
        _G.buyB = state
        if state then AutoBuyLoop(function() return _G.buyB end, "buyAllBelts") end
    end
})

tabFarm:CreateToggle({
    Name = "Auto Comprar Skills",
    CurrentValue = false,
    Callback = function(state)
        _G.buySk = state
        if state then AutoBuyLoop(function() return _G.buySk end, "buyAllSkills") end
    end
})

tabFarm:CreateToggle({
    Name = "Auto Comprar Shurikens",
    CurrentValue = false,
    Callback = function(state)
        _G.buySh = state
        if state then AutoBuyLoop(function() return _G.buySh end, "buyAllShurikens") end
    end
})

tabFarm:CreateToggle({
    Name = "Auto Comprar Ranks",
    CurrentValue = false,
    Callback = function(state)
        _G.buyR = state
        if state then
            task.spawn(function()
                while _G.buyR do
                    task.wait(0.5)
                    pcall(function()
                        local ranks = RS.Ranks.Ground:GetChildren()
                        for _, v in ipairs(ranks) do
                            ninjaEvent:FireServer("buyRank", v.Name)
                        end
                    end)
                end
            end)
        end
    end
})

-- ═══════════════════════════════════════════════════════
--                  ABA: BOSS FARM
-- ═══════════════════════════════════════════════════════

tabBoss:CreateSection("Auto Boss")

local function BossLoop(flagGetter, bossName)
    task.spawn(function()
        while flagGetter() do
            task.wait(0.001)
            pcall(function()
                local boss = workspace.bossFolder:FindFirstChild(bossName)
                if boss and boss:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = boss.HumanoidRootPart.CFrame
                    local char = LocalPlayer.Character
                    if char:FindFirstChildOfClass("Tool") then
                        char:FindFirstChildOfClass("Tool"):Activate()
                    else
                        for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
                            if v.ClassName == "Tool" and v:FindFirstChild("attackKatanaScript") then
                                v.attackTime.Value = 0.2
                                char.Humanoid:EquipTool(v)
                                break
                            end
                        end
                    end
                end
            end)
        end
    end)
end

tabBoss:CreateToggle({
    Name = "Auto Robot Boss",
    CurrentValue = false,
    Callback = function(state)
        _G.boss1 = state
        if state then BossLoop(function() return _G.boss1 end, "RobotBoss") end
    end
})

tabBoss:CreateToggle({
    Name = "Auto Eternal Boss",
    CurrentValue = false,
    Callback = function(state)
        _G.boss2 = state
        if state then BossLoop(function() return _G.boss2 end, "EternalBoss") end
    end
})

tabBoss:CreateToggle({
    Name = "Auto Ancient Magma Boss",
    CurrentValue = false,
    Callback = function(state)
        _G.boss3 = state
        if state then BossLoop(function() return _G.boss3 end, "AncientMagmaBoss") end
    end
})

tabBoss:CreateSection("Cristais")

local Crystal = {}
for _, v in pairs(workspace.mapCrystalsFolder:GetChildren()) do
    table.insert(Crystal, v.Name)
end

tabBoss:CreateDropdown({
    Name = "Selecionar Cristal",
    Options = Crystal, CurrentOption = {}, MultipleOptions = false,
    Callback = function(value) _G.cryEgg = value end
})

tabBoss:CreateToggle({
    Name = "Abrir Cristal (Loop)",
    CurrentValue = false,
    Callback = function(state)
        _G.cCry = state
        if state then
            task.spawn(function()
                while _G.cCry do
                    task.wait(0.05)
                    pcall(function()
                        rEvents.openCrystalRemote:InvokeServer("openCrystal", _G.cryEgg)
                    end)
                end
            end)
        end
    end
})

-- ═══════════════════════════════════════════════════════
--                     ABA: PETS
-- ═══════════════════════════════════════════════════════

tabPets:CreateSection("Comprar Pets")

-- ════ AUTO BUY PET ════
-- Cristais com preços em Coins (baseado no jogo real)
local PET_SHOP = {
    { name = "Blue Crystal",      price = 100         },
    { name = "Purple Crystal",    price = 500         },
    { name = "Orange Crystal",    price = 2500        },
    { name = "Enchanted Crystal", price = 10000       },
    { name = "Astral Crystal",    price = 50000       },
    { name = "Golden Crystal",    price = 250000      },
    { name = "Inferno Crystal",   price = 1000000     },
    { name = "Galaxy Crystal",    price = 5000000     },
    { name = "Frozen Crystal",    price = 25000000    },
    { name = "Eternal Crystal",   price = 100000000   },
    { name = "Storm Crystal",     price = 500000000   },
    { name = "Thunder Crystal",   price = 2000000000  },
    { name = "Legends Crystal",   price = 10000000000 },
    { name = "Eternity Crystal",  price = 50000000000 },
}

local function FormatPrice(n)
    if n >= 1000000000000 then return string.format("%.0fT", n/1000000000000)
    elseif n >= 1000000000 then return string.format("%.0fB", n/1000000000)
    elseif n >= 1000000    then return string.format("%.0fM", n/1000000)
    elseif n >= 1000       then return string.format("%.0fK", n/1000)
    else return tostring(n) end
end

local petShopOptions = {}
local petBuyMapping  = {}
for _, v in ipairs(PET_SHOP) do
    local label = v.name .. "  [" .. FormatPrice(v.price) .. " Coins]"
    table.insert(petShopOptions, label)
    petBuyMapping[label] = v.name
end

local selectedPetBuy = nil

tabPets:CreateDropdown({
    Name = "Selecionar Crystal para Comprar",
    Options = petShopOptions, CurrentOption = {}, MultipleOptions = false,
    Callback = function(opt) selectedPetBuy = petBuyMapping[opt] end
})

tabPets:CreateToggle({
    Name = "Auto Buy Pet (Crystal Loop)",
    CurrentValue = false,
    Callback = function(state)
        _G.autoBuyPet = state
        if state then
            task.spawn(function()
                while _G.autoBuyPet do
                    task.wait(0.1)
                    pcall(function()
                        if selectedPetBuy then
                            rEvents.openCrystalRemote:InvokeServer("openCrystal", selectedPetBuy)
                        end
                    end)
                end
            end)
        end
    end
})

tabPets:CreateSection("Equip Automático")

-- ════ AUTO EQUIP MELHOR PET ════
local RARITY_ORDER = {
    Basic=1, Advanced=2, Rare=3, Epic=4,
    Unique=5, Omega=6, Immortal=7, Legend=8
}

local function GetBestPet()
    local bestPet, bestRarity = nil, 0
    for _, folder in pairs(LocalPlayer.petsFolder:GetChildren()) do
        local rank = RARITY_ORDER[folder.Name] or 0
        if rank > bestRarity then
            local children = folder:GetChildren()
            if #children > 0 then
                bestRarity = rank
                bestPet = children[1]
            end
        end
    end
    return bestPet
end

tabPets:CreateToggle({
    Name = "Auto Equip Melhor Pet (Loop)",
    CurrentValue = false,
    Callback = function(state)
        _G.equipBest = state
        if state then
            task.spawn(function()
                while _G.equipBest do
                    task.wait(2)
                    pcall(function()
                        local best = GetBestPet()
                        if best then
                            rEvents.petEquipEvent:FireServer("equipPet", best.Name)
                        end
                    end)
                end
            end)
        end
    end
})

tabPets:CreateButton({
    Name = "Equipar Melhor Pet (Uma vez)",
    Callback = function()
        local ok, err = pcall(function()
            local best = GetBestPet()
            if best then
                rEvents.petEquipEvent:FireServer("equipPet", best.Name)
                Rayfield:Notify({ Title = "Pets", Content = "Melhor pet equipado: " .. best.Name, Duration = 3 })
            else
                Rayfield:Notify({ Title = "Pets", Content = "Nenhum pet encontrado.", Duration = 2 })
            end
        end)
        if not ok then
            Rayfield:Notify({ Title = "Erro", Content = tostring(err), Duration = 3 })
        end
    end
})

tabPets:CreateSection("Evoluções de Pets")

local function PetEventLoop(flagGetter, eventName, remoteName)
    task.spawn(function()
        while flagGetter() do
            task.wait(0.1)
            pcall(function()
                for _, folder in pairs(LocalPlayer.petsFolder:GetChildren()) do
                    for _, pet in pairs(folder:GetChildren()) do
                        if not flagGetter() then return end
                        rEvents[eventName]:FireServer(remoteName, pet.Name)
                    end
                end
            end)
        end
    end)
end

tabPets:CreateToggle({
    Name = "Auto Evoluir Pets",
    CurrentValue = false,
    Callback = function(state)
        _G.ePet = state
        if state then PetEventLoop(function() return _G.ePet end, "petEvolveEvent", "evolvePet") end
    end
})

tabPets:CreateToggle({
    Name = "Auto Eternalizar Pets",
    CurrentValue = false,
    Callback = function(state)
        _G.eEternal = state
        if state then PetEventLoop(function() return _G.eEternal end, "petEternalizeEvent", "eternalizePet") end
    end
})

tabPets:CreateToggle({
    Name = "Auto Immortalizar Pets",
    CurrentValue = false,
    Callback = function(state)
        _G.eImm = state
        if state then PetEventLoop(function() return _G.eImm end, "petImmortalizeEvent", "immortalizePet") end
    end
})

tabPets:CreateToggle({
    Name = "Auto Legend Pets",
    CurrentValue = false,
    Callback = function(state)
        _G.eLeg = state
        if state then PetEventLoop(function() return _G.eLeg end, "petLegendEvent", "legendPet") end
    end
})

tabPets:CreateSection("Vender Pets por Raridade")

local function SellPetFolder(flagGetter, folderName)
    task.spawn(function()
        while flagGetter() do
            task.wait(1)
            pcall(function()
                for _, v in pairs(LocalPlayer.petsFolder[folderName]:GetChildren()) do
                    rEvents.sellPetEvent:FireServer("sellPet", v)
                end
            end)
        end
    end)
end

tabPets:CreateToggle({
    Name = "Vender Pets Basic",
    CurrentValue = false,
    Callback = function(state)
        _G.sellBasic = state
        if state then SellPetFolder(function() return _G.sellBasic end, "Basic") end
    end
})

tabPets:CreateToggle({
    Name = "Vender Pets Advanced",
    CurrentValue = false,
    Callback = function(state)
        _G.sellAdv = state
        if state then SellPetFolder(function() return _G.sellAdv end, "Advanced") end
    end
})

tabPets:CreateToggle({
    Name = "Vender Pets Rare",
    CurrentValue = false,
    Callback = function(state)
        _G.sellRare = state
        if state then SellPetFolder(function() return _G.sellRare end, "Rare") end
    end
})

tabPets:CreateToggle({
    Name = "Vender Pets Epic",
    CurrentValue = false,
    Callback = function(state)
        _G.sellEpic = state
        if state then SellPetFolder(function() return _G.sellEpic end, "Epic") end
    end
})

tabPets:CreateToggle({
    Name = "Vender Pets Unique",
    CurrentValue = false,
    Callback = function(state)
        _G.sellUnique = state
        if state then SellPetFolder(function() return _G.sellUnique end, "Unique") end
    end
})

tabPets:CreateToggle({
    Name = "Vender Pets Omega",
    CurrentValue = false,
    Callback = function(state)
        _G.sellOmega = state
        if state then SellPetFolder(function() return _G.sellOmega end, "Omega") end
    end
})

-- ═══════════════════════════════════════════════════════
--                   ABA: TELEPORTE
-- ═══════════════════════════════════════════════════════

local ISLAND = {}
for _, v in pairs(workspace.islandUnlockParts:GetChildren()) do
    table.insert(ISLAND, v.Name)
end

tabTP:CreateSection("Ilhas")

tabTP:CreateDropdown({
    Name = "Teleportar para Ilha",
    Options = ISLAND, CurrentOption = {}, MultipleOptions = false,
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

tabTP:CreateSection("Locais Especiais")

tabTP:CreateButton({
    Name = "Teleportar para Shop",
    Callback = function()
        pcall(function()
            LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.shopAreaCircle5.circleInner.CFrame
        end)
    end
})

tabTP:CreateButton({
    Name = "Teleportar para KOTH",
    Callback = function()
        pcall(function()
            LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.kingOfTheHillPart.CFrame
        end)
    end
})

tabTP:CreateSection("Áreas de Treino")

tabTP:CreateButton({
    Name = "Mystical Waters (Bom Karma)",
    Callback = function()
        pcall(function()
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(347.74, 8824.53, 114.27)
        end)
    end
})

tabTP:CreateButton({
    Name = "Lava Pit (Mau Karma)",
    Callback = function()
        pcall(function()
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-116.63, 12952.53, 271.14)
        end)
    end
})

-- ═══════════════════════════════════════════════════════
--                     ABA: MISC
-- ═══════════════════════════════════════════════════════

tabMisc:CreateSection("Pulo")

local InfJumpEnabled = false
tabMisc:CreateToggle({
    Name = "Pulo Infinito (Geral)",
    CurrentValue = false,
    Callback = function(state) InfJumpEnabled = state end
})

UIS.JumpRequest:Connect(function()
    if InfJumpEnabled then
        pcall(function()
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
        end)
    end
end)

tabMisc:CreateToggle({
    Name = "Pulo Infinito (Double Jump)",
    CurrentValue = false,
    Callback = function(state)
        _G.iJump = state
        if state then
            task.spawn(function()
                while _G.iJump do
                    task.wait(0.1)
                    pcall(function()
                        LocalPlayer.multiJumpCount.Value = "99999999999999999"
                    end)
                end
            end)
        end
    end
})

tabMisc:CreateSection("Armas & Combate")

tabMisc:CreateToggle({
    Name = "Fast Shuriken",
    CurrentValue = false,
    Callback = function(state)
        _G.fastShuriken = state
        if state then
            task.spawn(function()
                while _G.fastShuriken do
                    task.wait(0.001)
                    pcall(function()
                        local Mouse = LocalPlayer:GetMouse()
                        for _, p in pairs(workspace.shurikensFolder:GetChildren()) do
                            if p.Name == "Handle" and p:FindFirstChild("BodyVelocity") then
                                local bv = p:FindFirstChildOfClass("BodyVelocity")
                                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                                bv.Velocity = Mouse.Hit.LookVector * 1000
                            end
                        end
                    end)
                end
            end)
        end
    end
})

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
                pcall(function() rEvents.elementMasteryEvent:FireServer(el) end)
                task.wait(0.1)
            end
            Rayfield:Notify({ Title = "Sucesso", Content = "Todos os elementos obtidos!", Duration = 3 })
        end)
    end
})

tabMisc:CreateSection("Utilidades")

-- ANTI-AFK usando evento Idled nativo do Roblox (método mais confiável e testado)
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end)

tabMisc:CreateLabel("✓ Anti-AFK ativo automaticamente")

tabMisc:CreateButton({
    Name = "Rejoinar",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

-- ═══════════════════════════════════════════════════════
--          CARREGAMENTO DE CONFIGURAÇÕES + NOTIFICAÇÃO
-- ═══════════════════════════════════════════════════════

Rayfield:LoadConfiguration()

Rayfield:Notify({
    Title = "Nuck Hub — VIP",
    Content = "Script carregado! Anti-AFK ativo. Bom jogo, " .. LocalPlayer.DisplayName .. "! 🥷",
    Duration = 5,
    Image = 6026568198,
})
