-- === AUTO ROLL FAMILY SCRIPT WITH GUI ===
-- Script for rolling family with customizable settings
-- Place ID cần match với game của bạn

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Y_OFFSET = 58

-- === DEFAULT CONFIGURATION ===
local CONFIG = {
    SLOT = "A",
    WEBHOOK = "",
    CLAN = "",
    DELAY_BETWEEN_ROLLS = 0.3,
    DEBUG = true
}

-- === GUI VARIABLES ===
local guiOpen = true
local isRolling = false
local rollsRemaining = 0
local currentFamily = ""

-- === HELPER FUNCTIONS ===
local function log(message)
    if CONFIG.DEBUG then
        print("[AutoRoll] " .. message)
    end
end

local function isVisible(obj)
    if not obj or not obj:IsA("GuiObject") then return false end
    local current = obj
    while current and current:IsA("GuiObject") do
        if not current.Visible then return false end
        current = current.Parent
    end
    local screenGui = obj:FindFirstAncestorOfClass("ScreenGui")
    if screenGui and not screenGui.Enabled then return false end
    return obj.AbsoluteSize.X > 0 and obj.AbsoluteSize.Y > 0
end

local function click(btn)
    if btn and isVisible(btn) then
        local x = btn.AbsolutePosition.X + (btn.AbsoluteSize.X / 2)
        local y = btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y / 2) + Y_OFFSET
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
        return true
    end
    return false
end

local function pressKey(keyCode)
    VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end

local function getCleanName(text)
    -- Xóa rarity info như (Common), (Rare), (Legend), etc
    local cleaned = text:gsub("%s*%b()", ""):gsub("%s+", " "):strip()
    return cleaned
end

local function sendWebhook(success, message)
    if CONFIG.WEBHOOK == "" or CONFIG.WEBHOOK == nil then
        log("⚠️ Webhook chưa được cấu hình")
        return
    end
    
    local data = {
        ["content"] = success and "🎉 **Auto Roll Success!**" or "❌ **Auto Roll Failed**",
        ["embeds"] = {{
            ["title"] = success and ("Tìm được: " .. currentFamily) or "Lỗi",
            ["description"] = message,
            ["color"] = success and 65280 or 16711680,
            ["fields"] = {
                {["name"] = "Slot", ["value"] = CONFIG.SLOT, ["inline"] = true},
                {["name"] = "Rolls Còn Lại", ["value"] = tostring(rollsRemaining), ["inline"] = true},
                {["name"] = "Clan Tìm", ["value"] = CONFIG.CLAN, ["inline"] = true}
            }
        }}
    }
    
    pcall(function()
        HttpService:PostAsync(CONFIG.WEBHOOK, HttpService:JSONEncode(data))
    end)
end

