-- === SERVICES ===
local player = game:GetService("Players").LocalPlayer
local pGui = player:WaitForChild("PlayerGui")
local vim = game:GetService("VirtualInputManager")
local http = game:GetService("HttpService")

-- === HELPER FUNCTIONS ===
local function click(obj)
    if obj and obj:IsA("GuiObject") then
        local x = obj.AbsolutePosition.X + (obj.AbsoluteSize.X / 2)
        local y = obj.AbsolutePosition.Y + (obj.AbsoluteSize.Y / 2) + 58 -- Offset cho Roblox Topbar
        vim:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.05)
        vim:SendMouseButtonEvent(x, y, 0, false, game, 1)
        return true
    end
    return false
end

local function sendWebhook(clanFound, rollsLeft)
    local data = {
        ["content"] = "🎉 **Auto Roll Success!**",
        ["embeds"] = {{
            ["title"] = "Clan Found: " .. clanFound,
            ["description"] = "Slot: " .. SLOT .. "\nRemaining Rolls: " .. rollsLeft,
            ["color"] = 65280 -- Green
        }}
    }
    pcall(function()
        http:PostAsync(WEBHOOK_URL, http:JSONEncode(data))
    end)
end

local function getCleanClanName(text)
    -- Xóa phần (Common), (Rare),... và khoảng trắng dư thừa
    local name = text:gsub("%s*%b()", ""):upper():gsub("%s+", "")
    return name
end

-- === MAIN WORKFLOW ===

-- 1. Chọn Slot
local slotPath = "Interface.Title_Screen.Slots." .. SLOT .. ".Select_" .. SLOT
local slotBtn = pGui
for _, name in ipairs(string.split(slotPath, ".")) do slotBtn = slotBtn:WaitForChild(name, 10) end

print("--- Dang chon Slot " .. SLOT .. " ---")
click(slotBtn)
task.wait(2)

-- 2. Click Customisation
local customBtn = pGui.Interface.Title_Screen.Buttons:WaitForChild("Customisation", 10)
click(customBtn)
task.wait(1)

-- 3. Click vao Family tab
local familyTab = pGui.Interface.Customisation:WaitForChild("Family", 10)
click(familyTab)
task.wait(1)

-- 4. Bat dau vong lap Roll
local rollButton = pGui.Interface.Customisation.Family.Buttons_2:WaitForChild("Roll", 10)
local rollTitle = rollButton:WaitForChild("Title", 10) -- "ROLL (XXX)"
local familyTitle = pGui.Interface.Customisation.Family.Family:WaitForChild("Title", 10) -- Tên Family hiện tại

print("--- Bat dau qua trinh Auto Roll ---")

while true do
    local currentText = familyTitle.Text -- Ví dụ: "BLOUSE (Common)"
    local rollsText = rollTitle.Text -- Ví dụ: "ROLL (3,967)"
    
    local clanName = getCleanClanName(currentText)
    local rollsRemaining = rollsText:match("%(([%d,]+)%)") or "0"
    
    print("Clan hien tai: " .. clanName .. " | Con lai: " .. rollsRemaining .. " luot")

    -- Kiem tra xem co trung Clan muc tieu khong
    local found = false
    for _, target in ipairs(TARGET_CLANS) do
        if clanName == target:upper() then
            found = true
            break
        end
    end

    if found then
        print("🎉 DA TIM THAY CLAN: " .. clanName)
        sendWebhook(clanName, rollsRemaining)
        break -- Dung script
    end

    -- Neu khong trung, tiep tuc Roll
    if rollsRemaining == "0" then
        warn("!!! DA HET LUOT ROLL !!!")
        break
    end

    click(rollButton)
    task.wait(DELAY_BETWEEN_ROLLS)
end

print("--- Script ket thuc ---")  

