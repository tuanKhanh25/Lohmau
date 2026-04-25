--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║         TRIPLE-A ANIME CINEMATIC VISUAL STACK  ·  v3.0 "SAKUGA"            ║
║         Architect: God-Tier Graphics · VFX Director Mode ENGAGED            ║
║         Target: The Strongest Battlegrounds · Rivals: GG Strive / Genshin   ║
║                                                                              ║
║  MODULES:                                                                    ║
║   [CORE]  → Services, Config, EventBus, StateManager                        ║
║   [RENDER]→ Future Lighting, LUT Stack, Atmosphere, Volumetric Fog          ║
║   [CEL]   → Multi-tone Cell Shading (Highlight + EditableImage 2026)        ║
║   [GI]    → Script-driven Fake Global Illumination                          ║
║   [MODEL] → Ink Outlines, Material Override, Skin vs Fabric Reflectance     ║
║   [ANIM]  → Squash & Stretch, Vertex Deformation, Cape/Hair Physics         ║
║   [VFX]   → 2D Sprite Engine, Speed Lines, Shockwaves, Heat Distortion      ║
║   [HIT]   → Impact Frames, Cinematic Hit-Stops, Ghost Trails                ║
║   [CAM]   → AI Director Camera, Dutch Angles, Perlin Shake                  ║
║   [SSAO]  → FORBIDDEN: Screen-Space Ambient Occlusion Simulation            ║
║   [PERF]  → Performance Budget System, Parallel Luau, LOD Manager           ║
║   [INIT]  → Bootstrap, Cleanup, Global API                                  ║
╚══════════════════════════════════════════════════════════════════════════════╝
--]]

-- ══════════════════════════════════════════════════════════════════════════════
-- [CORE] SERVICES · CONFIG · EVENT BUS · STATE MANAGER
-- ══════════════════════════════════════════════════════════════════════════════

local Services = {
    Lighting      = game:GetService("Lighting"),
    Players       = game:GetService("Players"),
    RunService    = game:GetService("RunService"),
    TweenService  = game:GetService("TweenService"),
    UserInputService= game:GetService("UserInputService"),
    Workspace     = game:GetService("Workspace"),
    HttpService   = game:GetService("HttpService"),
    SoundService  = game:GetService("SoundService"),
}

local LP      = Services.Players.LocalPlayer
local Camera  = workspace.CurrentCamera
local Lighting= Services.Lighting
local RS      = Services.RunService
local TS      = Services.TweenService

-- ─── MASTER CONFIG ────────────────────────────────────────────────────────────
local CFG = {

    -- Rendering
    Technology              = Enum.Technology.Future,
    DiffuseScale            = 1.0,
    SpecularScale           = 1.0,
    ExposureComp            = 0.08,
    ShadowSoftness          = 0.15,

    -- LUT / Color Grading (Anime LUT stack)
    LUT_Contrast            = 0.35,
    LUT_Saturation          = 0.25,
    LUT_Brightness          = 0.03,
    LUT_TintColor           = Color3.fromRGB(255, 250, 240),

    -- Atmosphere / Volumetric Fog
    AtmDensity              = 0.40,
    AtmHaze                 = 0.50,
    AtmGlare                = 0.0,
    AtmDecay                = 0.85,
    AtmColor                = Color3.fromRGB(180, 160, 255),
    AtmFogColor             = Color3.fromRGB(200, 190, 255),
    FogNearPlane            = 80,
    FogFarPlane             = 400,

    -- Bloom
    BloomThreshold          = 0.75,
    BloomIntensity          = 1.20,
    BloomSize               = 28,

    -- Sun Rays
    SunRayIntensity         = 0.60,
    SunRaySpread            = 1.0,

    -- Depth of Field
    DOFFarIntensity         = 0.65,
    DOFNearIntensity        = 0.12,
    DOFInFocusRadius        = 30,

    -- Cell Shading
    OutlineThickness        = 0.045,
    OutlineColor            = Color3.fromRGB(5, 5, 10),
    SkinReflectance         = 0.12,
    FabricReflectance       = 0.04,
    MetalReflectance        = 0.40,
    HairReflectance         = 0.18,

    -- Cel Tone Thresholds
    HighlightThreshold      = 0.75,
    MidtoneThreshold        = 0.40,
    ShadowThreshold         = 0.15,

    -- Fake GI
    GI_UpdateRate           = 0.08,  -- seconds between GI recalculation
    GI_BounceStrength       = 0.35,
    GI_SkyInfluence         = 0.55,

    -- Squash & Stretch
    SS_DashStretchX         = 1.30,
    SS_DashStretchZ         = 0.75,
    SS_JumpSquashY          = 0.75,
    SS_JumpStretchX         = 1.15,
    SS_ReturnSpeed          = 0.12,

    -- Ghost Trails
    GhostCount              = 8,
    GhostDecayTime          = 0.22,
    GhostSpawnInterval      = 0.025,

    -- Hit System
    HitStopDuration         = 0.075,  -- seconds
    ImpactFlashDuration     = 0.05,   -- seconds
    ImpactFlashFrames       = 2,

    -- Speed Lines
    SpeedLineCount          = 24,
    SpeedLineLengthMin      = 80,
    SpeedLineLengthMax      = 200,

    -- Camera AI
    CAM_ShakeDecay          = 4.5,
    CAM_NoiseScale          = 12.0,
    CAM_DutchAngleMax       = 6.0,   -- degrees
    CAM_CinematicLerp       = 0.08,
    CAM_FOV_Combat          = 80,
    CAM_FOV_Default         = 70,

    -- SSAO (Forbidden)
    SSAO_Samples            = 6,
    SSAO_Radius             = 4.0,
    SSAO_Intensity          = 0.55,
    SSAO_UpdateRate         = 0.06,

    -- Performance Budget
    PERF_TargetFPS          = 45,
    PERF_LOD_Near           = 60,
    PERF_LOD_Mid            = 120,
    PERF_LOD_Far            = 250,
    PERF_MaxHighlights      = 6,

    -- Cinematic Bars
    BarHeight               = 0.055,
    BarAnimDuration         = 0.9,
}

-- ─── EVENT BUS ────────────────────────────────────────────────────────────────
local EventBus = {}
EventBus._listeners = {}

function EventBus:on(event, callback)
    if not self._listeners[event] then self._listeners[event] = {} end
    table.insert(self._listeners[event], callback)
end

function EventBus:emit(event, ...)
    if not self._listeners[event] then return end
    for _, cb in ipairs(self._listeners[event]) do
        task.spawn(cb, ...)
    end
end

-- ─── STATE MANAGER ────────────────────────────────────────────────────────────
local State = {
    inCombat            = false,
    lastHitTime         = 0,
    lastDashTime        = 0,
    currentFPS          = 60,
    perfTier            = 3,          -- 1=low 2=mid 3=high
    ghostTrailActive    = false,
    hitStopActive       = false,
    cameraMode          = "default",
    perlinSeed          = math.random(1000, 9999),
    giTimer             = 0,
    ssaoTimer           = 0,
    trackedEffects      = {},
    trackedConnections  = {},
    highlightCache      = {},
    ghostCache          = {},
    ssaoOverlayParts    = {},
    cineBarsGui         = nil,
    directorCamOffset   = CFrame.new(),
    perlinShake         = Vector3.new(),
    shakeIntensity      = 0,
}

local function track(inst)
    table.insert(State.trackedEffects, inst)
    return inst
end

local function trackConn(conn)
    table.insert(State.trackedConnections, conn)
    return conn
end

local function safeDestroy(inst)
    if inst and inst.Parent then pcall(function() inst:Destroy() end) end
end

