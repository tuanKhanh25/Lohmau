-- [[ SCRIPT HACK VIP PRO MAX - BY TUẤN KHANH ]] --
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

-- Thông báo khởi động cực uy tín
StarterGui:SetCore("SendNotification", {
	Title = "HACK BY TUẤN KHANH",
	Text = "Đang kết nối Server... Bypass Anti-Cheat thành công!",
	Icon = "rbxassetid://6034503042",
	Duration = 5
})

task.wait(3)

-- Tạo một cái bảng hỏi đáp giả cho kịch tính
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 400, 0, 200)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -100)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 2
mainFrame.Parent = screenGui

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0.6, 0)
label.Text = "Hệ thống phát hiện tài khoản này đang nhận hỗ trợ từ Tuấn Khanh.\nBạn có đồng ý kích hoạt Mode Hack Toàn Năng không?"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.BackgroundTransparency = 1
label.TextWrapped = true
label.Font = Enum.Font.SourceSansBold
label.TextSize = 18
label.Parent = mainFrame

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0.4, 0, 0.2, 0)
btn.Position = UDim2.new(0.3, 0, 0.7, 0)
btn.Text = "CÓ, KÍCH HOẠT NGAY"
btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Parent = mainFrame

-- Khi nó bấm vào nút "CÓ"
btn.MouseButton1Click:Connect(function()
    label.Text = "Đang hack dữ liệu Roblox... Vui lòng không thoát game..."
    btn.Visible = false
    task.wait(3)
    
    -- Cú chốt hạ kinh điển
    local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
    player:Kick("\n\n[ADMINISTRATOR SYSTEM]\n\nUsername: " .. player.Name .. "\nBanned by: Tuấn Khanh Security\n\nReason: Bạn đã bị lừa! Đừng có hack nữa nhé bạn hiền.\nHardware ID: " .. hwid .. "\n\nNote: Tài khoản của bạn đã vào danh sách đen của Tuấn Khanh.")
end)
