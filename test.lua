-- [[ NHẬN DỮ LIỆU TỪ EXECUTOR ]] --
local WEBHOOK_URL = _G.WEBHOOK or ""
local TARGET_CLANS = _G.CLAN or {"HELOS", "FRITZ"}
local DELAY_BETWEEN_ROLLS = _G.SPEED or 1.5

-- [[ SERVICES ]] --
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local vim = game:GetService("VirtualInputManager")
local http = game:GetService("HttpService")
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- [[ PATHS ]] --
local familyUI = playerGui:WaitForChild("Interface"):WaitForChild("Customisation"):WaitForChild("Family")
local rollBtn = familyUI:WaitForChild("Buttons_2"):WaitForChild("Roll")
local rollTitle = rollBtn:WaitForChild("Title") -- Chứa "ROLL(XXX)"
local familyTitle = familyUI:WaitForChild("Family"):WaitForChild("Title") -- Chứa "NAME(RARITY)"
local warningPrompt = playerGui.Interface:WaitForChild("Warning"):WaitForChild("Prompt")

-- [[ FUNCTIONS ]] --
local function isVisible(obj)
    return obj and obj.Visible and obj.AbsoluteSize.X > 0
end

local function smartClick(obj)
    if isVisible(obj) then
        local x = obj.AbsolutePosition.X + (obj.AbsoluteSize.X / 2)
        local y = obj.AbsolutePosition.Y + (obj.AbsoluteSize.Y / 2) + 58
        vim:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.05)
        vim:SendMouseButtonEvent(x, y, 0, false, game, 1)
        return true
    end
    return false
end

local function parseInfo()
    -- Lấy tên Clan và Rarity
    local fText = familyTitle.Text
    local clan = fText:match("^(.-)%s*%(") or fText
    local rarity = fText:match("%((.-)%)") or "COMMON"
    
    -- Lấy số lượt Roll còn sót lại (Xử lý cả dấu phẩy như 1,234)
    local rText = rollTitle.Text
    local rollsStr = rText:match("%(([%d,]+)%)") or "0"
    local rollsNum = tonumber(rollsStr:gsub(",", "")) or 0
    
    return clan:upper():gsub("%s+", ""), rarity:upper(), rollsNum
end

local function sendWebhook(clan, rarity, rolls)
    if WEBHOOK_URL == "" then return end
    local data = {
        ["content"] = "🎉 **Auto Roll Success!**",
        ["embeds"] = {{
            ["title"] = "Clan: " .. clan .. " (" .. rarity .. ")",
            ["description"] = "Rolls còn lại: " .. rolls,
            ["color"] = 65280
        }}
    }
    pcall(function() http:PostAsync(WEBHOOK_URL, http:JSONEncode(data)) end)
end

-- [[ VÒNG LẶP CHÍNH (MAIN LOOP) ]] --
print("🚀 Script GitHub đang chạy... Đang kiểm tra lượt roll.")

while true do
    local clanName, rarity, rollsLeft = parseInfo()

    -- 1. Kiểm tra hết lượt roll
    if rollsLeft <= 0 then
        warn("❌ Đã hết lượt Roll (Số lượng: " .. rollsLeft .. ")")
        break
    end

    -- 2. Kiểm tra điều kiện dừng (Fritz, Helos hoặc Target)
    local isTarget = false
    if clanName == "FRITZ" or clanName == "HELOS" then
        isTarget = true
    else
        for _, t in ipairs(TARGET_CLANS) do
            if clanName == t:upper() then isTarget = true break end
        end
    end

    if isTarget then
        print("🏆 ĐÃ TÌM THẤY CLAN: " .. clanName)
        sendWebhook(clanName, rarity, rollsLeft)
        break
    end

    -- 3. Xử lý Warning Prompt (Bấm "Yes" nếu ra Epic/Legendary không phải mục tiêu)
    if isVisible(warningPrompt.Main) then
        local yesBtn = warningPrompt.Main:FindFirstChild("Yes")
        if yesBtn then 
            smartClick(yesBtn)
            task.wait(0.5) -- Chờ UI cập nhật sau khi bấm Yes
        end
    elseif rarity == "EPIC" or rarity == "LEGENDARY" then
        -- Trường hợp quay ra đồ xịn nhưng UI Warning chưa kịp hiện thì chuẩn bị bấm Yes
        print("⚠️ Phát hiện " .. rarity .. ", đợi bảng xác nhận...")
        task.wait(0.2)
        local yesBtn = warningPrompt.Main:FindFirstChild("Yes")
        if yesBtn then smartClick(yesBtn) end
    end

    -- 4. Thực hiện Roll
    print("🎲 Đang Roll... Còn lại: " .. rollsLeft)
    smartClick(rollBtn)
    
    -- 5. Đợi UI cập nhật nội dung mới
    task.wait(DELAY_BETWEEN_ROLLS)
end

print("🏁 Script đã dừng.")