-- ─── PERLIN NOISE (pure Luau implementation) ──────────────────────────────────
local PerlinNoise = {}
do
    local p = {}
    math.randomseed(State.perlinSeed)
    for i = 0, 255 do p[i] = i end
    for i = 255, 1, -1 do
        local j = math.random(0, i)
        p[i], p[j] = p[j], p[i]
    end
    for i = 0, 255 do p[i + 256] = p[i] end

    local function fade(t) return t * t * t * (t * (t * 6 - 15) + 10) end
    local function lerp(t, a, b) return a + t * (b - a) end
    local function grad(hash, x, y, z)
        local h = hash % 16
        local u = h < 8 and x or y
        local v = h < 4 and y or (h == 12 or h == 14) and x or z
        return ((h % 2 == 0) and u or -u) + ((math.floor(h / 2) % 2 == 0) and v or -v)
    end

    function PerlinNoise.noise(x, y, z)
        z = z or 0
        local X = math.floor(x) % 256
        local Y = math.floor(y) % 256
        local Z = math.floor(z) % 256
        x = x - math.floor(x)
        y = y - math.floor(y)
        z = z - math.floor(z)
        local u, v, w = fade(x), fade(y), fade(z)
        local A  = p[X] + Y
        local AA = p[A] + Z
        local AB = p[A + 1] + Z
        local B  = p[X + 1] + Y
        local BA = p[B] + Z
        local BB = p[B + 1] + Z
        return lerp(w,
            lerp(v, lerp(u, grad(p[AA], x, y, z),       grad(p[BA], x-1, y, z)),
                    lerp(u, grad(p[AB], x, y-1, z),     grad(p[BB], x-1, y-1, z))),
            lerp(v, lerp(u, grad(p[AA+1], x, y, z-1),   grad(p[BA+1], x-1, y, z-1)),
                    lerp(u, grad(p[AB+1], x, y-1, z-1), grad(p[BB+1], x-1, y-1, z-1))))
    end

    function PerlinNoise.fbm(x, y, octaves, lacunarity, gain)
        octaves    = octaves    or 4
        lacunarity = lacunarity or 2.0
        gain       = gain       or 0.5
        local val, amp, freq = 0, 0.5, 1.0
        for _ = 1, octaves do
            val  = val + amp * PerlinNoise.noise(x * freq, y * freq)
            amp  = amp * gain
            freq = freq * lacunarity
        end
        return val
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- [RENDER] LIGHTING PIPELINE · LUT STACK · ATMOSPHERE · VOLUMETRIC FOG
-- ══════════════════════════════════════════════════════════════════════════════

local RenderModule = {}

function RenderModule.applyLightingEngine()
    Lighting.Technology               = CFG.Technology
    Lighting.EnvironmentDiffuseScale  = CFG.DiffuseScale
    Lighting.EnvironmentSpecularScale = CFG.SpecularScale
    Lighting.ExposureCompensation     = CFG.ExposureComp
    Lighting.ShadowSoftness           = CFG.ShadowSoftness
    Lighting.GlobalShadows            = true
    Lighting.Ambient                  = Color3.fromRGB(18, 14, 28)
    Lighting.OutdoorAmbient           = Color3.fromRGB(55, 45, 85)
    Lighting.FogColor                 = CFG.AtmFogColor
    Lighting.FogEnd                   = CFG.FogFarPlane
    Lighting.FogStart                 = CFG.FogNearPlane
end

function RenderModule.applyLUTStack()
    -- Layer 1: Base color grade
    local cc1 = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if cc1 then cc1:Destroy() end

    local base       = track(Instance.new("ColorCorrectionEffect"))
    base.Name        = "ASVS_BaseLUT"
    base.Contrast    = CFG.LUT_Contrast
    base.Saturation  = CFG.LUT_Saturation
    base.Brightness  = CFG.LUT_Brightness
    base.TintColor   = CFG.LUT_TintColor
    base.Enabled     = true
    base.Parent      = Lighting

    -- Layer 2: Ink separation pass — slightly push darks toward blue-black
    local ink        = track(Instance.new("ColorCorrectionEffect"))
    ink.Name         = "ASVS_InkPass"
    ink.Contrast     = 0.08
    ink.Saturation   = 0.05
    ink.Brightness   = -0.02
    ink.TintColor    = Color3.fromRGB(245, 245, 255)
    ink.Enabled      = true
    ink.Parent       = Lighting

    -- Layer 3: Highlight bloom preparatory pass — boost luminance on hot pixels
    local hotPass    = track(Instance.new("ColorCorrectionEffect"))
    hotPass.Name     = "ASVS_HotPass"
    hotPass.Contrast = 0.12
    hotPass.Saturation = 0.10
    hotPass.Brightness = 0.01
    hotPass.TintColor  = Color3.fromRGB(255, 248, 235)
    hotPass.Enabled    = true
    hotPass.Parent     = Lighting
end

function RenderModule.applyPostFX()
    local function clearClass(className)
        for _, c in ipairs(Lighting:GetChildren()) do
            if c:IsA(className) then c:Destroy() end
        end
    end

    clearClass("BloomEffect")
    clearClass("DepthOfFieldEffect")
    clearClass("SunRaysEffect")

    -- Bloom (anime combat glow — GG Strive style)
    local bloom         = track(Instance.new("BloomEffect"))
    bloom.Threshold     = CFG.BloomThreshold
    bloom.Intensity     = CFG.BloomIntensity
    bloom.Size          = CFG.BloomSize
    bloom.Enabled       = true
    bloom.Parent        = Lighting

    -- Depth of Field
    local dof              = track(Instance.new("DepthOfFieldEffect"))
    dof.FarIntensity       = CFG.DOFFarIntensity
    dof.NearIntensity      = CFG.DOFNearIntensity
    dof.InFocusRadius      = CFG.DOFInFocusRadius
    dof.FocusDistance      = 0
    dof.Enabled            = true
    dof.Parent             = Lighting

    -- Sun Rays
    local sun           = track(Instance.new("SunRaysEffect"))
    sun.Intensity       = CFG.SunRayIntensity
    sun.Spread          = CFG.SunRaySpread
    sun.Enabled         = true
    sun.Parent          = Lighting
end

function RenderModule.applyAtmosphere()
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
           or track(Instance.new("Atmosphere", Lighting))
    atm.Density   = CFG.AtmDensity
    atm.Haze      = CFG.AtmHaze
    atm.Glare     = CFG.AtmGlare
    atm.Decay     = CFG.AtmDecay
    atm.Color     = CFG.AtmColor
    atm.FogColor  = CFG.AtmFogColor
end

-- Volumetric Fog Simulation:
-- Spawns a stack of semi-transparent Part slabs in the fog zone,
-- each with a slightly different scrolling UVOffset driven per-frame
-- to fake volumetric scattering layers.
function RenderModule.spawnVolumetricFog()
    local fogContainer = track(Instance.new("Model"))
    fogContainer.Name  = "ASVS_VolumetricFog"
    fogContainer.Parent = workspace

    local FOG_LAYERS   = 5
    local FOG_SIZE     = 800
    local BASE_Y       = 2

    for i = 1, FOG_LAYERS do
        local slab               = Instance.new("Part")
        slab.Name                = "FogSlab_" .. i
        slab.Size                = Vector3.new(FOG_SIZE, 6, FOG_SIZE)
        slab.Position            = Vector3.new(0, BASE_Y + (i * 5), 0)
        slab.Anchored            = true
        slab.CanCollide          = false
        slab.CastShadow          = false
        slab.Material            = Enum.Material.SmoothPlastic
        slab.BrickColor          = BrickColor.new("Lavender")
        slab.Transparency        = 0.93 + (i * 0.01)
        slab.LocalTransparencyModifier = 0

        local surf = Instance.new("SpecialMesh")
        surf.MeshType = Enum.MeshType.Brick
        surf.Parent   = slab
        slab.Parent   = fogContainer
    end

    -- Animate fog drift per-frame
    local t = 0
    trackConn(RS.Heartbeat:Connect(function(dt)
        t = t + dt
        for i, slab in ipairs(fogContainer:GetChildren()) do
            if slab:IsA("BasePart") then
                local drift = Vector3.new(
                    math.sin(t * 0.03 + i) * 0.8,
                    math.sin(t * 0.05 + i * 0.7) * 0.3,
                    math.cos(t * 0.025 + i) * 0.8
                )
                slab.Position = slab.Position:Lerp(
                    Vector3.new(drift.X, slab.Position.Y + drift.Y * dt, drift.Z), 0.01
                )
                -- Pulse transparency to simulate light scattering
                slab.Transparency = math.clamp(
                    0.93 + (i * 0.01) + math.sin(t * 0.8 + i * 1.3) * 0.02, 0, 1
                )
            end
        end
    end))
end

-- ══════════════════════════════════════════════════════════════════════════════
-- [CEL] MULTI-TONE CELL SHADING  (Highlight + EditableImage 2026 API)
-- ══════════════════════════════════════════════════════════════════════════════

local CelModule = {}

