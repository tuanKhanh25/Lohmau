--[[
    ╔══════════════════════════════════════════════╗
    ║        TUAN KHANH HUB - SECURITY SYSTEM      ║
    ║   ANTI-EXPLOIT PROTOCOL: ACTIVATED           ║
    ╚══════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

-- Tạo giao diện bao phủ toàn bộ
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TuanKhanh_Security"
ScreenGui.Parent = CoreGui
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999999

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 150) -- Màu xanh BSOD
MainFrame.Parent = ScreenGui

-- Hiệu ứng nhiễu màn hình (Glitch)
local function Glitch()
    task.spawn(function()
        while true do
            MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, math.random(100, 200))
            task.wait(0.05)
        end
    end)
end

-- Âm thanh báo động
local Alarm = Instance.new("Sound")
Alarm.SoundId = "rbxassetid://138081509" -- Tiếng còi hú
Alarm.Looped = true
Alarm.Parent = MainFrame
Alarm:Play()

-- Nội dung log hệ thống
local Console = Instance.new("TextLabel")
Console.Size = UDim2.new(0.9, 0, 0.8, 0)
Console.Position = UDim2.new(0.05, 0, 0.05, 0)
Console.BackgroundTransparency = 1
Console.Font = Enum.Font.Code
Console.TextColor3 = Color3.fromRGB(255, 255, 255)
Console.TextSize = 18
Console.TextXAlignment = Enum.TextXAlignment.Left
Console.TextYAlignment = Enum.TextYAlignment.Top
Console.Text = ""
Console.Parent = MainFrame

local lines = {
    "[!] INTERNAL ERROR: Memory Corruption at 0x00045F",
    "[!] SECURITY: Unauthorized Executor Detected.",
    "> Scanning User: " .. Players.LocalPlayer.Name,
    "> Hardware ID: " .. game:GetService("RbxAnalyticsService"):GetClientId(),
    "> Status: PERMANENT BAN INITIATED.",
    "> Deleting Scripts... [OK]",
    "> Corrupting Exploit Data... [OK]",
    "> SENDING DEVICE SNAPSHOT TO ROBLOX HQ...",
    "-------------------------------------------",
    "BY TUAN KHANH SYSTEM: DO NOT TURN OFF PC",
    "SYSTEM LOCK: 100%"
}

-- Chạy chữ
task.spawn(function()
    for _, line in ipairs(lines) do
        for i = 1, #line do
            Console.Text = Console.Text .. line:sub(i,i)
            task.wait(0.01)
        end
        Console.Text = Console.Text .. "\n"
        task.wait(0.3)
    end
    
    task.wait(1)
    Glitch()
    
    -- Hiện màn hình xanh chết chóc (Fake BSOD)
    MainFrame.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
    Console.Visible = false
    
    local BSOD = Instance.new("TextLabel")
    BSOD.Size = UDim2.new(1, 0, 1, 0)
    BSOD.BackgroundTransparency = 1
    BSOD.Font = Enum.Font.SourceSans
    BSOD.Text = ":(\n\nYour PC ran into a problem and needs to restart.\nWe're just collecting some error info, and then we'll restart for you.\n\n100% Complete\n\nFor more information about this issue and possible fixes, visit:\nhttps://www.roblox.com/stop-hacking-bro\n\nStop Code: EXPLOIT_DETECTED_BY_TUAN_KHANH"
    BSOD.TextColor3 = Color3.fromRGB(255, 255, 255)
    BSOD.TextSize = 30
    BSOD.Parent = MainFrame
    
    task.wait(5)
    Players.LocalPlayer:Kick("Hệ thống bảo mật Tuấn Khanh đã khóa tài khoản này. Lý do: Sử dụng hack trái phép.")
end)

-- Khóa toàn bộ GUI gốc của game
game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
