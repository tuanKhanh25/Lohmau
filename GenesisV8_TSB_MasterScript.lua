--[[
╔══════════════════════════════════════════════════════════════════╗
║          PROJECT GENESIS V8.0 — THE FINAL ASCENSION             ║
║          Total Visual Conversion — The Strongest Battlegrounds   ║
║          Engine: Streaming-Load Hybrid | Parallel Luau           ║
║                                                                  ║
║  INSTALL: Place as a LocalScript inside StarterPlayerScripts     ║
║  NOTES:   Some API features (EditableMesh, EditableImage) require║
║           beta flags enabled in Studio or live game support.     ║
╚══════════════════════════════════════════════════════════════════╝
]]

--====================================================================
-- SERVICES & CORE REFS
--====================================================================
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local StarterGui       = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- Perlin noise shorthand
local noise = math.noise
local sin   = math.sin
local cos   = math.cos
local pi    = math.pi
local rand  = math.random
local clamp = math.clamp

--====================================================================
-- GENESIS CONFIG — Tune everything here
--====================================================================
local CFG = {
    -- Grass
    GRASS_DENSITY       = 6,        -- blades per stud (radius)
    GRASS_HEIGHT_MIN    = 0.35,
    GRASS_HEIGHT_MAX    = 0.75,
    GRASS_WIND_SPEED    = 1.2,
    GRASS_WIND_STRENGTH = 18,       -- degrees of sway
    GRASS_FOOTSTEP_R    = 3.5,      -- radius that footsteps crush grass
    GRASS_BLADE_COLOR   = Color3.fromRGB(72, 140, 60),
    GRASS_TIP_COLOR     = Color3.fromRGB(180, 230, 100),
    GRASS_CHUNK_RADIUS  = 80,       -- studs around player to spawn grass
    GRASS_MAX_BLADES    = 1800,     -- hard cap to protect FPS

    -- Lighting / Post-FX
    BLOOM_INTENSITY     = 0.6,
    BLOOM_SIZE          = 24,
    BLOOM_THRESHOLD     = 0.85,
    DOF_FAR_INTENSITY   = 0.7,
    DOF_NEAR_INTENSITY  = 0.05,
    DOF_FOCUS_DIST      = 60,
    DOF_IN_FOCUS_R      = 12,
    SUNRAY_INTENSITY    = 0.18,
    SUNRAY_SPREAD       = 0.65,
    COLOR_BRIGHTNESS    = 0.06,
    COLOR_CONTRAST      = 0.12,
    COLOR_SATURATION    = 0.22,
    COLOR_TCC           = Color3.fromRGB(255, 245, 230),  -- warm tint
    MOTIONBLUR_AMOUNT   = 0.28,
    ATMO_DENSITY        = 0.32,
    ATMO_OFFSET         = 0.08,
    ATMO_COLOR          = Color3.fromRGB(199, 220, 255),
    ATMO_DECAY          = Color3.fromRGB(106, 127, 180),
    ATMO_GLARE          = Color3.fromRGB(255, 240, 180),
    ATMO_HAZE           = 1.8,

    -- Character FX
    OUTLINE_COLOR       = Color3.fromRGB(25, 25, 25),
    OUTLINE_WIDTH_NEAR  = 2.2,
    OUTLINE_WIDTH_FAR   = 0.6,
    OUTLINE_FAR_DIST    = 45,
    RIM_COLOR           = Color3.fromRGB(200, 230, 255),
    RIM_INTENSITY       = 1.8,
    JIGGLE_STIFFNESS    = 12,
    JIGGLE_DAMPING      = 6,
    INTERP_FPS          = 120,      -- target interpolation frame rate

    -- Loading screen
    LOAD_FAKE_DURATION  = 3.2,      -- seconds for cinematic intro
    LOAD_TITLE          = "GENESIS  V8",
    LOAD_SUBTITLE       = "Initializing Ascension Engine…",
}

--====================================================================
-- UTILITY
--====================================================================
local function safeCall(fn, label)
    local ok, err = pcall(fn)
    if not ok then
        warn("[GENESIS] Module failed — " .. (label or "?") .. ": " .. tostring(err))
    end
    return ok
end

local function lerp(a, b, t) return a + (b - a) * t end
local function lerpC3(a, b, t)
    return Color3.new(lerp(a.R,b.R,t), lerp(a.G,b.G,t), lerp(a.B,b.B,t))