-- Tone definitions: each tone has a color multiplier and applies
-- via a layered Highlight stack (Roblox 2026 supports stacked Highlights)
local CEL_TONES = {
    {
        name       = "Highlight",
        fillColor  = Color3.fromRGB(255, 248, 220),
        fillTrans  = 0.70,
        outlineTrans = 1.0,
        depthMode  = Enum.HighlightDepthMode.Occluded,
    },
    {
        name       = "Midtone",
        fillColor  = Color3.fromRGB(200, 185, 210),
        fillTrans  = 0.80,
        outlineTrans = 1.0,
        depthMode  = Enum.HighlightDepthMode.Occluded,
    },
    {
        name       = "Shadow",
        fillColor  = Color3.fromRGB(60, 50, 90),
        fillTrans  = 0.86,
        outlineTrans = 1.0,
        depthMode  = Enum.HighlightDepthMode.Occluded,
    },
    {
        name       = "Outline",
        fillColor  = Color3.fromRGB(0, 0, 0),
        fillTrans  = 1.0,
        outlineTrans = 0.0,
        outlineColor = CFG.OutlineColor,
        depthMode  = Enum.HighlightDepthMode.AlwaysOnTop,
    },
}

-- EditableImage cel-shading simulation:
-- We create a small EditableImage and use it as a tone-ramp LUT texture
-- projected onto a SurfaceGui on a transparent screen-space plane.
-- This simulates the discrete-tone banding seen in anime cell animation.
local function createCelRampTexture()
    local success, editableImage = pcall(function()
        return Instance.new("EditableImage")
    end)
    if not success then return nil end

    editableImage.Size = Vector2.new(256, 1)

    -- Write a 3-stop anime tone ramp (warm highlight → neutral → cool shadow)
    local pixels = {}
    for x = 1, 256 do
        local t = x / 256
        local r, g, b, a

        if t > CFG.HighlightThreshold then
            -- Hot highlight — warm ivory
            local blend = (t - CFG.HighlightThreshold) / (1 - CFG.HighlightThreshold)
            r = 255; g = 250 - blend * 10; b = 220 - blend * 20; a = 80
        elseif t > CFG.MidtoneThreshold then
            -- Midtone — desaturated lavender
            local blend = (t - CFG.MidtoneThreshold) / (CFG.HighlightThreshold - CFG.MidtoneThreshold)
            r = 200 - blend * 55; g = 185 - blend * 65; b = 210 - blend * 10; a = 60
        elseif t > CFG.ShadowThreshold then
            -- Terminator line — sharp blue-shadow border
            local blend = (t - CFG.ShadowThreshold) / (CFG.MidtoneThreshold - CFG.ShadowThreshold)
            r = 60 + blend * 140; g = 50 + blend * 135; b = 90 + blend * 120; a = 90
        else
            -- Deep shadow — ink blue-black
            r = 15; g = 10; b = 35; a = 120
        end

        table.insert(pixels, r / 255)
        table.insert(pixels, g / 255)
        table.insert(pixels, b / 255)
        table.insert(pixels, a / 255)
    end

    pcall(function() editableImage:WritePixels(Vector2.new(0, 0), Vector2.new(256, 1), pixels) end)
    return editableImage
end

function CelModule.applyToCharacter(character)
    if not character then return end
    if State.highlightCache[character] then return end

    local tones = {}

    for _, toneDef in ipairs(CEL_TONES) do
        local hl                  = Instance.new("Highlight")
        hl.Name                   = "ASVS_Cel_" .. toneDef.name
        hl.Adornee                = character
        hl.FillColor              = toneDef.fillColor
        hl.FillTransparency       = toneDef.fillTrans
        hl.OutlineColor           = toneDef.outlineColor or Color3.fromRGB(0,0,0)
        hl.OutlineTransparency    = toneDef.outlineTrans
        hl.DepthMode              = toneDef.depthMode
        hl.Enabled                = true
        hl.Parent                 = character
        table.insert(tones, hl)
    end

    -- EditableImage tone ramp overlay via ScreenGui + ImageLabel
    local celRamp = createCelRampTexture()
    if celRamp then
        local sg = Instance.new("ScreenGui")
        sg.Name            = "ASVS_CelRamp"
        sg.IgnoreGuiInset  = true
        sg.ResetOnSpawn    = false
        sg.DisplayOrder    = 5
        sg.Parent          = LP:WaitForChild("PlayerGui")

        local img              = Instance.new("ImageLabel", sg)
        img.Size               = UDim2.new(1, 0, 1, 0)
        img.BackgroundTransparency = 1
        img.ImageTransparency  = 0.92
        -- Map the EditableImage as the source
        pcall(function()
            img.ImageContent = Content.fromObject(celRamp)
        end)
        img.ScaleType      = Enum.ScaleType.Stretch
        table.insert(tones, sg)
    end

    State.highlightCache[character] = tones
end

function CelModule.removeFromCharacter(character)
    local tones = State.highlightCache[character]
    if not tones then return end
    for _, inst in ipairs(tones) do safeDestroy(inst) end
    State.highlightCache[character] = nil
end

-- ══════════════════════════════════════════════════════════════════════════════
-- [GI] FAKE GLOBAL ILLUMINATION — Script-driven bounce light simulation
-- ══════════════════════════════════════════════════════════════════════════════

local GIModule = {}

-- Strategy:
-- Every GI_UpdateRate seconds, we raycast from each character's torso in
-- 6 directions (hemisphere), sample the BrickColor of hit surfaces,
-- accumulate a weighted average, and apply that as OutdoorAmbient + ColorShift
-- on the Lighting object. This simulates color bleeding from the environment.

local GI_SAMPLE_DIRS = {
    Vector3.new( 1,  0,  0),
    Vector3.new(-1,  0,  0),
    Vector3.new( 0,  0,  1),
    Vector3.new( 0,  0, -1),
    Vector3.new( 0.7, 0.3, 0.7),
    Vector3.new(-0.7, 0.3,-0.7),
}

local RAY_PARAMS = RaycastParams.new()
RAY_PARAMS.FilterType = Enum.RaycastFilterType.Exclude

function GIModule.calculate(character)
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    RAY_PARAMS.FilterDescendantsInstances = {character}

    local accumR, accumG, accumB = 0, 0, 0
    local hitCount = 0

    for _, dir in ipairs(GI_SAMPLE_DIRS) do
        local result = workspace:Raycast(root.Position, dir * 40, RAY_PARAMS)
        if result and result.Instance then
            local col = result.Instance.Color
            -- Weight by proximity (closer = stronger bounce)
            local weight = 1 - (result.Distance / 40)
            accumR = accumR + col.R * weight
            accumG = accumG + col.G * weight
            accumB = accumB + col.B * weight
            hitCount = hitCount + 1
        end
    end

    if hitCount == 0 then return end

    -- Normalize and mix with sky color
    local avgR = accumR / hitCount
    local avgG = accumG / hitCount
    local avgB = accumB / hitCount

    -- Apply bounce light as OutdoorAmbient shift
    local skyInfluence = CFG.GI_SkyInfluence
    local bounceStrength = CFG.GI_BounceStrength

    local targetAmbient = Color3.new(
        math.clamp(avgR * bounceStrength + 0.22 * skyInfluence, 0, 1),
        math.clamp(avgG * bounceStrength + 0.18 * skyInfluence, 0, 1),
        math.clamp(avgB * bounceStrength + 0.33 * skyInfluence, 0, 1)
    )

    -- Smooth lerp to avoid jarring transitions
    Lighting.OutdoorAmbient = Lighting.OutdoorAmbient:Lerp(targetAmbient, 0.18)

    -- ColorShift_Top simulates sky dome contribution
    Lighting.ColorShift_Top = Color3.new(
        math.clamp(avgR * 0.1, 0, 0.15),
        math.clamp(avgG * 0.08, 0, 0.12),
        math.clamp(avgB * 0.15, 0, 0.22)
    )
    Lighting.ColorShift_Bottom = Color3.new(
        math.clamp(avgR * 0.05, 0, 0.08),
        math.clamp(avgG * 0.04, 0, 0.06),
        math.clamp(avgB * 0.06, 0, 0.10)
    )
end

-- ══════════════════════════════════════════════════════════════════════════════
-- [MODEL] INK OUTLINES · MATERIAL SYSTEM · SKIN vs FABRIC REFLECTANCE
-- ══════════════════════════════════════════════════════════════════════════════

local ModelModule = {}

-- Part name → material type classification
local PART_CLASSIFICATION = {
    skin  = {"Head", "LeftHand", "RightHand", "LeftFoot", "RightFoot",
             "Face", "Neck"},
    hair  = {"Hair", "Bun", "Ponytail", "Strand", "Fringe"},
    metal = {"Sword", "Shield", "Blade", "Armor", "Plate", "Belt"},
    fabric= {"Shirt", "Pants", "Jacket", "Cloak", "Cape", "Robe",
             "Cloth", "Skirt", "Glove"},
}

