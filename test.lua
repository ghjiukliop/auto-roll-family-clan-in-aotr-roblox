local player = game:GetService("Players").LocalPlayer
local vim = game:GetService("VirtualInputManager")
local http = game:GetService("HttpService")
local fs = game:GetService("DataStoreService")

local WEBHOOK_URL_WIN ="Your webhook link here"
local WEBHOOK_URL_LOG = "Your webhook link here"
local HISTORY_FILE = "rollHistory.json"

local TARGET_CLANS = {"Fritz", "Helos"}
local MAX_ROLLS = 10
local delayTime = 1
local rollHistory = {}
local sentAccounts = {}

local function isReallyVisible(obj)
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

local function waitAndGetClickable(parent, name)
    local target = parent:WaitForChild(name, 30)
    if target then
        local start = tick()
        while tick() - start < 30 do
            if isReallyVisible(target) then
                task.wait(0.5)
                return target
            end
            task.wait(0.5)
        end
    end
    return nil
end

local function clickPhysicalButton(btn)
    if btn then
        local x = btn.AbsolutePosition.X + (btn.AbsoluteSize.X / 2)
        local y = btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y / 2) + 58 
        vim:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.1)
        vim:SendMouseButtonEvent(x, y, 0, false, game, 1)
        return true
    end
    return false
end

local function pressKey(keyCode)
    vim:SendKeyEvent(true, keyCode, false, game)
    task.wait(0.1)
    vim:SendKeyEvent(false, keyCode, false, game)
    task.wait(delayTime)
end

local function loadHistory()
    local content = readfile and readfile(HISTORY_FILE) or nil
    if content then
        local success, data = pcall(function() return http:JSONDecode(content) end)
        if success and data then
            return data
        end
    end
    return {}
end

local function saveHistory(historyData)
    local content = http:JSONEncode(historyData)
    if writefile then
        pcall(function()
            writefile(HISTORY_FILE, content)
        end)
    end
end

local function fileExists(filename)
    local success = pcall(function()
        readfile(filename)
    end)
    return success
end

local function initializeHistoryFile()
    if not fileExists(HISTORY_FILE) then
        saveHistory({})
        print("Tao file rollHistory.json thanh cong")
    else
        print("File rollHistory.json da ton tai")
    end
end

local function accountAlreadySent(accountName, historyData)
    for _, entry in ipairs(historyData) do
        if entry["name"] == accountName and entry["sent"] == true then
            return true
        end
    end
    return false
end

local function markAccountAsSent(accountName, clans, historyData)
    for _, entry in ipairs(historyData) do
        if entry["name"] == accountName then
            entry["sent"] = true
            return
        end
    end
    table.insert(historyData, {["name"] = accountName, ["clans"] = clans, ["sent"] = true})
end

initializeHistoryFile()
local historyData = loadHistory()
local accountName = player.Name
local alreadySent = accountAlreadySent(accountName, historyData)

-- Bảng mã màu ANSI cho Discord
local ansi = {
    white = "\27[0;37m", blue = "\27[0;34m", purple = "\27[0;35m", 
    yellow = "\27[0;33m", red = "\27[0;31m", reset = "\27[0m"
}

-- Biến lưu trữ tạm thời trong phiên chạy này
local currentSessionClans = {}

local function getClanColor(clan)
    local c = clan:lower()
    if c:find("mythic") then return ansi.red, 15548997
    elseif c:find("legendary") then return ansi.yellow, 16776960
    elseif c:find("epic") then return ansi.purple, 10181046
    elseif c:find("rare") then return ansi.blue, 3447003
    else return ansi.white, 16777215 end
end

local function sendFinalWebhook()
    local coloredList = ""
    local maxColor = 16777215
    
    for _, clan in ipairs(currentSessionClans) do
        local colorCode, sidebar = getClanColor(clan)
        coloredList = coloredList .. colorCode .. clan .. ansi.reset .. "\n"
        if sidebar ~= 16777215 then maxColor = sidebar end
    end

    local payload = http:JSONEncode({
        username = "Your name STORE",
        embeds = {{
            title = "🍌 Roll Completed 🍌",
            color = maxColor,
            fields = {
                {name = "👤 Account", value = "```ansi\n" .. ansi.yellow .. accountName .. ansi.reset .. "```"},
                {name = "📜 Roll History", value = "```ansi\n" .. (coloredList ~= "" and coloredList or "No rolls") .. "```"}
            },
            footer = {text = "Cloud Phone System • " .. os.date("%X")}
        }}
    })

    local req = request or http_request or (syn and syn.request)
    if req then
        req({Url = WEBHOOK_URL_LOG, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload})
    end
    
    markAccountAsSent(accountName, currentSessionClans, historyData)
    saveHistory(historyData)
end

local function exitGame()
    task.wait(1)
    game:Shutdown()
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local playerGui = player:WaitForChild("PlayerGui", 999)
local interface = playerGui:WaitForChild("Interface", 999)
local titleScreen = interface:WaitForChild("Title_Screen", 999)

local slotA = titleScreen:WaitForChild("Slots", 999):WaitForChild("A", 999):WaitForChild("Select_A", 999)
print("--- Dang cho Slot A san sang ---")
repeat task.wait(1) until isReallyVisible(slotA)

clickPhysicalButton(slotA)
task.wait(2)

print("--- Bat dau thuc hien phim ---")
pressKey(Enum.KeyCode.BackSlash)
for i = 1, 3 do
    pressKey(Enum.KeyCode.Down)
end
pressKey(Enum.KeyCode.Return)

task.wait(3)
delayTime = 6

local customBtn = waitAndGetClickable(interface.Title_Screen.Buttons, "Customisation")
if customBtn then
    clickPhysicalButton(customBtn)
end

local familyCat = waitAndGetClickable(interface.Customisation.Categories, "Family")
if familyCat then
    clickPhysicalButton(familyCat)
end

local rollBtn = waitAndGetClickable(interface.Customisation.Family.Buttons_2, "Roll")
local clanTitle = interface.Customisation.Family.Family:WaitForChild("Title")

if rollBtn then
    local targetFound = false
    for i = 1, MAX_ROLLS do
        local oldClan = clanTitle.Text
        print("Dang Roll luot: " .. i)
        clickPhysicalButton(rollBtn)
        local t = 0
        repeat
            task.wait(0.5)
            t = t + 0.5
        until clanTitle.Text ~= oldClan or t > 4
        local currentClan = clanTitle.Text
        print("Ket qua: " .. currentClan)
        table.insert(rollHistory, currentClan)
        table.insert(currentSessionClans, currentClan)
        local found = false
        for _, target in pairs(TARGET_CLANS) do
            if string.find(string.lower(currentClan), string.lower(target)) then
                found = true
                break
            end
        end
        if found then
            targetFound = true
            break 
        end
        task.wait(2.5)
    end
    sendFinalWebhook()
    exitGame()
else
    sendFinalWebhook()
    exitGame()
end

print("--- Xong! ---")