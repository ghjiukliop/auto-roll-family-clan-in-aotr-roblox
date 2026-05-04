local g = game.GameId
local p = game.PlaceId

print("Universe ID: " .. tostring(g))
print("Place ID: " .. tostring(p))

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "ID Logged",
    Text = "Universe: " .. g .. "\nPlace: " .. p,
    Duration = 5
})

-- Conditional logic based on Place ID
if p == 13379208636 then
    print("Running PART 1 (Slot Selection)")

elseif p == 14916516914 then
    print("Running PART 2 (Boost Timer)")
else
    print("Place ID not matched for Part 1 or Part 2, proceeding to Part 3") 
end

-- phan 1
if p == 13379208636 then
local player = game:GetService("Players").LocalPlayer
local vim = game:GetService("VirtualInputManager")
local http = game:GetService("HttpService")

local delayTime = 1

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

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local playerGui = player:WaitForChild("PlayerGui", 999)
local interface = playerGui:WaitForChild("Interface", 999)
local titleScreen = interface:WaitForChild("Title_Screen", 999)

-- 1. Chọn Slot A
local slotA = titleScreen:WaitForChild("Slots", 999):WaitForChild("A", 999):WaitForChild("Select_A", 999)
print("--- Dang cho Slot A san sang ---")
repeat task.wait(1) until isReallyVisible(slotA)

clickPhysicalButton(slotA)
task.wait(2)

-- 2. Thao tác phím ban đầu
print("--- Bat dau thuc hien phim ---")
pressKey(Enum.KeyCode.BackSlash)
for i = 1, 3 do
    pressKey(Enum.KeyCode.Down)
end
pressKey(Enum.KeyCode.Return)

task.wait(3)

-- 3. Logic: Click Play -> Warning No -> Play -> Enter
local playBtn = waitAndGetClickable(titleScreen.Buttons, "Play")

if playBtn then
    print("--- Click vao Play lan 1 ---")
    clickPhysicalButton(playBtn)
    
    local warningFrame = interface:WaitForChild("Warning", 10)
    if warningFrame then
        local noBtn = waitAndGetClickable(warningFrame.Prompt.Main, "No")
        if noBtn then
            print("--- Thay bang Warning, dang click No ---")
            task.wait(1)
            clickPhysicalButton(noBtn)
            
            task.wait(2)
            print("--- Dang click vao Play lan 2 ---")
            clickPhysicalButton(playBtn)
            
            -- ĐOẠN CẬP NHẬT MỚI CỦA BẠN:
            task.wait(1) -- Chờ thêm 1 giây
            print("--- Dang nhan phim Return (Enter) ---")
            pressKey(Enum.KeyCode.Return)
        end
    end
else
    print("--- Khong tim thay nut Play ---")
end

print("--- Hoan thanh quy trinh ---")
end -- End of Part 1

-- phan 2 
if p == 14916516914 then
task.wait(60)

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local pGui = player:WaitForChild("PlayerGui")
local Y_OFFSET = 58

local function saveBoostTimer(endTime)
    local success = pcall(function() writefile("boost_timer.txt", tostring(endTime)) end)
    if success then
        print("Boost timer saved: " .. os.date("%H:%M:%S", endTime))
    end
end

local function extractAndSaveBoostTime(boostElement)
    local path = boostElement:FindFirstChild("Title")
    if path then
        local txt = path.ContentText
        local m, s = txt:match("(%d+):(%d+)")
        if m and s then
            local duration = (tonumber(m) * 60) + tonumber(s)
            local endTime = os.time() + duration
            saveBoostTimer(endTime)
            print("--- Boost Info ---")
            print("Duration: " .. m .. "m " .. s .. "s")
            print("End Time: " .. os.date("%H:%M:%S", endTime))
            return true
        end
    end
    return false