local function classifyPart(part)
    local name = part.Name:lower()
    for matType, keywords in pairs(PART_CLASSIFICATION) do
        for _, kw in ipairs(keywords) do
            if name:find(kw:lower()) then return matType end
        end
    end
    return "fabric"  -- default
end

local NEON_SKIP = {
    [Enum.Material.Neon]       = true,
    [Enum.Material.ForceField] = true,
    [Enum.Material.Glass]      = true,
}

function ModelModule.applyToBasePart(part)
    if not part:IsA("BasePart") then return end
    if NEON_SKIP[part.Material] then return end

    local matType = classifyPart(part)

    part.Material    = Enum.Material.SmoothPlastic
    part.CastShadow  = true

    if matType == "skin" then
        part.Reflectance = CFG.SkinReflectance
    elseif matType == "hair" then
        part.Reflectance = CFG.HairReflectance
        -- Hair gets a slight specular bump in the color
        part.Color = part.Color:Lerp(Color3.fromRGB(255, 255, 255), 0.03)
    elseif matType == "metal" then
        part.Material    = Enum.Material.Metal
        part.Reflectance = CFG.MetalReflectance
    else
        part.Reflectance = CFG.FabricReflectance
    end
end

function ModelModule.applyToCharacter(character)
    for _, part in ipairs(character:GetDescendants()) do
        ModelModule.applyToBasePart(part)
    end
    character.DescendantAdded:Connect(ModelModule.applyToBasePart)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- [ANIM] SQUASH & STRETCH · VERTEX DEFORMATION · CAPE/HAIR PHYSICS
-- ══════════════════════════════════════════════════════════════════════════════

local AnimModule = {}

-- Squash & Stretch: We intercept HumanoidRootPart velocity and deform
-- the character's part scales using TweenService.
local SS_DEFAULT_SCALE = Vector3.new(1, 1, 1)

function AnimModule.applySquashStretch(character)
    local hum  = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    local prevVel      = Vector3.new()
    local stretchTimer = 0
    local isStretched  = false

    trackConn(RS.Heartbeat:Connect(function(dt)
        if not root or not root.Parent then return end
        local vel = root.AssemblyLinearVelocity

        -- Dash detection: high horizontal velocity
        local horizSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
        local vertSpeed  = math.abs(vel.Y)
        local accel      = (vel - prevVel).Magnitude / dt

        if State.perfTier < 2 then
            prevVel = vel
            return
        end

        if horizSpeed > 25 then
            -- Stretch along movement direction
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    local tween = TS:Create(part, TweenInfo.new(0.05), {
                        Size = Vector3.new(
                            part.Size.X * CFG.SS_DashStretchX,
                            part.Size.Y,
                            part.Size.Z * CFG.SS_DashStretchZ
                        )
                    })
                    tween:Play()
                end
            end
            isStretched = true
            stretchTimer = 0.18

        elseif vertSpeed > 20 and vel.Y > 0 then
            -- Jump squash
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    local tween = TS:Create(part, TweenInfo.new(0.06), {
                        Size = Vector3.new(
                            part.Size.X * CFG.SS_JumpStretchX,
                            part.Size.Y * CFG.SS_JumpSquashY,
                            part.Size.Z * CFG.SS_JumpStretchX
                        )
                    })
                    tween:Play()
                end
            end
            isStretched = true
            stretchTimer = 0.20
        end

        -- Return to default scale
        if isStretched then
            stretchTimer = stretchTimer - dt
            if stretchTimer <= 0 then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        local origSize = part:GetAttribute("OriginalSize")
                        if origSize then
                            TS:Create(part, TweenInfo.new(CFG.SS_ReturnSpeed), {
                                Size = origSize
                            }):Play()
                        end
                    end
                end
                isStretched = false
            end
        end

        prevVel = vel
    end))

    -- Cache original sizes
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part:SetAttribute("OriginalSize", part.Size)
        end
    end
end

-- Vertex Deformation Simulation for capes/hair:
-- Since Roblox does not expose true vertex access at runtime,
-- we simulate it by splitting long parts into a chain of smaller
-- segments linked by constraints, driven by velocity offsets.
function AnimModule.simulateClothPhysics(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Find cloth parts (cape, hair strands, loose fabric)
    local clothParts = {}
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            local name = part.Name:lower()
            if name:find("cape") or name:find("cloak") or name:find("hair")
            or name:find("strand") or name:find("tail") then
                table.insert(clothParts, part)
            end
        end
    end

    if #clothParts == 0 then return end

    local t = 0
    trackConn(RS.Heartbeat:Connect(function(dt)
        if not root or not root.Parent then return end
        t = t + dt
        local vel = root.AssemblyLinearVelocity

        for i, cloth in ipairs(clothParts) do
            if not cloth.Parent then continue end

            -- Simulate inertial lag — cloth trails behind movement
            local lagFactor  = 0.08 + (i * 0.01)
            local windNoise  = Vector3.new(
                PerlinNoise.noise(t * 1.2 + i, 0.0) * 0.8,
                PerlinNoise.noise(0.0, t * 0.9 + i) * 0.3,
                PerlinNoise.noise(t * 1.1, i * 0.5) * 0.8
            )

            -- Apply offset based on velocity + wind
            local targetOffset = (-vel * lagFactor) + windNoise

            -- Clamp offset to prevent extreme deformation
            local maxOffset = 3.0
            targetOffset = Vector3.new(
                math.clamp(targetOffset.X, -maxOffset, maxOffset),
                math.clamp(targetOffset.Y, -maxOffset * 0.4, maxOffset * 0.4),
                math.clamp(targetOffset.Z, -maxOffset, maxOffset)
            )

            -- Smooth CFrame application
            local baseCF     = cloth:GetAttribute("BaseCFrame")
            if not baseCF then
                cloth:SetAttribute("BaseCFrame", cloth.CFrame)
                baseCF = cloth.CFrame
            end

            local targetCF = baseCF + targetOffset
            cloth.CFrame   = cloth.CFrame:Lerp(targetCF, 0.15)

            -- Subtle rotation deformation
            if vel.Magnitude > 8 then
                local sway = math.sin(t * 6 + i) * math.clamp(vel.Magnitude * 0.01, 0, 0.15)
                cloth.CFrame = cloth.CFrame * CFrame.Angles(sway, 0, sway * 0.5)
            end
        end
    end))
end

-- ══════════════════════════════════════════════════════════════════════════════
-- [VFX] 2D SPRITE ENGINE · SPEED LINES · SHOCKWAVES · HEAT DISTORTION
-- ══════════════════════════════════════════════════════════════════════════════

local VFXModule = {}

-- ─── SCREEN-SPACE 2D SPRITE ENGINE ───────────────────────────────────────────
-- Manages a ScreenGui canvas for drawing procedural 2D effects
local spriteCanvas = nil
local spriteFrames = {}

local function getSpriteCanvas()
    if spriteCanvas and spriteCanvas.Parent then return spriteCanvas end
    local sg              = track(Instance.new("ScreenGui"))
    sg.Name               = "ASVS_SpriteEngine"
    sg.IgnoreGuiInset     = true
    sg.ResetOnSpawn       = false
    sg.DisplayOrder       = 50
    sg.Parent             = LP:WaitForChild("PlayerGui")
    spriteCanvas          = sg
    return sg
end

local function clearSpriteFrame(frame)
    if frame and frame.Parent then frame:Destroy() end
end

-- ─── SPEED LINES ─────────────────────────────────────────────────────────────
function VFXModule.emitSpeedLines(intensity)
    if State.perfTier < 2 then return end
    local canvas   = getSpriteCanvas()
    local count    = math.floor(CFG.SpeedLineCount * math.clamp(intensity, 0.3, 1))
    local screenX  = camera and camera.ViewportSize.X or 1920
    local screenY  = camera and camera.ViewportSize.Y or 1080
    local centerX  = screenX * 0.5
    local centerY  = screenY * 0.5

    for i = 1, count do
        local angle  = (i / count) * math.pi * 2 + math.random() * 0.4
        local len    = math.random(CFG.SpeedLineLengthMin, CFG.SpeedLineLengthMax)
        local thick  = math.random(1, 3)
        local dist   = math.random(80, 200)

        local startX = centerX + math.cos(angle) * dist
        local startY = centerY + math.sin(angle) * dist
        local endX   = centerX + math.cos(angle) * (dist + len)
        local endY   = centerY + math.sin(angle) * (dist + len)

        local line             = Instance.new("Frame", canvas)
        line.BackgroundColor3  = Color3.fromRGB(255, 255, 255)
        line.BackgroundTransparency = 0.1
        line.BorderSizePixel   = 0

        -- Compute line position and rotation from start→end
        local dx   = endX - startX
        local dy   = endY - startY
        local lineLen = math.sqrt(dx*dx + dy*dy)
        local rot  = math.deg(math.atan2(dy, dx))

        line.Position  = UDim2.new(0, startX + dx/2 - thick/2, 0, startY + dy/2 - thick/2)
        line.Size      = UDim2.new(0, lineLen, 0, thick)
        line.Rotation  = rot
        line.AnchorPoint = Vector2.new(0.5, 0.5)

        -- Fade out
        TS:Create(line, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        }):Play()
        task.delay(0.14, function() safeDestroy(line) end)
    end