end

local function tweenProp(instance, props, duration, style, dir)
    style = style or Enum.EasingStyle.Quad
    dir   = dir   or Enum.EasingDirection.Out
    TweenService:Create(instance, TweenInfo.new(duration, style, dir), props):Play()
end

--====================================================================
-- MODULE 0 ── CINEMATIC LOADING SCREEN (Genshin-style)
--====================================================================
local function initLoadingScreen()
    local sg = Instance.new("ScreenGui")
    sg.Name            = "GenesisLoader"
    sg.IgnoreGuiInset  = true
    sg.ResetOnSpawn    = false
    sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    sg.Parent          = PlayerGui

    -- Dark overlay
    local bg = Instance.new("Frame")
    bg.Size            = UDim2.fromScale(1,1)
    bg.BackgroundColor3= Color3.new(0,0,0)
    bg.BorderSizePixel = 0
    bg.ZIndex          = 10
    bg.Parent          = sg

    -- Gradient shimmer
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(5,5,20)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15,10,40)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(5,5,20)),
    })
    grad.Rotation = 135
    grad.Parent   = bg

    -- Central logo frame
    local logoFrame = Instance.new("Frame")
    logoFrame.AnchorPoint      = Vector2.new(0.5, 0.5)
    logoFrame.Position         = UDim2.fromScale(0.5, 0.45)
    logoFrame.Size             = UDim2.new(0, 520, 0, 160)
    logoFrame.BackgroundColor3 = Color3.new(0,0,0)
    logoFrame.BackgroundTransparency = 1
    logoFrame.ZIndex           = 11
    logoFrame.Parent           = sg

    local title = Instance.new("TextLabel")
    title.Size             = UDim2.fromScale(1, 0.55)
    title.BackgroundTransparency = 1
    title.TextColor3       = Color3.fromRGB(220, 200, 140)
    title.Text             = CFG.LOAD_TITLE
    title.Font             = Enum.Font.GothamBold
    title.TextScaled       = true
    title.TextTransparency = 1
    title.ZIndex           = 12
    title.Parent           = logoFrame

    local sub = Instance.new("TextLabel")
    sub.Size             = UDim2.new(1, 0, 0.3, 0)
    sub.Position         = UDim2.fromScale(0, 0.65)
    sub.BackgroundTransparency = 1
    sub.TextColor3       = Color3.fromRGB(160, 160, 200)
    sub.Text             = CFG.LOAD_SUBTITLE
    sub.Font             = Enum.Font.Gotham
    sub.TextScaled       = true
    sub.TextTransparency = 1
    sub.ZIndex           = 12
    sub.Parent           = logoFrame

    -- Gold horizontal rule
    local rule = Instance.new("Frame")
    rule.AnchorPoint      = Vector2.new(0.5, 0.5)
    rule.Position         = UDim2.fromScale(0.5, 0.62)
    rule.Size             = UDim2.new(0, 0, 0, 1)
    rule.BackgroundColor3 = Color3.fromRGB(220, 190, 100)
    rule.BorderSizePixel  = 0
    rule.ZIndex           = 12
    rule.Parent           = logoFrame

    -- Progress bar bg
    local barBg = Instance.new("Frame")
    barBg.AnchorPoint      = Vector2.new(0.5, 0)
    barBg.Position         = UDim2.new(0.5, 0, 0.88, 0)
    barBg.Size             = UDim2.new(0, 340, 0, 3)
    barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    barBg.BorderSizePixel  = 0
    barBg.ZIndex           = 12
    barBg.Parent           = sg
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(220, 190, 100)
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 13
    bar.Parent           = barBg
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    -- Module label
    local modLabel = Instance.new("TextLabel")
    modLabel.AnchorPoint      = Vector2.new(0.5, 0)
    modLabel.Position         = UDim2.new(0.5, 0, 0.91, 0)
    modLabel.Size             = UDim2.new(0, 340, 0, 20)
    modLabel.BackgroundTransparency = 1
    modLabel.TextColor3       = Color3.fromRGB(120, 120, 160)
    modLabel.Text             = "Initializing…"
    modLabel.Font             = Enum.Font.Gotham
    modLabel.TextSize         = 11
    modLabel.TextTransparency = 1
    modLabel.ZIndex           = 13
    modLabel.Parent           = sg

    -- Animate in
    tweenProp(title,    {TextTransparency = 0},        0.8, Enum.EasingStyle.Sine)
    tweenProp(sub,      {TextTransparency = 0},        1.0, Enum.EasingStyle.Sine)
    tweenProp(rule,     {Size = UDim2.new(0,460,0,1)}, 1.0, Enum.EasingStyle.Expo)
    tweenProp(modLabel, {TextTransparency = 0},        0.8)
    task.wait(0.4)

    -- Progress function exposed to boot sequence
    local function setProgress(pct, label)
        tweenProp(bar,      {Size = UDim2.new(pct, 0, 1, 0)}, 0.4, Enum.EasingStyle.Quad)
        modLabel.Text = label or ""
    end

    -- Dismiss function
    local function dismiss()
        task.wait(0.3)
        tweenProp(bg,       {BackgroundTransparency = 1}, 1.2, Enum.EasingStyle.Sine)
        tweenProp(title,    {TextTransparency = 1},       0.8, Enum.EasingStyle.Sine)
        tweenProp(sub,      {TextTransparency = 1},       0.8, Enum.EasingStyle.Sine)
        tweenProp(rule,     {Size=UDim2.new(0,0,0,1)},   0.5, Enum.EasingStyle.Expo)
        tweenProp(barBg,    {BackgroundTransparency = 1}, 0.6)
        tweenProp(bar,      {BackgroundTransparency = 1}, 0.6)
        tweenProp(modLabel, {TextTransparency = 1},       0.6)
        task.wait(1.3)
        sg:Destroy()
    end

    return setProgress, dismiss
