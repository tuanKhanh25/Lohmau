--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║         ANIME CINEMATIC SHADER v2.0 — by Script Forge        ║
    ║   Optimized for: The Strongest Battlegrounds & Combat Games   ║
    ║   Engine: Future Lighting · Cell Shading · Full Post-FX Stack ║
    ╚══════════════════════════════════════════════════════════════╝
--]]

-- ─────────────────────────────────────────────────────────────────
--  SERVICES
-- ─────────────────────────────────────────────────────────────────
local Lighting        = game:GetService("Lighting")
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")

local LocalPlayer     = Players.LocalPlayer
local Camera          = workspace.CurrentCamera

-- ─────────────────────────────────────────────────────────────────
--  CONFIG — tweak these to taste
-- ─────────────────────────────────────────────────────────────────
local CONFIG = {

    -- Lighting engine
    Technology              = Enum.Technology.Future,
    EnvironmentDiffuseScale = 1,
    EnvironmentSpecularScale= 1,
    Ambient                 = Color3.fromRGB(20, 18, 30),
    OutdoorAmbient          = Color3.fromRGB(70, 60, 90),
    ShadowSoftness          = 0.2,
    ExposureCompensation    = 0.1,

    -- Atmosphere
    AtmosphereDensity       = 0.35,
    AtmosphereHaze          = 0.4,
    AtmosphereGlare         = 0,
    AtmosphereDecay         = 0.8,
    AtmosphereColor         = Color3.fromRGB(199, 170, 255),  -- slight violet sky
    AtmosphereFogColor      = Color3.fromRGB(220, 210, 255),

    -- Color Correction
    CCContrast              = 0.20,
    CCSaturation            = 0.15,
    CCBrightness            = 0.02,
    CCTintColor             = Color3.fromRGB(255, 250, 240),  -- warm ivory

    -- Bloom
    BloomThreshold          = 0.80,
    BloomIntensity          = 1.00,
    BloomSize               = 24,

    -- Depth of Field
    DOFFarIntensity         = 0.60,
    DOFInFocusRadius        = 35,
    DOFNearIntensity        = 0.10,
    DOFFocusDistance        = 0,    -- 0 = auto-focus on camera target

    -- Sun Rays
    SunRayIntensity         = 0.50,
    SunRaySpread            = 1.00,

    -- Cell Shading / Outline
    OutlineThickness        = 0.04,
    OutlineColor            = Color3.fromRGB(0, 0, 0),
    CharReflectance         = 0.08,

    -- Cinematic bars (letterbox)
    EnableCinematicBars     = true,
    CinematicBarHeight      = 0.06,  -- fraction of screen height
}

-- ─────────────────────────────────────────────────────────────────
--  STATE — track created instances for cleanup
-- ─────────────────────────────────────────────────────────────────
local createdEffects  = {}   -- { instance }
local characterConns  = {}   -- { connection }
local heartbeatConn   = nil
local highlightCache  = {}   -- [character] = Highlight

-- ─────────────────────────────────────────────────────────────────
--  UTILITY
-- ─────────────────────────────────────────────────────────────────
local function track(instance)
    table.insert(createdEffects, instance)
    return instance
end

local function safeDestroy(instance)
    if instance and instance.Parent then
        pcall(function() instance:Destroy() end)
    end
end

