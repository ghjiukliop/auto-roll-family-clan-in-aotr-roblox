-- [[ ĐOẠN NÀY ĐỂ NHẬN DỮ LIỆU TỪ EXECUTOR ]] --
local WEBHOOK_URL = _G.WEBHOOK or ""
local TARGET_CLANS = _G.CLAN or {"Helos", "Fritz"}
local DELAY_BETWEEN_ROLLS = _G.SPEED or 1.5

-- [[ CÁC DỊCH VỤ VÀ BIẾN HỆ THỐNG ]] --
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local vim = game:GetService("VirtualInputManager")
local http = game:GetService("HttpService")
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Đường dẫn UI
local familyUI = playerGui:WaitForChild("Interface"):WaitForChild("Customisation"):WaitForChild("Family")
local rollBtn = familyUI:WaitForChild("Buttons_2"):WaitForChild("Roll")
local rollTitle = rollBtn:WaitForChild("Title")
local familyTitle = familyUI:WaitForChild("Family"):WaitForChild("Title")
local warningPrompt = playerGui.Interface:WaitForChild("Warning"):WaitForChild("Prompt")

-- [[ HÀM HỖ TRỢ ]] --
local function isVisible(obj)
    if not obj or not obj:IsA("GuiObject") then return false end
    return obj.Visible and obj.AbsoluteSize.X > 0
end

local function smartClick(obj)
    if obj and isVisible(obj) then
        local x = obj.AbsolutePosition.X + (obj.AbsoluteSize.X / 2)
        local y = obj.AbsolutePosition.Y + (obj.AbsoluteSize.Y / 2) + 58
        vim:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.05)
        vim:SendMouseButtonEvent(x, y, 0, false, game, 1)
        return true
    end
    return false
end

local function parseClanInfo(text)
    local name = text:match("^(.-)%s*%(") or text
    local rarity = text:match("%((.-)%)") or "COMMON"
    return name:upper():gsub("%s+", ""), rarity:upper()
end

local function sendWebhook(clanFound, rarity, rollsLeft)
    if WEBHOOK_URL == "" then return end
    local data = {
        ["content"] = "🎉 **Auto Roll Success!**",
        ["embeds"] = {{
            ["title"] = "Clan Found: " .. clanFound .. " (" .. rarity .. ")",
            ["description"] = "Remaining Rolls: " .. rollsLeft,
            ["color"] = 65280
        }}
    }
    pcall(function() http:PostAsync(WEBHOOK_URL, http:JSONEncode(data)) end)
end

-- [[ LOGIC CHÍNH ]] --
print("🚀 Script GitHub đã chạy. Đang đợi đúng mục tiêu...")

while true do
    local clanName, rarity = parseClanInfo(familyTitle.Text)
    local rollsRemaining = rollTitle.Text:match("%(([%d,]+)%)") or "0"

    -- Dừng ngay nếu ra Fritz hoặc Helos (Ưu tiên tuyệt đối)
    if clanName == "FRITZ" or clanName == "HELOS" then
        print("🏆 TRÚNG CLAN ĐẶC BIỆT: " .. clanName)
        sendWebhook(clanName, rarity, rollsRemaining)
        break
    end

    -- Kiểm tra mục tiêu bạn chọn ở Executor
    local isTarget = false
    for _, target in ipairs(TARGET_CLANS) do
        if clanName == target:upper() then
            isTarget = true
            break
        end
    end

    if isTarget then
        print("✅ Đã tìm thấy mục tiêu: " .. clanName)
        sendWebhook(clanName, rarity, rollsRemaining)
        break
    end

    if rollsRemaining == "0" then break end

    -- Tự động bấm Yes khi ra Epic/Legendary không phải mục tiêu
    if rarity == "EPIC" or rarity == "LEGENDARY" then
        local yesBtn = warningPrompt.Main:FindFirstChild("Yes")
        if yesBtn then
            repeat
                smartClick(yesBtn)
                task.wait(0.3)
            until not isVisible(yesBtn)
        end
    end

    smartClick(rollBtn)
    task.wait(DELAY_BETWEEN_ROLLS)

    if isVisible(warningPrompt.Main) then
        smartClick(warningPrompt.Main:FindFirstChild("Yes"))
    end
end