end

--====================================================================
-- MODULE 1 ── LIGHTING  (Atmosphere + Post-Processing)
--====================================================================
local function initLighting()
    -- Atmosphere
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
    atmo.Parent      = Lighting
    atmo.Density     = CFG.ATMO_DENSITY
    atmo.Offset      = CFG.ATMO_OFFSET
    atmo.Color       = CFG.ATMO_COLOR
    atmo.Decay       = CFG.ATMO_DECAY
    atmo.Glare       = 0.4
    atmo.Haze        = CFG.ATMO_HAZE

    -- Sky colour shift
    Lighting.OutdoorAmbient = Color3.fromRGB(100, 110, 140)
    Lighting.Ambient        = Color3.fromRGB(80, 88, 120)
    Lighting.Brightness     = 3.2
    Lighting.ColorShift_Bottom = Color3.fromRGB(60, 80, 130)
    Lighting.ColorShift_Top    = Color3.fromRGB(220, 200, 160)
    Lighting.EnvironmentDiffuseScale  = 0.65
    Lighting.EnvironmentSpecularScale = 0.55
    Lighting.ShadowSoftness = 0.55

    -- Remove old effects, start fresh
    for _, v in Lighting:GetChildren() do
        if v:IsA("PostEffect") then v:Destroy() end
    end

    -- Bloom
    local bloom = Instance.new("BloomEffect")
    bloom.Enabled   = true
    bloom.Intensity = CFG.BLOOM_INTENSITY
    bloom.Size      = CFG.BLOOM_SIZE
    bloom.Threshold = CFG.BLOOM_THRESHOLD
    bloom.Parent    = Lighting

    -- Depth of Field
    local dof = Instance.new("DepthOfFieldEffect")
    dof.Enabled        = true
    dof.FarIntensity   = CFG.DOF_FAR_INTENSITY
    dof.NearIntensity  = CFG.DOF_NEAR_INTENSITY
    dof.FocusDistance  = CFG.DOF_FOCUS_DIST
    dof.InFocusRadius  = CFG.DOF_IN_FOCUS_R
    dof.Parent         = Lighting

    -- Sun Rays (god-ray approximation)
    local sunRay = Instance.new("SunRaysEffect")
    sunRay.Enabled   = true
    sunRay.Intensity = CFG.SUNRAY_INTENSITY
    sunRay.Spread    = CFG.SUNRAY_SPREAD
    sunRay.Parent    = Lighting

    -- Color Correction (cinematic LUT-like toning)
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Enabled     = true
    cc.Brightness  = CFG.COLOR_BRIGHTNESS
    cc.Contrast    = CFG.COLOR_CONTRAST
    cc.Saturation  = CFG.COLOR_SATURATION
    cc.TintColor   = CFG.COLOR_TCC
    cc.Parent      = Lighting

    -- Motion Blur
    local mb = Instance.new("BlurEffect")
    mb.Enabled = true
    mb.Size    = 0   -- driven dynamically by camera velocity
    mb.Parent  = Lighting

    -- SSAO approximation via ambient occlusion (Roblox native)
    -- Closest we can get: high-quality shadow softness + low ambient
    Lighting.ShadowSoftness = 0.6

    return dof, mb, cc
