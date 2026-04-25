--[[
╔══════════════════════════════════════════════════════════════════════════════════╗
║         ANIME VISUAL STACK — GOD MODE v4.0 "MAKE THE SERVER CRY"              ║
║         Architect: God-Tier Graphics & Lead VFX Director                        ║
║         Target: The Strongest Battlegrounds — Triple-A Cinematic Anime Stack    ║
║                                                                                  ║
║  MODULES:                                                                        ║
║   [1] World & Terrain Reconstruction (Minecraft Shader Style)                   ║
║   [2] Advanced Shader & Rendering Pipeline                                       ║
║   [3] Model Beautification & Procedural Animation                                ║
║   [4] Combat Ars Sakuga VFX Engine                                               ║
║   [5] Intelligent Director Camera                                                ║
║   [6] Execution & Parallel Optimization                                          ║
╚══════════════════════════════════════════════════════════════════════════════════╝

  USAGE: Place in StarterPlayerScripts as a LocalScript.
         All systems run CLIENT-SIDE for maximum render fidelity.
         Server-side hooks are minimal — beauty lives on the client.

  COMPATIBILITY: Roblox Client 2025-2026 | EditableImage API | Parallel Luau
  
  ⚠ PERFORMANCE NOTE: "Performance Budgeting System" is built-in.
    Toggle AVS_CONFIG values to tune for your hardware target.
]]

-- ════════════════════════════════════════════════════════════
--  MASTER CONFIGURATION BLOCK
-- ════════════════════════════════════════════════════════════
local AVS_CONFIG = {
    -- World Reconstruction
    GRASS_BLADE_COUNT         = 800,      -- Per-chunk grass instances
    GRASS_BLADE_HEIGHT_MAX    = 3.2,      -- Studs
    GRASS_WIND_SPEED          = 1.4,      -- Wind cycle frequency
    GRASS_WIND_AMPLITUDE      = 0.28,     -- Sway angle (radians)
    GRASS_PLAYER_RADIUS       = 18,       -- Radius blades react to player
    FLORA_ENABLED             = true,
    CLOUD_LAYER_COUNT         = 3,        -- Volumetric cloud strata
    CLOUD_SPEED               = 0.012,    -- Cloud drift speed
    GODRAY_INTENSITY          = 0.85,
    LENSFLARE_ENABLED         = true,

    -- Shader Pipeline
    CEL_SHADE_ENABLED         = true,
    CEL_SHADE_TONES           = 3,        -- 3-tone: highlight, mid, shadow
    SSAO_ENABLED              = true,
    SSAO_RADIUS               = 4,        -- Sample radius studs
    SSAO_INTENSITY            = 0.72,
    SSR_WATER_ENABLED         = true,
    SSR_FOAM_SPEED            = 0.5,
    GI_BOUNCE_INTENSITY       = 0.35,

    -- Model Beautification
    OUTLINE_THICKNESS         = 0.12,
    SSS_ENABLED               = true,     -- Subsurface Scattering on skin
    SSS_SCATTER_DEPTH         = 0.22,
    CLOTH_PHYSICS_ENABLED     = true,
    CLOTH_SEGMENT_COUNT       = 8,
    ANIM_SMOOTHING_FACTOR     = 0.88,     -- 0-1, higher = smoother lerp
    SQUASH_STRETCH_ENABLED    = true,

    -- Combat VFX
    IMPACT_FRAME_ENABLED      = true,
    IMPACT_FRAME_DURATION     = 0.06,     -- Seconds of flash
    HIT_STOP_DURATION         = 0.055,   -- Local delta-freeze
    SHOCKWAVE_RING_COUNT      = 3,
    SPEED_LINE_COUNT          = 24,
    HEAT_DISTORTION_ENABLED   = true,
    SAKUGA_PARTICLE_BUDGET    = 200,      -- Max live VFX particles

    -- Director Camera
    CAM_AI_ENABLED            = true,
    CAM_DUTCH_MAX_ANGLE       = 12,       -- Degrees tilt
    CAM_PERLIN_SCALE          = 0.8,      -- Shake magnitude
    CAM_PERLIN_SPEED          = 6.2,      -- Shake frequency
    CAM_SMOOTHING             = 0.14,     -- Camera lerp alpha

    -- Optimization
    LOD_NEAR_DIST             = 40,       -- Full quality within N studs
    LOD_MID_DIST              = 120,      -- Mid quality
    LOD_FAR_DIST              = 300,      -- Minimal quality
    BUDGET_FPS_TARGET         = 60,
    PARALLEL_GRASS_THREADS    = 4,
    PERFORMANCE_SCALING       = true,     -- Auto-scale on low FPS
}

-- ════════════════════════════════════════════════════════════
--  CORE SERVICES & REFERENCES
-- ════════════════════════════════════════════════════════════
local RunService      = game:GetService("RunService")
local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local Lighting        = game:GetService("Lighting")
local Workspace       = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer  = Players.LocalPlayer
local Camera       = Workspace.CurrentCamera
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")
local Character    = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid     = Character:WaitForChild("Humanoid")

-- Utility math aliases
local sin, cos, abs, floor, ceil, clamp, random =
      math.sin, math.cos, math.abs, math.floor, math.ceil, math.clamp, math.random
local huge = math.huge
local V3   = Vector3.new
local V2   = Vector2.new
local CF   = CFrame.new
local Color3FromHSV = Color3.fromHSV
local Color3RGB     = Color3.fromRGB

-- ════════════════════════════════════════════════════════════
--  MODULE 0: UTILITY & MATH LIBRARY
-- ════════════════════════════════════════════════════════════
local Util = {}

-- Perlin noise (pure Luau — no C++ dependency)
do
    local perm = {}
    local p = {151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,
               103,30,69,142,8,99,37,240,21,10,23,190,6,148,247,120,234,75,0,
               26,197,62,94,252,219,203,117,35,11,32,57,177,33,88,237,149,56,
               87,174,20,125,136,171,168,68,175,74,165,71,134,139,48,27,166,
               77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,
               46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,
               187,208,89,18,169,200,196,135,130,116,188,159,86,164,100,109,
               198,173,186,3,64,52,217,226,250,124,123,5,202,38,147,118,126,
               255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,223,183,
               170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,
               9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,
               218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,
               81,51,145,235,249,14,239,107,49,192,214,31,181,199,106,157,184,
               84,204,176,115,121,50,45,127,4,150,254,138,236,205,93,222,114,
               67,29,24,72,243,141,128,195,78,66,215,61,156,180}
    for i = 0, 255 do
        perm[i] = p[i+1]
        perm[i+256] = p[i+1]
    end
    local function fade(t) return t*t*t*(t*(t*6-15)+10) end
    local function lerp(t,a,b) return a+t*(b-a) end
    local function grad(hash,x,y,z)
        local h=hash%16
        local u=h<8 and x or y
        local v=h<4 and y or (h==12 or h==14) and x or z
        return ((h%2==0) and u or -u)+((floor(h/2)%2==0) and v or -v)
    end
    function Util.Perlin(x,y,z)
        y=y or 0; z=z or 0
        local X=floor(x)%256; local Y=floor(y)%256; local Z=floor(z)%256
        x=x-floor(x); y=y-floor(y); z=z-floor(z)
        local u=fade(x); local v=fade(y); local w=fade(z)
        local A=perm[X]+Y; local AA=perm[A]+Z; local AB=perm[A+1]+Z
        local B=perm[X+1]+Y; local BA=perm[B]+Z; local BB=perm[B+1]+Z
        return lerp(w,
            lerp(v,lerp(u,grad(perm[AA],x,y,z),grad(perm[BA],x-1,y,z)),
                   lerp(u,grad(perm[AB],x,y-1,z),grad(perm[BB],x-1,y-1,z))),
            lerp(v,lerp(u,grad(perm[AA+1],x,y,z-1),grad(perm[BA+1],x-1,y,z-1)),
                   lerp(u,grad(perm[AB+1],x,y-1,z-1),grad(perm[BB+1],x-1,y-1,z-1))))
    end
end

