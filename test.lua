local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Event = ReplicatedStorage
    :WaitForChild("GameEvents")
    :WaitForChild("BuyEventShopStock")

--------------------------------------------------
-- CONFIG
--------------------------------------------------

local CONFIG_FILE = "EventShop_Config.json"

local Config = {
    Twilight = false,
    BloodMoon = false,
    AutoBuy = false,
    AutoHop = false
}

local function SaveConfig()
    if not writefile then
        return
    end

    local success, encoded = pcall(function()
        return HttpService:JSONEncode(Config)
    end)

    if success then
        pcall(function()
            writefile(CONFIG_FILE, encoded)
        end)
    end
end

local function LoadConfig()
    if not (readfile and isfile) then
        return
    end

    local success, exists = pcall(function()
        return isfile(CONFIG_FILE)
    end)

    if not success or not exists then
        return
    end

    local readSuccess, data = pcall(function()
        return readfile(CONFIG_FILE)
    end)

    if not readSuccess then
        return
    end

    local decodeSuccess, loaded = pcall(function()
        return HttpService:JSONDecode(data)
    end)

    if decodeSuccess and type(loaded) == "table" then
        for key, defaultValue in pairs(Config) do
            if typeof(loaded[key]) == typeof(defaultValue) then
                Config[key] = loaded[key]
            end
        end
    end
end

LoadConfig()

--------------------------------------------------
-- CLEAN OLD UI
--------------------------------------------------

local oldUI = PlayerGui:FindFirstChild("EventShopUI")

if oldUI then
    oldUI:Destroy()
end

--------------------------------------------------
-- UI
--------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EventShopUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 280, 0, 240)
Main.Position = UDim2.new(0.5, -140, 0.5, -120)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Event Shop"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 21
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

--------------------------------------------------
-- DROPDOWN
--------------------------------------------------

local DropdownButton = Instance.new("TextButton")
DropdownButton.Size = UDim2.new(0, 230, 0, 40)
DropdownButton.Position = UDim2.new(0.5, -115, 0, 45)
DropdownButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
DropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DropdownButton.TextSize = 14
DropdownButton.Font = Enum.Font.GothamMedium
DropdownButton.Parent = Main

local DropCorner = Instance.new("UICorner")
DropCorner.CornerRadius = UDim.new(0, 8)
DropCorner.Parent = DropdownButton

local Dropdown = Instance.new("Frame")
Dropdown.Size = UDim2.new(0, 230, 0, 90)
Dropdown.Position = UDim2.new(0.5, -115, 0, 90)
Dropdown.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
Dropdown.BorderSizePixel = 0
Dropdown.Visible = false
Dropdown.ZIndex = 10
Dropdown.Parent = Main

local DropdownCorner = Instance.new("UICorner")
DropdownCorner.CornerRadius = UDim.new(0, 8)
DropdownCorner.Parent = Dropdown

--------------------------------------------------
-- TWILIGHT
--------------------------------------------------

local TwilightButton = Instance.new("TextButton")
TwilightButton.Size = UDim2.new(1, -10, 0, 35)
TwilightButton.Position = UDim2.new(0, 5, 0, 5)
TwilightButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TwilightButton.TextSize = 13
TwilightButton.Font = Enum.Font.Gotham
TwilightButton.ZIndex = 11
TwilightButton.Parent = Dropdown

local TwilightCorner = Instance.new("UICorner")
TwilightCorner.CornerRadius = UDim.new(0, 6)
TwilightCorner.Parent = TwilightButton

--------------------------------------------------
-- BLOOD MOON
--------------------------------------------------

local BloodMoonButton = Instance.new("TextButton")
BloodMoonButton.Size = UDim2.new(1, -10, 0, 35)
BloodMoonButton.Position = UDim2.new(0, 5, 0, 47)
BloodMoonButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BloodMoonButton.TextSize = 13
BloodMoonButton.Font = Enum.Font.Gotham
BloodMoonButton.ZIndex = 11
BloodMoonButton.Parent = Dropdown

local BloodMoonCorner = Instance.new("UICorner")
BloodMoonCorner.CornerRadius = UDim.new(0, 6)
BloodMoonCorner.Parent = BloodMoonButton

--------------------------------------------------
-- AUTO BUY BUTTON
--------------------------------------------------

local AutoBuyButton = Instance.new("TextButton")
AutoBuyButton.Size = UDim2.new(0, 230, 0, 45)
AutoBuyButton.Position = UDim2.new(0.5, -115, 0, 105)
AutoBuyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoBuyButton.TextSize = 16
AutoBuyButton.Font = Enum.Font.GothamBold
AutoBuyButton.Parent = Main

local AutoBuyCorner = Instance.new("UICorner")
AutoBuyCorner.CornerRadius = UDim.new(0, 9)
AutoBuyCorner.Parent = AutoBuyButton

--------------------------------------------------
-- AUTO HOP BUTTON
--------------------------------------------------

local AutoHopButton = Instance.new("TextButton")
AutoHopButton.Size = UDim2.new(0, 230, 0, 45)
AutoHopButton.Position = UDim2.new(0.5, -115, 0, 160)
AutoHopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoHopButton.TextSize = 16
AutoHopButton.Font = Enum.Font.GothamBold
AutoHopButton.Parent = Main

local AutoHopCorner = Instance.new("UICorner")
AutoHopCorner.CornerRadius = UDim.new(0, 9)
AutoHopCorner.Parent = AutoHopButton

--------------------------------------------------
-- UI UPDATE FUNCTIONS
--------------------------------------------------

local DropdownOpen = false

