local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- ================= CẤU HÌNH VIP =================
local CONFIG = {
    COMBO_DIST = 5.5,        -- Tầm đánh M1 tối ưu
    DASH_DIST = 18,          -- Tầm lướt
    SAFE_DIST = 25,          -- Tầm vờn quanh đối thủ
    PERFECT_BLOCK = 90,      -- 90% tỷ lệ đỡ đòn hoàn hảo (Instant Input)
    AWAKEN_HEALTH_PCT = 30,  -- Bật nộ khi máu dưới 30%
    FLEE_HEALTH_PCT = 15,    -- Bỏ chạy/Né liên tục khi máu dưới 15%
}

-- Hệ thống quản lý Combo & Cooldown
local CombatState = {
    M1_Step = 1,
    LastM1 = 0,
    Skills = {
        [1] = {Key = Enum.KeyCode.One, LastUsed = 0, Cooldown = 15},
        [2] = {Key = Enum.KeyCode.Two, LastUsed = 0, Cooldown = 20},
        [3] = {Key = Enum.KeyCode.Three, LastUsed = 0, Cooldown = 25}
    }
}

-- ================= HÀM HỖ TRỢ =================

-- Giả lập phím bấm (Instant Input)
local function tapKey(key)
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.02) -- Tốc độ nhả phím cực nhanh
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

-- Kiểm tra trạng thái bất khả xâm phạm (I-Frame / Ragdoll)
local function isInvincible(character)
    if not character then return true end
    local hum = character:FindFirstChild("Humanoid")
    -- TSB thường dùng PlatformStand khi bị knockback/ragdoll
    if hum and (hum.PlatformStand or hum.Sit or hum:GetState() == Enum.HumanoidStateType.Physics) then
        return true
    end
    -- Check ForceField (Nếu game dùng)
    if character:FindFirstChildOfClass("ForceField") then return true end
    return false
end

-- Tìm mục tiêu tối ưu nhất
local function getBestTarget()
    local bestDist, target = math.huge, nil
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChild("Humanoid")
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 and not isInvincible(plr.Character) then
                local dist = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    target = plr.Character
                end
            end
        end
    end
    return target, bestDist
end

-- ================= LOGIC CHIẾN ĐẤU =================

local function executeGodCombo()
    local now = tick()
    
    -- Delay giữa các đòn M1 (0.4s là nhịp chuẩn của TSB)
    if now - CombatState.LastM1 > 0.4 then
        if CombatState.M1_Step <= 3 then
            -- Tung 3 hit M1
            tapKey(Enum.KeyCode.ButtonL2) -- Hoặc mouse1click() nếu dùng exploit executor
            CombatState.M1_Step = CombatState.M1_Step + 1
            CombatState.LastM1 = now
        else
            -- Hit thứ 4: Thay vì M1 chốt, xài Skill để nối combo
            local skillUsed = false
            for i = 1, 3 do
                if now - CombatState.Skills[i].LastUsed > CombatState.Skills[i].Cooldown then
                    tapKey(CombatState.Skills[i].Key)
                    CombatState.Skills[i].LastUsed = now
                    skillUsed = true
                    break
                end
            end
            
            if not skillUsed then
                -- Nếu hết chiêu, đấm hit 4 để đẩy lùi
                tapKey(Enum.KeyCode.ButtonL2)
            end
            
            CombatState.M1_Step = 1 -- Reset chuỗi
            CombatState.LastM1 = now + 0.5 -- Nghỉ một nhịp sau khi kết thúc chuỗi
        end
    end
end

-- ================= VÒNG LẶP CHÍNH =================

RunService.Heartbeat:Connect(function(deltaTime)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    local hum = char.Humanoid

    local myHealthPct = (hum.Health / hum.MaxHealth) * 100

    -- Auto Awakening (Phím G)
    if myHealthPct <= CONFIG.AWAKEN_HEALTH_PCT then
        tapKey(Enum.KeyCode.G)
    end

    local enemy, dist = getBestTarget()
    
    if not enemy then 
        -- Nếu không có mục tiêu hợp lệ (địch chết hoặc đang ragdoll), thả block và dừng lại
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        return 
    end
    
    local enemyRoot = enemy.HumanoidRootPart
    local enemyHum = enemy.Humanoid

    -- 1. HARD CFRAME LOCK (Nhưng Smooth để không giật lag)
    local targetLook = CFrame.new(root.Position, Vector3.new(enemyRoot.Position.X, root.Position.Y, enemyRoot.Position.Z))
    -- Tốc độ xoay nội suy: Càng gần xoay càng nhanh để bám mục tiêu
    local turnSpeed = math.clamp(1 / dist, 0.1, 0.8) 
    root.CFrame = root.CFrame:Lerp(targetLook, turnSpeed)

    -- 2. ĐỌC TÌNH HUỐNG & ĐỠ ĐÒN (Instant Input Block)
    local isDanger = false
    for _, anim in pairs(enemyHum:GetPlayingAnimationTracks()) do
        local animName = anim.Name:lower()
        if animName:match("attack") or animName:match("skill") or animName:match("punch") or animName:match("kick") then
            isDanger = true
            break
        end
    end

    if isDanger and dist <= CONFIG.DASH_DIST then
        if math.random(1, 100) <= CONFIG.PERFECT_BLOCK then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
            return -- Khi đang đỡ thì không di chuyển hay đánh
        end
    else
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    end

    -- 3. DI CHUYỂN CHIẾN THUẬT KẾT HỢP
    if myHealthPct <= CONFIG.FLEE_HEALTH_PCT then
        -- Trạng thái: Sinh tồn (Lướt lùi hoặc đi xa ra)
        local fleePos = root.Position + (root.Position - enemyRoot.Position).Unit * 20
        hum:MoveTo(fleePos)
        if math.random(1, 40) == 1 then tapKey(Enum.KeyCode.Q) end -- Spam lướt để chạy
        
    elseif dist > CONFIG.SAFE_DIST then
        -- Chế độ: Đi bộ áp sát
        hum:MoveTo(enemyRoot.Position)
        
    elseif dist <= CONFIG.SAFE_DIST and dist > CONFIG.DASH_DIST then
        -- Chế độ: Orbiting (Đi vòng tròn)
        local timeSec = tick() * 1.5
        local orbitOffset = Vector3.new(math.cos(timeSec) * 15, 0, math.sin(timeSec) * 15)
        hum:MoveTo(enemyRoot.Position + orbitOffset)
        
    elseif dist <= CONFIG.DASH_DIST and dist > CONFIG.COMBO_DIST then
        -- Chế độ: Nhào vô (Dash In)
        hum:MoveTo(enemyRoot.Position)
        if not isDanger and math.random(1, 30) == 1 then
            tapKey(Enum.KeyCode.Q) -- Lướt tới khi an toàn
        end

    elseif dist <= CONFIG.COMBO_DIST then
        -- Chế độ: Xẻ thịt (Cận chiến)
        hum:MoveTo(root.Position) -- Đứng tấn vững vàng
        executeGodCombo()
    end
end)