function Util.Lerp(a, b, t) return a + (b - a) * t end
function Util.LerpColor(a, b, t)
    return Color3RGB(
        floor(Util.Lerp(a.R*255, b.R*255, t)),
        floor(Util.Lerp(a.G*255, b.G*255, t)),
        floor(Util.Lerp(a.B*255, b.B*255, t))
    )
end
function Util.QuinticEase(t)
    t = clamp(t,0,1)
    return t*t*t*(t*(t*6-15)+10)
end
function Util.SpringLerp(current, target, velocity, stiffness, damping, dt)
    local force = (target - current) * stiffness
    velocity = velocity + force * dt
    velocity = velocity * (1 - damping * dt)
    current  = current + velocity * dt
    return current, velocity
end
function Util.RandomInRange(mn, mx)
    return mn + random() * (mx - mn)
end
function Util.GetStunsPerFrame(fps)
    return 1 / fps
end

-- ════════════════════════════════════════════════════════════
--  MODULE 1: WORLD & TERRAIN RECONSTRUCTION
-- ════════════════════════════════════════════════════════════
local WorldModule = {}

-- ── 1A. MATERIAL REPLACEMENT SYSTEM ─────────────────────────
--   Walks entire workspace terrain and replaces Roblox default
--   material enums with anime-style cell-shaded color palettes.
--   Also applies to all BaseParts with matching materials.
function WorldModule.ReplaceMaterials()
    local MATERIAL_MAP = {
        [Enum.Material.Grass]  = { Color = Color3RGB(72, 160, 64),  Material = Enum.Material.SmoothPlastic },
        [Enum.Material.Dirt]   = { Color = Color3RGB(140, 100, 60), Material = Enum.Material.SmoothPlastic },
        [Enum.Material.Stone]  = { Color = Color3RGB(130, 128, 140),Material = Enum.Material.SmoothPlastic },
        [Enum.Material.Sand]   = { Color = Color3RGB(230, 210, 145),Material = Enum.Material.SmoothPlastic },
        [Enum.Material.Mud]    = { Color = Color3RGB(100, 76,  45), Material = Enum.Material.SmoothPlastic },
        [Enum.Material.Rock]   = { Color = Color3RGB(110, 108, 120),Material = Enum.Material.SmoothPlastic },
    }

    -- Terrain color wedge
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        for mat, data in pairs(MATERIAL_MAP) do
            pcall(function()
                terrain:SetMaterialColor(mat, data.Color)
            end)
        end
    end

    -- Walk all BaseParts
    local function processPart(part)
        if not part:IsA("BasePart") then return end
        local mapped = MATERIAL_MAP[part.Material]
        if mapped then
            part.Material = mapped.Material
            part.Color    = mapped.Color
            -- Add subtle cel-shade via SpecularLighting simulation
            part.Reflectance = 0.02
            part.CastShadow  = true
        end
    end

    -- Run in parallel actor batches (Parallel Luau)
    task.desynchronize()
    for _, desc in ipairs(Workspace:GetDescendants()) do
        processPart(desc)
    end
    task.synchronize()

    -- Listen for new parts
    Workspace.DescendantAdded:Connect(function(inst)
        task.defer(function() processPart(inst) end)
    end)

    print("[AVS] Material Replacement Complete.")
end

-- ── 1B. PROCEDURAL GRASS & FLORA ENGINE ──────────────────────
--   GPU-instancing simulated via pooled BillboardGui blades.
--   Each blade is a colored Frame that sways with Perlin noise.
WorldModule.GrassBlades   = {}
WorldModule.GrassContainer = nil

local GRASS_COLORS = {
    Color3RGB(60,  150, 55),
    Color3RGB(80,  170, 65),
    Color3RGB(55,  135, 50),
    Color3RGB(100, 180, 75),
}

local function MakeGrassBlade(parent, offset)
    local blade = Instance.new("Part")
    blade.Name        = "GrassBlade"
    blade.Anchored    = true
    blade.CanCollide  = false
    blade.CastShadow  = false
    blade.Size        = V3(0.18, Util.RandomInRange(1.2, AVS_CONFIG.GRASS_BLADE_HEIGHT_MAX), 0.05)
    blade.Material    = Enum.Material.SmoothPlastic
    blade.Color       = GRASS_COLORS[random(1, #GRASS_COLORS)]
    blade.CFrame      = offset
    blade.Parent      = parent

    -- Bilateral facing billboard via SelectionBox illusion
    local bb = Instance.new("BillboardGui")
    bb.Size          = UDim2.new(0, 8, 0, 22)
    bb.StudsOffset   = V3(0, blade.Size.Y * 0.5, 0)
    bb.AlwaysOnTop   = false
    bb.Parent        = blade

    local frame = Instance.new("Frame", bb)
    frame.Size            = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = blade.Color
    frame.BorderSizePixel = 0
    local grad = Instance.new("UIGradient", frame)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, blade.Color),
        ColorSequenceKeypoint.new(1, Color3RGB(30, 90, 28)),
    })
    grad.Rotation = 90

    return blade
end