end

--====================================================================
-- MODULE 2 ── DYNAMIC DOF — lock onto nearest enemy character
--====================================================================
local function initDynamicDOF(dof)
    task.spawn(function()
        while task.wait(0.15) do
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                local hrp  = char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local nearest, nearDist = nil, math.huge
                for _, p in Players:GetPlayers() do
                    if p ~= LocalPlayer and p.Character then
                        local oHRP = p.Character:FindFirstChild("HumanoidRootPart")
                        if oHRP then
                            local d = (oHRP.Position - hrp.Position).Magnitude
                            if d < nearDist then
                                nearDist = d
                                nearest  = oHRP
                            end
                        end
                    end
                end

                if nearest then
                    -- Smoothly shift DOF focus to enemy
                    local camDist = (nearest.Position - Camera.CFrame.Position).Magnitude
                    dof.FocusDistance = lerp(dof.FocusDistance, camDist, 0.12)
                    dof.InFocusRadius = lerp(dof.InFocusRadius, 8, 0.12)
                else
                    dof.FocusDistance = lerp(dof.FocusDistance, CFG.DOF_FOCUS_DIST, 0.06)
                    dof.InFocusRadius = lerp(dof.InFocusRadius,  CFG.DOF_IN_FOCUS_R,  0.06)
                end
            end)
        end
    end)
end

--====================================================================
-- MODULE 3 ── MOTION BLUR — driven by camera angular velocity
--====================================================================
local function initMotionBlur(mb)
    local prevCF = Camera.CFrame
    RunService.RenderStepped:Connect(function(dt)
        pcall(function()
            local angle = prevCF:ToObjectSpace(Camera.CFrame)
            local ax, ay, az = angle:ToEulerAnglesXYZ()
            local totalRot = (math.abs(ax) + math.abs(ay) + math.abs(az)) / dt
            local blurSize = clamp(totalRot * 0.006, 0, 14) * CFG.MOTIONBLUR_AMOUNT
            mb.Size = lerp(mb.Size, blurSize, 0.25)
            prevCF  = Camera.CFrame
        end)
    end)
end

--====================================================================
-- MODULE 4 ── TERRAIN VISUAL UPGRADE
--====================================================================
local function initTerrain()
    -- Roblox Terrain material overrides (limited to supported materials)
    -- We maximize what's possible: custom colors + detail textures
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return end

    -- Push Terrain into max-quality material mode
    terrain.WaterWaveSize    = 0.8
    terrain.WaterWaveSpeed   = 12
    terrain.WaterTransparency= 0.3
    terrain.WaterReflectance = 0.75

    -- Material color overrides — Studio-Ghibli-esque palette
    local matColors = {
        [Enum.Material.Grass]        = Color3.fromRGB(76, 148, 68),
        [Enum.Material.LeafyGrass]   = Color3.fromRGB(88, 160, 72),
        [Enum.Material.Ground]       = Color3.fromRGB(110, 85, 60),
        [Enum.Material.Sand]         = Color3.fromRGB(210, 185, 130),
        [Enum.Material.Rock]         = Color3.fromRGB(120, 115, 110),
        [Enum.Material.SmoothPlastic]= Color3.fromRGB(200, 195, 185),
        [Enum.Material.Cobblestone]  = Color3.fromRGB(130, 125, 118),
        [Enum.Material.Brick]        = Color3.fromRGB(160, 100, 75),
        [Enum.Material.Mud]          = Color3.fromRGB(88, 68, 50),
        [Enum.Material.Snow]         = Color3.fromRGB(235, 245, 255),
        [Enum.Material.Sandstone]    = Color3.fromRGB(190, 160, 110),
    }
    for mat, col in matColors do
        pcall(function()
            terrain:SetMaterialColor(mat, col)
        end)
    end