-- === CREATE GUI ===
local function createGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoRollGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 350, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
    mainFrame.BorderSizePixel = 2
    mainFrame.Parent = screenGui
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Text = "🎲 AUTO ROLL FAMILY"
    title.Parent = mainFrame
    
    local padding = 10
    local yOffset = 50
    local inputHeight = 30
    
    -- SLOT Input
    local slotLabel = Instance.new("TextLabel")
    slotLabel.Size = UDim2.new(1, -20, 0, 20)
    slotLabel.Position = UDim2.new(0, 10, 0, yOffset)
    slotLabel.BackgroundTransparency = 1
    slotLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    slotLabel.TextSize = 12
    slotLabel.Font = Enum.Font.Gotham
    slotLabel.Text = "SLOT (A/B/C)"
    slotLabel.Parent = mainFrame
    
    local slotInput = Instance.new("TextBox")
    slotInput.Name = "SlotInput"
    slotInput.Size = UDim2.new(1, -20, 0, inputHeight)
    slotInput.Position = UDim2.new(0, 10, 0, yOffset + 20)
    slotInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    slotInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    slotInput.TextSize = 14
    slotInput.Font = Enum.Font.Gotham
    slotInput.Text = CONFIG.SLOT
    slotInput.ClearTextOnFocus = false
    slotInput.Parent = mainFrame
    
    yOffset = yOffset + 60
    
    -- CLAN Input
    local clanLabel = Instance.new("TextLabel")
    clanLabel.Size = UDim2.new(1, -20, 0, 20)
    clanLabel.Position = UDim2.new(0, 10, 0, yOffset)
    clanLabel.BackgroundTransparency = 1
    clanLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    clanLabel.TextSize = 12
    clanLabel.Font = Enum.Font.Gotham
    clanLabel.Text = "CLAN NAME (vd: BLOUSE, BOZADO)"
    clanLabel.Parent = mainFrame
    
    local clanInput = Instance.new("TextBox")
    clanInput.Name = "ClanInput"
    clanInput.Size = UDim2.new(1, -20, 0, inputHeight)
    clanInput.Position = UDim2.new(0, 10, 0, yOffset + 20)
    clanInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    clanInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    clanInput.TextSize = 14
    clanInput.Font = Enum.Font.Gotham
    clanInput.Text = CONFIG.CLAN
    clanInput.ClearTextOnFocus = false
    clanInput.Parent = mainFrame
    
    yOffset = yOffset + 60
    
    -- WEBHOOK Input
    local webhookLabel = Instance.new("TextLabel")
    webhookLabel.Size = UDim2.new(1, -20, 0, 20)
    webhookLabel.Position = UDim2.new(0, 10, 0, yOffset)
    webhookLabel.BackgroundTransparency = 1
    webhookLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    webhookLabel.TextSize = 12
    webhookLabel.Font = Enum.Font.Gotham
    webhookLabel.Text = "WEBHOOK URL"
    webhookLabel.Parent = mainFrame
    
    local webhookInput = Instance.new("TextBox")
    webhookInput.Name = "WebhookInput"
    webhookInput.Size = UDim2.new(1, -20, 0, inputHeight)
    webhookInput.Position = UDim2.new(0, 10, 0, yOffset + 20)
    webhookInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    webhookInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    webhookInput.TextSize = 12
    webhookInput.Font = Enum.Font.Gotham
    webhookInput.Text = CONFIG.WEBHOOK
    webhookInput.ClearTextOnFocus = false
    webhookInput.Parent = mainFrame
    
    yOffset = yOffset + 60
    
    -- START Button
    local startBtn = Instance.new("TextButton")
    startBtn.Name = "StartButton"
    startBtn.Size = UDim2.new(0.45, 0, 0, 40)
    startBtn.Position = UDim2.new(0, 10, 0, yOffset)
    startBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    startBtn.TextSize = 14
    startBtn.Font = Enum.Font.GothamBold
    startBtn.Text = "START"
    startBtn.Parent = mainFrame
    
    -- STOP Button
    local stopBtn = Instance.new("TextButton")
    stopBtn.Name = "StopButton"
    stopBtn.Size = UDim2.new(0.45, 0, 0, 40)
    stopBtn.Position = UDim2.new(0.55, 0, 0, yOffset)
    stopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    stopBtn.TextSize = 14
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.Text = "STOP"
    stopBtn.Parent = mainFrame
    
    yOffset = yOffset + 50
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -20, 0, 60)
    statusLabel.Position = UDim2.new(0, 10, 0, yOffset)
    statusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    statusLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Text = "📍 Status: Ready\n⏳ Waiting..."
    statusLabel.TextWrapped = true
    statusLabel.Parent = mainFrame
    
    -- Button Functions
    startBtn.MouseButton1Click:Connect(function()
        CONFIG.SLOT = slotInput.Text:upper()
        CONFIG.CLAN = clanInput.Text:upper()
        CONFIG.WEBHOOK = webhookInput.Text
        
        if CONFIG.CLAN == "" then
            statusLabel.Text = "❌ Clan chưa nhập!"
            return
        end
        
        isRolling = true
        startBtn.Enabled = false
        log("🚀 Bắt đầu Auto Roll cho: " .. CONFIG.CLAN)
        startAutoRoll(statusLabel)
    end)
    
    stopBtn.MouseButton1Click:Connect(function()
        isRolling = false
        startBtn.Enabled = true
        statusLabel.Text = "⛔ Đã dừng"
        log("⛔ Đã dừng Auto Roll")
    end)
    
    return screenGui, statusLabel
end