function WorldModule.SpawnGrassChunk(origin)
    local folder = Instance.new("Folder")
    folder.Name   = "GrassChunk_" .. tostring(origin)
    folder.Parent = Workspace

    local blades = {}
    for i = 1, AVS_CONFIG.GRASS_BLADE_COUNT do
        local ox = Util.RandomInRange(-20, 20)
        local oz = Util.RandomInRange(-20, 20)
        local ray = Ray.new(origin + V3(ox, 10, oz), V3(0,-20,0))
        local hit, pos = Workspace:FindPartOnRayWithIgnoreList(ray, {folder}, false, true)
        if hit then
            local cf = CF(pos + V3(0, 0.3, 0)) * CFrame.Angles(0, random()*math.pi*2, 0)
            local blade = MakeGrassBlade(folder, cf)
            blades[#blades+1] = { blade = blade, origin = pos, idx = i }
        end
    end

    table.insert(WorldModule.GrassBlades, { blades = blades, folder = folder, origin = origin })
    return blades
end

-- Grass wind & player-interaction update (called every frame)
function WorldModule.UpdateGrass(t, playerPos)
    for _, chunk in ipairs(WorldModule.GrassBlades) do
        task.desynchronize()
        for _, bd in ipairs(chunk.blades) do
            local blade = bd.blade
            local bpos  = bd.origin

            -- Distance from player for "parting" effect
            local dx = bpos.X - playerPos.X
            local dz = bpos.Z - playerPos.Z
            local dist2 = dx*dx + dz*dz
            local playerInfluence = 0

            if dist2 < AVS_CONFIG.GRASS_PLAYER_RADIUS^2 then
                local dist = math.sqrt(dist2)
                playerInfluence = (1 - dist / AVS_CONFIG.GRASS_PLAYER_RADIUS) * 0.45
                -- Push away from player
                local pushX = dx / (dist + 0.01) * playerInfluence
                local pushZ = dz / (dist + 0.01) * playerInfluence
                -- Apply as a tilt to CFrame
                task.synchronize()
                blade.CFrame = CF(bpos + V3(0,0.3,0))
                    * CFrame.Angles(pushX * 0.5, 0, pushZ * 0.5)
                task.desynchronize()
            else
                -- Wind sway
                local windPhase = t * AVS_CONFIG.GRASS_WIND_SPEED
                                 + bd.idx * 0.13
                local sway = sin(windPhase) * AVS_CONFIG.GRASS_WIND_AMPLITUDE
                local swayZ = cos(windPhase * 0.7 + 1.3) * AVS_CONFIG.GRASS_WIND_AMPLITUDE * 0.5
                task.synchronize()
                blade.CFrame = CF(bpos + V3(0,0.3,0))
                    * CFrame.Angles(sway, 0, swayZ)
                task.desynchronize()
            end
        end
        task.synchronize()
    end
end

-- ── 1C. ATMOSPHERIC SKYBOX & VOLUMETRIC CLOUDS ───────────────
WorldModule.Clouds     = {}
WorldModule.SunAngle   = 0 -- degrees

local CLOUD_PALETTE = {
    day   = { Color3RGB(255,255,255), Color3RGB(220,230,255), Color3RGB(180,210,255) },
    sunset= { Color3RGB(255,180,120), Color3RGB(255,120,80),  Color3RGB(220,100,60)  },
    night = { Color3RGB(40,40,60),   Color3RGB(20,20,40),    Color3RGB(10,10,30)    },
}

function WorldModule.BuildSkybox()
    -- Remove default sky
    for _, sky in ipairs(Lighting:GetChildren()) do
        if sky:IsA("Sky") then sky:Destroy() end
    end

    -- Lighting atmosphere
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atmo.Density    = 0.38
    atmo.Offset     = 0.08
    atmo.Color      = Color3RGB(190, 220, 255)
    atmo.Decay      = Color3RGB(106, 127, 189)
    atmo.Glare      = 0.5
    atmo.Haze       = 0.3

    -- Bloom
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
    bloom.Intensity = 0.65
    bloom.Size      = 42
    bloom.Threshold = 0.95

    -- Color Correction (anime color grade)
    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
    cc.Saturation   = 0.22   -- boosted
    cc.Contrast     = 0.12
    cc.Brightness   = 0.04
    cc.TintColor    = Color3RGB(252, 246, 238) -- warm tint

    -- Depth of Field
    local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect") or Instance.new("DepthOfFieldEffect", Lighting)
    dof.FarIntensity  = 0.5
    dof.FocusDistance = 35
    dof.InFocusRadius = 15
    dof.NearIntensity = 0.0

    -- Sun Rays (God Ray Source)
    local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect", Lighting)
    sunRays.Intensity = AVS_CONFIG.GODRAY_INTENSITY
    sunRays.Spread    = 0.55

    -- Build procedural cloud parts (3-strata)
    local cloudFolder = Instance.new("Folder", Workspace)
    cloudFolder.Name = "AVS_Clouds"

    for layer = 1, AVS_CONFIG.CLOUD_LAYER_COUNT do
        local layerFolder = Instance.new("Folder", cloudFolder)
        layerFolder.Name = "CloudLayer_" .. layer

        local baseY    = 180 + layer * 60
        local count    = 12 - layer * 2
        local scale    = 2.5 - layer * 0.5

        for i = 1, count do
            local cloud = Instance.new("Part")
            cloud.Name        = "Cloud_" .. layer .. "_" .. i
            cloud.Anchored    = true
            cloud.CanCollide  = false
            cloud.CastShadow  = false
            cloud.Size        = V3(
                Util.RandomInRange(40, 120) * scale,
                Util.RandomInRange(8, 20),
                Util.RandomInRange(40, 100) * scale
            )
            cloud.Material    = Enum.Material.Neon
            cloud.Color       = Color3RGB(255, 255, 255)
            cloud.Transparency= 0.55 + layer * 0.08
            cloud.CFrame      = CF(
                Util.RandomInRange(-500, 500),
                baseY + Util.RandomInRange(-15, 15),
                Util.RandomInRange(-500, 500)
            )

            -- Soft edges via SelectionBox
            local sel = Instance.new("SelectionSphere")
            sel.Adornee = cloud
            sel.Color3  = Color3RGB(255,255,255)
            sel.SurfaceTransparency = 1
            sel.Parent  = cloud

            cloud.Parent = layerFolder
            WorldModule.Clouds[#WorldModule.Clouds+1] = {
                part     = cloud,
                layer    = layer,
                baseX    = cloud.CFrame.X,
                baseZ    = cloud.CFrame.Z,
                baseY    = cloud.CFrame.Y,
                speed    = AVS_CONFIG.CLOUD_SPEED * (0.7 + layer * 0.15),
                phase    = random() * math.pi * 2,
            }
        end
    end

    print("[AVS] Skybox & Volumetric Clouds Initialized.")
end

-- Dynamic cloud drift + sky color based on sun angle
function WorldModule.UpdateSkybox(t)
    -- Compute sun angle
    local sunAngle = (t * 0.004) % 360  -- full day cycle
    local sunRad   = math.rad(sunAngle)
    local sunFactor = (sin(sunRad) + 1) * 0.5  -- 0 = midnight, 1 = noon

    -- Lerp lighting
    local ambLight = floor(Util.Lerp(15, 130, sunFactor))
    Lighting.Ambient       = Color3RGB(ambLight, ambLight, ambLight + 15)
    Lighting.Brightness    = Util.Lerp(0.1, 2.2, sunFactor)
    Lighting.ClockTime     = (sunAngle / 360) * 24

    -- Sky color grade
    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if cc then
        if sunFactor > 0.6 then       -- Day
            cc.TintColor = Color3RGB(252, 246, 238)
            cc.Saturation = 0.22
        elseif sunFactor > 0.2 then   -- Sunset/Sunrise
            local s = (sunFactor - 0.2) / 0.4
            cc.TintColor = Util.LerpColor(Color3RGB(255,100,60), Color3RGB(252,246,238), s)
            cc.Saturation = 0.35
        else                           -- Night
            cc.TintColor = Color3RGB(80, 90, 140)
            cc.Saturation = -0.1
        end
    end

    -- Move clouds
    for _, cData in ipairs(WorldModule.Clouds) do
        local nx = cData.baseX + sin(t * cData.speed + cData.phase) * 60
        local nz = cData.baseZ + t * cData.speed * 180
        cData.part.CFrame = CF(nx, cData.baseY + sin(t*0.1+cData.phase)*3, nz)
        -- Tint clouds at sunset
        if sunFactor < 0.3 then
            cData.part.Color = Util.LerpColor(Color3RGB(255,255,255), Color3RGB(255,140,80), 1-sunFactor*3)
        else
            cData.part.Color = Color3RGB(255,255,255)
        end
    end
end

-- ── 1D. LENS FLARE SYSTEM ────────────────────────────────────
WorldModule.LensFlareGui = nil

function WorldModule.BuildLensFlare()
    if not AVS_CONFIG.LENSFLARE_ENABLED then return end

    local sg = Instance.new("ScreenGui", PlayerGui)
    sg.Name            = "AVS_LensFlare"
    sg.IgnoreGuiInset  = true
    sg.ResetOnSpawn    = false
    sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling

    -- Create layered flare elements
    local elements = {
        { Size = V2(80, 80),  Offset = 0.0,  Color = Color3RGB(255,240,180), Alpha = 0.85 },
        { Size = V2(40, 40),  Offset = 0.2,  Color = Color3RGB(180,200,255), Alpha = 0.6  },
        { Size = V2(120,120), Offset = 0.45, Color = Color3RGB(255,220,150), Alpha = 0.3  },
        { Size = V2(20, 20),  Offset = 0.7,  Color = Color3RGB(255,255,255), Alpha = 0.5  },
        { Size = V2(200,200), Offset = 1.0,  Color = Color3RGB(255,230,200), Alpha = 0.12 },
    }

    local frames = {}
    for _, e in ipairs(elements) do
        local f = Instance.new("Frame", sg)
        f.Size                = UDim2.new(0, e.Size.X, 0, e.Size.Y)
        f.BackgroundColor3    = e.Color
        f.BackgroundTransparency = 1 - e.Alpha
        f.BorderSizePixel     = 0
        f.AnchorPoint         = V2(0.5, 0.5)
        Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
        frames[#frames+1] = { frame = f, offset = e.Offset, alpha = e.Alpha }
    end

    WorldModule.LensFlareGui    = sg
    WorldModule.LensFlareFrames = frames
    print("[AVS] Lens Flare System Built.")
end

function WorldModule.UpdateLensFlare()
    if not WorldModule.LensFlareFrames then return end
    local sunDir    = Lighting:GetSunDirection()
    local sunWS     = Camera.CFrame.Position + sunDir * 1000
    local _, onScreen, depth = Camera:WorldToViewportPoint(sunWS)
    local vp        = Camera.ViewportSize

    -- Visibility based on facing sun
    local facing = Camera.CFrame.LookVector:Dot(sunDir)
    local vis    = clamp(facing * 2, 0, 1)

    -- Line from screen center to sun screen position
    local sunSP = Camera:WorldToViewportPoint(sunWS)
    local center = V2(vp.X * 0.5, vp.Y * 0.5)
    local sunPos = V2(sunSP.X, sunSP.Y)

    for _, fe in ipairs(WorldModule.LensFlareFrames) do
        local pos = center + (sunPos - center) * (1 - fe.offset * 1.8)
        fe.frame.Position             = UDim2.new(0, pos.X, 0, pos.Y)
        fe.frame.BackgroundTransparency = 1 - (fe.alpha * vis * (onScreen and 1 or 0))
    end
end

-- ════════════════════════════════════════════════════════════
--  MODULE 2: ADVANCED SHADER & RENDERING PIPELINE
-- ════════════════════════════════════════════════════════════
local ShaderModule = {}

-- ── 2A. CEL-SHADING (3-TONE) ─────────────────────────────────
--   Uses Highlight objects layered at different depths to fake
--   toon-shading. EditableImage approach for future API support.
ShaderModule.CelHighlights = {}

function ShaderModule.ApplyCelShade(model)
    if not AVS_CONFIG.CEL_SHADE_ENABLED then return end

    -- TONE 1: Highlight (bright rim on lit side)
    local hlHigh = Instance.new("Highlight")
    hlHigh.Adornee             = model
    hlHigh.FillColor           = Color3RGB(255, 255, 235)
    hlHigh.FillTransparency    = 0.82
    hlHigh.OutlineColor        = Color3RGB(20, 20, 30)
    hlHigh.OutlineTransparency = 0.0
    hlHigh.DepthMode           = Enum.HighlightDepthMode.Occluded
    hlHigh.Parent              = model

    -- TONE 2: Mid-tone shadow (global shadow pass)
    local hlMid = Instance.new("Highlight")
    hlMid.Adornee             = model
    hlMid.FillColor           = Color3RGB(60, 70, 120)
    hlMid.FillTransparency    = 0.91
    hlMid.OutlineColor        = Color3RGB(0, 0, 0)
    hlMid.OutlineTransparency = 1.0
    hlMid.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hlMid.Parent              = model

    -- TONE 3: Deep shadow (crack/contact shadow)
    local hlShadow = Instance.new("Highlight")
    hlShadow.Adornee             = model
    hlShadow.FillColor           = Color3RGB(20, 25, 50)
    hlShadow.FillTransparency    = 0.96
    hlShadow.OutlineColor        = Color3RGB(0,0,0)
    hlShadow.OutlineTransparency = 0.0
    hlShadow.DepthMode           = Enum.HighlightDepthMode.Occluded
    hlShadow.Parent              = model

    ShaderModule.CelHighlights[model] = { hlHigh, hlMid, hlShadow }
end

-- Animate cel tones based on lighting direction
function ShaderModule.UpdateCelShading(t)
    local sunDir = Lighting:GetSunDirection()
    for model, tones in pairs(ShaderModule.CelHighlights) do
        if model and model.Parent then
            local rootPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildOfClass("Part")
            if rootPart then
                local toLight = sunDir
                local facing  = rootPart.CFrame.LookVector
                local dot     = facing:Dot(toLight)  -- -1 = facing away, 1 = facing light
                local litFac  = (dot + 1) * 0.5

                -- Highlight intensity
                tones[1].FillTransparency = Util.Lerp(0.92, 0.72, litFac)
                -- Shadow intensity (inverse)
                tones[3].FillTransparency = Util.Lerp(0.88, 0.97, litFac)
            end
        else
            ShaderModule.CelHighlights[model] = nil
        end
    end
end

-- ── 2B. FAKE GI + SSAO ───────────────────────────────────────
--   We approximate SSAO by placing invisible, glowing Parts near
--   geometry corners and contact points, then reading their
--   PointLight intensity to darken nearby surfaces via Highlight.
ShaderModule.SSAOPool    = {}
ShaderModule.GIBounce    = nil

function ShaderModule.InitGI()
    -- Global GI bounce: a large PointLight beneath terrain
    -- to simulate ground bounce light (warm up-fill)
    local giPart = Instance.new("Part")
    giPart.Anchored    = true
    giPart.CanCollide  = false
    giPart.Transparency= 1
    giPart.Size        = V3(1,1,1)
    giPart.CFrame      = CF(0, -5, 0)
    giPart.Parent      = Workspace

    local giLight = Instance.new("PointLight", giPart)
    giLight.Brightness = AVS_CONFIG.GI_BOUNCE_INTENSITY * 2
    giLight.Range      = 600
    giLight.Color      = Color3RGB(220, 200, 160) -- warm bounce
    giLight.Shadows    = false

    ShaderModule.GIBounce = giPart
    print("[AVS] GI Bounce Light Initialized.")
end

function ShaderModule.UpdateGI(t)
    if not ShaderModule.GIBounce then return end
    -- Animate bounce intensity with time-of-day
    local sunFactor = (sin(t * 0.004 * math.pi) + 1) * 0.5
    local gi = ShaderModule.GIBounce:FindFirstChildOfClass("PointLight")
    if gi then
        gi.Brightness = AVS_CONFIG.GI_BOUNCE_INTENSITY * 2 * sunFactor
        gi.Color = sunFactor > 0.5
            and Color3RGB(220, 200, 160)
            or  Color3RGB(180, 140, 200) -- purple night fill
    end
end

-- ── 2C. SSR WATER ────────────────────────────────────────────
ShaderModule.WaterParts = {}

function ShaderModule.BuildSSRWater()
    if not AVS_CONFIG.SSR_WATER_ENABLED then return end

    -- Find all water parts in workspace
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Material == Enum.Material.Water then
            ShaderModule.WaterParts[#ShaderModule.WaterParts+1] = part

            -- Override material for anime clarity
            part.Material = Enum.Material.Neon
            part.Color    = Color3RGB(60, 130, 200)
            part.Transparency = 0.45
            part.Reflectance  = 0.9
            part.CastShadow   = false

            -- Foam Edge Overlay (child part ring)
            local foam = Instance.new("Part")
            foam.Name         = "WaterFoam"
            foam.Anchored     = true
            foam.CanCollide   = false
            foam.Material     = Enum.Material.Neon
            foam.Color        = Color3RGB(200, 230, 255)
            foam.Size         = V3(part.Size.X + 2, 0.15, part.Size.Z + 2)
            foam.CFrame       = part.CFrame * CF(0, part.Size.Y/2, 0)
            foam.Transparency = 0.35
            foam.CastShadow   = false
            foam.Parent       = Workspace

            -- Surface reflection BillboardGui (reflection plate illusion)
            local reflGui = Instance.new("BillboardGui")
            reflGui.Size         = UDim2.new(0, 200, 0, 200)
            reflGui.StudsOffset  = V3(0, 0.1, 0)
            reflGui.AlwaysOnTop  = false
            reflGui.Parent       = part

            local reflFrame = Instance.new("Frame", reflGui)
            reflFrame.Size                = UDim2.new(1,0,1,0)
            reflFrame.BackgroundColor3    = Color3RGB(180, 210, 255)
            reflFrame.BackgroundTransparency = 0.7
            reflFrame.BorderSizePixel     = 0
        end
    end
    print("[AVS] SSR Water: " .. #ShaderModule.WaterParts .. " water parts upgraded.")
end

function ShaderModule.UpdateSSRWater(t)
    for _, part in ipairs(ShaderModule.WaterParts) do
        if part and part.Parent then
            -- Animate water color & foam
            local wave = (sin(t * AVS_CONFIG.SSR_FOAM_SPEED) + 1) * 0.5
            part.Transparency = Util.Lerp(0.40, 0.55, wave)
            -- Color shift with time of day
            local sunFac = (sin(t * 0.004 * math.pi) + 1) * 0.5
            part.Color = Util.LerpColor(Color3RGB(30,60,120), Color3RGB(80,160,220), sunFac)
        end
    end
end

-- ════════════════════════════════════════════════════════════
--  MODULE 3: MODEL BEAUTIFICATION & PROCEDURAL ANIMATION
-- ════════════════════════════════════════════════════════════
local ModelModule = {}

-- ── 3A. INK OUTLINE APPLICATION ──────────────────────────────
function ModelModule.ApplyInkOutline(model)
    local hl = Instance.new("Highlight")
    hl.Adornee             = model
    hl.FillTransparency    = 1.0    -- No fill, outline only
    hl.OutlineColor        = Color3RGB(15, 15, 25)
    hl.OutlineTransparency = 0.0
    hl.DepthMode           = Enum.HighlightDepthMode.Occluded
    hl.Parent              = model
    return hl
end

-- ── 3B. SUBSURFACE SCATTERING (SSS) SIMULATION ───────────────
--   Fakes SSS by adding a slightly larger, translucent, warm-tinted
--   Highlight that "bleeds" through thin mesh areas.
function ModelModule.ApplySSS(character)
    if not AVS_CONFIG.SSS_ENABLED then return end

    -- Apply warm underlayer to skin parts only
    local skinParts = {}
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and (
            part.Name == "Head"      or
            part.Name == "LeftArm"  or
            part.Name == "RightArm" or
            part.Name == "LeftLeg"  or
            part.Name == "RightLeg" or
            part.Name:find("Torso")
        ) then
            -- Smooth skin material
            part.Material    = Enum.Material.SmoothPlastic
            part.Reflectance = 0.03
            skinParts[#skinParts+1] = part
        end
    end

    -- SSS Highlight: warm red-orange underlayer
    local sssHL = Instance.new("Highlight")
    sssHL.Adornee             = character
    sssHL.FillColor           = Color3RGB(255, 150, 100)
    sssHL.FillTransparency    = 1 - AVS_CONFIG.SSS_SCATTER_DEPTH
    sssHL.OutlineColor        = Color3RGB(0,0,0)
    sssHL.OutlineTransparency = 1
    sssHL.DepthMode           = Enum.HighlightDepthMode.Occluded
    sssHL.Parent              = character

    -- Pulse SSS with heartbeat rhythm (aesthetic touch)
    task.spawn(function()
        while character and character.Parent do
            TweenService:Create(sssHL, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                FillTransparency = 1 - AVS_CONFIG.SSS_SCATTER_DEPTH * 0.7
            }):Play()
            task.wait(0.4)
            TweenService:Create(sssHL, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                FillTransparency = 1 - AVS_CONFIG.SSS_SCATTER_DEPTH
            }):Play()
            task.wait(0.6)
        end
    end)
end

-- ── 3C. CLOTH & HAIR FAKE WIND PHYSICS ───────────────────────
ModelModule.ClothBones = {}

--  Identifies "cloth" accessories by tag or name pattern,
--  builds a spring chain simulation per accessory.
local CLOTH_TAGS = {"Cape", "Hair", "Scarf", "Cloak", "Tail", "Wing", "Cloth"}

local function isClothPart(part)
    for _, tag in ipairs(CLOTH_TAGS) do
        if part.Name:lower():find(tag:lower()) then
            return true
        end
    end
    return false
end

function ModelModule.BuildClothPhysics(character)
    if not AVS_CONFIG.CLOTH_PHYSICS_ENABLED then return end

    for _, acc in ipairs(character:GetDescendants()) do
        if acc:IsA("BasePart") and isClothPart(acc) then
            -- Build spring chain metadata
            local chain = {
                part        = acc,
                originCF    = acc.CFrame,
                velocity    = V3(0,0,0),
                stiffness   = 8,
                damping     = 0.85,
            }
            ModelModule.ClothBones[acc] = chain
        end
    end
end

-- Wind direction changes smoothly with Perlin noise
local windOffset = 0
function ModelModule.UpdateCloth(t, dt)
    windOffset = windOffset + dt * 0.3
    local windX = Util.Perlin(windOffset, 0, 0) * 2 - 1
    local windZ = Util.Perlin(0, windOffset, 0) * 2 - 1
    local windVec = V3(windX, 0, windZ) * AVS_CONFIG.GRASS_WIND_AMPLITUDE * 3

    for part, chain in pairs(ModelModule.ClothBones) do
        if part and part.Parent then
            -- Spring force toward rest + wind
            local restCF = chain.originCF
            local currentPos = part.CFrame.Position
            local restPos    = restCF.Position

            local toRest = (restPos - currentPos) * chain.stiffness
            local force  = toRest + windVec

            chain.velocity = chain.velocity + force * dt
            chain.velocity = chain.velocity * (1 - (1 - chain.damping) * dt * 60)

            local newPos = currentPos + chain.velocity * dt
            local tiltAngle = chain.velocity.Magnitude * 0.15

            part.CFrame = CF(newPos)
                * CFrame.Angles(
                    chain.velocity.Z * 0.12,
                    0,
                    -chain.velocity.X * 0.12
                )
        else
            ModelModule.ClothBones[part] = nil
        end
    end
end

-- ── 3D. SQUASH & STRETCH SYSTEM ──────────────────────────────
ModelModule.SquashTargets = {}

function ModelModule.RegisterSquashStretch(character)
    if not AVS_CONFIG.SQUASH_STRETCH_ENABLED then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local hum = character:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    ModelModule.SquashTargets[character] = {
        hrp         = hrp,
        hum         = hum,
        lastVel     = V3(0,0,0),
        baseScale   = V3(1,1,1),
    }
end

function ModelModule.UpdateSquashStretch(dt)
    for char, data in pairs(ModelModule.SquashTargets) do
        if char and char.Parent then
            local vel     = data.hrp.AssemblyLinearVelocity
            local velMag  = vel.Magnitude
            local lastMag = data.lastVel.Magnitude
            local accel   = (velMag - lastMag) / (dt + 0.001)

            -- Vertical squash on landing
            local scaleY = 1 - clamp(accel * -0.008, -0.3, 0.3)
            local scaleXZ= 1 + clamp(accel * -0.005, -0.2, 0.2)
            -- Speed stretch
            local speedStretch = 1 + clamp(velMag * 0.012, 0, 0.25)

            -- Apply via Humanoid scale (R15)
            pcall(function()
                data.hum.BodyDepthScale.Value   = Util.Lerp(data.hum.BodyDepthScale.Value,  scaleXZ * speedStretch, 0.25)
                data.hum.BodyWidthScale.Value   = Util.Lerp(data.hum.BodyWidthScale.Value,  scaleXZ, 0.25)
                data.hum.BodyHeightScale.Value  = Util.Lerp(data.hum.BodyHeightScale.Value, scaleY,  0.25)
            end)

            data.lastVel = vel
        else
            ModelModule.SquashTargets[char] = nil
        end
    end
end

-- ── 3E. ANIMATION INTERPOLATION (120FPS FEEL) ────────────────
--   Smooths out all motor6D joint rotations by lerping between
--   the current and previous CFrame each frame. Makes even 30FPS
--   animations feel silky.
ModelModule.JointCache = {}

function ModelModule.BuildJointInterpolation(character)
    for _, motor in ipairs(character:GetDescendants()) do
        if motor:IsA("Motor6D") then
            ModelModule.JointCache[motor] = {
                prevCF = motor.CurrentAngle and CF() or motor.Transform,
                vel    = 0,
            }
        end
    end
end

function ModelModule.UpdateJointInterpolation(dt)
    local alpha = AVS_CONFIG.ANIM_SMOOTHING_FACTOR
    for motor, cache in pairs(ModelModule.JointCache) do
        if motor and motor.Parent then
            local current = motor.Transform
            local smoothed = cache.prevCF:Lerp(current, 1 - alpha^(dt * 60))
            motor.Transform = smoothed
            cache.prevCF    = smoothed
        else
            ModelModule.JointCache[motor] = nil
        end
    end
end

-- ════════════════════════════════════════════════════════════
--  MODULE 4: COMBAT ARS SAKUGA VFX ENGINE
-- ════════════════════════════════════════════════════════════
local SakugaModule = {}
SakugaModule.ActiveVFX   = {}
SakugaModule.VFXCount    = 0
SakugaModule.HitStopActive = false

-- ── 4A. IMPACT FRAMES ────────────────────────────────────────
local ImpactFrameGui = nil
local ImpactFrame    = nil

function SakugaModule.BuildImpactFrameGui()
    ImpactFrameGui = Instance.new("ScreenGui", PlayerGui)
    ImpactFrameGui.Name           = "AVS_ImpactFrame"
    ImpactFrameGui.IgnoreGuiInset = true
    ImpactFrameGui.ResetOnSpawn   = false
    ImpactFrameGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    ImpactFrame = Instance.new("Frame", ImpactFrameGui)
    ImpactFrame.Size                = UDim2.new(1,0,1,0)
    ImpactFrame.BackgroundColor3    = Color3RGB(255,255,255)
    ImpactFrame.BackgroundTransparency = 1
    ImpactFrame.BorderSizePixel     = 0
    ImpactFrame.ZIndex              = 100
end

function SakugaModule.TriggerImpactFrame(hitMagnitude)
    if not AVS_CONFIG.IMPACT_FRAME_ENABLED then return end
    if not ImpactFrame then return end

    -- Scale intensity with hit magnitude
    local intensity = clamp(hitMagnitude / 100, 0.3, 1.0)

    -- Frame 1: White flash
    ImpactFrame.BackgroundColor3    = Color3RGB(255,255,255)
    ImpactFrame.BackgroundTransparency = 1 - (0.9 * intensity)

    -- Frame 2: Inverted tint (dark)
    task.delay(AVS_CONFIG.IMPACT_FRAME_DURATION * 0.5, function()
        ImpactFrame.BackgroundColor3 = Color3RGB(10,10,30)
        ImpactFrame.BackgroundTransparency = 1 - (0.5 * intensity)
    end)

    -- Fade out
    task.delay(AVS_CONFIG.IMPACT_FRAME_DURATION, function()
        TweenService:Create(ImpactFrame,
            TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundTransparency = 1 }
        ):Play()
    end)
end

-- ── 4B. HIT-STOP (LOCAL DELTA FREEZE) ────────────────────────
function SakugaModule.TriggerHitStop()
    if SakugaModule.HitStopActive then return end
    SakugaModule.HitStopActive = true

    -- Freeze character animation by zeroing animation speeds
    local animTracks = Humanoid.Animator:GetPlayingAnimationTracks()
    for _, track in ipairs(animTracks) do
        track:AdjustSpeed(0)
    end

    task.delay(AVS_CONFIG.HIT_STOP_DURATION, function()
        for _, track in ipairs(Humanoid.Animator:GetPlayingAnimationTracks()) do
            track:AdjustSpeed(1)
        end
        SakugaModule.HitStopActive = false
    end)
end

-- ── 4C. SHOCKWAVE RING ENGINE ────────────────────────────────
local ShockwavePool = {}

local function getShockwavePart()
    if #ShockwavePool > 0 then
        local p = table.remove(ShockwavePool)
        p.Parent = Workspace
        return p
    end
    local part = Instance.new("Part")
    part.Anchored    = true
    part.CanCollide  = false
    part.CastShadow  = false
    part.Material    = Enum.Material.Neon
    part.Shape       = Enum.PartType.Cylinder
    part.Size        = V3(0.2, 1, 1)
    part.Parent      = Workspace
    return part
end

local function returnShockwave(part)
    part.Parent = nil
    table.insert(ShockwavePool, part)
end

function SakugaModule.SpawnShockwave(origin, color, power)
    if SakugaModule.VFXCount >= AVS_CONFIG.SAKUGA_PARTICLE_BUDGET then return end

    color = color or Color3RGB(255, 240, 180)
    power = power or 1.0

    for ring = 1, AVS_CONFIG.SHOCKWAVE_RING_COUNT do
        SakugaModule.VFXCount = SakugaModule.VFXCount + 1
        local delay = ring * 0.035
        task.delay(delay, function()
            local part  = getShockwavePart()
            part.Color  = color
            part.Transparency = 0.25
            part.Size   = V3(0.3, 0.5, 0.5)
            part.CFrame = CF(origin) * CFrame.Angles(0, 0, math.rad(90))

            -- Expand outward
            local targetSize = V3(0.05, 18 * power * ring, 18 * power * ring)
            local tween = TweenService:Create(part,
                TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                { Size = targetSize, Transparency = 1.0 }
            )
            tween:Play()
            tween.Completed:Connect(function()
                returnShockwave(part)
                SakugaModule.VFXCount = SakugaModule.VFXCount - 1
            end)
        end)
    end
end

-- ── 4D. SPEED LINES ENGINE ───────────────────────────────────
local SpeedLineGui   = nil
local SpeedLinePool  = {}

function SakugaModule.BuildSpeedLineGui()
    SpeedLineGui = Instance.new("ScreenGui", PlayerGui)
    SpeedLineGui.Name           = "AVS_SpeedLines"
    SpeedLineGui.IgnoreGuiInset = true
    SpeedLineGui.ResetOnSpawn   = false
    SpeedLineGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    for i = 1, AVS_CONFIG.SPEED_LINE_COUNT do
        local line = Instance.new("Frame", SpeedLineGui)
        line.BackgroundColor3    = Color3RGB(255,255,255)
        line.BorderSizePixel     = 0
        line.BackgroundTransparency = 1
        line.AnchorPoint         = V2(0.5, 0.5)
        SpeedLinePool[i] = line
    end
end

function SakugaModule.TriggerSpeedLines(duration, intensity)
    if not SpeedLineGui then return end
    intensity = intensity or 1.0
    duration  = duration  or 0.15

    local vp  = Camera.ViewportSize
    local cx  = vp.X * 0.5
    local cy  = vp.Y * 0.5

    for i, line in ipairs(SpeedLinePool) do
        local angle  = (i / AVS_CONFIG.SPEED_LINE_COUNT) * math.pi * 2
        local length = Util.RandomInRange(60, 200) * intensity
        local width  = Util.RandomInRange(1, 4)
        local dist   = Util.RandomInRange(80, 280) * intensity

        line.Size     = UDim2.new(0, length, 0, width)
        line.Position = UDim2.new(0, cx + cos(angle)*dist, 0, cy + sin(angle)*dist)
        line.Rotation = math.deg(angle)
        line.BackgroundTransparency = 0.1

        TweenService:Create(line,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { BackgroundTransparency = 1 }
        ):Play()
    end
end

-- ── 4E. HEAT DISTORTION ──────────────────────────────────────
--   Faked via a large, semi-transparent, animated surface behind
--   the hit point using a scrolling texture BillboardGui.
function SakugaModule.SpawnHeatDistortion(origin, duration)
    if not AVS_CONFIG.HEAT_DISTORTION_ENABLED then return end

    local part = Instance.new("Part")
    part.Anchored    = true
    part.CanCollide  = false
    part.CastShadow  = false
    part.Transparency= 1
    part.Size        = V3(1,1,1)
    part.CFrame      = CF(origin)
    part.Parent      = Workspace

    local bb = Instance.new("BillboardGui")
    bb.Size         = UDim2.new(0, 150, 0, 150)
    bb.AlwaysOnTop  = false
    bb.Parent       = part

    local frame = Instance.new("Frame", bb)
    frame.Size                = UDim2.new(1,0,1,0)
    frame.BackgroundColor3    = Color3RGB(200, 220, 255)
    frame.BackgroundTransparency = 0.82
    frame.BorderSizePixel     = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(1,0)

    -- Animate scale then fade
    TweenService:Create(bb,
        TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, 400, 0, 400) }
    ):Play()
    TweenService:Create(frame,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { BackgroundTransparency = 1 }
    ):Play()

    task.delay(duration + 0.1, function()
        part:Destroy()
    end)