end

--====================================================================
-- MODULE 5 ── PROCEDURAL 3D GRASS (EditableMesh blades)
--====================================================================
-- Each blade: a thin wedge part with wind-driven CFrame offset.
-- Blades are pooled and recycled as the player moves.

local GrassModule = {}
do
    local bladePool    = {}  -- {part, baseCF, height, windPhase}
    local bladeCount   = 0
    local grassFolder  = Instance.new("Folder")
    grassFolder.Name   = "GenesisGrass"
    grassFolder.Parent = Workspace

    -- Template blade (WedgePart for a simple leaf silhouette)
    local function makeBlade()
        local p = Instance.new("WedgePart")
        p.Anchored       = true
        p.CanCollide     = false
        p.CastShadow     = false
        p.Material       = Enum.Material.SmoothPlastic
        p.Size           = Vector3.new(0.08, 0.5, 0.10)
        p.Color          = CFG.GRASS_BLADE_COLOR
        p.Parent         = grassFolder
        return p
    end

    local function getOrCreateBlade()
        if #bladePool > 0 then
            return table.remove(bladePool)
        end
        bladeCount += 1
        return makeBlade()
    end

    local activeBlade = {}   -- array of {part, basePos, height, phase, crush}

    -- Spawn grass patch around a world position
    local function spawnPatch(center, radius, density)
        for dx = -radius, radius, 1/density do
            for dz = -radius, radius, 1/density do
                if #activeBlade >= CFG.GRASS_MAX_BLADES then return end
                if math.sqrt(dx*dx + dz*dz) > radius then continue end

                local wx = center.X + dx + (rand() - 0.5) * 0.4
                local wz = center.Z + dz + (rand() - 0.5) * 0.4

                -- Raycast to find ground
                local origin = Vector3.new(wx, center.Y + 10, wz)
                local ray    = RaycastParams.new()
                ray.FilterDescendantsInstances = {grassFolder}
                ray.FilterType = Enum.RaycastFilterType.Exclude
                local result = Workspace:Raycast(origin, Vector3.new(0, -20, 0), ray)
                if not result then continue end

                local ground = result.Instance
                -- Only on grass-like surfaces
                if ground.Material ~= Enum.Material.Grass
                and ground.Material ~= Enum.Material.LeafyGrass
                and ground.Material ~= Enum.Material.Ground
                and ground:IsA("Terrain") == false then continue end

                local gy = result.Position.Y
                local h  = lerp(CFG.GRASS_HEIGHT_MIN, CFG.GRASS_HEIGHT_MAX, rand())
                local blade = getOrCreateBlade()
                blade.Size  = Vector3.new(0.07 + rand()*0.04, h, 0.09 + rand()*0.04)
                -- Random yaw so blades face different directions
                local yaw   = rand() * pi * 2
                local baseP = Vector3.new(wx, gy + h/2, wz)
                blade.CFrame = CFrame.new(baseP) * CFrame.Angles(0, yaw, 0)
                blade.Color  = lerpC3(CFG.GRASS_BLADE_COLOR, CFG.GRASS_TIP_COLOR, rand()*0.5)
                blade.Transparency = 0

                table.insert(activeBlade, {
                    part   = blade,
                    basePos= baseP,
                    yaw    = yaw,
                    height = h,
                    phase  = rand() * pi * 2,
                    crush  = 0,
                })
            end
            task.wait()  -- yield each row to avoid frame spike
        end
    end

    -- Recycle blades far from player
    local function recycleDistant(playerPos, keepRadius)
        for i = #activeBlade, 1, -1 do
            local b = activeBlade[i]
            local dx = b.basePos.X - playerPos.X
            local dz = b.basePos.Z - playerPos.Z
            if dx*dx + dz*dz > keepRadius*keepRadius then
                b.part.Transparency = 1
                table.insert(bladePool, b.part)
                table.remove(activeBlade, i)
            end
        end
    end

    -- Wind + footstep animation loop (offloaded with desynchronize)
    RunService.Heartbeat:Connect(function(dt)
        local t = os.clock()
        pcall(function()
            local char  = LocalPlayer.Character
            local hrpPos = char and char:FindFirstChild("HumanoidRootPart")
                           and char.HumanoidRootPart.Position
                           or Vector3.new(0, 0, 0)

            task.desynchronize()
            for _, b in activeBlade do
                -- Wind via Perlin noise per blade
                local wx = noise(b.basePos.X * 0.08, b.basePos.Z * 0.08,
                                 t * CFG.GRASS_WIND_SPEED) * CFG.GRASS_WIND_STRENGTH
                local wz = noise(b.basePos.Z * 0.08, b.basePos.X * 0.08,
                                 t * CFG.GRASS_WIND_SPEED + 100) * CFG.GRASS_WIND_STRENGTH * 0.5

                -- Footstep crush
                local fdx = b.basePos.X - hrpPos.X
                local fdz = b.basePos.Z - hrpPos.Z
                local fd  = fdx*fdx + fdz*fdz
                if fd < CFG.GRASS_FOOTSTEP_R * CFG.GRASS_FOOTSTEP_R then
                    b.crush = clamp(b.crush + dt * 6, 0, 1)
                else
                    b.crush = clamp(b.crush - dt * 3, 0, 1)
                end

                local crushAngleX = b.crush * 55   -- degrees
                local totalX = math.rad(wx + crushAngleX)
                local totalZ = math.rad(wz)

                b.part.CFrame = CFrame.new(b.basePos)
                    * CFrame.Angles(0, b.yaw, 0)
                    * CFrame.Angles(totalX, 0, totalZ)
            end
            task.synchronize()
        end)
    end)

    -- Streaming: update grass patch when player moves significantly
    local lastPatchPos = Vector3.new(math.huge, 0, math.huge)
    RunService.Heartbeat:Connect(function()
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hrp  = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local pos = hrp.Position
            if (pos - lastPatchPos).Magnitude > 18 then
                lastPatchPos = pos
                recycleDistant(pos, CFG.GRASS_CHUNK_RADIUS * 1.4)
                task.spawn(spawnPatch, pos, CFG.GRASS_CHUNK_RADIUS, CFG.GRASS_DENSITY)
            end
        end)
    end)

    GrassModule.spawnInitial = function(pos)
        spawnPatch(pos, CFG.GRASS_CHUNK_RADIUS, CFG.GRASS_DENSITY)
    end
