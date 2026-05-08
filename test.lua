-- [[ CONFIGURATION ]] --
local WEBHOOK_URL = _G.WEBHOOK or _G.WEBHOOK_URL or ""
local TARGET_CLANS = _G.CLAN or _G.TARGET_CLANS or {"ACKERMAN", "YEAGER"}
local DELAY_BETWEEN_ROLLS = _G.SPEED or _G.DELAY_BETWEEN_ROLLS or 1.5

-- [[ SERVICES ]] --
local player = game:GetService("Players").LocalPlayer
local pGui = player:WaitForChild("PlayerGui")
local vim = game:GetService("VirtualInputManager")
local http = game:GetService("HttpService")

-- [[ UI ELEMENTS ]] --
-- Đường dẫn chính xác theo yêu cầu của bạn
local rollTitle = pGui:WaitForChild("Interface"):WaitForChild("Customisation")
    :WaitForChild("Family"):WaitForChild("Buttons_2"):WaitForChild("Roll"):WaitForChild("Title")

local familyTitle = pGui:WaitForChild("Interface"):WaitForChild("Customisation")
    :WaitForChild("Family"):WaitForChild("Family"):WaitForChild("Title")

local warningPrompt = pGui:WaitForChild("Interface"):WaitForChild("Warning"):WaitForChild("Prompt")

-- [[ HELPER FUNCTIONS ]] --

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

local function parseInfo()
    -- Tách Clan Name và Rarity từ: "Fritz (Legendary)"
    local fText = familyTitle.Text or ""
    local clan = fText:match("^(.-)%s*%(") or fText
    local rarity = fText:match("%((.-)%)") or "COMMON"
    
    -- Lấy số lượt Roll từ: "ROLL (3,403)"
    local rText = rollTitle.Text or ""
    local rollsStr = rText:match("%(([%d,]+)%)")
    local rollsNum = rollsStr and tonumber((rollsStr:gsub(",", ""))) or nil
    
    return clan:upper():gsub("%s+", ""), rarity:upper(), rollsNum, rText
end

local function sendWebhook(clan, rarity, rolls)
    if WEBHOOK_URL == "" then return end
    local data = {
        ["content"] = "🎉 **Auto Roll Success!**",
        ["embeds"] = {{
            ["title"] = "✅ Clan: " .. clan .. " (" .. rarity .. ")",
            ["description"] = "Rolls còn lại: " .. tostring(rolls),
            ["color"] = 65280
        }}
    }
    pcall(function() http:PostAsync(WEBHOOK_URL, http:JSONEncode(data)) end)
end

-- [[ MAIN LOOP ]] --
print("🚀 Script GitHub đã chạy. Đang đợi đúng mục tiêu...")

while true do
    local clanName, rarity, rollsLeft, rawRollText = parseInfo()

    -- 1. KIỂM TRA ĐIỀU KIỆN DỪNG ĐẶC BIỆT (Hard Stop)
    if clanName == "FRITZ" or clanName == "HELOS" then
        print("🏆 TRÚNG CLAN SIÊU HIẾM: " .. clanName)
        sendWebhook(clanName, rarity, rollsLeft or "Unknown")
        break
    end

    -- 2. KIỂM TRA CLAN MỤC TIÊU
    local isTarget = false
    for _, t in ipairs(TARGET_CLANS) do
        if clanName == t:upper() then isTarget = true break end
    end

    if isTarget then
        print("✅ ĐÃ TÌM THẤY MỤC TIÊU: " .. clanName)
        sendWebhook(clanName, rarity, rollsLeft or "Unknown")
        break
    end

    -- 3. KIỂM TRA HẾT LƯỢT (Chỉ dừng khi text chứa chữ ROLL và số là 0)
    if rollsLeft == 0 and rawRollText:find("ROLL") then
        warn("❌ Hết lượt Roll!")
        break
    end

    -- 4. XỬ LÝ WARNING PROMPT (Yes/No)
    -- Nếu trúng Epic/Legendary không phải mục tiêu hoặc bảng Warning hiện lên
    if isVisible(warningPrompt.Main) or rarity:find("EPIC") or rarity:find("LEGEND") then
        local yesBtn = warningPrompt.Main:FindFirstChild("Yes")
        if yesBtn and isVisible(yesBtn) then
            print("⚠️ Bỏ qua Clan hiếm (" .. rarity .. ") để roll tiếp...")
            smartClick(yesBtn)
            task.wait(0.5)
        end
    end

    -- 5. THỰC HIỆN ROLL
    -- Nếu text đang là "." ".." "..." (đang roll) thì đợi, không bấm tiếp
    if not rawRollText:find("%.%.%.") then
        print("🎲 Rolling... (Clan: " .. clanName .. " | Lượt: " .. (rollsLeft or "...") .. ")")
        smartClick(rollTitle) -- Click thẳng vào Title của Button như bạn yêu cầu
    end

    task.wait(DELAY_BETWEEN_ROLLS)
end

print("🏁 Script kết thúc.")