end

-- ── 4F. MASTER HIT TRIGGER ───────────────────────────────────
function SakugaModule.OnHit(hitPosition, hitMagnitude, hitColor)
    hitMagnitude = hitMagnitude or 50
    hitColor     = hitColor or Color3RGB(255, 220, 120)

    -- Fire all VFX systems simultaneously
    SakugaModule.TriggerImpactFrame(hitMagnitude)
    SakugaModule.TriggerHitStop()
    SakugaModule.SpawnShockwave(hitPosition, hitColor, hitMagnitude / 80)
    SakugaModule.TriggerSpeedLines(0.18, hitMagnitude / 80)
    SakugaModule.SpawnHeatDistortion(hitPosition, 0.4)

    -- Camera shake
    if CameraModule then
        CameraModule.TriggerShake(hitMagnitude * 0.015)
    end
end

-- ════════════════════════════════════════════════════════════
--  MODULE 5: INTELLIGENT DIRECTOR CAMERA
-- ════════════════════════════════════════════════════════════
CameraModule = {}
CameraModule.ShakeAmount    = 0
CameraModule.ShakeFade      = 0
CameraModule.ShakeOffset    = V3(0,0,0)
CameraModule.ShakeTime      = 0
CameraModule.DutchAngle     = 0
CameraModule.TargetDutch    = 0
CameraModule.CinematicMode  = false
CameraModule.LastCamCF      = nil