local function UpdateDropdownText()
    local selected = {}

    if Config.Twilight then
        table.insert(selected, "Twilight")
    end

    if Config.BloodMoon then
        table.insert(selected, "Blood Moon")
    end

    local arrow = DropdownOpen and " ▲" or " ▼"

    if #selected == 0 then
        DropdownButton.Text = "Select Shops" .. arrow
    elseif #selected == 1 then
        DropdownButton.Text = selected[1] .. arrow
    else
        DropdownButton.Text = "Twilight + Blood Moon" .. arrow
    end
end

local function UpdateTwilight()
    if Config.Twilight then
        TwilightButton.Text = "☑ Twilight Shop Night Egg"
        TwilightButton.BackgroundColor3 = Color3.fromRGB(55, 125, 80)
    else
        TwilightButton.Text = "☐ Twilight Shop Night Egg"
        TwilightButton.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
    end
end

local function UpdateBloodMoon()
    if Config.BloodMoon then
        BloodMoonButton.Text = "☑ Blood Moon Shop Night Egg"
        BloodMoonButton.BackgroundColor3 = Color3.fromRGB(55, 125, 80)
    else
        BloodMoonButton.Text = "☐ Blood Moon Shop Night Egg"
        BloodMoonButton.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
    end
end

local function UpdateAutoBuy()
    if Config.AutoBuy then
        AutoBuyButton.Text = "AUTO BUY: ON"
        AutoBuyButton.BackgroundColor3 = Color3.fromRGB(55, 180, 90)
    else
        AutoBuyButton.Text = "AUTO BUY: OFF"
        AutoBuyButton.BackgroundColor3 = Color3.fromRGB(180, 55, 55)
    end
end

local function UpdateAutoHop()
    if Config.AutoHop then
        AutoHopButton.Text = "AUTO REJOIN: ON"
        AutoHopButton.BackgroundColor3 = Color3.fromRGB(55, 180, 90)
    else
        AutoHopButton.Text = "AUTO REJOIN: OFF"
        AutoHopButton.BackgroundColor3 = Color3.fromRGB(180, 55, 55)
    end
end

local function RefreshUI()
    UpdateTwilight()
    UpdateBloodMoon()
    UpdateAutoBuy()
    UpdateAutoHop()
    UpdateDropdownText()
end

RefreshUI()

--------------------------------------------------
-- DROPDOWN EVENTS
--------------------------------------------------

DropdownButton.MouseButton1Click:Connect(function()
    DropdownOpen = not DropdownOpen
    Dropdown.Visible = DropdownOpen

    if DropdownOpen then
        Main.Size = UDim2.new(0, 280, 0, 335)
        AutoBuyButton.Position = UDim2.new(0.5, -115, 0, 200)
        AutoHopButton.Position = UDim2.new(0.5, -115, 0, 255)
    else
        Main.Size = UDim2.new(0, 280, 0, 240)
        AutoBuyButton.Position = UDim2.new(0.5, -115, 0, 105)
        AutoHopButton.Position = UDim2.new(0.5, -115, 0, 160)
    end

    UpdateDropdownText()
end)

TwilightButton.MouseButton1Click:Connect(function()
    Config.Twilight = not Config.Twilight

    UpdateTwilight()
    UpdateDropdownText()
    SaveConfig()
end)

BloodMoonButton.MouseButton1Click:Connect(function()
    Config.BloodMoon = not Config.BloodMoon

    UpdateBloodMoon()
    UpdateDropdownText()
    SaveConfig()
end)

AutoBuyButton.MouseButton1Click:Connect(function()
    Config.AutoBuy = not Config.AutoBuy

    UpdateAutoBuy()
    SaveConfig()
end)

AutoHopButton.MouseButton1Click:Connect(function()
    Config.AutoHop = not Config.AutoHop

    UpdateAutoHop()
    SaveConfig()
end)

--------------------------------------------------
-- AUTO BUY
--------------------------------------------------

task.spawn(function()
    while ScreenGui.Parent do
        if not Config.AutoBuy then
            task.wait(0.5)
            continue
        end

        if Config.Twilight then
            pcall(function()
                Event:FireServer("Night Egg", "Twilight Shop")
            end)
        end

        if Config.BloodMoon then
            pcall(function()
                Event:FireServer("Night Egg", "Blood Moon Shop")
            end)
        end

        task.wait(1)
    end
end)

--------------------------------------------------
-- AUTO REJOIN / DISCONNECT DETECTION
--------------------------------------------------

local Rejoining = false

local function Rejoin()
    if not Config.AutoHop then
        return
    end

    if Rejoining then
        return
    end

    Rejoining = true

    task.wait(1)

    local success = pcall(function()
        TeleportService:TeleportToPlaceInstance(
            game.PlaceId,
            game.JobId,
            Player
        )
    end)

    if not success then
        pcall(function()
            TeleportService:Teleport(
                game.PlaceId,
                Player
            )
        end)
    end

    task.wait(5)
    Rejoining = false
end

--------------------------------------------------
-- DETECT ROBLOX DISCONNECT PROMPT
--------------------------------------------------

task.spawn(function()
    while ScreenGui.Parent do
        if Config.AutoHop then
            local promptGui = CoreGui:FindFirstChild("RobloxPromptGui")

            if promptGui then
                local overlay = promptGui:FindFirstChild("promptOverlay")

                if overlay then
                    local errorPrompt = overlay:FindFirstChild("ErrorPrompt")

                    if errorPrompt and errorPrompt.Visible then
                        Rejoin()
                    end
                end
            end
        end

        task.wait(1)
    end
end)

--------------------------------------------------
-- SAVE WHEN SCRIPT/UI CLOSES
--------------------------------------------------

ScreenGui.Destroying:Connect(function()
    SaveConfig()
end)