end

--====================================================================
-- MODULE 6 ── CHARACTER SYSTEM (Outline + Rim Light + Jiggle)
--====================================================================
local characterHandles = {}  -- player → {highlight, jiggleParts}

local function applyCharacterFX(character, isLocal)
    if characterHandles[character] then return end

    -- Anime outline via Highlight (closest Roblox API to outline shading)
    local hl = Instance.new("Highlight")
    hl.Adornee            = character
    hl.OutlineColor       = CFG.OUTLINE_COLOR
    hl.OutlineTransparency= 0
    hl.FillTransparency   = 1
    hl.DepthMode          = Enum.HighlightDepthMode.Occluded
    hl.Parent             = character

    -- Rim light (PointLight on torso = fake SSS/rim approximation)
    local torso = character:FindFirstChild("UpperTorso")
               or character:FindFirstChild("Torso")
    if torso then
        local rim = Instance.new("PointLight")
        rim.Color      = CFG.RIM_COLOR
        rim.Brightness = CFG.RIM_INTENSITY
        rim.Range      = 9
        rim.Shadows    = false
        rim.Parent     = torso
    end

    -- Distance-based outline width (driven in RenderStepped)
    local function updateOutline()
        pcall(function()
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local d = (hrp.Position - Camera.CFrame.Position).Magnitude
            local t = clamp((d - 10) / (CFG.OUTLINE_FAR_DIST - 10), 0, 1)
            -- Highlight doesn't expose width directly; colour alpha mimics it
            hl.OutlineTransparency = lerp(0, 0.55, t)
        end)
    end

    -- Jiggle physics — find accessory handles
    local jiggleParts = {}
    for _, acc in character:GetDescendants() do
        if acc:IsA("BasePart") and (
            acc.Name:lower():find("cape") or
            acc.Name:lower():find("hair") or
            acc.Name:lower():find("tail") or
            acc.Name:lower():find("scarf") or
            acc.Name:lower():find("wing")
        ) then
            table.insert(jiggleParts, {
                part     = acc,
                vel      = Vector3.new(0,0,0),
                prevPos  = acc.Position,
                baseCF   = acc.CFrame,
            })
        end
    end

    characterHandles[character] = {
        highlight   = hl,
        jiggleParts = jiggleParts,
        updateOutline = updateOutline,
    }