local function tweenProps(instance, props, duration)
    local info = TweenInfo.new(duration or 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    TweenService:Create(instance, info, props):Play()
end

-- ─────────────────────────────────────────────────────────────────
--  1. ENGINE OVERRIDE — Force Future lighting
-- ─────────────────────────────────────────────────────────────────
local function applyLighting()
    Lighting.Technology              = CONFIG.Technology
    Lighting.EnvironmentDiffuseScale = CONFIG.EnvironmentDiffuseScale
    Lighting.EnvironmentSpecularScale= CONFIG.EnvironmentSpecularScale
    Lighting.Ambient                 = CONFIG.Ambient
    Lighting.OutdoorAmbient          = CONFIG.OutdoorAmbient
    Lighting.ShadowSoftness          = CONFIG.ShadowSoftness
    Lighting.ExposureCompensation    = CONFIG.ExposureCompensation
    Lighting.GlobalShadows           = true
    print("[AnimeShader] Lighting → Future mode applied.")
end

-- ─────────────────────────────────────────────────────────────────
--  2. ATMOSPHERE — Depth and cinematic air
-- ─────────────────────────────────────────────────────────────────
local function applyAtmosphere()
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
              or track(Instance.new("Atmosphere", Lighting))

    atm.Density   = CONFIG.AtmosphereDensity
    atm.Haze      = CONFIG.AtmosphereHaze
    atm.Glare     = CONFIG.AtmosphereGlare
    atm.Decay     = CONFIG.AtmosphereDecay
    atm.Color     = CONFIG.AtmosphereColor
    atm.FogColor  = CONFIG.AtmosphereFogColor
end

-- ─────────────────────────────────────────────────────────────────
--  3. POST-PROCESSING STACK
-- ─────────────────────────────────────────────────────────────────
local function removeOldEffect(className)
    local existing = Lighting:FindFirstChildOfClass(className)
    if existing then existing:Destroy() end
end

local function applyPostFX()

    -- 3a. Color Correction
    removeOldEffect("ColorCorrectionEffect")
    local cc      = track(Instance.new("ColorCorrectionEffect"))
    cc.Contrast   = CONFIG.CCContrast
    cc.Saturation = CONFIG.CCSaturation
    cc.Brightness = CONFIG.CCBrightness
    cc.TintColor  = CONFIG.CCTintColor
    cc.Enabled    = true
    cc.Parent     = Lighting

    -- 3b. Bloom — anime combat glow
    removeOldEffect("BloomEffect")
    local bloom        = track(Instance.new("BloomEffect"))
    bloom.Threshold    = CONFIG.BloomThreshold
    bloom.Intensity    = CONFIG.BloomIntensity
    bloom.Size         = CONFIG.BloomSize
    bloom.Enabled      = true
    bloom.Parent       = Lighting

    -- 3c. Depth of Field — cinematic focus plane
    removeOldEffect("DepthOfFieldEffect")
    local dof             = track(Instance.new("DepthOfFieldEffect"))
    dof.FarIntensity      = CONFIG.DOFFarIntensity
    dof.InFocusRadius     = CONFIG.DOFInFocusRadius
    dof.NearIntensity     = CONFIG.DOFNearIntensity
    dof.FocusDistance     = CONFIG.DOFFocusDistance
    dof.Enabled           = true
    dof.Parent            = Lighting

    -- 3d. Sun Rays — volumetric "God Rays"
    removeOldEffect("SunRaysEffect")
    local sun          = track(Instance.new("SunRaysEffect"))
    sun.Intensity      = CONFIG.SunRayIntensity
    sun.Spread         = CONFIG.SunRaySpread
    sun.Enabled        = true
    sun.Parent         = Lighting

    print("[AnimeShader] Post-FX stack → Bloom, DoF, SunRays, ColorCorrection applied.")
end

-- ─────────────────────────────────────────────────────────────────
--  4. CELL SHADING — Highlight outline + material override
-- ─────────────────────────────────────────────────────────────────
local HUMANOID_PARTS = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
    "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg",  -- R6
}

local SKIP_MATERIALS = {
    [Enum.Material.Neon]        = true,
    [Enum.Material.ForceField]  = true,
}

local function styleBasePart(part)
    if part:IsA("BasePart") and not SKIP_MATERIALS[part.Material] then
        part.Material    = Enum.Material.SmoothPlastic
        part.Reflectance = CONFIG.CharReflectance
        part.CastShadow  = true
    end
end

local function applyHighlight(character)
    if highlightCache[character] then return end

    -- Outline
    local hl                = Instance.new("Highlight")
    hl.FillTransparency     = 1
    hl.OutlineColor         = CONFIG.OutlineColor
    hl.OutlineTransparency  = 0
    hl.DepthMode            = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee              = character
    hl.Parent               = character
    highlightCache[character] = hl

    -- Material override on all parts
    for _, part in ipairs(character:GetDescendants()) do
        styleBasePart(part)
    end
    character.DescendantAdded:Connect(function(part)
        styleBasePart(part)
    end)
end

local function removeHighlight(character)
    local hl = highlightCache[character]
    if hl then
        safeDestroy(hl)
        highlightCache[character] = nil
    end
end

-- Apply to a player's character now and on respawn
local function hookPlayer(player)
    local function onChar(char)
        char:WaitForChild("HumanoidRootPart", 10)
        applyHighlight(char)

        -- cleanup on death/removal
        char.AncestryChanged:Connect(function(_, parent)
            if not parent then
                removeHighlight(char)
            end
        end)
    end

    if player.Character then onChar(player.Character) end
    local conn = player.CharacterAdded:Connect(onChar)
    table.insert(characterConns, conn)
end