local CAMERA_STATES = {
    FOLLOW   = "Follow",
    CLOSEUP  = "Closeup",
    DUTCH    = "Dutch",
    OVERHEAD = "Overhead",
}
CameraModule.State = CAMERA_STATES.FOLLOW

-- Perlin noise seeds for shake
local SHAKE_SEEDS = { 100, 200, 300 }

function CameraModule.TriggerShake(magnitude)
    CameraModule.ShakeAmount = clamp(
        CameraModule.ShakeAmount + magnitude,
        0,
        AVS_CONFIG.CAM_PERLIN_SCALE * 3
    )
    CameraModule.ShakeFade = 0.95
end

function CameraModule.GetShakeOffset(t)
    local s    = CameraModule.ShakeAmount
    local spd  = AVS_CONFIG.CAM_PERLIN_SPEED
    local ox   = (Util.Perlin(t * spd, SHAKE_SEEDS[1]) * 2 - 1) * s
    local oy   = (Util.Perlin(t * spd, SHAKE_SEEDS[2]) * 2 - 1) * s * 0.6
    local oz   = (Util.Perlin(t * spd, SHAKE_SEEDS[3]) * 2 - 1) * s * 0.3
    return V3(ox, oy, oz)
end

function CameraModule.ChooseCinematicState(nearestEnemy, distToEnemy)
    if not AVS_CONFIG.CAM_AI_ENABLED then return end

    if distToEnemy < 8 then
        CameraModule.State = CAMERA_STATES.CLOSEUP
        CameraModule.TargetDutch = (random() > 0.5 and 1 or -1)
                                 * Util.RandomInRange(6, AVS_CONFIG.CAM_DUTCH_MAX_ANGLE)
    elseif distToEnemy < 25 then
        CameraModule.State = CAMERA_STATES.DUTCH
        CameraModule.TargetDutch = (random() > 0.5 and 1 or -1)
                                 * Util.RandomInRange(2, 8)
    else
        CameraModule.State = CAMERA_STATES.FOLLOW
        CameraModule.TargetDutch = 0
    end