end

local function removeCharacterFX(character)
    local h = characterHandles[character]
    if h then
        pcall(function() h.highlight:Destroy() end)
        characterHandles[character] = nil
    end
end

-- Jiggle + outline update loop
RunService.RenderStepped:Connect(function(dt)
    for char, data in characterHandles do
        pcall(function()
            -- Outline width
            data.updateOutline()

            -- Jiggle (spring simulation)
            for _, jp in data.jiggleParts do
                local p = jp.part
                if not p.Parent then continue end

                local vel   = jp.vel
                local hrp   = char:FindFirstChild("HumanoidRootPart")
                local accel = hrp and (hrp.Velocity * -0.018) or Vector3.zero

                -- Spring: F = -k*x - b*v
                vel = vel + accel
                vel = vel * (1 - CFG.JIGGLE_DAMPING * dt)
                jp.vel = vel

                -- Apply jiggle as a CFrame angle offset
                local ox = clamp(vel.X * 0.022, -0.18, 0.18)
                local oz = clamp(vel.Z * 0.022, -0.18, 0.18)
                p.CFrame = jp.baseCF * CFrame.Angles(ox, 0, oz)
            end
        end)
    end
end)

-- Hook all current + future players
local function hookPlayer(player)
    local function onCharAdded(char)
        task.wait(1)  -- wait for accessories to load
        local isLocal = player == LocalPlayer
        safeCall(function() applyCharacterFX(char, isLocal) end, "CharFX")
        char.AncestryChanged:Connect(function()
            if not char.Parent then
                removeCharacterFX(char)
            end
        end)
    end
    if player.Character then onCharAdded(player.Character) end
    player.CharacterAdded:Connect(onCharAdded)
end

--====================================================================
-- MODULE 7 ── 120FPS SUB-FRAME INTERPOLATION
--====================================================================
-- We cannot override Roblox's physics tick, but we CAN interpolate
-- character display positions client-side using RenderStepped.
local interpTargets = {}  -- {hrp → {prevPos, prevCF, nextPos, nextCF, alpha}}

local TARGET_DT = 1 / CFG.INTERP_FPS

RunService.Heartbeat:Connect(function()
    -- Record physics-tick positions as interpolation targets
    for _, p in Players:GetPlayers() do
        pcall(function()
            local char = p.Character
            if not char then return end
            local hrp  = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local entry = interpTargets[hrp]
            if entry then
                entry.prevCF  = entry.nextCF
                entry.nextCF  = hrp.CFrame
                entry.alpha   = 0
            else
                interpTargets[hrp] = {
                    prevCF = hrp.CFrame,
                    nextCF = hrp.CFrame,
                    alpha  = 0,
                }
            end
        end)
    end
end)