end

    -------------------------------------------------------------------------
    -- 1. DỊCH CHUYỂN ĐẾN TỌA ĐỘ ĐƯỢC LƯU
    -------------------------------------------------------------------------
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(223.36, 6.25, 51.28)
    end
    task.wait(1)

    -------------------------------------------------------------------------
    -- 2. CLICK VÀO MISSIONS
    -------------------------------------------------------------------------
    local missionsBtn = pGui:WaitForChild("Interface"):WaitForChild("Missions"):WaitForChild("Prompt"):WaitForChild("Selection"):WaitForChild("Missions")
    
    if missionsBtn and missionsBtn.Visible then
        local x = missionsBtn.AbsolutePosition.X + (missionsBtn.AbsoluteSize.X / 2)
        local y = missionsBtn.AbsolutePosition.Y + (missionsBtn.AbsoluteSize.Y / 2) + Y_OFFSET
        
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end
    task.wait(1.5) -- Đợi giao diện Mission hiện ra

    -------------------------------------------------------------------------
    -- 3. TÌM MAP CÓ BOOST REWARD
    -------------------------------------------------------------------------
    local missionsFolder = pGui.Interface.Missions
    local mapsContainer = missionsFolder.Missions.Main.Maps.Maps
    local mapList = {"Chapel_Missions", "Docks_Missions", "Forest_Missions", "Outskirts_Missions", "Shiganshina_Missions", "Stohess_Missions", "Trost_Missions", "Utgard_Missions"}
    local boostFound = false
    local boostElement = nil
    
    for _, name in ipairs(mapList) do
        local map = mapsContainer:FindFirstChild(name)
        if map and map:FindFirstChild("Boost") then
            boostElement = map:FindFirstChild("Boost")
            local mx = map.AbsolutePosition.X + (map.AbsoluteSize.X / 2)
            local my = map.AbsolutePosition.Y + (map.AbsoluteSize.Y / 2) + Y_OFFSET
            
            -- Click chọn map có boost
            VirtualInputManager:SendMouseButtonEvent(mx, my, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(mx, my, 0, false, game, 1)
            
            boostFound = true
            break
        end
    end

    if not boostFound then return end -- Dừng nếu không có boost
    task.wait(0.5)

    -- Extract and save boost timer if found
    if boostFound and boostElement then
        task.wait(1)
        extractAndSaveBoostTime(boostElement)
    end

    -------------------------------------------------------------------------
    -- 4. NHẤN VÀO CREATE (Creation_Missions)
    -------------------------------------------------------------------------
    local creationBtn = missionsFolder.Missions.Main.Info.Main.Buttons:WaitForChild("Creation_Missions")
    
    if creationBtn and creationBtn.Visible then
        local cx = creationBtn.AbsolutePosition.X + (creationBtn.AbsoluteSize.X / 2)
        local cy = creationBtn.AbsolutePosition.Y + (creationBtn.AbsoluteSize.Y / 2) + Y_OFFSET
        
        VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
    end

    print("--- Pipeline hoàn tất! ---")

-- [BƯỚC 5] Click vào nút để mở bảng Modifiers
    local modInfo = pGui:WaitForChild("Interface"):WaitForChild("Missions"):WaitForChild("Info"):WaitForChild("Main"):WaitForChild("Info")
    local openModifiersBtn = modInfo:WaitForChild("Modifiers"):WaitForChild("Modifiers_Buttons")
    humanClick(openModifiersBtn)

    task.wait(0.5)

-- [BƯỚC 6] Vòng lặp chọn Modifiers
    local options = modInfo:WaitForChild("Modifiers"):WaitForChild("Options")
    local modifierNames = {
        "Grid", "Boring", "Chronic Injuries", "Fog", "Glass Cannon", 
        "Injury Prone", "Nightmare", "No Memories", "No Perks", 
        "No Skills", "Oddball", "Simple", "Time Trial"
    }

    for _, modName in ipairs(modifierNames) do
        local targetMod = nil
        for _, child in ipairs(options:GetChildren()) do
            if child.Name == modName and child:IsA("GuiObject") then
                targetMod = child
                break
            end
        end
        
        if targetMod then
            if options:IsA("ScrollingFrame") then
                local targetY = targetMod.AbsolutePosition.Y - options.AbsolutePosition.Y + options.CanvasPosition.Y
                options.CanvasPosition = Vector2.new(0, targetY - (options.AbsoluteSize.Y / 3)) 
                task.wait(0.1)
            end
            local clickTarget = targetMod:FindFirstChild("Interact") or targetMod
            humanClick(clickTarget)
        end
    end

-- [BƯỚC 7] Click nút Return để đóng bảng Modifiers
    local returnBtn = modInfo:WaitForChild("Modifiers"):WaitForChild("Modifiers_Buttons"):WaitForChild("Modifiers_Return")
    humanClick(returnBtn)

    task.wait(0.5)

-- [BƯỚC 8] Click nút Begin để bắt đầu Mission
    local beginBtn = missionsFolder:WaitForChild("Info"):WaitForChild("Main"):WaitForChild("Info"):WaitForChild("Main"):WaitForChild("Info_Buttons"):WaitForChild("Begin")
    humanClick(beginBtn)

    print("--- Pipeline Hoàn Tất! ---")
end -- End of Part 2

-- phan 3 - Chạy chỉ khi không ở trong 2 Place ID đặc biệt
if p ~= 13379208636 and p ~= 14916516914 then
print("Running PART 3 (Boost Timer Check)")

task.wait(1)

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local pGui = player:WaitForChild("PlayerGui")

-- Boost Timer Functions
local function checkAndLoadBoostTimer()
    local success, content = pcall(function() return readfile("boost_timer.txt") end)
    if success and content then
        local endTime = tonumber(content)
        if endTime and os.time() < endTime then
            print("Boost still active! Time remaining: " .. (endTime - os.time()) .. " seconds")
            return true
        else
            print("Boost has expired, leaving mission...")
            return false
        end
    end
    return true -- No timer file yet, proceed normally
end

local function isVisible(o)
    local c = o
    while c and c:IsA("GuiObject") do
        if not c.Visible then return false end
        c = c.Parent
    end
    return o.AbsoluteSize.X > 0
end

local function clickLeaveButton()
    print("Waiting for Leave_2 button...")
    local maxWait = 30
    local elapsed = 0
    
    while elapsed < maxWait do
        local b = pGui:FindFirstChild("Interface")
        if b then
            b = b:FindFirstChild("Rewards")
            if b then
                b = b:FindFirstChild("Main")
                if b then
                    b = b:FindFirstChild("Info")
                    if b then
                        b = b:FindFirstChild("Main")
                        if b then
                            b = b:FindFirstChild("Buttons")
                            if b then
                                b = b:FindFirstChild("Leave_2")
                                if b and isVisible(b) then
                                    print("Found Leave_2, spam clicking...")
                                    local clickCount = math.random(2, 7)
                                    print("Clicking " .. clickCount .. " times")
                                    
                                    for i = 1, clickCount do
                                        local x = b.AbsolutePosition.X + (b.AbsoluteSize.X / 2)
                                        local y = b.AbsolutePosition.Y + (b.AbsoluteSize.Y / 2) + 58
                                        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
                                        task.wait(0.05)
                                        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
                                        task.wait(0.1)
                                        print("Click " .. i .. " at: " .. x .. ", " .. y)
                                    end
                                    print("Leave sequence completed")
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.5)
        elapsed = elapsed + 0.5
    end
    
    print("Timeout: Leave_2 button did not appear within " .. maxWait .. " seconds")
end

-- Check if boost has expired
local boostStillActive = checkAndLoadBoostTimer()
if not boostStillActive then
    clickLeaveButton()
end

print("--- Part 3 Completed ---")
end -- End of Part 3