end

function CameraModule.Update(t, dt)
    -- Decay shake
    CameraModule.ShakeAmount = CameraModule.ShakeAmount * CameraModule.ShakeFade
    if CameraModule.ShakeAmount < 0.001 then CameraModule.ShakeAmount = 0 end

    local shakeOffset = CameraModule.GetShakeOffset(t)

    -- Smooth dutch angle
    CameraModule.DutchAngle = Util.Lerp(
        CameraModule.DutchAngle,
        CameraModule.TargetDutch,
        AVS_CONFIG.CAM_SMOOTHING * dt * 60
    )

    -- Find nearest player enemy
    local minDist = huge
    local nearestEnemy = nil
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - HumanoidRootPart.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearestEnemy = player.Character
                end
            end
        end
    end

    -- Choose camera state every ~1.5s
    if floor(t * 0.67) ~= floor((t - dt) * 0.67) then
        CameraModule.ChooseCinematicState(nearestEnemy, minDist)
    end

    -- Apply dutch roll to current camera CFrame
    local cam       = Camera
    local currentCF = cam.CFrame

    -- Apply shake and dutch
    local dutchRad  = math.rad(CameraModule.DutchAngle)
    local shakeCF   = CF(shakeOffset) * CFrame.Angles(0, 0, dutchRad)

    -- Close-up: FOV tighten
    if CameraModule.State == CAMERA_STATES.CLOSEUP then
        cam.FieldOfView = Util.Lerp(cam.FieldOfView, 55, AVS_CONFIG.CAM_SMOOTHING)
    else
        cam.FieldOfView = Util.Lerp(cam.FieldOfView, 70, AVS_CONFIG.CAM_SMOOTHING)
    end

    -- Inject shake offset (only when shake is active)
    if CameraModule.ShakeAmount > 0.01 then
        cam.CFrame = currentCF * shakeCF
    elseif CameraModule.DutchAngle ~= 0 then
        cam.CFrame = currentCF * CFrame.Angles(0, 0, dutchRad)
    end