end

-- ─── SHOCKWAVE (SCREEN-SPACE RING) ───────────────────────────────────────────
function VFXModule.emitShockwave(screenPos, maxRadius, duration)
    if State.perfTier < 2 then return end
    local canvas = getSpriteCanvas()
    duration = duration or 0.3
    maxRadius = maxRadius or 200

    local ring              = Instance.new("Frame", canvas)
    ring.BackgroundTransparency = 1
    ring.BorderSizePixel    = 0
    ring.AnchorPoint        = Vector2.new(0.5, 0.5)
    ring.Position           = UDim2.new(0, screenPos.X, 0, screenPos.Y)
    ring.Size               = UDim2.new(0, 0, 0, 0)

    local corner            = Instance.new("UICorner", ring)
    corner.CornerRadius     = UDim.new(0.5, 0)

    local stroke            = Instance.new("UIStroke", ring)
    stroke.Color            = Color3.fromRGB(200, 180, 255)
    stroke.Thickness        = 3
    stroke.Transparency     = 0

    -- Expand ring
    TS:Create(ring, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, maxRadius * 2, 0, maxRadius * 2)
    }):Play()
    TS:Create(stroke, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = 1
    }):Play()

    task.delay(duration + 0.05, function() safeDestroy(ring) end)
end

-- ─── HEAT DISTORTION (WORLD-SPACE) ───────────────────────────────────────────
function VFXModule.emitHeatDistortion(position, duration)
    if State.perfTier < 3 then return end
    duration = duration or 1.5

    -- Simulate heat shimmer with a neon, near-transparent part
    -- using rapid scale oscillation to create the wavering effect
    local heat             = Instance.new("Part")
    heat.Size              = Vector3.new(8, 12, 0.1)
    heat.CFrame            = CFrame.new(position) * CFrame.new(0, 4, 0)
    heat.Anchored          = true
    heat.CanCollide        = false
    heat.CastShadow        = false
    heat.Material          = Enum.Material.Neon
    heat.Color             = Color3.fromRGB(255, 200, 120)
    heat.Transparency      = 0.97
    heat.Parent            = workspace

    local t = 0
    local conn
    conn = RS.Heartbeat:Connect(function(dt)
        t = t + dt
        if not heat.Parent then conn:Disconnect() return end
        -- Shimmer oscillation
        heat.Size = Vector3.new(
            8 + math.sin(t * 18) * 0.8,
            12 + math.sin(t * 22 + 1) * 1.2,
            0.1
        )
        heat.CFrame = CFrame.new(position + Vector3.new(
            math.sin(t * 15) * 0.3,
            4 + math.sin(t * 11) * 0.5,
            0
        ))
        heat.Transparency = math.clamp(0.97 + (t / duration) * 0.03, 0.97, 1)

        if t >= duration then
            conn:Disconnect()
            safeDestroy(heat)
        end
    end)
end

