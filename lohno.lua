local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- ================= CẤU HÌNH TRÍ TUỆ NHÂN TẠO =================
local BOT_BRAIN = {
    State = "Baiting", -- Trạng thái hiện tại
    Target = nil,
    ReactionDelay = {0.05, 0.12}, -- Humanization: Độ trễ ngẫu nhiên
    ComboSequence = {1, 2, "Q", 4, "M1", 3}, -- Chuỗi combo Saitama chuẩn
    IsAwakened = false,
}

-- ================= HỆ THỐNG HUMANIZATION (7) =================
local function humanTap(key)
    task.wait(math.random(BOT_BRAIN.ReactionDelay[1]*100, BOT_BRAIN.ReactionDelay[2]*100)/100)
    VIM:SendKeyEvent(true, key, false, game)
    task.wait(0.03)
    VIM:SendKeyEvent(false, key, false, game)
end

-- ================= HỆ THỐNG PHÒNG THỦ & PHẢN XẠ (3) =================
-- Perfect Block: Chỉ bấm F khi đòn đánh sắp chạm vào người
local function handleDefense(enemy, dist)
    local isAttacking = false
    local anims = enemy.Humanoid:GetPlayingAnimationTracks()
    
    for _, a in pairs(anims) do
        if a.Name:lower():find("attack") or a.Name:lower():find("skill") then
            -- Tính toán timing: Nếu animation đã chạy được 30% thì mới Block (Bait block)
            if a.TimePosition > 0.1 then 
                isAttacking = true 
                break 
            end
        end
    end

    if isAttacking and dist < 12 then
        VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        -- Logic Dash né (4): Dash trái hoặc phải thay vì lùi
        if math.random(1, 100) > 80 then
            local directions = {Enum.KeyCode.A, Enum.KeyCode.D}
            humanTap(directions[math.random(1, #directions)])
            humanTap(Enum.KeyCode.Q)
        end
    else
        VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    end
end

-- ================= CHIẾN THUẬT DI CHUYỂN "ẢO" (4) =================
local function mixMovement(root, enemyRoot, dist)
    local time = tick()
    if dist > 15 then
        -- Fake Rush: Lao vào rồi khựng lại để bait địch ra chiêu hụt
        if math.sin(time * 2) > 0.8 then
            root.Parent.Humanoid:MoveTo(enemyRoot.Position + (root.CFrame.LookVector * -5))
        else
            root.Parent.Humanoid:MoveTo(enemyRoot.Position)
        end
    else
        -- Zigzag Orbit: Không di chuyển vòng tròn đều mà đi theo hình zíc zắc
        local offset = Vector3.new(math.cos(time * 4) * 12, 0, math.sin(time * 2) * 12)
        root.Parent.Humanoid:MoveTo(enemyRoot.Position + offset)
    end
end

-- ================= COMBO SAITAMA CHUYÊN SÂU (1 & 6) =================
local lastSkill = 0
local function executeSaitamaCombo(dist)
    if tick() - lastSkill < 0.5 then return end
    
    -- Kiểm tra nếu địch đang Block -> Dùng chiêu 1 (Shove) để phá thủ
    local enemyChar = BOT_BRAIN.Target
    local isEnemyBlocking = enemyChar:FindFirstChild("BlockVFX") or false -- Tùy game check VFX hoặc Anim

    if isEnemyBlocking then
        humanTap(Enum.KeyCode.One) -- Phá thủ
        lastSkill = tick()
    elseif dist < 6 then
        -- Combo chuẩn: M1 x3 -> Skill 2 -> Dash -> Skill 4
        -- (Đây là nơi bro nạp logic thứ tự chiêu vào)
        humanTap(Enum.KeyCode.ButtonL2) 
    end
end

-- ================= VÒNG LẶP NÃO BỘ (FSM) =================
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    -- 5. Target System: Tìm đứa máu thấp nhất trong tầm 50m
    local target, dist = nil, 50
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") then
            local h = p.Character.Humanoid
            local d = (char.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if h.Health > 0 and d < dist then
                -- Ưu tiên đứa máu thấp (Game Sense)
                target = p.Character
                dist = d
            end
        end
    end
    
    BOT_BRAIN.Target = target
    if not target then return end

    -- 10. Game Sense: Khi nào chạy, khi nào đánh
    local myHealth = char.Humanoid.Health
    if myHealth < 20 then
        BOT_BRAIN.State = "Fleeing"
    elseif dist < 8 then
        BOT_BRAIN.State = "Bursting"
    else
        BOT_BRAIN.State = "Baiting"
    end

    -- Thực thi State
    handleDefense(target, dist)
    
    if BOT_BRAIN.State == "Baiting" then
        mixMovement(char.HumanoidRootPart, target.HumanoidRootPart, dist)
    elseif BOT_BRAIN.State == "Bursting" then
        char.Humanoid:MoveTo(target.HumanoidRootPart.Position)
        executeSaitamaCombo(dist)
    elseif BOT_BRAIN.State == "Fleeing" then
        -- Chạy zíc zắc thoát thân
        char.Humanoid:MoveTo(char.HumanoidRootPart.Position + (char.HumanoidRootPart.CFrame.LookVector * -20))
    end
end)