-- === AUTO ROLL WORKFLOW ===
function startAutoRoll(statusLabel)
    task.wait(1)
    
    -- Step 1: Click vào slot
    statusLabel.Text = "📍 Status: Đang chọn Slot " .. CONFIG.SLOT
    
    local interface = playerGui:WaitForChild("Interface", 30)
    if not interface then
        log("❌ Interface không tìm thấy")
        return
    end
    
    local titleScreen = interface:FindFirstChild("Title_Screen")
    if titleScreen then
        local slotBtn = titleScreen:FindFirstChild("Slots")
        if slotBtn then
            slotBtn = slotBtn:FindFirstChild(CONFIG.SLOT)
            if slotBtn then
                slotBtn = slotBtn:FindFirstChild("Select_" .. CONFIG.SLOT)
                if click(slotBtn) then
                    log("✅ Clicked Slot " .. CONFIG.SLOT)
                    task.wait(2)
                end
            end
        end
    end
    
    -- Step 2: Đợi đến khi vào game và tìm Customization
    statusLabel.Text = "📍 Status: Đang tìm Customization"
    task.wait(2)
    
    local customBtn = nil
    local startTime = tick()
    while isRolling and (tick() - startTime) < 60 do
        local ui = playerGui:FindFirstChild("Interface")
        if ui then
            -- Tìm nút Customization
            local function findButton(parent, name)
                if parent:IsA("GuiObject") and parent.Name:find(name) then
                    return parent
                end
                for _, child in pairs(parent:GetChildren()) do
                    local result = findButton(child, name)
                    if result then return result end
                end
                return nil
            end
            
            customBtn = findButton(ui, "Customiz")
            if customBtn and isVisible(customBtn) then
                break
            end
        end
        task.wait(0.5)
    end
    
    if customBtn and click(customBtn) then
        log("✅ Opened Customization")
        task.wait(2)
    else
        statusLabel.Text = "❌ Customization không tìm thấy"
        isRolling = false
        return
    end
    
    -- Step 3: Tìm và click vào Family
    statusLabel.Text = "📍 Status: Đang tìm Family"
    
    local familyBtn = nil
    startTime = tick()
    while isRolling and (tick() - startTime) < 30 do
        local ui = playerGui:FindFirstChild("Interface")
        if ui then
            local function findFamilyButton(parent)
                if parent:IsA("TextButton") or parent:IsA("TextLabel") then
                    local text = parent.Text or ""
                    if text:find("Family") or text:find("family") then
                        return parent
                    end
                end
                for _, child in pairs(parent:GetChildren()) do
                    local result = findFamilyButton(child)
                    if result then return result end
                end
                return nil
            end
            
            familyBtn = findFamilyButton(ui)
            if familyBtn and isVisible(familyBtn) then
                break
            end
        end
        task.wait(0.3)
    end
    
    if familyBtn and click(familyBtn) then
        log("✅ Opened Family Section")
        task.wait(2)
    else
        statusLabel.Text = "❌ Family button không tìm thấy"
        isRolling = false
        return
    end
    
    -- Step 4: Bắt đầu Roll
    statusLabel.Text = "📍 Status: Bắt đầu spam Roll"
    
    local rollAttempts = 0
    local maxAttempts = 1000
    
    while isRolling and rollAttempts < maxAttempts do
        -- Tìm ROLL button
        local rollBtn = nil
        local familyText = nil
        
        local ui = playerGui:FindFirstChild("Interface")
        if ui then
            local function findRollButton(parent)
                if parent:IsA("TextButton") then
                    local text = parent.Text or ""
                    if text:find("ROLL") or text:find("Roll") then
                        return parent
                    end
                end
                for _, child in pairs(parent:GetChildren()) do
                    local result = findRollButton(child)
                    if result then return result end
                end
                return nil
            end
            
            local function findFamilyText(parent)
                if parent:IsA("TextLabel") or parent:IsA("TextButton") then
                    local text = parent.Text or ""
                    -- Tìm text button hiển thị family name
                    if text ~= "" and not text:find("ROLL") and parent.AbsoluteSize.Y > 20 then
                        return parent
                    end
                end
                for _, child in pairs(parent:GetChildren()) do
                    local result = findFamilyText(child)
                    if result then return result end
                end
                return nil
            end
            
            rollBtn = findRollButton(ui)
            familyText = findFamilyText(ui)
        end
        
        -- Extract số lần roll còn lại từ ROLL(XXX)
        if rollBtn then
            local rollText = rollBtn.Text or ""
            local matches = rollText:match("ROLL%s*%((%d+)%)")
            if matches then
                rollsRemaining = tonumber(matches)
            end
        end
        
        -- Check family name
        if familyText then
            currentFamily = getCleanName(familyText.Text or "")
            
            -- Nếu tìm được family muốn
            if currentFamily:upper():find(CONFIG.CLAN:upper()) then
                statusLabel.Text = "✅ Status: Tìm được " .. currentFamily .. "!"
                log("🎉 Tìm được: " .. currentFamily)
                sendWebhook(true, "Tìm được family: " .. currentFamily .. "\nTrong " .. rollAttempts .. " lần roll")
                isRolling = false
                return
            end
        end
        
        -- Click Roll button
        if rollBtn and click(rollBtn) then
            rollAttempts = rollAttempts + 1
            statusLabel.Text = "📍 Status: Rolling... (" .. rollAttempts .. ")\n👨‍👩‍👧 Current: " .. currentFamily
            log("🎲 Roll #" .. rollAttempts .. " - Family: " .. currentFamily)
            
            task.wait(CONFIG.DELAY_BETWEEN_ROLLS)
        else
            task.wait(0.5)
        end
    end
    
    if rollAttempts >= maxAttempts then
        statusLabel.Text = "⚠️ Đạt giới hạn roll (" .. maxAttempts .. ")"
        sendWebhook(false, "Đạt giới hạn " .. maxAttempts .. " lần roll mà chưa tìm được " .. CONFIG.CLAN)
    end
    
    isRolling = false
end

-- === MAIN INITIALIZATION ===
if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(2)
local screenGui, statusLabel = createGui()
log("🎮 Auto Roll Family GUI Created")
statusLabel.Text = "✅ Status: Ready\n⏳ Chờ lệnh..."