local function applyToAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        hookPlayer(player)
    end
    local conn = Players.PlayerAdded:Connect(hookPlayer)
    table.insert(characterConns, conn)

    -- Cleanup on player leave
    Players.PlayerRemoving:Connect(function(player)
        if player.Character then
            removeHighlight(player.Character)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────
--  5. CINEMATIC LETTERBOX BARS (optional)
-- ─────────────────────────────────────────────────────────────────
local topBar, botBar

local function applyCinematicBars()
    if not CONFIG.EnableCinematicBars then return end

    local sg = track(Instance.new("ScreenGui"))
    sg.Name              = "AnimeCinematicBars"
    sg.IgnoreGuiInset    = true
    sg.ResetOnSpawn      = false
    sg.DisplayOrder      = 999
    sg.Parent            = LocalPlayer:WaitForChild("PlayerGui")

    local function makeBar(anchorY, posY)
        local f              = Instance.new("Frame", sg)
        f.BackgroundColor3   = Color3.fromRGB(0, 0, 0)
        f.BorderSizePixel    = 0
        f.AnchorPoint        = Vector2.new(0, anchorY)
        f.Position           = UDim2.new(0, 0, posY, 0)
        f.Size               = UDim2.new(1, 0, 0, 0)  -- animate in
        f.BackgroundTransparency = 0
        return f
    end

    topBar = makeBar(0, 0)
    botBar = makeBar(1, 1)

    -- Animate bars in over 0.8 s
    local barH = CONFIG.CinematicBarHeight
    local info  = TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(topBar, info, { Size = UDim2.new(1, 0, barH, 0) }):Play()
    TweenService:Create(botBar, info, { Size = UDim2.new(1, 0, barH, 0) }):Play()

    print("[AnimeShader] Cinematic bars → applied.")
end

-- ─────────────────────────────────────────────────────────────────
--  6. HEARTBEAT — DOF auto-focus + stability loop
-- ─────────────────────────────────────────────────────────────────
local function startHeartbeat()
    local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
    if not dof then return end

    heartbeatConn = RunService.Heartbeat:Connect(function()
        -- Auto-focus: raycast from camera toward its look direction
        local camPos   = Camera.CFrame.Position
        local camLook  = Camera.CFrame.LookVector
        local rayResult = workspace:Raycast(
            camPos,
            camLook * 300,
            RaycastParams.new()
        )

        if rayResult then
            local dist = (rayResult.Position - camPos).Magnitude
            -- Smoothly lerp focus distance for cinematic feel
            dof.FocusDistance = dof.FocusDistance + (dist - dof.FocusDistance) * 0.05
        end

        -- Guard: re-enforce Future tech each frame in case the game overrides it
        if Lighting.Technology ~= CONFIG.Technology then
            Lighting.Technology = CONFIG.Technology
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────
--  7. CLEANUP — call this to fully remove all effects
-- ─────────────────────────────────────────────────────────────────
local function cleanup()
    print("[AnimeShader] Cleaning up all effects...")

    -- Disconnect heartbeat
    if heartbeatConn then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end

    -- Disconnect character hooks
    for _, conn in ipairs(characterConns) do
        conn:Disconnect()
    end
    characterConns = {}

    -- Destroy all tracked Lighting effects
    for _, effect in ipairs(createdEffects) do
        safeDestroy(effect)
    end
    createdEffects = {}

    -- Remove all highlights
    for char, hl in pairs(highlightCache) do
        safeDestroy(hl)
    end
    highlightCache = {}

    -- Restore sane Lighting defaults
    Lighting.Technology              = Enum.Technology.ShadowMap
    Lighting.EnvironmentDiffuseScale = 0.5
    Lighting.EnvironmentSpecularScale= 0.5

    print("[AnimeShader] Cleanup complete.")
end

-- ─────────────────────────────────────────────────────────────────
--  INIT — fire everything in order
-- ─────────────────────────────────────────────────────────────────
local function init()
    print("[AnimeShader] Initializing...")

    applyLighting()
    applyAtmosphere()
    applyPostFX()
    applyToAllPlayers()
    applyCinematicBars()
    startHeartbeat()

    print("[AnimeShader] ✓ All systems active. Call cleanup() to remove.")
end

init()

-- ─────────────────────────────────────────────────────────────────
--  EXPOSE cleanup globally so you can call it from the executor
-- ─────────────────────────────────────────────────────────────────
getgenv().AnimeShaderCleanup = cleanup
-- Usage: AnimeShaderCleanup()
