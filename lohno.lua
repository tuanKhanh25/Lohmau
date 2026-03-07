--[[ 
    TUAN KHANH HUB - DOOMSDAY EDITION
    MỤC ĐÍCH: TRỊ BỆNH SÀI HACK CỦA BẠN BÈ
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- Dọn dẹp GUI cũ
if CoreGui:FindFirstChild("TK_Doomsday") then
    CoreGui.TK_Doomsday:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TK_Doomsday"
ScreenGui.Parent = CoreGui
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999999

local Background = Instance.new("Frame")
Background.Size = UDim2.new(1, 0, 1, 0)
Background.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Background.Parent = ScreenGui

local Terminal = Instance.new("TextLabel")
Terminal.Size = UDim2.new(0.9, 0, 0.9, 0)
Terminal.Position = UDim2.new(0.05, 0, 0.05, 0)
Terminal.BackgroundTransparency = 1
Terminal.Font = Enum.Font.Code
Terminal.TextColor3 = Color3.fromRGB(0, 255, 0)
Terminal.TextSize = 16
Terminal.TextXAlignment = Enum.TextXAlignment.Left
Terminal.TextYAlignment = Enum.TextYAlignment.Top
Terminal.Text = ""
Terminal.Parent = Background

-- Âm thanh
local Siren = Instance.new("Sound")
Siren.SoundId = "rbxassetid://138081509" -- Còi báo động
Siren.Looped = true
Siren.Volume = 2
Siren.Parent = Background

local GlitchSound = Instance.new("Sound")
GlitchSound.SoundId = "rbxassetid://833058091" -- Tiếng nhiễu sóng
GlitchSound.Volume = 3
GlitchSound.Parent = Background

-- Hàm gõ chữ từ từ
local function typeWriter(text, color, delayTime)
    Terminal.TextColor3 = color or Color3.fromRGB(0, 255, 0)
    for i = 1, #text do
        Terminal.Text = Terminal.Text .. text:sub(i,i)
        task.wait(delayTime or 0.01)
    end
    Terminal.Text = Terminal.Text .. "\n"
end

-- Hiệu ứng rung camera cực mạnh
local function shakeCamera()
    RunService.RenderStepped:Connect(function()
        local x = math.random(-2, 2)
        local y = math.random(-2, 2)
        local z = math.random(-2, 2)
        Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
    end)
end

-- TIẾN TRÌNH KỊCH BẢN
task.spawn(function()
    -- [PHẦN 1: MỒI NHỬ]
    typeWriter("> [TUẤN KHANH HUB] V4.0 PREMIUM INITIALIZED...", Color3.fromRGB(0, 255, 255))
    task.wait(1)
    typeWriter("> Bypassing Anti-Cheat... [SUCCESS]")
    typeWriter("> Injecting Fast Attack Module... [SUCCESS]")
    typeWriter("> Loading Auto Farm Logic... [SUCCESS]")
    task.wait(2)
    typeWriter("> Executing Main Thread...")
    task.wait(1.5)

    -- [PHẦN 2: LẬT MẶT]
    GlitchSound:Play()
    Background.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
    typeWriter("\nFATAL ERROR: BYFRON KERNEL-LEVEL DETECTED INJECTION!", Color3.fromRGB(255, 0, 0))
    task.wait(1)
    Siren:Play()
    shakeCamera() -- Bắt đầu rung màn hình
    
    for i = 1, 5 do
        Background.BackgroundColor3 = (i % 2 == 0) and Color3.fromRGB(150, 0, 0) or Color3.fromRGB(0, 0, 0)
        task.wait(0.2)
    end
    Background.BackgroundColor3 = Color3.fromRGB(10, 0, 0)

    typeWriter("\n[ROBLOX SECURITY]: UNAUTHORIZED EXPLOIT FOUND IN MEMORY.", Color3.fromRGB(255, 50, 50))
    typeWriter(">> LOCKING SYSTEM TO PREVENT DAMAGE...", Color3.fromRGB(255, 0, 0))
    task.wait(2)

    -- Đọc thông tin giả để hù dọa
    local fakeIP = "113.190." .. math.random(10, 250) .. "." .. math.random(10, 250)
    local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
    
    typeWriter("\n[EXTRACTING USER DATA...]")
    task.wait(1)
    typeWriter("-> Username: " .. Players.LocalPlayer.Name, Color3.fromRGB(200, 200, 200))
    typeWriter("-> IP Address: " .. fakeIP, Color3.fromRGB(200, 200, 200))
    typeWriter("-> Hardware ID: " .. hwid, Color3.fromRGB(200, 200, 200))
    task.wait(2)
    
    -- [PHẦN 3: ĐÒN CHÍ MẠNG]
    typeWriter("\n[!] WARNING: EXPLOIT HAS CORRUPTED GAME FILES.", Color3.fromRGB(255, 100, 0))
    typeWriter(">> INITIATING COUNTER-MEASURES...", Color3.fromRGB(255, 100, 0))
    task.wait(2)
    
    typeWriter("\n[SYSTEM]: ACCESSING WEBCAM TO CAPTURE CHEATER'S FACE...", Color3.fromRGB(255, 0, 255))
    task.wait(2)
    typeWriter("-> Webcam Access: GRANTED. Image captured and sent to Roblox HQ.", Color3.fromRGB(255, 0, 255))
    task.wait(2)

    typeWriter("\n[SYSTEM]: DELETING EXPLOIT TRACES FROM OPERATING SYSTEM...", Color3.fromRGB(255, 255, 0))
    task.wait(1)
    
    -- Dọa xóa file hệ thống
    for i = 1, 15 do
        typeWriter("Deleting C:\\Windows\\System32\\dllcache\\module_"..math.random(1000,9999)..".sys ... [OK]", Color3.fromRGB(100, 100, 100), 0.05)
    end
    
    task.wait(1)
    typeWriter("\n[CRITICAL]: WINDOWS OS CORRUPTION IMMINENT.", Color3.fromRGB(255, 0, 0))
    typeWriter("DO NOT TURN OFF YOUR PC. SYSTEM PURGE IN PROGRESS.", Color3.fromRGB(255, 0, 0))
    
    -- Đếm ngược cuối cùng
    for i = 15, 1, -1 do
        Terminal.Text = Terminal.Text .. "\nPURGE IN: " .. i .. " SECONDS"
        task.wait(1)
    end
    
    -- Kick cực gắt
    Players.LocalPlayer:Kick("\n🚨 HỆ THỐNG TUẤN KHANH ĐÃ KHÓA THIẾT BỊ 🚨\n\nPhát hiện sử dụng phần mềm thứ 3.\nWebcam và IP của bạn đã được ghi nhận.\nHệ điều hành đang tự động gỡ bỏ file rác. Vui lòng kiểm tra lại máy tính!")
end)

-- Khóa toàn bộ phím và màn hình
game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Escape then
        -- Chặn nút ESC
    end
end)