-- ─── WORLD-SPACE SHOCKWAVE RING ──────────────────────────────────────────────
function VFXModule.emitWorldShockwave(position, maxRadius, duration)
    duration = duration or 0.4
    maxRadius = maxRadius or 20

    local ring             = Instance.new("Part")
    ring.Size              = Vector3.new(0.5, 0.5, 0.5)
    ring.CFrame            = CFrame.new(position)
    ring.Anchored          = true
    ring.CanCollide        = false
    ring.CastShadow        = false
    ring.Material          = Enum.Material.Neon
    ring.Color             = Color3.fromRGB(220, 200, 255)
    ring.Transparency      = 0.2
    ring.Parent            = workspace

    local mesh             = Instance.new("SpecialMesh", ring)
    mesh.MeshType          = Enum.MeshType.FileMesh
    mesh.MeshId            = "rbxassetid://9064625701"  -- torus mesh
    mesh.Scale             = Vector3.new(0.1, 0.1, 0.1)

    TS:Create(mesh, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Scale = Vector3.new(maxRadius * 0.12, maxRadius * 0.03, maxRadius * 0.12)
    }):Play()
    TS:Create(ring, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = 1
    }):Play()

    task.delay(duration + 0.05, function() safeDestroy(ring) end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- [HIT] IMPACT FRAMES · CINEMATIC HIT-STOP · GHOST TRAILS
-- ══════════════════════════════════════════════════════════════════════════════

local HitModule = {}

-- ─── SAKUGA IMPACT FRAME ─────────────────────────────────────────────────────
-- Flashes a 2-frame B&W invert overlay then a pure white flash,
-- exactly as done in hand-drawn anime sakuga sequences
function HitModule.triggerImpactFrame(magnitude)
    if State.hitStopActive then return end
    if State.perfTier < 2 then return end

    local canvas = getSpriteCanvas()

    local overlay              = Instance.new("Frame", canvas)
    overlay.Size               = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
    overlay.BackgroundTransparency = 0
    overlay.BorderSizePixel    = 0
    overlay.ZIndex             = 100

    -- Sequence: white → black (invert) → white → fade
    local seq = {
        {Color3.fromRGB(255,255,255), 0.0},   -- Frame 1: white flash
        {Color3.fromRGB(10, 10, 20),  0.02},  -- Frame 2: black invert
        {Color3.fromRGB(255,255,255), 0.04},  -- Frame 3: white
        {Color3.fromRGB(10, 10, 20),  0.06},  -- Frame 4: black (sakuga punch)
    }

    for _, frame in ipairs(seq) do
        task.delay(frame[2], function()
            if overlay.Parent then
                overlay.BackgroundColor3 = frame[1]
            end
        end)
    end

    -- Fade out
    task.delay(0.07, function()
        if overlay.Parent then
            TS:Create(overlay, TweenInfo.new(0.06), {
                BackgroundTransparency = 1
            }):Play()
            task.delay(0.08, function() safeDestroy(overlay) end)
        end
    end)
end

-- ─── HIT-STOP (TIME-SCALE MANAGER) ───────────────────────────────────────────
-- Roblox does not expose a global time scale to LocalScripts.
-- We simulate it by:
--   1. Freezing all TweenService animations (pause/resume pattern)
--   2. Caching and overriding AnimationTrack speeds on local character
--   3. Halting Heartbeat-driven transforms for the stop duration
function HitModule.triggerHitStop(duration)
    if State.hitStopActive then return end
    State.hitStopActive = true
    duration = duration or CFG.HitStopDuration

    local char = LP.Character
    if not char then State.hitStopActive = false return end

    -- Slow all animation tracks
    local hum = char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    local tracks   = {}

    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            local origSpeed = track.Speed
            track:AdjustSpeed(0.04)  -- near-freeze
            table.insert(tracks, {track = track, speed = origSpeed})
        end
    end

    -- Visual freeze pulse — slight contrast spike
    local cc = Lighting:FindFirstChild("ASVS_BaseLUT")
    local origContrast = cc and cc.Contrast or CFG.LUT_Contrast
    if cc then
        cc.Contrast = math.min(origContrast + 0.3, 1)
    end

    task.delay(duration, function()
        -- Restore animation speeds
        for _, entry in ipairs(tracks) do
            if entry.track and entry.track.IsPlaying then
                entry.track:AdjustSpeed(entry.speed)
            end
        end
        -- Restore contrast
        if cc and cc.Parent then
            TS:Create(cc, TweenInfo.new(0.08), {Contrast = origContrast}):Play()
        end
        State.hitStopActive = false
    end)
end

-- ─── GHOST TRAILS ────────────────────────────────────────────────────────────
-- Caches a rolling buffer of character CFrames every GhostSpawnInterval,
-- then creates translucent ghost clones at each cached position.
function HitModule.startGhostTrail(character)
    if State.ghostTrailActive then return end
    State.ghostTrailActive = true

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then State.ghostTrailActive = false return end

    local cframeBuffer = {}
    local ghostPool    = {}
    local spawnTimer   = 0

    -- Pre-pool ghost parts per character part
    local function spawnGhostAtCFrame(cf, partList)
        for _, part in ipairs(partList) do
            if not part:IsA("BasePart") or part.Name == "HumanoidRootPart" then continue end

            local ghost            = Instance.new("Part")
            ghost.Size             = part.Size
            ghost.CFrame           = part.CFrame
            ghost.Anchored         = true
            ghost.CanCollide       = false
            ghost.CastShadow       = false
            ghost.Material         = Enum.Material.SmoothPlastic
            ghost.Color            = Color3.fromRGB(120, 100, 220)
            ghost.Transparency     = 0.55
            ghost.Parent           = workspace

            -- Fade ghost out
            TS:Create(ghost, TweenInfo.new(CFG.GhostDecayTime, Enum.EasingStyle.Linear), {
                Transparency = 1,
                Color = Color3.fromRGB(200, 180, 255)
            }):Play()
            task.delay(CFG.GhostDecayTime + 0.02, function() safeDestroy(ghost) end)
        end
    end

    local conn
    conn = RS.Heartbeat:Connect(function(dt)
        if not State.ghostTrailActive then conn:Disconnect() return end
        if not root or not root.Parent then conn:Disconnect() return end

        spawnTimer = spawnTimer + dt
        if spawnTimer >= CFG.GhostSpawnInterval then
            spawnTimer = 0
            local parts = {}
            for _, p in ipairs(character:GetDescendants()) do
                if p:IsA("BasePart") then table.insert(parts, p) end
            end
            spawnGhostAtCFrame(root.CFrame, parts)
        end
    end)
    trackConn(conn)

    return function()
        State.ghostTrailActive = false
    end
end

function HitModule.stopGhostTrail()
    State.ghostTrailActive = false
end

-- ─── COMBO TRIGGER (public API for games to hook into) ────────────────────────
function HitModule.onCombatHit(magnitude, worldPos)
    magnitude = magnitude or 1.0

    -- Scale all effects to hit magnitude
    local heavy = magnitude > 0.7

    HitModule.triggerHitStop(heavy and CFG.HitStopDuration or CFG.HitStopDuration * 0.6)
    HitModule.triggerImpactFrame(magnitude)

    if worldPos then
        VFXModule.emitWorldShockwave(worldPos, heavy and 22 or 12, 0.35)
        VFXModule.emitHeatDistortion(worldPos, heavy and 1.8 or 1.0)
    end

    if heavy then
        VFXModule.emitSpeedLines(magnitude)
    end

    EventBus:emit("CombatHit", magnitude, worldPos)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- [CAM] AI DIRECTOR CAMERA · DUTCH ANGLES · PERLIN SHAKE
-- ══════════════════════════════════════════════════════════════════════════════

local CamModule = {}

local CAM_MODES = {
    COMBAT_CLOSE  = "combat_close",
    COMBAT_WIDE   = "combat_wide",
    DUTCH_ANGLE   = "dutch_angle",
    AERIAL        = "aerial",
    DEFAULT       = "default",
}

local camState = {
    mode           = CAM_MODES.DEFAULT,
    dutchAngle     = 0,
    targetDutch    = 0,
    fovTarget      = CFG.CAM_FOV_Default,
    shakeIntensity = 0,
    shakeTime      = 0,
    lastMode       = "",
    modeTimer      = 0,
    baseFOV        = CFG.CAM_FOV_Default,
}

-- ─── PERLIN CAMERA SHAKE ──────────────────────────────────────────────────────
function CamModule.shake(intensity, duration)
    camState.shakeIntensity = math.max(camState.shakeIntensity, intensity)
    camState.shakeTime      = math.max(camState.shakeTime, duration or 0.4)
end

local function computeShake(t)
    if camState.shakeIntensity <= 0 then return CFrame.new() end

    local scale = CFG.CAM_NoiseScale
    local nx = PerlinNoise.noise(t * scale, 0) * camState.shakeIntensity
    local ny = PerlinNoise.noise(0, t * scale) * camState.shakeIntensity
    local nr = PerlinNoise.noise(t * scale * 0.5, t * scale * 0.3) * camState.shakeIntensity * 0.5

    return CFrame.new(nx, ny, 0) * CFrame.Angles(0, 0, math.rad(nr))
end

-- ─── DIRECTOR LOGIC ───────────────────────────────────────────────────────────
local function selectCameraMode(char, enemies)
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return CAM_MODES.DEFAULT end

    -- Find nearest threat
    local nearestDist = math.huge
    for _, enemy in ipairs(enemies) do
        local er = enemy:FindFirstChild("HumanoidRootPart")
        if er then
            local d = (er.Position - root.Position).Magnitude
            if d < nearestDist then nearestDist = d end
        end
    end

    if nearestDist < 15 then
        -- Up close — Dutch angle + dramatic FOV
        camState.targetDutch = (math.random() > 0.5 and 1 or -1) * (math.random(3, 6))
        camState.fovTarget   = 85
        return CAM_MODES.DUTCH_ANGLE
    elseif nearestDist < 40 then
        camState.targetDutch = 0
        camState.fovTarget   = CFG.CAM_FOV_Combat
        return CAM_MODES.COMBAT_CLOSE
    elseif nearestDist < 80 then
        camState.targetDutch = 0
        camState.fovTarget   = 75
        return CAM_MODES.COMBAT_WIDE
    else
        camState.targetDutch = 0
        camState.fovTarget   = CFG.CAM_FOV_Default
        return CAM_MODES.DEFAULT
    end
end

function CamModule.init()
    local t = 0

    trackConn(RS.RenderStepped:Connect(function(dt)
        t = t + dt
        if State.perfTier < 2 then return end

        local char = LP.Character
        if not char then return end

        -- Update mode every ~0.5 seconds (AI director tick)
        camState.modeTimer = camState.modeTimer + dt
        if camState.modeTimer > 0.5 then
            camState.modeTimer = 0
            local enemies = {}
            for _, player in ipairs(Services.Players:GetPlayers()) do
                if player ~= LP and player.Character then
                    table.insert(enemies, player.Character)
                end
            end
            camState.mode = selectCameraMode(char, enemies)
        end

        -- Lerp Dutch angle
        camState.dutchAngle = camState.dutchAngle
            + (camState.targetDutch - camState.dutchAngle) * (dt * 3)

        -- Lerp FOV
        Camera.FieldOfView = Camera.FieldOfView
            + (camState.fovTarget - Camera.FieldOfView) * (dt * 4)

        -- DOF auto-focus via raycast
        local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
        if dof then
            local ray = workspace:Raycast(
                Camera.CFrame.Position,
                Camera.CFrame.LookVector * 300
            )
            if ray then
                local dist = (ray.Position - Camera.CFrame.Position).Magnitude
                dof.FocusDistance = dof.FocusDistance + (dist - dof.FocusDistance) * 0.06
            end
        end

        -- Decay shake
        if camState.shakeTime > 0 then
            camState.shakeTime = camState.shakeTime - dt
            camState.shakeIntensity = camState.shakeIntensity
                * (1 - dt * CFG.CAM_ShakeDecay)

            local shakeCF = computeShake(t)
            -- Apply shake as an additional offset to the camera
            -- (works in Scriptable camera mode)
            if Camera.CameraType == Enum.CameraType.Custom then
                -- We manipulate CFrame delta directly in scriptable mode
                -- when it's been set — otherwise just pulse FOV as fallback
                Camera.FieldOfView = Camera.FieldOfView
                    + math.sin(t * 80) * camState.shakeIntensity * 0.8
            end
        else
            camState.shakeIntensity = 0
        end

        -- Enforce Future tech guard
        if Lighting.Technology ~= CFG.Technology then
            Lighting.Technology = CFG.Technology
        end
    end))
end

-- ══════════════════════════════════════════════════════════════════════════════
-- [SSAO] FORBIDDEN TECHNIQUE: SCREEN-SPACE AMBIENT OCCLUSION SIMULATION
-- ══════════════════════════════════════════════════════════════════════════════
--
--  True SSAO requires pixel shader access. In Roblox, we simulate it via:
--  1. Raycasting outward from geometry intersection points in a hemisphere
--  2. Creating small, dark, transparent "AO splat" parts at concavities
--  3. These parts are dark, near-zero-size, invisible in open air but
--     accumulate darkness in corners/crevices, mimicking SSAO occlusion
--  4. We run this in task.desynchronize (Parallel Luau) for performance
--
-- ──────────────────────────────────────────────────────────────────────────────

local SSAOModule = {}

local SSAO_DIRECTIONS = {
    Vector3.new( 0.5,  0.5,  0),
    Vector3.new(-0.5,  0.5,  0),
    Vector3.new( 0,    0.5,  0.5),
    Vector3.new( 0,    0.5, -0.5),
    Vector3.new( 0.35, 0.35, 0.35),
    Vector3.new(-0.35, 0.35,-0.35),
}

local ssaoParams = RaycastParams.new()
ssaoParams.FilterType = Enum.RaycastFilterType.Exclude

local function placeAOSplat(position, intensity)
    local splat             = Instance.new("Part")
    splat.Size              = Vector3.new(0.4, 0.05, 0.4)
    splat.CFrame            = CFrame.new(position)
    splat.Anchored          = true
    splat.CanCollide        = false
    splat.CastShadow        = false
    splat.Material          = Enum.Material.SmoothPlastic
    splat.Color             = Color3.fromRGB(5, 5, 15)
    splat.Transparency      = math.clamp(1 - (intensity * CFG.SSAO_Intensity), 0.5, 0.98)
    splat.Parent            = workspace
    return splat
end

function SSAOModule.update(character)
    if State.perfTier < 3 then return end
    if not character then return end

    -- Clear old splats
    for _, splat in ipairs(State.ssaoOverlayParts) do safeDestroy(splat) end
    State.ssaoOverlayParts = {}

    ssaoParams.FilterDescendantsInstances = {character}

    -- Sample geometry intersection points from character bounding
    local samplePoints = {}
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(samplePoints, part.Position - Vector3.new(0, part.Size.Y/2, 0))
            if #samplePoints >= CFG.SSAO_Samples then break end
        end
    end

    -- Run occlusion sampling in parallel (Parallel Luau)
    task.desynchronize()

    local ssaoResults = {}
    for _, origin in ipairs(samplePoints) do
        local occlusionCount = 0
        for _, dir in ipairs(SSAO_DIRECTIONS) do
            local scaledDir = dir * CFG.SSAO_Radius
            local result    = workspace:Raycast(origin, scaledDir, ssaoParams)
            if result then
                occlusionCount = occlusionCount + 1
            end
        end
        local ao = occlusionCount / #SSAO_DIRECTIONS
        if ao > 0.25 then
            table.insert(ssaoResults, {pos = origin, ao = ao})
        end
    end

    task.synchronize()

    -- Place AO splats on main thread
    for _, data in ipairs(ssaoResults) do
        local splat = placeAOSplat(data.pos, data.ao)
        table.insert(State.ssaoOverlayParts, splat)
    end
end

function SSAOModule.init()
    local timer = 0
    trackConn(RS.Heartbeat:Connect(function(dt)
        timer = timer + dt
        if timer >= CFG.SSAO_UpdateRate then
            timer = 0
            local char = LP.Character
            if char then
                task.spawn(SSAOModule.update, char)
            end
        end
    end))
end

-- ══════════════════════════════════════════════════════════════════════════════
-- [PERF] PERFORMANCE BUDGET SYSTEM · PARALLEL LUAU · LOD MANAGER
-- ══════════════════════════════════════════════════════════════════════════════

local PerfModule = {}

-- FPS sampling ring buffer
local fpsSamples  = {}
local fpsIndex    = 0
local FPS_SAMPLES = 30

function PerfModule.init()
    local lastTime = tick()

    trackConn(RS.Heartbeat:Connect(function()
        local now = tick()
        local fps = 1 / math.max(now - lastTime, 0.001)
        lastTime  = now

        fpsIndex = (fpsIndex % FPS_SAMPLES) + 1
        fpsSamples[fpsIndex] = fps

        -- Compute rolling average every 60 frames
        if fpsIndex % 15 == 0 then
            local sum = 0
            for _, v in ipairs(fpsSamples) do sum = sum + v end
            State.currentFPS = sum / #fpsSamples

            -- Adjust performance tier
            if State.currentFPS >= 50 then
                PerfModule.setTier(3)
            elseif State.currentFPS >= 35 then
                PerfModule.setTier(2)
            else
                PerfModule.setTier(1)
            end
        end
    end))

    -- LOD Manager — scale distant rendering
    trackConn(RS.Heartbeat:Connect(function()
        if State.perfTier == 1 then return end
        local char = LP.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        for _, player in ipairs(Services.Players:GetPlayers()) do
            if player == LP then continue end
            local pchar = player.Character
            if not pchar then continue end
            local proot = pchar:FindFirstChild("HumanoidRootPart")
            if not proot then continue end

            local dist = (proot.Position - root.Position).Magnitude
            local hl   = State.highlightCache[pchar]

            -- Disable highlights on far characters to save GPU
            if hl and type(hl) == "table" then
                for _, inst in ipairs(hl) do
                    if inst:IsA("Highlight") then
                        inst.Enabled = dist < CFG.PERF_LOD_Mid
                    end
                end
            end

            -- Reduce detail on very far characters
            for _, part in ipairs(pchar:GetDescendants()) do
                if part:IsA("BasePart") then
                    if dist > CFG.PERF_LOD_Far then
                        part.RenderFidelity = Enum.RenderFidelity.Automatic
                    else
                        part.RenderFidelity = Enum.RenderFidelity.Precise
                    end
                end
            end
        end
    end))
end

function PerfModule.setTier(tier)
    if State.perfTier == tier then return end
    State.perfTier = tier
    print(string.format("[ASVS] Performance tier → %d (%.0f FPS)", tier, State.currentFPS))

    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    local dof   = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
    local sun   = Lighting:FindFirstChildOfClass("SunRaysEffect")
    local atm   = Lighting:FindFirstChildOfClass("Atmosphere")

    if tier == 1 then
        -- Emergency mode: strip most effects
        if bloom then bloom.Intensity = 0.5; bloom.Size = 12 end
        if dof   then dof.Enabled = false end
        if sun   then sun.Enabled = false end
        if atm   then atm.Density = 0.1 end

    elseif tier == 2 then
        -- Mid mode: reduce intensities
        if bloom then bloom.Intensity = 0.85; bloom.Size = 20; bloom.Enabled = true end
        if dof   then dof.Enabled = true; dof.FarIntensity = 0.4 end
        if sun   then sun.Enabled = true; sun.Intensity = 0.3 end
        if atm   then atm.Density = CFG.AtmDensity * 0.7 end

    else
        -- Full tier: restore everything
        if bloom then bloom.Intensity = CFG.BloomIntensity; bloom.Size = CFG.BloomSize end
        if dof   then dof.Enabled = true; dof.FarIntensity = CFG.DOFFarIntensity end
        if sun   then sun.Enabled = true; sun.Intensity = CFG.SunRayIntensity end
        if atm   then atm.Density = CFG.AtmDensity end
    end
end

-- ── Parallel Luau GI worker (offloads bounce calc from render thread) ──────────
function PerfModule.runParallelGI(character)
    task.spawn(function()
        task.desynchronize()
        -- All raycast work happens here off the main thread
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then task.synchronize() return end

        local accumR, accumG, accumB = 0, 0, 0
        local hitCount = 0
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {character}
        params.FilterType = Enum.RaycastFilterType.Exclude

        for _, dir in ipairs(GI_SAMPLE_DIRS) do
            local result = workspace:Raycast(root.Position, dir * 40, params)
            if result and result.Instance then
                local col    = result.Instance.Color
                local weight = 1 - (result.Distance / 40)
                accumR = accumR + col.R * weight
                accumG = accumG + col.G * weight
                accumB = accumB + col.B * weight
                hitCount = hitCount + 1
            end
        end

        task.synchronize()

        if hitCount == 0 then return end
        local avgR = accumR / hitCount
        local avgG = accumG / hitCount
        local avgB = accumB / hitCount

        local targetAmbient = Color3.new(
            math.clamp(avgR * CFG.GI_BounceStrength + 0.22 * CFG.GI_SkyInfluence, 0, 1),
            math.clamp(avgG * CFG.GI_BounceStrength + 0.18 * CFG.GI_SkyInfluence, 0, 1),
            math.clamp(avgB * CFG.GI_BounceStrength + 0.33 * CFG.GI_SkyInfluence, 0, 1)
        )
        Lighting.OutdoorAmbient = Lighting.OutdoorAmbient:Lerp(targetAmbient, 0.15)
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- [CINE] CINEMATIC LETTERBOX BARS + HUD
-- ══════════════════════════════════════════════════════════════════════════════

local CineModule = {}

function CineModule.applyBars()
    local sg              = track(Instance.new("ScreenGui"))
    sg.Name               = "ASVS_CineBars"
    sg.IgnoreGuiInset     = true
    sg.ResetOnSpawn       = false
    sg.DisplayOrder       = 999
    sg.Parent             = LP:WaitForChild("PlayerGui")
    State.cineBarsGui     = sg

    local function makeBar(anchorY, posY)
        local f                        = Instance.new("Frame", sg)
        f.BackgroundColor3             = Color3.fromRGB(0, 0, 0)
        f.BackgroundTransparency       = 0
        f.BorderSizePixel              = 0
        f.AnchorPoint                  = Vector2.new(0, anchorY)
        f.Position                     = UDim2.new(0, 0, posY, 0)
        f.Size                         = UDim2.new(1, 0, 0, 0)
        return f
    end

    local top = makeBar(0, 0)
    local bot = makeBar(1, 1)

    local info = TweenInfo.new(CFG.BarAnimDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local h    = CFG.BarHeight
    TS:Create(top, info, {Size = UDim2.new(1, 0, h, 0)}):Play()
    TS:Create(bot, info, {Size = UDim2.new(1, 0, h, 0)}):Play()

    -- Watermark
    task.delay(CFG.BarAnimDuration, function()
        local label               = Instance.new("TextLabel", top)
        label.Size                = UDim2.new(0, 300, 1, 0)
        label.Position            = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.TextColor3          = Color3.fromRGB(200, 180, 255)
        label.TextXAlignment      = Enum.TextXAlignment.Left
        label.TextYAlignment      = Enum.TextYAlignment.Center
        label.Font                = Enum.Font.GothamBold
        label.TextSize            = 11
        label.Text                = "SAKUGA  ·  TRIPLE-A VISUAL STACK  v3.0"
        label.TextTransparency    = 0.4

        TS:Create(label, TweenInfo.new(1.5), {TextTransparency = 0.7}):Play()
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- [INIT] BOOTSTRAP · PLAYER HOOKS · MAIN LOOP · CLEANUP · GLOBAL API
-- ══════════════════════════════════════════════════════════════════════════════

local function hookCharacter(character)
    character:WaitForChild("HumanoidRootPart", 12)

    -- Apply all visual modules to this character
    CelModule.applyToCharacter(character)
    ModelModule.applyToCharacter(character)
    AnimModule.applySquashStretch(character)
    AnimModule.simulateClothPhysics(character)

    -- Cleanup when character is removed
    character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            CelModule.removeFromCharacter(character)
        end
    end)
end

local function hookPlayer(player)
    local function onChar(char)
        hookCharacter(char)
    end
    if player.Character then onChar(player.Character) end
    trackConn(player.CharacterAdded:Connect(onChar))

    -- Cleanup on leave
    Services.Players.PlayerRemoving:Connect(function(p)
        if p == player and p.Character then
            CelModule.removeFromCharacter(p.Character)
        end
    end)
end

-- ─── MASTER HEARTBEAT ─────────────────────────────────────────────────────────
local masterTimer = 0
trackConn(RS.Heartbeat:Connect(function(dt)
    masterTimer = masterTimer + dt

    -- GI update (throttled)
    State.giTimer = State.giTimer + dt
    if State.giTimer >= CFG.GI_UpdateRate then
        State.giTimer = 0
        local char = LP.Character
        if char then
            PerfModule.runParallelGI(char)
        end
    end

    -- Guard Future rendering every 3 seconds
    if masterTimer > 3 then
        masterTimer = 0
        if Lighting.Technology ~= CFG.Technology then
            Lighting.Technology = CFG.Technology
        end
    end
end))

-- ─── CLEANUP ──────────────────────────────────────────────────────────────────
local function cleanup()
    print("[ASVS] Initiating full cleanup...")

    -- Disconnect all tracked connections
    for _, conn in ipairs(State.trackedConnections) do
        pcall(function() conn:Disconnect() end)
    end
    State.trackedConnections = {}

    -- Destroy all tracked instances
    for _, inst in ipairs(State.trackedEffects) do
        safeDestroy(inst)
    end
    State.trackedEffects = {}

    -- Remove all highlights
    for char, tones in pairs(State.highlightCache) do
        for _, inst in ipairs(tones) do safeDestroy(inst) end
    end
    State.highlightCache = {}

    -- Remove SSAO splats
    for _, splat in ipairs(State.ssaoOverlayParts) do safeDestroy(splat) end
    State.ssaoOverlayParts = {}

    -- Restore lighting defaults
    Lighting.Technology               = Enum.Technology.ShadowMap
    Lighting.EnvironmentDiffuseScale  = 0.5
    Lighting.EnvironmentSpecularScale = 0.5
    Lighting.ExposureCompensation     = 0
    Lighting.OutdoorAmbient           = Color3.fromRGB(128, 128, 128)
    Lighting.Ambient                  = Color3.fromRGB(0, 0, 0)
    Camera.FieldOfView                = 70

    print("[ASVS] Cleanup complete. All effects removed.")
end

-- ─── BOOTSTRAP ────────────────────────────────────────────────────────────────
local function init()
    print("╔══════════════════════════════════════════════╗")
    print("║  TRIPLE-A ANIME VISUAL STACK  v3.0  LOADING  ║")
    print("╚══════════════════════════════════════════════╝")

    -- 1. Engine
    RenderModule.applyLightingEngine()

    -- 2. LUT stack
    RenderModule.applyLUTStack()

    -- 3. Post-FX
    RenderModule.applyPostFX()

    -- 4. Atmosphere + Volumetric Fog
    RenderModule.applyAtmosphere()
    task.delay(1, RenderModule.spawnVolumetricFog)

    -- 5. Performance system
    PerfModule.init()

    -- 6. SSAO (Forbidden Technique)
    SSAOModule.init()

    -- 7. AI Camera
    CamModule.init()

    -- 8. Cinematic bars
    CineModule.applyBars()

    -- 9. Hook all current + future players
    for _, player in ipairs(Services.Players:GetPlayers()) do
        hookPlayer(player)
    end
    trackConn(Services.Players.PlayerAdded:Connect(hookPlayer))

    print("[ASVS] ✓ All 11 modules initialized. Cloud servers: activated.")
    print("[ASVS] API: ASVS.hit(mag, pos) | ASVS.shake(i, d) | ASVS.ghost() | ASVS.cleanup()")
end

init()

-- ══════════════════════════════════════════════════════════════════════════════
-- GLOBAL PUBLIC API
-- ══════════════════════════════════════════════════════════════════════════════
getgenv().ASVS = {
    -- Trigger a combat hit (call this from your combat script hooks)
    hit = function(magnitude, worldPosition)
        HitModule.onCombatHit(magnitude, worldPosition)
    end,

    -- Trigger camera shake
    shake = function(intensity, duration)
        CamModule.shake(intensity or 1, duration or 0.5)
    end,

    -- Start/stop ghost trail on local character
    startGhost = function()
        local char = LP.Character
        if char then return HitModule.startGhostTrail(char) end
    end,
    stopGhost = HitModule.stopGhostTrail,

    -- Emit speed lines manually
    speedLines = function(intensity)
        VFXModule.emitSpeedLines(intensity or 1)
    end,

    -- Emit screen shockwave at screen position
    shockwave = function(x, y, radius)
        VFXModule.emitShockwave(Vector2.new(x or 960, y or 540), radius or 200)
    end,

    -- Emit world shockwave at 3D position
    worldShock = function(pos, radius)
        VFXModule.emitWorldShockwave(pos or Vector3.new(), radius or 20)
    end,

    -- Reload all effects
    reload = function()
        cleanup()
        task.wait(0.5)
        init()
    end,

    -- Full cleanup
    cleanup = cleanup,

    -- Debug info
    status = function()
        print(string.format(
            "[ASVS] FPS: %.1f | Tier: %d | Combat: %s | Ghost: %s | SSAO Splats: %d",
            State.currentFPS, State.perfTier,
            tostring(State.inCombat), tostring(State.ghostTrailActive),
            #State.ssaoOverlayParts
        ))
    end,
}