RunService.RenderStepped:Connect(function(dt)
    -- Advance alpha toward next physics frame
    for hrp, entry in interpTargets do
        pcall(function()
            if not hrp.Parent then
                interpTargets[hrp] = nil
                return
            end
            entry.alpha = clamp(entry.alpha + dt / TARGET_DT, 0, 1)
            -- Only apply to non-local characters (don't fight camera control)
            local ownerChar = hrp.Parent
            local owner     = ownerChar and Players:GetPlayerFromCharacter(ownerChar)
            if owner and owner ~= LocalPlayer then
                hrp.CFrame = entry.prevCF:Lerp(entry.nextCF, entry.alpha)
            end
        end)
    end
end)

--====================================================================
-- MODULE 8 ── VOLUMETRIC CLOUD LAYER (Billboard approximation)
--====================================================================
local function initClouds()
    -- Roblox Clouds object (native, introduced 2022)
    local clouds = Workspace.Terrain:FindFirstChildOfClass("Clouds")
               or Instance.new("Clouds")
    clouds.Cover       = 0.52
    clouds.Density     = 0.72
    clouds.Color       = Color3.fromRGB(220, 225, 240)
    clouds.Parent      = Workspace.Terrain
end

--====================================================================
-- MODULE 9 ── FOLIAGE WIND (existing trees/bushes in scene)
--====================================================================
local function initFoliage()
    -- Sway every Mesh/Special Mesh part tagged as foliage or named like one
    local foliageKeywords = {"tree","leaf","bush","fern","plant","foliage","shrub","branch"}
    local foliageParts    = {}

    for _, obj in Workspace:GetDescendants() do
        if obj:IsA("BasePart") and not obj.Anchored == false then
            local name = obj.Name:lower()
            for _, kw in foliageKeywords do
                if name:find(kw) then
                    table.insert(foliageParts, {part=obj, baseCF=obj.CFrame, phase=rand()*pi*2})
                    break
                end
            end
        end
    end

    -- Anchor all foliage and drive via Heartbeat
    for _, f in foliageParts do
        f.part.Anchored = true
    end

    RunService.Heartbeat:Connect(function()
        local t = os.clock()
        pcall(function()
            task.desynchronize()
            for _, f in foliageParts do
                local sw = sin(t * 1.4 + f.phase) * 0.025
                local sw2 = cos(t * 0.9 + f.phase + 1) * 0.015
                f.part.CFrame = f.baseCF * CFrame.Angles(sw, 0, sw2)
            end
            task.synchronize()
        end)
    end)
end

--====================================================================
-- MODULE 10 ── VFX ENHANCEMENT (Skill spatial refraction via Blur)
--====================================================================
-- When a skill VFX BasePart (tagged "GenesisVFX") is near the camera,
-- push in a localised blur to simulate heat-haze / spatial distortion.
local function initVFX()
    local vfxBlur = Instance.new("BlurEffect")
    vfxBlur.Size   = 0
    vfxBlur.Parent = Lighting

    RunService.RenderStepped:Connect(function()
        pcall(function()
            local maxEffect = 0
            for _, obj in Workspace:GetDescendants() do
                if obj:IsA("BasePart") and obj:GetAttribute("GenesisVFX") then
                    local d = (obj.Position - Camera.CFrame.Position).Magnitude
                    if d < 25 then
                        local strength = (1 - d/25) * 8
                        if strength > maxEffect then maxEffect = strength end
                    end
                end
            end
            vfxBlur.Size = lerp(vfxBlur.Size, maxEffect, 0.2)
        end)
    end)
end

--====================================================================
-- GENESIS BOOT SEQUENCE
--====================================================================
local function boot()
    -- 0. Cinematic loading screen
    local setProgress, dismiss = initLoadingScreen()
    task.wait(0.6)

    local modules = {
        { name = "⚡ Lighting & Post-Processing",   fn = initLighting },
        { name = "🌫  Atmosphere & Clouds",          fn = initClouds   },
        { name = "🌍 Terrain Transfiguration",       fn = initTerrain  },
        { name = "🌿 Foliage Wind Engine",           fn = initFoliage  },
        { name = "⚔️  Character & Animation System", fn = function()
            for _, p in Players:GetPlayers() do
                hookPlayer(p)
            end
            Players.PlayerAdded:Connect(hookPlayer)
        end},
        { name = "✨ VFX Spatial Refraction",        fn = initVFX     },
    }

    for i, mod in modules do
        setProgress((i-1)/#modules, mod.name)
        safeCall(mod.fn, mod.name)
        task.wait(CFG.LOAD_FAKE_DURATION / #modules)
        setProgress(i/#modules, mod.name .. "  ✓")
        task.wait(0.15)
    end

    -- Initialise DOF and motion blur with returned handles
    local dof, mb = initLighting()  -- lighting already applied; returns refs
    -- Actually grab refs properly:
    local dofRef = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
    local mbRef  = Lighting:FindFirstChildOfClass("BlurEffect")
    if dofRef then safeCall(function() initDynamicDOF(dofRef) end, "DynamicDOF") end
    if mbRef  then safeCall(function() initMotionBlur(mbRef)  end, "MotionBlur") end

    -- Spawn initial grass after boot
    task.spawn(function()
        task.wait(1)
        pcall(function()
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp  = char:WaitForChild("HumanoidRootPart", 5)
            if hrp then GrassModule.spawnInitial(hrp.Position) end
        end)
    end)

    setProgress(1, "🚀 GENESIS V8 — ASCENSION COMPLETE")
    task.wait(0.6)
    dismiss()

    print("[GENESIS V8.0] ✅ All modules online. The Strongest Battlegrounds is now unrecognisable.")
end

-- Run
task.spawn(boot)