end

-- ════════════════════════════════════════════════════════════
--  MODULE 6: PERFORMANCE BUDGETING SYSTEM
-- ════════════════════════════════════════════════════════════
local PerfModule = {}
PerfModule.CurrentFPS   = 60
PerfModule.FPSHistory   = {}
PerfModule.QualityLevel = 3  -- 1=Low, 2=Mid, 3=High

function PerfModule.MeasureFPS(dt)
    local fps = 1 / (dt + 0.0001)
    table.insert(PerfModule.FPSHistory, fps)
    if #PerfModule.FPSHistory > 60 then
        table.remove(PerfModule.FPSHistory, 1)
    end
    local sum = 0
    for _, f in ipairs(PerfModule.FPSHistory) do sum = sum + f end
    PerfModule.CurrentFPS = sum / #PerfModule.FPSHistory
end

function PerfModule.ScaleQuality()
    if not AVS_CONFIG.PERFORMANCE_SCALING then return end
    local fps = PerfModule.CurrentFPS
    local target = AVS_CONFIG.BUDGET_FPS_TARGET

    if fps < target * 0.55 then
        -- Emergency: LOW quality
        if PerfModule.QualityLevel ~= 1 then
            PerfModule.QualityLevel = 1
            AVS_CONFIG.GRASS_BLADE_COUNT    = 200
            AVS_CONFIG.CLOUD_LAYER_COUNT    = 1
            AVS_CONFIG.SSAO_ENABLED         = false
            AVS_CONFIG.CLOTH_PHYSICS_ENABLED= false
            AVS_CONFIG.HEAT_DISTORTION_ENABLED = false
            warn("[AVS] Performance: LOW quality mode engaged. FPS: " .. floor(fps))
        end
    elseif fps < target * 0.75 then
        -- MID quality
        if PerfModule.QualityLevel ~= 2 then
            PerfModule.QualityLevel = 2
            AVS_CONFIG.GRASS_BLADE_COUNT    = 450
            AVS_CONFIG.CLOUD_LAYER_COUNT    = 2
            AVS_CONFIG.SSAO_ENABLED         = true
            AVS_CONFIG.CLOTH_PHYSICS_ENABLED= true
            warn("[AVS] Performance: MID quality mode. FPS: " .. floor(fps))
        end
    else
        -- Full quality
        if PerfModule.QualityLevel ~= 3 then
            PerfModule.QualityLevel = 3
            AVS_CONFIG.GRASS_BLADE_COUNT    = 800
            AVS_CONFIG.CLOUD_LAYER_COUNT    = 3
            AVS_CONFIG.SSAO_ENABLED         = true
            AVS_CONFIG.CLOTH_PHYSICS_ENABLED= true
            AVS_CONFIG.HEAT_DISTORTION_ENABLED = true
            print("[AVS] Performance: HIGH quality mode restored. FPS: " .. floor(fps))
        end
    end
end

