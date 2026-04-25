local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

---------------------------------------------------
-- PHẦN 1: KÍCH HOẠT ENGINE TƯƠNG LAI (MÓNG NHÀ ĐẸP)
---------------------------------------------------
-- Ép Roblox dùng Future Lighting với đổ bóng thời gian thực chính xác
settings().Rendering.GraphicsMode = Enum.GraphicsMode.Direct3D11 -- Ép dùng DX11 (nếu Cloud hỗ trợ)
Lighting.Technology = Enum.Technology.Future
Lighting.ShadowSoftness = 0 -- Đổ bóng sắc nét đến từng milimet
Lighting.EnvironmentDiffuseScale = 1 -- Phản chiếu ánh sáng môi trường max
Lighting.EnvironmentSpecularScale = 1 -- Kim loại, mồ hôi, máu bóng loáng
Lighting.GlobalShadows = true

---------------------------------------------------
-- PHẦN 2: POST-PROCESSING SIÊU CẤP (VIBE ANIME)
---------------------------------------------------

-- 1. Bloom (Độ lóa): Làm skill, hiệu ứng rực rỡ như phim Makoto Shinkai
local bloom = Lighting:FindFirstChild("CryBloom") or Instance.new("BloomEffect", Lighting)
bloom.Name = "CryBloom"
bloom.Intensity = 0.8 -- Cực mạnh
bloom.Size = 56 -- Tỏa rộng
bloom.Threshold = 0.7 -- Chỉ skill mạnh mới lóa

-- 2. ColorCorrection (Màu sắc): Màu sắc tươi, độ tương phản cao đặc trưng Anime
local cc = Lighting:FindFirstChild("CryColor") or Instance.new("ColorCorrectionEffect", Lighting)
cc.Name = "CryColor"
cc.Brightness = 0.1
cc.Contrast = 0.35 -- Tương phản cực cao
cc.Saturation = 0.25 -- Màu sắc rực rỡ
cc.TintColor = Color3.fromRGB(255, 250, 240) -- Tone nắng ấm nghệ thuật

-- 3. DepthOfField (Nhiếp ảnh): Xóa phông làm nổi bật Model
local dof = Lighting:FindFirstChild("CryDoF") or Instance.new("DepthOfFieldEffect", Lighting)
dof.Name = "CryDoF"
dof.FarIntensity = 1
dof.FocusDistance = 25 -- Luôn nét ở khoảng cách combat
dof.InFocusRadius = 50
dof.NearIntensity = 0.5 -- Xóa mờ nhẹ phần trước mặt

-- 4. SunRays (Tia nắng): Thêm các tia nắng "Phật quang"
local sun = Lighting:FindFirstChild("CrySun") or Instance.new("SunRaysEffect", Lighting)
sun.Name = "CrySun"
sun.Intensity = 0.1 -- Không quá chói
sun.Spread = 1 -- Tia nắng tỏa rộng

-- 5. Blur (Làm mờ chuyển động): Tăng độ mượt khi combo
local blur = Lighting:FindFirstChild("CryBlur") or Instance.new("BlurEffect", Lighting)
blur.Name = "CryBlur"
blur.Size = 2 -- Mờ nhẹ khi quay camera

---------------------------------------------------
-- PHẦN 3: ĐỘT PHÁ MÔ HÌNH (MAKE MODEL BEAUTIFUL)
---------------------------------------------------
-- Phần này sẽ quét mọi Model và Parts trong game để áp dụng chất liệu siêu cấp

local function beautifyCharacter(char)
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            -- 1. Khử bóng khối: Làm bề mặt nhân vật mịn màng, giống da anime
            part.CastShadow = false -- Tắt shadow mặc định của part để dùng Shadow của Future
            
            -- 2. Thêm độ phản chiếu nhẹ (Giả lập da mịn)
            if part.Name == "Head" or part.Name:match("Arm") or part.Name:match("Leg") or part.Name == "Torso" then
                part.Material = Enum.Material.SmoothPlastic
                part.Reflectance = 0.05 -- Phản chiếu ánh sáng nhẹ để nhìn không bị "lì"
            end
            
            -- 3. Tạo Outline (Viền nhân vật) - Chỉ có Anime mới có
            -- Kỹ thuật này ngốn CPU Cloud kinh khủng nhất
            if not part:FindFirstChild("SelectionHighlight") then
                local highlight = Instance.new("Highlight", part)
                highlight.FillTransparency = 1 -- Chỉ giữ Outline
                highlight.OutlineColor = Color3.fromRGB(0, 0, 0) -- Viền đen
                highlight.OutlineTransparency = 0.5 -- Viền mờ nhẹ
            end
        end
    end
end

-- Áp dụng cho người chơi hiện tại
if game.Players.LocalPlayer.Character then
    beautifyCharacter(game.Players.LocalPlayer.Character)
end

-- Tự động áp dụng khi người chơi respawn
game.Players.LocalPlayer.CharacterAdded:Connect(beautifyCharacter)

-- Quét môi trường xung quanh (Optional: rất nặng)
local function beautifyEnvironment()
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Material == Enum.Material.Grass then
            -- Làm cỏ nhìn chân thực hơn
            part.Material = Enum.Material.DiamondPlate -- Hack texture để tạo khối cỏ sắc nét
            part.Color = Color3.fromRGB(50, 150, 50)
        end
    end
end
-- beautifyEnvironment() -- Uncomment dòng này nếu muốn Map cũng khóc theo

---------------------------------------------------
-- PHẦN 4: HỆ THỐNG NÂNG CẤP ĐỊA HÌNH & NƯỚC VIP
---------------------------------------------------
if Terrain then
    Terrain.WaterReflectance = 1 -- Phản chiếu bóng người như gương
    Terrain.WaterTransparency = 0 -- Nước trong vắt, thấy đáy
    Terrain.WaterWaveSize = 0.05 -- Sóng nhỏ, lăn tăn cinematic
    Terrain.WaterWaveSpeed = 0.5 -- Sóng chậm nhẹ nhàng
end

-- Ép Roblox đồ họa mức cao nhất
settings().Rendering.QualityLevel = Enum.QualityLevel.Level21 -- Ép lên mức Ultra 21
game:GetService("GuiService"):SetGlobalGuiInset(0,0,0,0) -- Full màn hình

print(">>> SIÊU SCRIPT ANIME VIP ĐÃ KÍCH HOẠT. MÁY CLOUD, KHÓC ĐI! <<<")