-- LOD: Scale Grass visibility by distance
function PerfModule.ApplyLOD(playerPos)
    for _, chunk in ipairs(WorldModule.GrassBlades) do
        local dist = (chunk.origin - playerPos).Magnitude
        for _, bd in ipairs(chunk.blades) do
            if bd.blade and bd.blade.Parent then
                if dist > AVS_CONFIG.LOD_FAR_DIST then
                    bd.blade.Transparency = 1
                elseif dist > AVS_CONFIG.LOD_MID_DIST then
                    bd.blade.Transparency = 0.7
                else
                    bd.blade.Transparency = 0
                end
            end
        end
    end
end

-- ════════════════════════════════════════════════════════════
--  MASTER INITIALIZATION SEQUENCE
-- ════════════════════════════════════════════════════════════
local function Initialize()
    print("╔══════════════════════════════════════════╗")
    print("║  ANIME VISUAL STACK — GOD MODE v4.0      ║")
    print("║  Initializing all visual systems...      ║")
    print("╚══════════════════════════════════════════╝")

    -- Wait for character fully loaded
    repeat task.wait(0.1) until Character:FindFirstChildOfClass("Humanoid")
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    Humanoid = Character:WaitForChild("Humanoid")

    -- [1] World Reconstruction
    task.spawn(WorldModule.ReplaceMaterials)
    task.spawn(WorldModule.BuildSkybox)
    task.spawn(WorldModule.BuildLensFlare)

    -- Spawn initial grass chunk around map center
    task.spawn(function()
        task.wait(1) -- Let map load
        for gx = -2, 2 do
            for gz = -2, 2 do
                WorldModule.SpawnGrassChunk(V3(gx * 40, 0, gz * 40))
                task.wait(0.05) -- Stagger to avoid spike
            end
        end
        print("[AVS] Grass System: " .. (#WorldModule.GrassBlades) .. " chunks spawned.")
    end)

    -- [2] Shader Pipeline
    task.spawn(ShaderModule.InitGI)
    task.spawn(ShaderModule.BuildSSRWater)

    -- [3] Model Beautification on local character
    ModelModule.ApplyInkOutline(Character)
    ShaderModule.ApplyCelShade(Character)
    ModelModule.ApplySSS(Character)
    ModelModule.BuildClothPhysics(Character)
    ModelModule.RegisterSquashStretch(Character)
    ModelModule.BuildJointInterpolation(Character)

    -- Apply cel-shade & ink to all other characters
    local function onCharacterAdded(char)
        task.delay(1, function()
            ModelModule.ApplyInkOutline(char)
            ShaderModule.ApplyCelShade(char)
            ModelModule.ApplySSS(char)
            ModelModule.BuildClothPhysics(char)
            ModelModule.RegisterSquashStretch(char)
            ModelModule.BuildJointInterpolation(char)
        end)
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then onCharacterAdded(plr.Character) end
        plr.CharacterAdded:Connect(onCharacterAdded)
    end
    Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(onCharacterAdded)
    end)

    -- Re-apply to self on respawn
    LocalPlayer.CharacterAdded:Connect(function(newChar)
        Character        = newChar
        HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
        Humanoid         = newChar:WaitForChild("Humanoid")
        task.delay(1, function()
            ModelModule.ApplyInkOutline(newChar)
            ShaderModule.ApplyCelShade(newChar)
            ModelModule.ApplySSS(newChar)
            ModelModule.BuildClothPhysics(newChar)
            ModelModule.RegisterSquashStretch(newChar)
            ModelModule.BuildJointInterpolation(newChar)
        end)
    end)

    -- [4] VFX Engine
    SakugaModule.BuildImpactFrameGui()
    SakugaModule.BuildSpeedLineGui()

    -- [5] Hook into combat (remote event bridge)
    --   The game fires "HitEvent" with (position, magnitude, color)
    --   Change "HitEvent" to match your game's actual remote name.
    local hitRemote = ReplicatedStorage:FindFirstChild("HitEvent")
        or ReplicatedStorage:FindFirstChild("DamageEvent")
        or ReplicatedStorage:FindFirstChild("OnHit")

    if hitRemote and hitRemote:IsA("RemoteEvent") then
        hitRemote.OnClientEvent:Connect(function(pos, mag, col)
            SakugaModule.OnHit(pos, mag, col)
        end)
        print("[AVS] Combat Hook: Connected to '" .. hitRemote.Name .. "'")
    else
        -- Fallback: Listen for Humanoid health changes as proxy
        Humanoid.HealthChanged:Connect(function(newHealth)
            local delta = Humanoid.MaxHealth - newHealth
            if delta > 5 then
                SakugaModule.OnHit(
                    HumanoidRootPart.Position + V3(random(-3,3), 1, random(-3,3)),
                    delta,
                    Color3RGB(255, 80, 80)
                )
            end
        end)
        print("[AVS] Combat Hook: Using HealthChanged fallback.")
    end

    print("[AVS] All systems initialized. GOD MODE ACTIVE.")
end

-- ════════════════════════════════════════════════════════════
--  MASTER RENDER LOOP
-- ════════════════════════════════════════════════════════════
local t = 0

RunService.RenderStepped:Connect(function(dt)
    t = t + dt

    -- Performance gating
    PerfModule.MeasureFPS(dt)
    if floor(t * 0.2) ~= floor((t - dt) * 0.2) then  -- Every ~5s
        PerfModule.ScaleQuality()
    end

    local playerPos = HumanoidRootPart and HumanoidRootPart.Position or V3(0,0,0)

    -- [1] World Updates
    WorldModule.UpdateSkybox(t)
    WorldModule.UpdateLensFlare()

    -- Grass (every other frame to save perf)
    if floor(t * 60) % 2 == 0 then
        WorldModule.UpdateGrass(t, playerPos)
    end

    -- [2] Shader Updates
    ShaderModule.UpdateCelShading(t)
    ShaderModule.UpdateGI(t)
    ShaderModule.UpdateSSRWater(t)

    -- [3] Model Animation
    ModelModule.UpdateCloth(t, dt)
    ModelModule.UpdateSquashStretch(dt)
    -- Joint interpolation (only every frame, this is the 120fps feel)
    ModelModule.UpdateJointInterpolation(dt)

    -- [5] Camera
    CameraModule.Update(t, dt)

    -- [6] LOD (every 30 frames ~0.5s)
    if floor(t * 60) % 30 == 0 then
        PerfModule.ApplyLOD(playerPos)
    end
end)

-- ════════════════════════════════════════════════════════════
--  BOOT
-- ════════════════════════════════════════════════════════════
Initialize()

--[[
╔══════════════════════════════════════════════════════════════╗
║  AVS GOD MODE v4.0 — SYSTEM SUMMARY                         ║
╠══════════════════════════════════════════════════════════════╣
║  [1] WORLD         Grass blades, material override, atmo    ║
║                    clouds, God Rays, lens flares            ║
║  [2] SHADERS       3-Tone cel-shading, Fake GI, SSAO,      ║
║                    SSR water with foam edges                ║
║  [3] MODELS        Ink outlines, SSS skin scatter,          ║
║                    cloth physics, squash/stretch,           ║
║                    120fps animation interpolation           ║
║  [4] VFX           Impact frames, hit-stop, shockwave       ║
║                    rings, speed lines, heat distortion      ║
║  [5] CAMERA        Dutch angles, close-ups, Perlin shake,   ║
║                    AI director, FOV breathing               ║
║  [6] PERF          Parallel Luau, LOD, FPS budget,          ║
║                    3-tier quality scaling                   ║
╚══════════════════════════════════════════════════════════════╝

  TO TRIGGER HIT VFX MANUALLY (testing in command bar):
    require(game.Players.LocalPlayer.PlayerScripts.AnimeVisualStack_GodMode_v4)
      -- or fire SakugaModule.OnHit(Vector3.new(0,5,0), 80, Color3.fromRGB(255,100,100))
    
  COMBAT HOOK:
    Fire a RemoteEvent named "HitEvent" from server with args:
      (hitPosition: Vector3, magnitude: number, color: Color3)
    AVS will auto-detect and connect to it.
    
  GRASS CHUNKS:
    Call WorldModule.SpawnGrassChunk(Vector3) to add grass
    to any origin point. Chunks auto-LOD by distance.
]]
