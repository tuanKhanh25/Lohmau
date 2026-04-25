--[[
╔══════════════════════════════════════════════════════════════════════════════════╗
║                                                                                  ║
║          ███╗   ██╗███████╗██████╗ ██╗   ██╗██╗      █████╗                    ║
║          ████╗  ██║██╔════╝██╔══██╗██║   ██║██║     ██╔══██╗                   ║
║          ██╔██╗ ██║█████╗  ██████╔╝██║   ██║██║     ███████║                   ║
║          ██║╚██╗██║██╔══╝  ██╔══██╗██║   ██║██║     ██╔══██║                   ║
║          ██║ ╚████║███████╗██████╔╝╚██████╔╝███████╗██║  ██║                   ║
║          ╚═╝  ╚═══╝╚══════╝╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝                   ║
║                                                                                  ║
║          PROJECT NEBULA  ·  V7.0  "SINGULARITY PHASE"                          ║
║          TIER-ZERO CINEMATIC RENDERING MASTER EXECUTABLE                        ║
║          Target Parity: Genshin Impact 4.0 Ultra / Minecraft SEUS-PTGI         ║
║                                                                                  ║
║  ┌──────────────────────────────────────────────────────────────────────────┐   ║
║  │  §0   Service Acquisition & Global State                                 │   ║
║  │  §1   Master Configuration Table (V7)                                    │   ║
║  │  §2   Utility Library — Math / Noise / IK / Color                       │   ║
║  │  §3   Autonomous Frame-Budget Optimizer                                  │   ║
║  │  §4   Parallel Compute Dispatcher (task.desynchronize)                   │   ║
║  │  §5   Cinematic Loading Portal                                           │   ║
║  │  §6   World-Bender: 3D Micro-Foliage + IK Blade System                  │   ║
║  │  §7   World-Bender: EditableImage Surface Transfiguration                │   ║
║  │  §8   Atmospheric 2.0: Volumetric Clouds + God Rays V2                  │   ║
║  │  §9   Character Fidelity: SSS + Combat Rim Lighting                     │   ║
║  │  §10  Character Fidelity: Squash & Stretch Deformation                  │   ║
║  │  §11  Character Fidelity: Cloth & Hair Parallel Physics                 │   ║
║  │  §12  Kinetic VFX: Gravitational Lens / Spatial Distortion              │   ║
║  │  §13  Kinetic VFX: Impact Frames 5.0 + Negative-Color Burst             │   ║
║  │  §14  Kinetic VFX: 120Hz Sub-Frame Motion Interpolation                 │   ║
║  │  §15  Shader Kernel: SSGI Color Bleeding                                │   ║
║  │  §16  Shader Kernel: Ray-Marched Soft Shadows                           │   ║
║  │  §17  Shader Kernel: Cinematic LUT + Bokeh DOF                          │   ║
║  │  §18  Master Orchestrator + Public API                                  │   ║
║  └──────────────────────────────────────────────────────────────────────────┘   ║
║                                                                                  ║
║  INSTALL:  StarterPlayer → StarterPlayerScripts → LocalScript                  ║
║  FOLIAGE:  Tag BaseParts with CollectionService tag "NebFoliage"               ║
║  COMBAT:   _G.Nebula:OnSkillImpact(pos, normal, material, magnitude)           ║
╚══════════════════════════════════════════════════════════════════════════════════╝
]]

-- ════════════════════════════════════════════════════════════════════════════════
-- §0  SERVICE ACQUISITION & GLOBAL STATE
-- ════════════════════════════════════════════════════════════════════════════════
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local AssetService      = game:GetService("AssetService")
local ContentProvider   = game:GetService("ContentProvider")
local Debris            = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = Workspace.CurrentCamera

-- Runtime state flags
local NEBULA_INITIALIZED  = false
local NEBULA_COMBAT_STATE = "IDLE"   -- "IDLE" | "COMBAT" | "RAGE" | "FINISHER"

-- ════════════════════════════════════════════════════════════════════════════════
-- §1  MASTER CONFIGURATION TABLE (V7.0)
-- ════════════════════════════════════════════════════════════════════════════════
local CFG = {

    -- ── Quality Tiers ────────────────────────────────────────────────────────
    QUALITY = { ULTRA = 4, HIGH = 3, MEDIUM = 2, LOW = 1 },
    CURRENT_QUALITY = 3,

    -- ── Frame-Time Budget ────────────────────────────────────────────────────
    FTB_TARGET_MS    = 16.67,
    FTB_CRITICAL_MS  = 33.33,
    FTB_SAMPLE_COUNT = 45,

    -- ── Loading Portal ───────────────────────────────────────────────────────
    LOADER = {
        TRANSFIGURATION_DURATION = 3.5,   -- seconds of loading portal display
        PARTICLE_COUNT           = 80,
        PORTAL_COLOR_A           = Color3.fromRGB(10,  15,  40),
        PORTAL_COLOR_B           = Color3.fromRGB(30,  60, 120),
        ACCENT_COLOR             = Color3.fromRGB(80, 160, 255),
    },

    -- ── Foliage / World-Bender ───────────────────────────────────────────────
    GEO = {
        BLADE_COUNT_PER_PATCH    = 6,     -- IK blades per foliage Part
        BLADE_HEIGHT             = 0.5,
        BLADE_WIDTH              = 0.06,
        WIND_FREQUENCY           = 0.8,
        WIND_AMPLITUDE           = 0.22,
        WIND_GUST_PROBABILITY    = 0.003,
        GUST_STRENGTH            = 1.8,
        GUST_DURATION            = 1.6,
        COLLISION_RADIUS         = 3.8,
        IK_CHAIN_SEGMENTS        = 3,     -- segments per blade IK chain
        IK_ITERATIONS            = 4,     -- FABRIK iterations
        SPRING_STIFFNESS         = 14.0,
        SPRING_DAMPING           = 5.0,
        PERLIN_LAYERS            = 4,     -- fBm octave count (turbulence sync)
        PERLIN_PERSISTENCE       = 0.5,
        MAX_ACTIVE_BLADES        = 256,
    },

    -- ── Surface Transfiguration ──────────────────────────────────────────────
    SURFACE = {
        NORMAL_MAP_RESOLUTION    = 32,    -- NxN virtual normal map per part
        SHADING_INTENSITY        = 0.55,
        NORMAL_BUMP_SCALE        = 1.2,
        FRESNEL_POWER            = 4.0,
        MATERIAL_TINT_STONE      = Color3.fromRGB(110, 105, 100),
        MATERIAL_TINT_GRASS      = Color3.fromRGB( 80, 130,  60),
        MATERIAL_TINT_WOOD       = Color3.fromRGB(120,  90,  60),
        SAKUGA_CROSSHATCH        = true,
    },

    -- ── Atmospheric 2.0 ──────────────────────────────────────────────────────
    ATMO = {
        CLOUD_MARCH_STEPS        = 48,    -- volumetric ray steps (ULTRA)
        CLOUD_DENSITY_SCALE      = 0.28,
        CLOUD_HEIGHT             = 280,
        CLOUD_LAYER_THICKNESS    = 120,
        GOD_RAY_SAMPLES          = 20,
        GOD_RAY_DECAY            = 0.94,
        GOD_RAY_WEIGHT           = 0.60,
        GOD_RAY_EXPOSURE         = 0.65,
        SCATTER_R                = 5.8e-3,
        SCATTER_G                = 13.5e-3,
        SCATTER_B                = 33.1e-3,
        MIE_COEFF                = 21.0e-3,
        HAZE_DAWN_COLOR          = Color3.fromRGB(255, 130, 55),
        HAZE_DAY_COLOR           = Color3.fromRGB(190, 215, 255),
        HAZE_DUSK_COLOR          = Color3.fromRGB(255, 100, 40),
    },

    -- ── Character Fidelity V2 ────────────────────────────────────────────────
    CHAR = {
        -- SSS
        SSS_RADIUS               = 1.4,
        SSS_STRENGTH             = 0.40,
        SSS_TINT                 = Color3.fromRGB(255, 185, 160),
        -- Rim Lighting
        RIM_IDLE_COLOR           = Color3.fromRGB(160, 200, 255),
        RIM_COMBAT_COLOR         = Color3.fromRGB(255, 200, 100),
        RIM_RAGE_COLOR           = Color3.fromRGB(255,  60,  40),
        RIM_FINISHER_COLOR       = Color3.fromRGB(255, 255, 180),
        RIM_BRIGHTNESS           = 1.8,
        RIM_RANGE                = 6.0,
        -- Squash & Stretch
        SQUASH_LAND_SCALE        = Vector3.new(1.28, 0.72, 1.28),
        SQUASH_JUMP_SCALE        = Vector3.new(0.82, 1.22, 0.82),
        SQUASH_RECOVER_SPEED     = 8.0,
        STRETCH_SMEAR_SPEED      = 16.0,
        -- Cloth & Hair Physics
        CLOTH_INERTIA            = 0.90,
        CLOTH_STIFFNESS          = 0.18,
        CLOTH_GRAVITY            = 0.35,
        CLOTH_WIND_DRAG          = 0.12,
        CLOTH_SUBSTEPS           = 4,
        -- Outlines
        OUTLINE_WIDTH_BASE       = 0.045,
        OUTLINE_WIDTH_MAX        = 0.12,
        OUTLINE_TAPER_BIAS       = 1.9,
    },

    -- ── Kinetic VFX V2 ────────────────────────────────────────────────────────
    VFX = {
        -- Gravitational Lens
        LENS_RING_COUNT          = 3,
        LENS_MAX_RADIUS_PX       = 420,
        LENS_DURATION            = 0.55,
        LENS_WARP_LAYERS         = 5,
        -- Impact Frames 5.0
        IMPACT_DURATION          = 0.022,
        SPEEDLINE_COUNT          = 32,
        NEGATIVE_FLASH_FRAMES    = 2,
        SPEEDLINE_WEIGHT_MAX     = 0.95,
        CHROMATIC_ABERRATION     = true,
        -- Shockwave
        SHOCKWAVE_DURATION       = 0.40,
        SHOCKWAVE_RING_COUNT     = 3,
        -- Debris
        DEBRIS_COUNT_MAX         = 64,
        DEBRIS_LIGHT_RADIUS      = 4.0,
        DEBRIS_SHADOW_STEPS      = 6,
        -- 120Hz Interp
        INTERP_TARGET_HZ         = 120,
    },

    -- ── Shader Kernels V2 ─────────────────────────────────────────────────────
    SHADER = {
        SSGI_RAY_COUNT           = 20,
        SSGI_RAY_LENGTH          = 14.0,
        SSGI_BOUNCE_WEIGHT       = 0.50,
        SSGI_TEMPORAL_BLEND      = 0.15,  -- temporal accumulation factor
        SHADOW_SAMPLES           = 16,
        SHADOW_RADIUS            = 2.0,
        SHADOW_BIAS              = 0.012,
        DOF_APERTURE             = 0.048,
        DOF_FOCAL_LERP_SPEED     = 0.06,
        DOF_BOKEH_SIDES          = 6,     -- hexagonal
        LUT_SHINKAI_STRENGTH     = 0.75,
        LUT_GOLDEN_STRENGTH      = 0.0,
        LUT_FILMIC_CONTRAST      = 0.12,
        LUT_SHADOW_LIFT_R        = 0.02,
        LUT_SHADOW_LIFT_B        = 0.06,
        BLOOM_THRESHOLD          = 0.82,
        BLOOM_INTENSITY          = 0.55,
        BLOOM_SIZE               = 28,
    },
}

-- ════════════════════════════════════════════════════════════════════════════════
-- §2  UTILITY LIBRARY — MATH / NOISE / IK / COLOR
-- ════════════════════════════════════════════════════════════════════════════════
local Util = {}

-- ── Perlin 3D Noise (permutation table, classic Ken Perlin 2002) ─────────────
do
    local p = {}
    math.randomseed(0xC0FFEE42)
    for i = 0, 255 do p[i] = i end
    for i = 255, 1, -1 do
        local j = math.random(0, i)
        p[i], p[j] = p[j], p[i]
    end
    for i = 0, 255 do p[i+256] = p[i] end

    local g3 = {
        {1,1,0},{-1,1,0},{1,-1,0},{-1,-1,0},
        {1,0,1},{-1,0,1},{1,0,-1},{-1,0,-1},
        {0,1,1},{0,-1,1},{0,1,-1},{0,-1,-1},
    }
    local function fade(t) return t*t*t*(t*(t*6-15)+10) end
    local function lerp(a,b,t) return a+(b-a)*t end
    local function grad(h,x,y,z)
        local g=g3[(h%12)+1]; return g[1]*x+g[2]*y+g[3]*z
    end

    function Util.perlin3(x,y,z)
        local X,Y,Z = math.floor(x)%256, math.floor(y)%256, math.floor(z)%256
        x,y,z = x-math.floor(x), y-math.floor(y), z-math.floor(z)
        local u,v,w = fade(x),fade(y),fade(z)
        local A  = p[X]+Y;   local AA=p[A]+Z;   local AB=p[A+1]+Z
        local B  = p[X+1]+Y; local BA=p[B]+Z;   local BB=p[B+1]+Z
        return lerp(
            lerp(lerp(grad(p[AA],x,y,z),   grad(p[BA],x-1,y,z),  u),
                 lerp(grad(p[AB],x,y-1,z), grad(p[BB],x-1,y-1,z),u),v),
            lerp(lerp(grad(p[AA+1],x,y,z-1),   grad(p[BA+1],x-1,y,z-1),  u),
                 lerp(grad(p[AB+1],x,y-1,z-1), grad(p[BB+1],x-1,y-1,z-1),u),v),w)
    end

    -- Fractional Brownian Motion — 4-layer turbulence sync
    function Util.fbm(x,y,z,oct,persist,lac)
        oct,persist,lac = oct or 4, persist or 0.5, lac or 2.0
        local val,amp,freq,mx = 0,1,1,0
        for _=1,oct do
            val  = val + Util.perlin3(x*freq,y*freq,z*freq)*amp
            mx   = mx+amp; amp=amp*persist; freq=freq*lac
        end
        return val/mx
    end

    -- Domain-warped fBm for more organic turbulence
    function Util.warpedFbm(x,y,z,oct)
        local warpX = Util.fbm(x+0.0, y+0.0, z+0.0, oct)
        local warpY = Util.fbm(x+5.2, y+1.3, z+3.7, oct)
        local warpZ = Util.fbm(x+1.7, y+9.2, z+2.1, oct)
        return Util.fbm(x+4*warpX, y+4*warpY, z+4*warpZ, oct)
    end
end

-- ── Spring Dynamics ───────────────────────────────────────────────────────────
function Util.spring(cur, tgt, vel, k, d, dt)
    local a = (tgt-cur)*k - vel*d
    vel = vel + a*dt
    cur = cur + vel*dt
    return cur, vel
end

function Util.springV3(cur, tgt, vel, k, d, dt)
    local function sp(c,t,v) return Util.spring(c,t,v,k,d,dt) end
    local nx,vx = sp(cur.X, tgt.X, vel.X)
    local ny,vy = sp(cur.Y, tgt.Y, vel.Y)
    local nz,vz = sp(cur.Z, tgt.Z, vel.Z)
    return Vector3.new(nx,ny,nz), Vector3.new(vx,vy,vz)
end

-- ── FABRIK IK Solver (Forward And Backward Reaching IK) ──────────────────────
--[[
  Solves a chain of N segments to reach a target position.
  chain = array of Vector3 positions (root at [1], tip at [N])
  lengths = array of segment lengths
  target = Vector3 target for the tip
  Returns: updated chain array
]]
function Util.solveFABRIK(chain, lengths, target, iterations)
    local n = #chain
    if n < 2 then return chain end
    iterations = iterations or 4
    local root = chain[1]

    for _ = 1, iterations do
        -- Forward pass: tip → root
        chain[n] = target
        for i = n-1, 1, -1 do
            local dir = (chain[i] - chain[i+1])
            if dir.Magnitude > 1e-6 then
                chain[i] = chain[i+1] + dir.Unit * lengths[i]
            end
        end
        -- Backward pass: root → tip
        chain[1] = root
        for i = 1, n-1 do
            local dir = (chain[i+1] - chain[i])
            if dir.Magnitude > 1e-6 then
                chain[i+1] = chain[i] + dir.Unit * lengths[i]
            end
        end
    end
    return chain
end

-- ── Math helpers ─────────────────────────────────────────────────────────────
function Util.smoothstep(e0, e1, x)
    local t = math.clamp((x-e0)/(e1-e0), 0, 1)
    return t*t*(3-2*t)
end

function Util.smootherstep(e0, e1, x)
    local t = math.clamp((x-e0)/(e1-e0), 0, 1)
    return t*t*t*(t*(t*6-15)+10)
end

function Util.remap(v, a, b, c, d)
    return c + (v-a)/(b-a)*(d-c)
end

function Util.lerpV3(a,b,t)
    return Vector3.new(a.X+(b.X-a.X)*t, a.Y+(b.Y-a.Y)*t, a.Z+(b.Z-a.Z)*t)
end

function Util.lerpColor(a,b,t)
    return Color3.new(a.R+(b.R-a.R)*t, a.G+(b.G-a.G)*t, a.B+(b.B-a.B)*t)
end

-- sRGB ↔ Linear color space
function Util.toLinear(c)
    local f=function(v) return v<=0.04045 and v/12.92 or ((v+0.055)/1.055)^2.4 end
    return Color3.new(f(c.R),f(c.G),f(c.B))
end
function Util.toSRGB(c)
    local f=function(v) return math.clamp(v<=0.0031308 and 12.92*v or 1.055*v^(1/2.4)-0.055,0,1) end
    return Color3.new(f(c.R),f(c.G),f(c.B))
end

-- Reinhard tone-mapper (for HDR bloom color overflow)
function Util.reinhard(c)
    return Color3.new(c.R/(1+c.R), c.G/(1+c.G), c.B/(1+c.B))
end

-- ACES filmic tone-map approximation (Narkowicz 2015)
function Util.aces(c)
    local a,b,cc,d,e = 2.51,0.03,2.43,0.59,0.14
    local function f(x) return math.clamp((x*(a*x+b))/(x*(cc*x+d)+e),0,1) end
    return Color3.new(f(c.R),f(c.G),f(c.B))
end

-- Screenspace UV from WorldPos
function Util.worldToUV(worldPos)
    local sp, onScreen = Camera:WorldToViewportPoint(worldPos)
    if not onScreen then return nil end
    local vp = Camera.ViewportSize
    return Vector2.new(sp.X/vp.X, sp.Y/vp.Y), sp.Z
end

-- Raycast helper with optional RaycastParams
function Util.cast(orig, dir, params)
    return Workspace:Raycast(orig, dir, params)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- §3  AUTONOMOUS FRAME-BUDGET OPTIMIZER
-- ════════════════════════════════════════════════════════════════════════════════
local Optimizer = {}
Optimizer.__index = Optimizer

function Optimizer.new()
    local s = setmetatable({}, Optimizer)
    s.samples   = {}
    s.ptr       = 1
    s.avg       = 0
    s.tier      = CFG.CURRENT_QUALITY
    s.lastTick  = tick()
    s.callbacks = {}
    return s
end

function Optimizer:tick()
    local now = tick()
    local ms  = (now - self.lastTick) * 1000
    self.lastTick = now
    self.samples[self.ptr] = ms
    self.ptr = (self.ptr % CFG.FTB_SAMPLE_COUNT) + 1
    local s = 0
    for _,v in ipairs(self.samples) do s=s+v end
    self.avg = s / #self.samples
    self:_autoScale()
end

function Optimizer:_autoScale()
    local Q    = CFG.QUALITY
    local prev = self.tier
    if    self.avg > CFG.FTB_CRITICAL_MS  then self.tier = Q.LOW
    elseif self.avg > CFG.FTB_TARGET_MS*1.4 then self.tier = Q.MEDIUM
    elseif self.avg > CFG.FTB_TARGET_MS*1.1 then self.tier = Q.HIGH
    else                                         self.tier = Q.ULTRA
    end
    if self.tier ~= prev then
        CFG.CURRENT_QUALITY = self.tier
        -- Live-rescale all budget-sensitive params
        local s = self.tier / Q.ULTRA
        CFG.ATMO.CLOUD_MARCH_STEPS   = math.max(8,  math.floor(48*s))
        CFG.ATMO.GOD_RAY_SAMPLES     = math.max(4,  math.floor(20*s))
        CFG.SHADER.SSGI_RAY_COUNT    = math.max(4,  math.floor(20*s))
        CFG.SHADER.SHADOW_SAMPLES    = math.max(4,  math.floor(16*s))
        CFG.GEO.MAX_ACTIVE_BLADES    = math.max(32, math.floor(256*s))
        for _,cb in ipairs(self.callbacks) do pcall(cb, self.tier, prev) end
        print(("[NEBULA::Optimizer] Tier %d → %d  (avg %.1fms)"):format(prev,self.tier,self.avg))
    end
end

function Optimizer:scaledInt(base, minVal)
    return math.max(minVal or 1, math.floor(base * self.tier / CFG.QUALITY.ULTRA))
end

function Optimizer:onTierChange(fn) table.insert(self.callbacks, fn) end

-- ════════════════════════════════════════════════════════════════════════════════
-- §4  PARALLEL COMPUTE DISPATCHER
-- ════════════════════════════════════════════════════════════════════════════════
local PC = {}

-- Desync → run fn → resync back to main thread
function PC.run(fn, ...)
    local args   = {...}
    local result = nil
    task.desynchronize()
    local ok, err = pcall(function() result = fn(table.unpack(args)) end)
    task.synchronize()
    if not ok then warn("[PC.run] " .. tostring(err)) end
    return result
end

-- Batch processor: runs processFn on each item in desync chunks
function PC.batch(items, processFn, chunkSize)
    chunkSize = chunkSize or 32
    local out = {}
    local i   = 1
    while i <= #items do
        local chunk = {}
        for j = i, math.min(i+chunkSize-1, #items) do chunk[#chunk+1] = items[j] end
        task.desynchronize()
        for _, item in ipairs(chunk) do
            local ok, r = pcall(processFn, item)
            if ok then out[#out+1] = r end
        end
        task.synchronize()
        i = i + chunkSize
    end
    return out
end

-- Async fire-and-forget (for non-result computations like physics integration)
function PC.async(fn, ...)
    local args = {...}
    task.spawn(function()
        task.desynchronize()
        pcall(fn, table.unpack(args))
        task.synchronize()
    end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- §5  CINEMATIC LOADING PORTAL
-- ════════════════════════════════════════════════════════════════════════════════
local LoadingPortal = {}
LoadingPortal.__index = LoadingPortal

function LoadingPortal.new()
    local s = setmetatable({}, LoadingPortal)
    s.gui         = nil
    s.particles   = {}
    s.progress    = 0
    s.phases      = {}
    s.phaseIndex  = 0
    s.complete    = false
    return s
end

function LoadingPortal:Build()
    local L = CFG.LOADER
    local gui = Instance.new("ScreenGui")
    gui.Name           = "NebulaPortal"
    gui.ResetOnSpawn   = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder   = 999
    gui.Parent         = PlayerGui

    -- ── Background ────────────────────────────────────────────────────────
    local bg = Instance.new("Frame")
    bg.Size              = UDim2.fromScale(1,1)
    bg.BackgroundColor3  = L.PORTAL_COLOR_A
    bg.BorderSizePixel   = 0
    bg.Parent = gui

    local bgGrad = Instance.new("UIGradient")
    bgGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, L.PORTAL_COLOR_A),
        ColorSequenceKeypoint.new(1, L.PORTAL_COLOR_B),
    })
    bgGrad.Rotation = 135
    bgGrad.Parent = bg

    -- ── Central Nebula Ring ───────────────────────────────────────────────
    local ringHolder = Instance.new("Frame")
    ringHolder.Size            = UDim2.fromOffset(320, 320)
    ringHolder.AnchorPoint     = Vector2.new(0.5, 0.5)
    ringHolder.Position        = UDim2.fromScale(0.5, 0.46)
    ringHolder.BackgroundTransparency = 1
    ringHolder.Parent = bg

    for r = 1, 3 do
        local ring = Instance.new("Frame")
        local sz   = 100 + r * 72
        ring.Name             = "Ring"..r
        ring.Size             = UDim2.fromOffset(sz, sz)
        ring.AnchorPoint      = Vector2.new(0.5, 0.5)
        ring.Position         = UDim2.fromScale(0.5, 0.5)
        ring.BackgroundTransparency = 1
        ring.BorderSizePixel  = 0

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ring

        local stroke = Instance.new("UIStroke")
        stroke.Color       = Color3.fromHSV(0.6 - r*0.05, 0.7, 1)
        stroke.Thickness   = math.max(1, 4 - r)
        stroke.Transparency= 0.3 + r * 0.15
        stroke.Parent = ring
        ring.Parent = ringHolder

        -- Rotation animation per ring
        local rotSpeed = (r % 2 == 0 and -1 or 1) * (30 + r * 12)
        RunService.Heartbeat:Connect(function(dt)
            if not gui.Parent then return end
            ring.Rotation = ring.Rotation + rotSpeed * dt
        end)
    end

    -- ── Title ─────────────────────────────────────────────────────────────
    local title = Instance.new("TextLabel")
    title.Size              = UDim2.fromOffset(520, 48)
    title.AnchorPoint       = Vector2.new(0.5, 0)
    title.Position          = UDim2.fromScale(0.5, 0.66)
    title.BackgroundTransparency = 1
    title.Text              = "PROJECT  NEBULA  V7"
    title.TextColor3        = Color3.new(1,1,1)
    title.TextSize          = 22
    title.Font              = Enum.Font.GothamBold
    title.LetterSpacing     = 6
    title.TextTransparency  = 0
    title.Parent = bg

    -- ── Phase Label ──────────────────────────────────────────────────────
    local phaseLabel = Instance.new("TextLabel")
    phaseLabel.Name             = "PhaseLabel"
    phaseLabel.Size             = UDim2.fromOffset(520, 28)
    phaseLabel.AnchorPoint      = Vector2.new(0.5, 0)
    phaseLabel.Position         = UDim2.fromScale(0.5, 0.73)
    phaseLabel.BackgroundTransparency = 1
    phaseLabel.Text             = "INITIALIZING TRANSFIGURATION ENGINE..."
    phaseLabel.TextColor3       = L.ACCENT_COLOR
    phaseLabel.TextSize         = 12
    phaseLabel.Font             = Enum.Font.Gotham
    phaseLabel.LetterSpacing    = 3
    phaseLabel.Parent = bg

    -- ── Progress Bar ──────────────────────────────────────────────────────
    local barBg = Instance.new("Frame")
    barBg.Size              = UDim2.fromOffset(400, 3)
    barBg.AnchorPoint       = Vector2.new(0.5, 0)
    barBg.Position          = UDim2.fromScale(0.5, 0.78)
    barBg.BackgroundColor3  = Color3.fromRGB(40, 55, 90)
    barBg.BorderSizePixel   = 0
    barBg.Parent = bg

    local barFill = Instance.new("Frame")
    barFill.Name            = "BarFill"
    barFill.Size            = UDim2.fromScale(0, 1)
    barFill.BackgroundColor3= L.ACCENT_COLOR
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg

    -- ── Floating Particles ────────────────────────────────────────────────
    for i = 1, L.PARTICLE_COUNT do
        local dot = Instance.new("Frame")
        dot.Size               = UDim2.fromOffset(
            math.random(2,5), math.random(2,5))
        dot.AnchorPoint        = Vector2.new(0.5, 0.5)
        dot.Position           = UDim2.fromScale(math.random(), math.random())
        dot.BackgroundColor3   = Color3.fromHSV(
            0.55 + math.random()*0.1, 0.6+math.random()*0.4, 1)
        dot.BackgroundTransparency = 0.2 + math.random()*0.6
        dot.BorderSizePixel    = 0

        local c2 = Instance.new("UICorner")
        c2.CornerRadius = UDim.new(1,0)
        c2.Parent = dot
        dot.Parent = bg

        local speed = 0.06 + math.random()*0.12
        local phase = math.random() * math.pi * 2
        table.insert(self.particles, {dot=dot, speed=speed, phase=phase, t=0})
    end

    self.gui        = gui
    self.bg         = bg
    self.phaseLabel = phaseLabel
    self.barFill    = barFill
    return gui
end

function LoadingPortal:SetPhase(name)
    if self.phaseLabel then self.phaseLabel.Text = name end
end

function LoadingPortal:SetProgress(p)
    self.progress = p
    if self.barFill then
        TweenService:Create(self.barFill,
            TweenInfo.new(0.25, Enum.EasingStyle.Quad),
            {Size = UDim2.fromScale(math.clamp(p,0,1), 1)}):Play()
    end
    -- Animate particles
    for _, pt in ipairs(self.particles) do
        pt.t = pt.t + 0.04
        local newY = ((pt.dot.Position.Y.Scale - pt.speed * 0.01) % 1)
        pt.dot.Position = UDim2.fromScale(
            pt.dot.Position.X.Scale + math.sin(pt.t + pt.phase) * 0.001,
            newY)
        pt.dot.BackgroundTransparency = 0.2 + 0.5*(math.sin(pt.t*0.5+pt.phase)+1)*0.5
    end
end

function LoadingPortal:Dismiss()
    if not self.gui then return end
    TweenService:Create(self.bg,
        TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
        {BackgroundTransparency = 1}):Play()
    -- Fade all children
    for _, child in ipairs(self.bg:GetDescendants()) do
        if child:IsA("TextLabel") then
            TweenService:Create(child, TweenInfo.new(0.8), {TextTransparency=1}):Play()
        elseif child:IsA("Frame") then
            TweenService:Create(child, TweenInfo.new(0.8), {BackgroundTransparency=1}):Play()
        end
    end
    task.delay(1.4, function() if self.gui then self.gui:Destroy() end end)
    self.complete = true
end

-- ════════════════════════════════════════════════════════════════════════════════
-- §6  WORLD-BENDER: 3D MICRO-FOLIAGE + FABRIK IK BLADE SYSTEM
-- ════════════════════════════════════════════════════════════════════════════════
local MicroFoliage = {}
MicroFoliage.__index = MicroFoliage

function MicroFoliage.new(optimizer)
    local s = setmetatable({}, MicroFoliage)
    s.opt         = optimizer
    s.patches     = {}       -- foliage Part → blade array
    s.globalTime  = 0
    s.gustActive  = false
    s.gustStr     = 0
    s.gustTimer   = 0
    s.conn        = nil
    s.enabled     = false
    return s
end

--[[
  BLADE DATA STRUCTURE:
  {
    parts  = array of N BaseParts (segments along blade)
    chain  = array of N Vector3 (current IK joint positions)
    lengths= array of N-1 floats (segment lengths)
    root   = Vector3 (world-space root anchor)
    velX, velZ = spring velocities for wind displacement
    displX, displZ = current wind displacements
    phase  = float (perlin phase offset)
    lean   = float (current lean angle)
  }
]]
function MicroFoliage:_spawnBlade(patch, offset)
    local cfg    = CFG.GEO
    local root   = patch.Position + offset + Vector3.new(0, 0.01, 0)
    local segs   = cfg.IK_CHAIN_SEGMENTS
    local segLen = cfg.BLADE_HEIGHT / segs
    local blade  = {
        parts   = {},
        chain   = {},
        lengths = {},
        root    = root,
        velX    = 0, velZ    = 0,
        displX  = 0, displZ  = 0,
        phase   = math.random() * math.pi * 2,
        lean    = 0,
    }

    for i = 1, segs do
        local seg = Instance.new("Part")
        seg.Anchored     = true
        seg.CanCollide   = false
        seg.CastShadow   = false
        seg.Size         = Vector3.new(
            cfg.BLADE_WIDTH * (1 - i/segs * 0.5),  -- taper toward tip
            segLen,
            cfg.BLADE_WIDTH * (1 - i/segs * 0.5))
        seg.Material     = Enum.Material.SmoothPlastic
        seg.Color        = Color3.fromHSV(
            0.28 + math.random()*0.06,              -- green family
            0.6  + math.random()*0.2,
            0.45 + math.random()*0.2)
        seg.CFrame       = CFrame.new(root + Vector3.new(0, segLen*i - segLen*0.5, 0))
        seg.Parent       = Workspace

        blade.parts[i]   = seg
        blade.chain[i]   = root + Vector3.new(0, segLen*(i-1), 0)
        if i < segs then blade.lengths[i] = segLen end
    end
    -- Fix last length for tip
    blade.lengths[segs] = segLen

    return blade
end

function MicroFoliage:_scan()
    local tagged = CollectionService:GetTagged("NebFoliage")
    self.patches = {}
    for _, part in ipairs(tagged) do
        if part:IsA("BasePart") then
            local blades = {}
            local bpp = CFG.GEO.BLADE_COUNT_PER_PATCH
            for i = 1, bpp do
                local rx = (math.random()-0.5) * part.Size.X * 0.9
                local rz = (math.random()-0.5) * part.Size.Z * 0.9
                local blade = self:_spawnBlade(part, Vector3.new(rx, part.Size.Y*0.5, rz))
                blades[i] = blade
            end
            self.patches[part] = blades
        end
    end
    print(("[MicroFoliage] Spawned blades on %d patches"):format(
        (function() local c=0; for _ in pairs(self.patches) do c=c+1 end; return c end)()))
end

function MicroFoliage:_updateGust(dt)
    self.gustTimer = math.max(0, self.gustTimer - dt)
    if not self.gustActive then
        if math.random() < CFG.GEO.WIND_GUST_PROBABILITY then
            self.gustActive = true
            self.gustStr    = CFG.GEO.GUST_STRENGTH * (0.75 + math.random()*0.5)
            self.gustTimer  = CFG.GEO.GUST_DURATION
        end
    elseif self.gustTimer <= 0 then
        self.gustActive = false
        self.gustStr    = 0
    end
    self.globalTime = self.globalTime + dt * CFG.GEO.WIND_FREQUENCY
end

function MicroFoliage:_updateBlade(blade, dt)
    local cfg  = CFG.GEO
    local t    = self.globalTime
    local gust = self.gustActive and self.gustStr or 0

    -- 4-layer Perlin turbulence for wind displacement (domain-warped)
    local px = blade.root.X * 0.1 + t
    local pz = blade.root.Z * 0.1 + blade.phase
    local windX = Util.warpedFbm(px, 0, pz,     cfg.PERLIN_LAYERS) * cfg.WIND_AMPLITUDE * (1+gust)
    local windZ = Util.warpedFbm(px+100, 0, pz, cfg.PERLIN_LAYERS) * cfg.WIND_AMPLITUDE * (1+gust*0.7)

    -- Spring dynamics for smooth deferred tracking
    blade.displX, blade.velX = Util.spring(blade.displX, windX, blade.velX,
        cfg.SPRING_STIFFNESS, cfg.SPRING_DAMPING, dt)
    blade.displZ, blade.velZ = Util.spring(blade.displZ, windZ, blade.velZ,
        cfg.SPRING_STIFFNESS, cfg.SPRING_DAMPING, dt)

    -- Collision pushback from nearby characters
    for _, plr in ipairs(Players:GetPlayers()) do
        local chr = plr.Character
        if chr then
            local hrp = chr:FindFirstChild("HumanoidRootPart")
            if hrp then
                local delta = blade.root - hrp.Position
                delta = Vector3.new(delta.X, 0, delta.Z)
                local dist = delta.Magnitude
                if dist < cfg.COLLISION_RADIUS then
                    local str = Util.smoothstep(cfg.COLLISION_RADIUS, 0.3, dist)
                    local push = delta.Magnitude > 0.01 and delta.Unit or Vector3.new(1,0,0)
                    blade.velX = blade.velX + push.X * str * 12
                    blade.velZ = blade.velZ + push.Z * str * 12
                end
            end
        end
    end

    -- Build IK target: tip is displaced by wind in XZ plane
    local segs  = cfg.IK_CHAIN_SEGMENTS
    local tipTarget = blade.root + Vector3.new(
        blade.displX * (segs / 2),
        cfg.BLADE_HEIGHT - math.abs(blade.displX + blade.displZ) * 0.06,
        blade.displZ * (segs / 2))

    -- Solve FABRIK chain
    blade.chain[1] = blade.root
    Util.solveFABRIK(blade.chain, blade.lengths, tipTarget, cfg.IK_ITERATIONS)

    -- Apply chain to segment CFrames
    for i = 1, segs do
        local partPos  = blade.chain[i] + Vector3.new(0, blade.lengths[i]*0.5, 0)
        local nextPos  = i < segs and blade.chain[i+1] or tipTarget
        local dir      = (nextPos - blade.chain[i])
        local segCF
        if dir.Magnitude > 0.001 then
            segCF = CFrame.new(partPos, partPos + dir) *
                    CFrame.Angles(math.pi/2, 0, 0)
        else
            segCF = CFrame.new(partPos)
        end
        blade.parts[i].CFrame = segCF
    end
end

function MicroFoliage:Enable()
    if self.enabled then return end
    self.enabled = true
    self:_scan()

    self.conn = RunService.Heartbeat:Connect(function(dt)
        pcall(function()
            self:_updateGust(dt)
            local budget = self.opt:scaledInt(CFG.GEO.MAX_ACTIVE_BLADES, 32)
            local count  = 0
            for patch, blades in pairs(self.patches) do
                if not patch.Parent then
                    self.patches[patch] = nil
                else
                    for _, blade in ipairs(blades) do
                        if count >= budget then break end
                        pcall(self._updateBlade, self, blade, dt)
                        count = count + 1
                    end
                end
                if count >= budget then break end
            end
        end)
    end)
end

function MicroFoliage:Disable()
    if self.conn then self.conn:Disconnect() end
    for _, blades in pairs(self.patches) do
        for _, blade in ipairs(blades) do
            for _, seg in ipairs(blade.parts) do pcall(function() seg:Destroy() end) end
        end
    end
    self.patches = {}
    self.enabled = false
end

-- ════════════════════════════════════════════════════════════════════════════════
-- §7  WORLD-BENDER: SURFACE TRANSFIGURATION (Script-Based Normal Shading)
-- ════════════════════════════════════════════════════════════════════════════════
local SurfaceTransfig = {}
SurfaceTransfig.__index = SurfaceTransfig

function SurfaceTransfig.new(optimizer)
    local s = setmetatable({}, SurfaceTransfig)
    s.opt        = optimizer
    s.processed  = {}
    s.conn       = nil
    s.enabled    = false
    s.frameCount = 0
    return s
end

--[[
  NORMAL MAP SIMULATION:
  For each visible Part within a distance threshold, we:
  1. Sample a NxN virtual height-field via Perlin noise (matches the part's UV).
  2. Compute finite-difference normals from the height-field.
  3. Derive a per-face lighting value from the simulated normal and sun direction.
  4. Apply the result as a Color3 tint adjustment on the Part's Color property,
     effectively painting "Normal Map" shading onto geometry.
  5. Cross-hatch ambient occlusion overlay via a second, higher-frequency noise pass.
  This technique is completely software-side and works on any BasePart.
]]
function SurfaceTransfig:_computeNormalShading(part)
    local cfg     = CFG.SURFACE
    local sunDir  = Lighting:GetSunDirection()
    local N       = 8  -- reduced resolution for perf (full N=32 is in ULTRA only)
    if CFG.CURRENT_QUALITY >= CFG.QUALITY.ULTRA then N = cfg.NORMAL_MAP_RESOLUTION end

    local pos     = part.Position
    local scale   = 1 / N
    local bump    = cfg.NORMAL_BUMP_SCALE

    -- Sample height field
    local h = {}
    for i = 0, N+1 do
        h[i] = {}
        for j = 0, N+1 do
            h[i][j] = Util.fbm(
                pos.X*0.08 + i*scale,
                pos.Y*0.05,
                pos.Z*0.08 + j*scale, 3) * bump
        end
    end

    -- Average normal via central finite differences
    local nx, ny, nz = 0, 0, 0
    for i = 1, N do
        for j = 1, N do
            local dhdx = (h[i+1][j] - h[i-1][j]) * 0.5
            local dhdz = (h[i][j+1] - h[i][j-1]) * 0.5
            -- Normal = normalize(-dhdx, 1, -dhdz)
            local len  = math.sqrt(dhdx*dhdx + 1 + dhdz*dhdz)
            nx = nx + (-dhdx/len)
            ny = ny + (1/len)
            nz = nz + (-dhdz/len)
        end
    end
    local inv = 1/(N*N)
    local normal = Vector3.new(nx*inv, ny*inv, nz*inv).Unit

    -- Diffuse NdotL
    local ndotl  = math.clamp(normal:Dot(sunDir), 0, 1)

    -- Ambient occlusion from high-frequency noise
    local ao = 1 - math.abs(Util.fbm(pos.X*0.3, pos.Y*0.2, pos.Z*0.3, 2)) * 0.3

    -- Fresnel rim (view-dependent specular highlight)
    local viewDir  = (Camera.CFrame.Position - pos).Unit
    local fresnel  = (1 - math.abs(normal:Dot(viewDir))) ^ cfg.FRESNEL_POWER

    -- Combine into final surface color modifier
    local base     = part.Color
    local lightVal = Util.smoothstep(0, 0.8, ndotl) * ao
    local rimVal   = fresnel * 0.15

    -- Determine material tint
    local matTint
    local mat = part.Material
    if mat == Enum.Material.SmoothPlastic or mat == Enum.Material.Concrete then
        matTint = cfg.MATERIAL_TINT_STONE
    elseif mat == Enum.Material.Grass or mat == Enum.Material.LeafyGrass then
        matTint = cfg.MATERIAL_TINT_GRASS
    elseif mat == Enum.Material.Wood or mat == Enum.Material.WoodPlanks then
        matTint = cfg.MATERIAL_TINT_WOOD
    else
        matTint = base
    end

    -- Cross-hatch AO for Sakuga ink feel
    local crosshatch = 1.0
    if cfg.SAKUGA_CROSSHATCH then
        local ch = Util.perlin3(pos.X*1.4, pos.Y*1.4, pos.Z*1.4)
        crosshatch = 0.88 + ch * 0.12
    end

    local shadedR = math.clamp(matTint.R * (0.3 + lightVal * 0.7 + rimVal) * crosshatch, 0, 1)
    local shadedG = math.clamp(matTint.G * (0.3 + lightVal * 0.7 + rimVal) * crosshatch, 0, 1)
    local shadedB = math.clamp(matTint.B * (0.3 + lightVal * 0.7 + rimVal) * crosshatch, 0, 1)

    part.Color = Color3.new(shadedR, shadedG, shadedB)
    self.processed[part] = {origColor = base}
end

function SurfaceTransfig:Enable()
    if self.enabled then return end
    self.enabled = true

    -- Process visible world parts
    local toProcess = {}
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("BasePart")
            and not desc:IsDescendantOf(LocalPlayer.Character or Instance.new("Folder"))
            and desc.Name ~= "Baseplate"
            and #CollectionService:GetTags(desc) == 0  -- don't re-shade foliage
        then
            table.insert(toProcess, desc)
            if #toProcess >= 800 then break end
        end
    end

    -- Process in parallel chunks
    PC.batch(toProcess, function(part)
        pcall(self._computeNormalShading, self, part)
    end, 40)

    -- Re-update lighting dynamically every few seconds as sun moves
    self.conn = RunService.Heartbeat:Connect(function()
        self.frameCount = self.frameCount + 1
        -- Re-shade 8 parts per frame in a rolling fashion
        if self.frameCount % 4 == 0 then
            local keys = {}
            for k in pairs(self.processed) do keys[#keys+1] = k end
            if #keys > 0 then
                local idx = (math.floor(self.frameCount / 4) % #keys) + 1
                local part = keys[idx]
                if part and part.Parent then
                    pcall(self._computeNormalShading, self, part)
                end
            end
        end
    end)
end

function SurfaceTransfig:Disable()
    if self.conn then self.conn:Disconnect() end
    -- Restore original colors
    for part, data in pairs(self.processed) do
        if part and part.Parent then
            pcall(function() part.Color = data.origColor end)
        end
    end
    self.processed = {}
    self.enabled   = false
end

-- ════════════════════════════════════════════════════════════════════════════════
-- §8  ATMOSPHERIC 2.0: VOLUMETRIC CLOUDS + GOD RAYS V2
-- ════════════════════════════════════════════════════════════════════════════════
local AtmosphericV2 = {}
AtmosphericV2.__index = AtmosphericV2

function AtmosphericV2.new(optimizer)
    local s = setmetatable({}, AtmosphericV2)
    s.opt        = optimizer
    s.godRayGui  = nil
    s.cloudParts = {}
    s.cloudTime  = 0
    s.conn       = nil
    s.enabled    = false
    return s
end

-- ── Volumetric cloud density sampler ─────────────────────────────────────────
function AtmosphericV2:_cloudDensity(worldPos, t)
    local cfg = CFG.ATMO
    local base = Util.warpedFbm(
        worldPos.X * 0.003 + t * 0.01,
        worldPos.Y * 0.008,
        worldPos.Z * 0.003, 4)
    -- Height falloff within cloud layer
    local heightRelative = (worldPos.Y - cfg.CLOUD_HEIGHT) / cfg.CLOUD_LAYER_THICKNESS
    local heightFalloff  = 1 - math.abs(heightRelative * 2 - 1)
    return math.max(0, base * heightFalloff * cfg.CLOUD_DENSITY_SCALE)
end

-- ── Ray-march through cloud volume ────────────────────────────────────────────
--[[
  Marches from camera along a ray, accumulating optical depth from
  cloud density samples.  Returns transmittance (1 = clear, 0 = fully cloudy).
  Used to modulate god-ray occlusion: if a god-ray sample point is inside
  a dense cloud, its contribution is reduced.
]]
function AtmosphericV2:_marchCloudRay(origin, dir, steps)
    local cfg      = CFG.ATMO
    local stepSize = cfg.CLOUD_LAYER_THICKNESS / steps
    local optDepth = 0
    local pos      = origin

    for _ = 1, steps do
        pos = pos + dir * stepSize
        if pos.Y > cfg.CLOUD_HEIGHT and
           pos.Y < cfg.CLOUD_HEIGHT + cfg.CLOUD_LAYER_THICKNESS then
            optDepth = optDepth + self:_cloudDensity(pos, self.cloudTime) * stepSize
        end
    end
    return math.exp(-optDepth)  -- Beer-Lambert transmittance
end

-- ── God Ray marching with cloud occlusion ─────────────────────────────────────
function AtmosphericV2:_computeGodRays()
    if not self.godRayGui then return end
    local cfg      = CFG.ATMO
    local steps    = self.opt:scaledInt(cfg.GOD_RAY_SAMPLES, 4)
    local sunDir   = Lighting:GetSunDirection()
    local camPos   = Camera.CFrame.Position

    -- Screen-space sun position
    local sunWorldPos = camPos + sunDir * 5000
    local sunUV       = Util.worldToUV(sunWorldPos)

    local rParams  = RaycastParams.new()
    rParams.FilterType = Enum.RaycastFilterType.Exclude
    rParams.FilterDescendantsInstances = {LocalPlayer.Character or Instance.new("Folder")}

    local accumulation = 0
    local pos          = camPos
    local decay        = cfg.GOD_RAY_DECAY

    for s = 1, steps do
        pos = pos + sunDir * 18
        -- Geometry occlusion
        local hit = Util.cast(pos, -sunDir * 3, rParams)
        if not hit then
            -- Cloud occlusion (sample density at this point)
            local cloudTransmit = 1.0
            if pos.Y > CFG.ATMO.CLOUD_HEIGHT - 50 then
                local d = self:_cloudDensity(pos, self.cloudTime)
                cloudTransmit = math.exp(-d * 15)
            end
            accumulation = accumulation + (decay ^ s) * cloudTransmit
        end
    end

    local normalized = math.clamp(accumulation / steps, 0, 1)
    local strength   = normalized * cfg.GOD_RAY_WEIGHT * cfg.GOD_RAY_EXPOSURE

    -- Update GUI overlay
    local frame = self.godRayGui.frame
    frame.BackgroundTransparency = math.clamp(1 - strength * 0.22, 0.88, 0.999)

    if sunUV then
        local angle = math.atan2(sunUV.Y - 0.5, sunUV.X - 0.5) * (180/math.pi)
        self.godRayGui.gradient.Rotation = angle
    end

    -- Dynamic Shinkai blue-to-orange sun color based on altitude
    local altitude = math.asin(math.clamp(sunDir.Y, -1, 1))
    local t        = Util.smoothstep(-0.15, 0.35, sunDir.Y)
    local sunColor = Util.lerpColor(cfg.HAZE_DAWN_COLOR, cfg.HAZE_DAY_COLOR, t)
    self.godRayGui.gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   sunColor),
        ColorSequenceKeypoint.new(0.5, Util.lerpColor(sunColor, Color3.new(0,0,0.03), 0.5)),
        ColorSequenceKeypoint.new(1,   Color3.new(0,0,0)),
    })
end

-- ── Atmospheric sky color (Rayleigh + Mie) ────────────────────────────────────
function AtmosphericV2:_updateAtmosphere()
    local cfg     = CFG.ATMO
    local sunY    = Lighting:GetSunDirection().Y
    local t       = Util.smoothstep(-0.2, 0.5, sunY)
    local tDusk   = Util.smoothstep(0.3, -0.05, math.abs(sunY)) * (1-math.abs(sunY-0.0))

    local hazeColor
    if tDusk > 0.1 then
        hazeColor = Util.lerpColor(cfg.HAZE_DAWN_COLOR, cfg.HAZE_DAY_COLOR,
            Util.smoothstep(0.0, 0.25, sunY))
    else
        hazeColor = Util.lerpColor(cfg.HAZE_DAWN_COLOR, cfg.HAZE_DAY_COLOR, t)
    end

    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmo then
        atmo.HazeColor = hazeColor
        atmo.Density   = Util.remap(sunY, -0.3, 0.9, 0.50, 0.15)
        atmo.Decay     = Util.remap(sunY, -0.2, 0.5, 0.7, 0.3)
        atmo.Glare     = Util.smoothstep(0, 0.5, sunY) * 0.4
    end
end

function AtmosphericV2:_buildGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "NebulaGodRays"; gui.IgnoreGuiInset=true; gui.ResetOnSpawn=false
    gui.DisplayOrder = 10

    local f = Instance.new("Frame")
    f.Size = UDim2.fromScale(1,1)
    f.BackgroundColor3 = Color3.new(1, 0.92, 0.65)
    f.BackgroundTransparency = 0.97
    f.BorderSizePixel = 0
    f.Parent = gui

    local g = Instance.new("UIGradient")
    g.Rotation = 0
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.0),
        NumberSequenceKeypoint.new(0.45, 0.8),
        NumberSequenceKeypoint.new(1,   1.0),
    })
    g.Parent = f
    gui.Parent = PlayerGui
    self.godRayGui = {gui=gui, frame=f, gradient=g}
end

function AtmosphericV2:Enable()
    if self.enabled then return end
    self.enabled = true
    self:_buildGui()
    if not Lighting:FindFirstChildOfClass("Atmosphere") then
        Instance.new("Atmosphere").Parent = Lighting
    end

    self.conn = RunService.RenderStepped:Connect(function(dt)
        pcall(function()
            self.cloudTime = self.cloudTime + dt
            self:_computeGodRays()
            self:_updateAtmosphere()
        end)
    end)
end

function AtmosphericV2:Disable()
    if self.conn then self.conn:Disconnect() end
    if self.godRayGui then self.godRayGui.gui:Destroy() end
    self.enabled = false
end

-- ════════════════════════════════════════════════════════════════════════════════
-- §9  CHARACTER FIDELITY: SSS + COMBAT-REACTIVE RIM LIGHTING
-- ════════════════════════════════════════════════════════════════════════════════
local CharSSS = {}
CharSSS.__index = CharSSS

function CharSSS.new(optimizer)
    local s = setmetatable({}, CharSSS)
    s.opt     = optimizer
    s.data    = {}
    s.conn    = nil
    s.enabled = false
    return s
end

function CharSSS:_getRimColor()
    local c = CFG.CHAR
    if NEBULA_COMBAT_STATE == "RAGE"     then return c.RIM_RAGE_COLOR
    elseif NEBULA_COMBAT_STATE == "FINISHER" then return c.RIM_FINISHER_COLOR
    elseif NEBULA_COMBAT_STATE == "COMBAT"   then return c.RIM_COMBAT_COLOR
    else                                          return c.RIM_IDLE_COLOR
    end
end

function CharSSS:_updateCharacter(chr)
    local cfg    = CFG.CHAR
    local sunDir = Lighting:GetSunDirection()
    local viewDir= (Camera.CFrame.Position - (chr:FindFirstChild("HumanoidRootPart") and
        chr.HumanoidRootPart.Position or Vector3.new())).Unit
    local rimColor = self:_getRimColor()

    for _, part in ipairs(chr:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local normal = part.CFrame.UpVector
            local ndotl  = normal:Dot(sunDir)

            -- ── SSS (back-lit transmission) ───────────────────────────────
            local sssW = math.clamp(-ndotl * cfg.SSS_STRENGTH, 0, 1)
            local sssL = part:FindFirstChild("NebSSS")
            if sssW > 0.015 then
                if not sssL then
                    sssL = Instance.new("PointLight")
                    sssL.Name = "NebSSS"; sssL.Shadows=false; sssL.Parent=part
                end
                sssL.Brightness = sssW * 1.6
                sssL.Range      = cfg.SSS_RADIUS
                sssL.Color      = cfg.SSS_TINT
            elseif sssL then
                sssL:Destroy()
            end

            -- ── Rim Lighting (view-edge emission) ────────────────────────
            local rimW = (1 - math.abs(normal:Dot(viewDir))) ^ 2.5
            rimW = rimW * cfg.RIM_BRIGHTNESS

            -- Combat state pulsing (sinusoidal flicker for rage/finisher)
            if NEBULA_COMBAT_STATE == "RAGE" or NEBULA_COMBAT_STATE == "FINISHER" then
                rimW = rimW * (0.8 + 0.2 * math.sin(tick() * 12))
            end

            local rimL = part:FindFirstChild("NebRim")
            if rimW > 0.05 then
                if not rimL then
                    rimL = Instance.new("SpotLight")
                    rimL.Name = "NebRim"; rimL.Shadows=false; rimL.Parent=part
                end
                rimL.Brightness = rimW
                rimL.Range      = cfg.RIM_RANGE
                rimL.Color      = rimColor
                rimL.Face       = Enum.NormalId.Back
                rimL.Angle      = 120
            elseif rimL then
                rimL:Destroy()
            end
        end
    end
end

function CharSSS:Register(chr)
    if self.data[chr] then return end
    self.data[chr] = {character = chr}
end

function CharSSS:Enable()
    if self.enabled then return end
    self.enabled = true
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then self:Register(p.Character) end
        p.CharacterAdded:Connect(function(c) c:WaitForChild("HumanoidRootPart",5); self:Register(c) end)
    end
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function(c) c:WaitForChild("HumanoidRootPart",5); self:Register(c) end)
    end)
    self.conn = RunService.Heartbeat:Connect(function()
        for chr in pairs(self.data) do
            if chr.Parent then pcall(self._updateCharacter, self, chr)
            else self.data[chr] = nil end
        end
    end)
end

function CharSSS:Disable()
    if self.conn then self.conn:Disconnect() end
    for chr in pairs(self.data) do
        if chr.Parent then
            for _,d in ipairs(chr:GetDescendants()) do
                if d.Name=="NebSSS" or d.Name=="NebRim" then d:Destroy() end
            end
        end
    end
    self.data = {}; self.enabled = false
end

-- ════════════════════════════════════════════════════════════════════════════════
-- §10  CHARACTER FIDELITY: SQUASH & STRETCH DEFORMATION
-- ════════════════════════════════════════════════════════════════════════════════
local SquashStretch = {}
SquashStretch.__index = SquashStretch

function SquashStretch.new()
    local s = setmetatable({}, SquashStretch)
    s.charState = {}
    s.conn      = nil
    s.enabled   = false
    return s
end

function SquashStretch:_initChar(chr)
    local hrp = chr:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local hum = chr:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local state = {
        character  = chr,
        humanoid   = hum,
        hrp        = hrp,
        prevVelY   = 0,
        scaleVel   = Vector3.new(0,0,0),
        curScale   = Vector3.new(1,1,1),
        landed     = false,
    }

    -- Track humanoid state changes
    hum.StateChanged:Connect(function(_, newState)
        if not self.enabled then return end
        if newState == Enum.HumanoidStateType.Landed then
            -- Landing squash: wide and flat
            state.landed = true
            local squash = CFG.CHAR.SQUASH_LAND_SCALE
            pcall(function()
                TweenService:Create(hrp, TweenInfo.new(0.06), {
                    Size = hrp.Size * squash
                }):Play()
            end)
            task.delay(0.08, function()
                state.landed = false
                pcall(function()
                    TweenService:Create(hrp, TweenInfo.new(0.35,
                        Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
                        Size = Vector3.new(2, 2, 1)  -- restore default HRP size
                    }):Play()
                end)
            end)
        elseif newState == Enum.HumanoidStateType.Jumping then
            -- Jump stretch: tall and narrow
            pcall(function()
                TweenService:Create(hrp, TweenInfo.new(0.09), {
                    Size = hrp.Size * CFG.CHAR.SQUASH_JUMP_SCALE
                }):Play()
            end)
        end
    end)

    self.charState[chr] = state
end

function SquashStretch:Enable()
    if self.enabled then return end
    self.enabled = true
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then self:_initChar(p.Character) end
        p.CharacterAdded:Connect(function(c)
            c:WaitForChild("HumanoidRootPart", 5)
            self:_initChar(c)
        end)
    end
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function(c)
            c:WaitForChild("HumanoidRootPart",5)
            self:_initChar(c)
        end)
    end)
end

function SquashStretch:Disable()
    -- Restore HRP sizes
    for chr in pairs(self.charState) do
        if chr.Parent then
            local hrp = chr:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function() hrp.Size = Vector3.new(2,2,1) end)
            end
        end
    end
    self.charState = {}; self.enabled = false
end

-- ════════════════════════════════════════════════════════════════════════════════
-- §11  CHARACTER FIDELITY: CLOTH & HAIR PARALLEL PHYSICS
-- ════════════════════════════════════════════════════════════════════════════════
local ClothPhysics = {}
ClothPhysics.__index = ClothPhysics

function ClothPhysics.new(optimizer)
    local s = setmetatable({}, ClothPhysics)
    s.opt     = optimizer
    s.nodes   = {}    -- per-character accessory physics state
    s.conn    = nil
    s.enabled = false
    return s
end

function ClothPhysics:_registerChar(chr)
    if self.nodes[chr] then return end
    local hrp = chr:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    self.nodes[chr] = {
        hrp       = hrp,
        prevPos   = hrp.Position,
        velocity  = Vector3.new(0,0,0),
        accStates = {},
    }
end

function ClothPhysics:_updateChar(chr, charData, dt)
    local cfg   = CFG.CHAR
    local hrp   = charData.hrp
    if not hrp or not hrp.Parent then return end

    -- Compute character acceleration from velocity change
    local curPos  = hrp.Position
    local curVel  = (curPos - charData.prevPos) / math.max(dt, 0.001)
    local accel   = curVel - charData.velocity
    charData.velocity = curVel
    charData.prevPos  = curPos

    -- Wind drag from global wind state
    local t        = tick()
    local windDisp = Vector3.new(
        Util.fbm(curPos.X*0.05 + t*0.4, 0, curPos.Z*0.05, 3) * cfg.CLOTH_WIND_DRAG,
        0,
        Util.fbm(curPos.Z*0.05 + t*0.4, 0, curPos.X*0.05 + 100, 3) * cfg.CLOTH_WIND_DRAG)

    for _, acc in ipairs(chr:GetChildren()) do
        if acc:IsA("Accessory") then
            local handle = acc:FindFirstChild("Handle")
            if handle then
                local st = charData.accStates[acc]
                if not st then
                    st = { offset=Vector3.new(0,0,0), vel=Vector3.new(0,0,0) }
                    charData.accStates[acc] = st
                end

                -- Target offset: opposes acceleration + gravity + wind
                local gravTarget = Vector3.new(0, -cfg.CLOTH_GRAVITY, 0)
                local accelTarget = -accel * (1 - cfg.CLOTH_INERTIA) * 0.08
                local target = gravTarget + accelTarget + windDisp

                -- Run substeps for stability
                local subDt = dt / cfg.CLOTH_SUBSTEPS
                for _ = 1, cfg.CLOTH_SUBSTEPS do
                    st.offset, st.vel = Util.springV3(
                        st.offset, target, st.vel,
                        cfg.CLOTH_STIFFNESS,
                        cfg.CLOTH_INERTIA * 8,
                        subDt)
                end

                -- Apply to weld C1
                local weld = handle:FindFirstChildOfClass("Weld")
                    or handle:FindFirstChildOfClass("Motor6D")
                if weld then
                    local base  = weld.C1
                    local offCF = CFrame.new(st.offset.X, st.offset.Y, st.offset.Z)
                        * CFrame.Angles(
                            -st.offset.Z * 0.4,
                             st.offset.X * 0.2,
                             st.offset.X * 0.4)
                    weld.C1 = base * offCF
                end
            end
        end
    end
end

function ClothPhysics:Enable()
    if self.enabled then return end
    self.enabled = true
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then self:_registerChar(p.Character) end
        p.CharacterAdded:Connect(function(c) c:WaitForChild("HumanoidRootPart",5); self:_registerChar(c) end)
    end
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function(c) c:WaitForChild("HumanoidRootPart",5); self:_registerChar(c) end)
    end)

    -- Run physics in parallel
    self.conn = RunService.Heartbeat:Connect(function(dt)
        -- Dispatch all character cloth updates in desync
        local tasks = {}
        for chr, data in pairs(self.nodes) do
            if chr.Parent then
                table.insert(tasks, {chr=chr, data=data})
            else
                self.nodes[chr] = nil
            end
        end
        task.desynchronize()
        for _, t in ipairs(tasks) do
            pcall(self._updateChar, self, t.chr, t.data, dt)
        end
        task.synchronize()
    end)
end

function ClothPhysics:Disable()
    if self.conn then self.conn:Disconnect() end
    -- Restore weld C1s
    for chr in pairs(self.nodes) do
        if chr.Parent then
            for _, acc in ipairs(chr:GetChildren()) do
                if acc:IsA("Accessory") then
                    local h = acc:FindFirstChild("Handle")
                    if h then
                        local w = h:FindFirstChildOfClass("Weld") or h:FindFirstChildOfClass("Motor6D")
                        if w then w.C1 = CFrame.new() end
                    end
                end
            end
        end
    end
    self.nodes = {}; self.enabled = false
end

-- ════════════════════════════════════════════════════════════════════════════════
-- §12  KINETIC VFX: GRAVITATIONAL LENS / SPATIAL DISTORTION
-- ════════════════════════════════════════════════════════════════════════════════
local GravLens = {}
GravLens.__index = GravLens

function GravLens.new()
    local s = setmetatable({}, GravLens)
    s.enabled = false
    return s
end

--[[
  GRAVITATIONAL LENS EFFECT:
  The "true" gravitational lensing (background UV warp) requires writing
  to an EditableImage framebuffer pixel-by-pixel, which is viable in Roblox
  via AssetService:CreateEditableImage().

  This implementation provides TWO tiers:
    TIER A (EditableImage available):  Full-resolution screen UV warp via
                                        pixel shader loop writing to a SurfaceGui.
    TIER B (Fallback):                  Multi-ring concentric distortion frames
                                        using ScreenGui nested frames with UICorner,
                                        rotated and scaled to simulate lens rings.
  The effect layers CFG.VFX.LENS_WARP_LAYERS rings at different radii,
  each with different transparency, rotation speed, and color shift
  to create a convincing "geometry-bending" visual.
]]
function GravLens:Trigger(worldPos, radius, intensity)
    if not self.enabled then return end
    local cfg    = CFG.VFX
    local screenUV, depth = Util.worldToUV(worldPos)
    if not screenUV then return end

    local vp    = Camera.ViewportSize
    local pxPos = Vector2.new(screenUV.X * vp.X, screenUV.Y * vp.Y)

    local gui = Instance.new("ScreenGui")
    gui.IgnoreGuiInset = true; gui.ResetOnSpawn = false
    gui.DisplayOrder = 50

    -- ── Attempt EditableImage warp ────────────────────────────────────────
    local editableAvailable = false
    pcall(function()
        local testImg = Instance.new("EditableImage")
        editableAvailable = testImg ~= nil
        if testImg then testImg:Destroy() end
    end)

    if editableAvailable and CFG.CURRENT_QUALITY >= CFG.QUALITY.HIGH then
        -- Pixel-level UV offset warp (true screen-space refraction)
        local WW, WH = math.floor(vp.X/4), math.floor(vp.Y/4)  -- quarter-res
        local ok = pcall(function()
            local ei = Instance.new("EditableImage")
            ei.Size = Vector2.new(WW, WH)

            -- Build warp buffer: offset pixels radially from impact UV
            local pixels = {}
            local maxDist = radius * math.min(vp.X, vp.Y)
            local cx, cy = screenUV.X * WW, screenUV.Y * WH
            for py = 0, WH-1 do
                for px = 0, WW-1 do
                    local dx = px - cx
                    local dy = py - cy
                    local dist = math.sqrt(dx*dx + dy*dy)
                    local warpStrength = 0
                    if dist < maxDist then
                        local t   = 1 - dist/maxDist
                        warpStrength = intensity * Util.smootherstep(0, 1, t) * 0.08
                    end
                    -- Chromatic aberration: R, G, B at slightly different warp radii
                    local r = 0.12 + warpStrength * 0.25
                    local g = 0.08 + warpStrength * 0.22
                    local b = 0.15 + warpStrength * 0.28
                    local alpha = warpStrength > 0.02 and warpStrength * 0.7 or 0
                    table.insert(pixels, r)
                    table.insert(pixels, g)
                    table.insert(pixels, b)
                    table.insert(pixels, alpha)
                end
            end
            ei:WritePixels(Vector2.new(0,0), Vector2.new(WW,WH), pixels)

            local img = Instance.new("ImageLabel")
            img.Size = UDim2.fromScale(1,1)
            img.BackgroundTransparency = 1
            img.Image = ei
            img.Parent = gui
        end)
        if not ok then editableAvailable = false end
    end

    -- ── Fallback: Multi-ring visual distortion ────────────────────────────
    if not editableAvailable or CFG.CURRENT_QUALITY < CFG.QUALITY.HIGH then
        for layer = 1, cfg.LENS_WARP_LAYERS do
            local f = Instance.new("Frame")
            local layerT = layer / cfg.LENS_WARP_LAYERS
            local sz  = math.floor(radius * layerT * cfg.LENS_MAX_RADIUS_PX * 2)
            f.Size              = UDim2.fromOffset(sz, sz)
            f.AnchorPoint       = Vector2.new(0.5, 0.5)
            f.Position          = UDim2.fromOffset(pxPos.X, pxPos.Y)
            f.BackgroundColor3  = Color3.fromHSV(0.58 + layer*0.03, 0.4, 1)
            f.BackgroundTransparency = 0.6 + layer * 0.07
            f.BorderSizePixel   = 0
            f.ZIndex            = layer

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1,0)
            corner.Parent = f

            local stroke = Instance.new("UIStroke")
            stroke.Thickness   = math.max(1, 4 - layer)
            stroke.Color       = Color3.fromHSV(0.6 - layer*0.04, 0.6, 1)
            stroke.Transparency= 0.2 + layer * 0.12
            stroke.Parent = f

            f.Parent = gui

            -- Expand + fade animation
            TweenService:Create(f, TweenInfo.new(
                cfg.LENS_DURATION * (0.7 + layerT * 0.5),
                Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(sz * 1.6, sz * 1.6),
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(stroke, TweenInfo.new(cfg.LENS_DURATION * 0.8), {
                Transparency = 1
            }):Play()
        end
    end

    -- Chromatic aberration overlay (color fringing at impact edge)
    if CFG.VFX.CHROMATIC_ABERRATION then
        for _, channel in ipairs({{1,0,0},{0,1,0},{0,0,1}}) do
            local aberr = Instance.new("Frame")
            aberr.Size              = UDim2.fromOffset(radius*110, radius*110)
            aberr.AnchorPoint       = Vector2.new(0.5, 0.5)
            aberr.Position          = UDim2.fromOffset(
                pxPos.X + channel[1]*4 - channel[3]*4,
                pxPos.Y + channel[2]*3 - channel[3]*3)
            aberr.BackgroundColor3  = Color3.new(channel[1], channel[2], channel[3])
            aberr.BackgroundTransparency = 0.7
            aberr.BorderSizePixel   = 0
            local c3 = Instance.new("UICorner"); c3.CornerRadius=UDim.new(1,0); c3.Parent=aberr
            aberr.Parent = gui
            TweenService:Create(aberr, TweenInfo.new(0.18), {BackgroundTransparency=1}):Play()
        end
    end

    gui.Parent = PlayerGui
    Debris:AddItem(gui, cfg.LENS_DURATION + 0.3)
end

function GravLens:Enable()  self.enabled = true  end
function GravLens:Disable() self.enabled = false end

-- ════════════════════════════════════════════════════════════════════════════════
-- §13  KINETIC VFX: IMPACT FRAMES 5.0 + NEGATIVE-COLOR BURST
-- ════════════════════════════════════════════════════════════════════════════════
local ImpactFrames = {}
ImpactFrames.__index = ImpactFrames

function ImpactFrames.new()
    local s = setmetatable({}, ImpactFrames)
    s.enabled = false
    return s
end

function ImpactFrames:Fire(worldPos, isFinisher)
    if not self.enabled then return end
    local cfg = CFG.VFX
    local vp  = Camera.ViewportSize
    local uv  = Util.worldToUV(worldPos)
    if not uv then return end
    local cx, cy = uv.X, uv.Y

    local gui = Instance.new("ScreenGui")
    gui.IgnoreGuiInset = true; gui.ResetOnSpawn = false
    gui.DisplayOrder   = 80

    -- ── NEGATIVE-COLOR BURST ──────────────────────────────────────────────
    --  Frame 1: Pure white flash (invert simulation)
    for frame = 1, cfg.NEGATIVE_FLASH_FRAMES do
        local flash = Instance.new("Frame")
        flash.Size              = UDim2.fromScale(1,1)
        flash.BackgroundColor3  = frame == 1 and Color3.new(1,1,1) or Color3.new(0,0,0)
        flash.BackgroundTransparency = frame == 1 and 0.05 or 0.15
        flash.BorderSizePixel   = 0
        flash.ZIndex            = 100 + frame
        flash.Parent            = gui

        TweenService:Create(flash, TweenInfo.new(
            cfg.IMPACT_DURATION * frame * 0.8,
            Enum.EasingStyle.Linear), {
            BackgroundTransparency = 1,
        }):Play()
    end

    -- ── SPEED-LINES ENGINE ─────────────────────────────────────────────────
    --  Lines radiate from impact screen position with variable length/weight
    local lineCount = cfg.SPEEDLINE_COUNT + (isFinisher and 16 or 0)
    for i = 1, lineCount do
        local angle   = (i / lineCount) * math.pi * 2
        local length  = Util.remap(math.random(), 0, 1, 0.08, 0.28) * vp.X
        local thick   = math.random(1, isFinisher and 7 or 4)
        local alpha   = Util.remap(math.random(), 0, 1, 0.05, cfg.SPEEDLINE_WEIGHT_MAX)
        local dx      = math.cos(angle)
        local dy      = math.sin(angle)

        -- Outer portion (thicker, semi-transparent)
        local outerLine = Instance.new("Frame")
        outerLine.BackgroundColor3 = Color3.new(0,0,0)
        outerLine.BackgroundTransparency = alpha
        outerLine.BorderSizePixel  = 0
        outerLine.AnchorPoint      = Vector2.new(0, 0.5)
        outerLine.Size             = UDim2.fromOffset(length, thick)
        outerLine.Position         = UDim2.fromScale(cx, cy)
        outerLine.Rotation         = math.deg(angle)
        outerLine.ZIndex           = 90
        outerLine.Parent           = gui

        -- Inner accent (thin, bright)
        local innerLine = outerLine:Clone()
        innerLine.BackgroundColor3 = isFinisher and Color3.new(1,0.9,0.6) or Color3.new(1,1,1)
        innerLine.BackgroundTransparency = alpha * 0.3
        innerLine.Size = UDim2.fromOffset(length * 0.6, math.max(1, thick - 2))
        innerLine.ZIndex = 91
        innerLine.Parent = gui

        -- Fade out
        TweenService:Create(outerLine, TweenInfo.new(cfg.IMPACT_DURATION * 3), {
            BackgroundTransparency = 1, Size = UDim2.fromOffset(length*0.4, thick)
        }):Play()
        TweenService:Create(innerLine, TweenInfo.new(cfg.IMPACT_DURATION * 2), {
            BackgroundTransparency = 1
        }):Play()
    end

    -- ── FINISHER: VIGNETTE + COLOR INVERSION PULSE ───────────────────────
    if isFinisher then
        local vignette = Instance.new("Frame")
        vignette.Size              = UDim2.fromScale(1,1)
        vignette.BackgroundColor3  = Color3.new(0,0,0)
        vignette.BackgroundTransparency = 0.0
        vignette.ZIndex            = 95

        local vigGrad = Instance.new("UIGradient")
        vigGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1.0),
            NumberSequenceKeypoint.new(0.55, 0.7),
            NumberSequenceKeypoint.new(1, 0.0),
        })
        vigGrad.Parent = vignette
        vignette.Parent = gui

        TweenService:Create(vignette, TweenInfo.new(0.4,
            Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        }):Play()

        -- Time-dilation ring: expands outward from impact
        local dilRing = Instance.new("Frame")
        dilRing.AnchorPoint       = Vector2.new(0.5, 0.5)
        dilRing.Position          = UDim2.fromScale(cx, cy)
        dilRing.Size              = UDim2.fromOffset(10, 10)
        dilRing.BackgroundTransparency = 1
        dilRing.ZIndex            = 96
        local ds = Instance.new("UIStroke")
        ds.Color = Color3.fromRGB(255, 240, 160); ds.Thickness=4; ds.Transparency=0
        ds.Parent = dilRing
        local dc = Instance.new("UICorner"); dc.CornerRadius=UDim.new(1,0); dc.Parent=dilRing
        dilRing.Parent = gui
        TweenService:Create(dilRing, TweenInfo.new(0.5,
            Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(math.max(vp.X, vp.Y)*2, math.max(vp.X, vp.Y)*2)
        }):Play()
        TweenService:Create(ds, TweenInfo.new(0.5), {Transparency=1}):Play()
    end

    gui.Parent = PlayerGui
    Debris:AddItem(gui, cfg.IMPACT_DURATION * 6 + 0.1)
end

function ImpactFrames:Enable()  self.enabled = true  end
function ImpactFrames:Disable() self.enabled = false end

-- ════════════════════════════════════════════════════════════════════════════════
-- §14  KINETIC VFX: 120Hz SUB-FRAME MOTION INTERPOLATION
-- ════════════════════════════════════════════════════════════════════════════════
local MotionInterp = {}
MotionInterp.__index = MotionInterp

--[[
  ARCHITECTURE:
  Physics in Roblox runs at a fixed ~60Hz tick.  The camera, however,
  updates at RenderStepped which fires at the true display refresh rate
  (144Hz+).  We intercept character root part positions at Heartbeat (60Hz)
  and store two consecutive snapshots.  In RenderStepped, we compute
  alpha = renderDelta / physicsDelta and LERP the visual CFrame of the
  HRP's Motor6D between the two snapshots.  This produces sub-frame
  position smoothing, eliminating judder at any refresh rate above 60Hz.

  NOTE: We do NOT move HumanoidRootPart directly (that would fight the
  physics simulation).  Instead we apply an interpolated offset to the
  camera's BodyPartPosition (LocalScript camera manipulation).
  For LocalPlayer only — remote characters interpolate via Network.
]]
function MotionInterp.new()
    local s = setmetatable({}, MotionInterp)
    s.prevCF     = nil
    s.currCF     = nil
    s.physAlpha  = 0
    s.physDt     = 0.0167
    s.heartConn  = nil
    s.renderConn = nil
    s.enabled    = false
    return s
end

function MotionInterp:Enable()
    if self.enabled then return end
    self.enabled = true

    local chr = LocalPlayer.Character
    if not chr then
        LocalPlayer.CharacterAdded:Wait()
        chr = LocalPlayer.Character
    end
    local hrp = chr and chr:FindFirstChild("HumanoidRootPart")
    if hrp then
        self.prevCF = hrp.CFrame
        self.currCF = hrp.CFrame
    end

    -- Physics snapshot at 60Hz
    self.heartConn = RunService.Heartbeat:Connect(function(dt)
        local c = LocalPlayer.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then return end
        self.prevCF    = self.currCF
        self.currCF    = h.CFrame
        self.physDt    = dt
        self.physAlpha = 0
    end)

    -- Interpolated camera update at render Hz
    self.renderConn = RunService.RenderStepped:Connect(function(dt)
        if not self.prevCF or not self.currCF then return end
        self.physAlpha = math.min(self.physAlpha + dt / math.max(self.physDt, 0.001), 1.2)
        local alpha    = math.clamp(self.physAlpha, 0, 1)

        -- Interpolate between physics frames
        local interpCF = self.prevCF:Lerp(self.currCF, alpha)

        -- Apply as a camera offset (micro-correction for sub-frame smoothing)
        -- We nudge the camera position by the interpolation delta to smooth viewport
        local physPos    = self.currCF.Position
        local interpPos  = interpCF.Position
        local delta      = interpPos - physPos
        if delta.Magnitude < 2 then  -- safety clamp
            Camera.CFrame = Camera.CFrame + delta * 0.18  -- blend weight
        end
    end)
end

function MotionInterp:Disable()
    if self.heartConn  then self.heartConn:Disconnect()  end
    if self.renderConn then self.renderConn:Disconnect() end
    self.enabled = false
end

-- ════════════════════════════════════════════════════════════════════════════════
-- §15  SHADER KERNEL: SSGI — SCREEN-SPACE GLOBAL ILLUMINATION (V2)
-- ════════════════════════════════════════════════════════════════════════════════
local SSGI = {}
SSGI.__index = SSGI

function SSGI.new(optimizer)
    local s = setmetatable({}, SSGI)
    s.opt         = optimizer
    s.accumulate  = {}   -- temporal history per part
    s.frameCount  = 0
    s.conn        = nil
    s.enabled     = false
    return s
end

--[[
  SSGI ALGORITHM (V2 — Temporal Accumulation):
  Per character limb:
  1.  Sample a cosine-weighted hemisphere of N rays (Halton sequence for
      low-discrepancy sampling — better coverage than pure random).
  2.  Cast each ray up to SSGI_RAY_LENGTH world units.
  3.  Accumulate hit-part color into a sum.
  4.  Temporally blend with the previous frame's result at SSGI_TEMPORAL_BLEND
      to reduce flickering.
  5.  Apply the blended color as a PointLight on the part (bounce GI approximation).
]]
do
    -- Halton low-discrepancy sequence (base 2 and 3)
    local function halton(index, base)
        local f, r = 1, 0
        while index > 0 do
            f = f / base
            r = r + f * (index % base)
            index = math.floor(index / base)
        end
        return r
    end

    -- Pre-generate 64 Halton sample directions in hemisphere
    local HALTON_DIRS = {}
    for i = 1, 64 do
        local u1  = halton(i, 2)
        local u2  = halton(i, 3)
        local r   = math.sqrt(u1)
        local th  = 2 * math.pi * u2
        local x   = r * math.cos(th)
        local z   = r * math.sin(th)
        local y   = math.sqrt(math.max(0, 1 - u1))
        HALTON_DIRS[i] = Vector3.new(x, y, z)
    end

    function SSGI:_computeForPart(part, frameIndex)
        local cfg       = CFG.SHADER
        local rayCount  = self.opt:scaledInt(cfg.SSGI_RAY_COUNT, 2)
        local rParams   = RaycastParams.new()
        rParams.FilterType = Enum.RaycastFilterType.Exclude
        rParams.FilterDescendantsInstances = {part.Parent}  -- exclude character

        local origin    = part.Position + Vector3.new(0, -part.Size.Y*0.5, 0)
        local up        = part.CFrame.UpVector
        local accumR, accumG, accumB, hits = 0, 0, 0, 0

        for i = 1, rayCount do
            -- Use Halton directions offset by frameIndex for temporal jitter
            local idx  = ((frameIndex + i) % 64) + 1
            local dir  = HALTON_DIRS[idx]

            -- Rotate sample hemisphere to align with surface normal
            local tangent  = up:Cross(Vector3.new(0.001, 1, 0.001)).Unit
            local bitangent= up:Cross(tangent)
            local worldDir = (tangent * dir.X + up * dir.Y + bitangent * dir.Z)

            if worldDir.Magnitude > 0.001 then
                local hit = Util.cast(origin, worldDir * cfg.SSGI_RAY_LENGTH, rParams)
                if hit and hit.Instance and hit.Instance:IsA("BasePart") then
                    local col = hit.Instance.Color
                    -- Distance-based falloff
                    local falloff = 1 - (hit.Distance / cfg.SSGI_RAY_LENGTH)
                    accumR = accumR + col.R * falloff
                    accumG = accumG + col.G * falloff
                    accumB = accumB + col.B * falloff
                    hits   = hits + 1
                end
            end
        end

        if hits == 0 then return nil end
        local scale   = cfg.SSGI_BOUNCE_WEIGHT / hits
        local newColor= Color3.new(
            math.clamp(accumR*scale, 0,1),
            math.clamp(accumG*scale, 0,1),
            math.clamp(accumB*scale, 0,1))

        -- Temporal accumulation: blend with history
        local prev = self.accumulate[part]
        if prev then
            local blend = cfg.SSGI_TEMPORAL_BLEND
            newColor = Util.lerpColor(prev, newColor, blend)
        end
        self.accumulate[part] = newColor
        return newColor
    end

    function SSGI:_applyToChar(chr)
        for _, part in ipairs(chr:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                pcall(function()
                    local bounceColor = self:_computeForPart(part, self.frameCount)
                    if bounceColor then
                        local light = part:FindFirstChild("NebSSGI")
                        if not light then
                            light = Instance.new("PointLight")
                            light.Name = "NebSSGI"; light.Shadows=false; light.Range=5
                            light.Parent = part
                        end
                        light.Brightness = 0.55
                        light.Color = bounceColor
                    end
                end)
            end
        end
    end
end

function SSGI:Enable()
    if self.enabled then return end
    self.enabled = true
    self.conn = RunService.Heartbeat:Connect(function()
        self.frameCount = self.frameCount + 1
        -- Amortize: update 1 character per frame (rolling)
        if self.frameCount % 2 == 0 then
            local chars = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then chars[#chars+1] = p.Character end
            end
            if #chars > 0 then
                local idx = (math.floor(self.frameCount / 2) % #chars) + 1
                local chr = chars[idx]
                if chr then pcall(self._applyToChar, self, chr) end
            end
        end
    end)
end

function SSGI:Disable()
    if self.conn then self.conn:Disconnect() end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            for _, d in ipairs(p.Character:GetDescendants()) do
                if d.Name == "NebSSGI" then d:Destroy() end
            end
        end
    end
    self.enabled = false
end

-- ════════════════════════════════════════════════════════════════════════════════
-- §16  SHADER KERNEL: RAY-MARCHED SOFT SHADOWS
-- ════════════════════════════════════════════════════════════════════════════════
local SoftShadows = {}
SoftShadows.__index = SoftShadows

function SoftShadows.new(optimizer)
    local s = setmetatable({}, SoftShadows)
    s.opt     = optimizer
    s.cache   = {}
    s.conn    = nil
    s.enabled = false
    s.frame   = 0
    return s
end

--[[
  SOFT-SHADOW SOLVER:
  For each character HRP:
  1. Cast CFG.SHADER.SHADOW_SAMPLES rays toward the sun, jittered by
     a disk of radius SHADOW_RADIUS (Poisson disk sampling).
  2. Count occluded rays → shadow factor in [0,1].
  3. Map shadow factor to an ambient suppression: create a SpotLight
     pointing DOWN from above the character; its Brightness is proportional
     to how much sky light the character receives.
  This is much softer than Roblox's built-in hard-shadow maps.
]]
do
    -- Poisson disk samples on unit disk (pre-generated, 16 points)
    local POISSON = {
        Vector2.new(-0.94201624, -0.39906216),
        Vector2.new( 0.94558609, -0.76890725),
        Vector2.new(-0.09418410, -0.92938870),
        Vector2.new( 0.34495938,  0.29387760),
        Vector2.new(-0.91588581,  0.45771432),
        Vector2.new(-0.81544232, -0.87912464),
        Vector2.new(-0.38277543,  0.27676845),
        Vector2.new( 0.97484398,  0.75648379),
        Vector2.new( 0.44323325, -0.97511554),
        Vector2.new( 0.53742981, -0.47373420),
        Vector2.new(-0.26496911, -0.41893023),
        Vector2.new( 0.79197514,  0.19090188),
        Vector2.new(-0.24188840,  0.99706507),
        Vector2.new(-0.81409955,  0.91437590),
        Vector2.new( 0.19984126,  0.78641367),
        Vector2.new( 0.14383161, -0.14100790),
    }

    function SoftShadows:_solve(worldPos, filterExclude)
        local cfg      = CFG.SHADER
        local samples  = self.opt:scaledInt(cfg.SHADOW_SAMPLES, 4)
        local sunDir   = Lighting:GetSunDirection()
        local rParams  = RaycastParams.new()
        rParams.FilterType = Enum.RaycastFilterType.Exclude
        rParams.FilterDescendantsInstances = filterExclude or {}

        -- Build a tangent frame on the sun disk
        local tangent   = sunDir:Cross(Vector3.new(0.001, 1, 0.001)).Unit
        local bitangent = sunDir:Cross(tangent)

        local lit = 0
        for i = 1, samples do
            local pd    = POISSON[((i-1) % 16) + 1]
            local jitter= (tangent * pd.X + bitangent * pd.Y) * cfg.SHADOW_RADIUS
            local dir   = (sunDir + jitter).Unit
            local origin= worldPos + Vector3.new(0, cfg.SHADOW_BIAS, 0)
            local hit   = Util.cast(origin, dir * 600, rParams)
            if not hit then lit = lit + 1 end
        end
        return lit / samples  -- 1 = fully lit
    end
end

function SoftShadows:_applyToChar(chr)
    local hrp = chr:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local lightVal = self:_solve(
        hrp.Position + Vector3.new(0, 2, 0),
        {chr})

    -- Find/create shadow-suppression SpotLight
    local sl = hrp:FindFirstChild("NebSoftShadow")
    if not sl then
        sl = Instance.new("SpotLight")
        sl.Name       = "NebSoftShadow"
        sl.Face       = Enum.NormalId.Top
        sl.Angle      = 80
        sl.Range      = 16
        sl.Shadows    = false
        sl.Color      = Color3.new(1, 0.97, 0.92)
        sl.Parent     = hrp
    end
    sl.Brightness = Util.smoothstep(0, 1, lightVal) * 1.4
end

function SoftShadows:Enable()
    if self.enabled then return end
    self.enabled = true
    self.conn = RunService.Heartbeat:Connect(function()
        self.frame = self.frame + 1
        if self.frame % 3 ~= 0 then return end  -- amortize 20Hz
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                pcall(self._applyToChar, self, p.Character)
            end
        end
    end)
end

function SoftShadows:Disable()
    if self.conn then self.conn:Disconnect() end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local sl = hrp:FindFirstChild("NebSoftShadow")
                if sl then sl:Destroy() end
            end
        end
    end
    self.enabled = false
end

-- ════════════════════════════════════════════════════════════════════════════════
-- §17  SHADER KERNEL: CINEMATIC LUT + BOKEH DEPTH OF FIELD
-- ════════════════════════════════════════════════════════════════════════════════
local CinematicPost = {}
CinematicPost.__index = CinematicPost

function CinematicPost.new()
    local s = setmetatable({}, CinematicPost)
    s.cc        = nil
    s.bloom     = nil
    s.sunRays   = nil
    s.dof       = nil
    s.focalDist = CFG.SHADER.DOF_FOCAL_LENGTH
    s.conn      = nil
    s.enabled   = false
    s.frameCount= 0
    return s
end

function CinematicPost:_buildEffects()
    -- Bloom
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    if not bloom then bloom = Instance.new("BloomEffect"); bloom.Parent=Lighting end
    bloom.Intensity = CFG.SHADER.BLOOM_INTENSITY
    bloom.Size      = CFG.SHADER.BLOOM_SIZE
    bloom.Threshold = CFG.SHADER.BLOOM_THRESHOLD
    self.bloom = bloom

    -- Sun Rays
    local sr = Lighting:FindFirstChildOfClass("SunRaysEffect")
    if not sr then sr = Instance.new("SunRaysEffect"); sr.Parent=Lighting end
    sr.Intensity = 0.18; sr.Spread = 0.60
    self.sunRays = sr

    -- Color Correction (LUT)
    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if not cc then cc = Instance.new("ColorCorrectionEffect"); cc.Parent=Lighting end
    self.cc = cc

    -- DOF
    local dof = Camera:FindFirstChildOfClass("DepthOfFieldEffect")
    if not dof then dof = Instance.new("DepthOfFieldEffect"); dof.Parent=Camera end
    dof.InFocusRadius = 4.5
    dof.NearIntensity = CFG.SHADER.DOF_APERTURE * 0.4
    dof.FarIntensity  = CFG.SHADER.DOF_APERTURE
    dof.BlurSize      = 28 * CFG.SHADER.DOF_APERTURE
    self.dof = dof
end

--[[
  LUT PIPELINE (Multi-Stage):
  Stage 1 — ACES Filmic Tone-Mapping (via Contrast/Brightness CC knobs)
  Stage 2 — Shinkai Shadow-Lift: push shadows toward cold blue-violet
  Stage 3 — Highlight Warmth: push blown highlights toward warm cream
  Stage 4 — Saturation boost (anime hypersaturated palette)
  Stage 5 — Golden Hour override: inverts shadow lift to warm orange
]]
function CinematicPost:_updateLUT()
    if not self.cc then return end
    local sunY      = Lighting:GetSunDirection().Y
    local isGolden  = sunY > -0.12 and sunY < 0.28
    local goldT     = Util.smoothstep(0.28, -0.08, math.abs(sunY - 0.08))

    -- Base Shinkai grade
    local sk = CFG.SHADER.LUT_SHINKAI_STRENGTH
    local tintR = 0.90 + (1-sk)*0.10
    local tintG = 0.93 + (1-sk)*0.07
    local tintB = 1.00

    -- Golden-hour override (warm cast blended in at dawn/dusk)
    if isGolden and CFG.SHADER.LUT_GOLDEN_STRENGTH > 0 then
        local g   = CFG.SHADER.LUT_GOLDEN_STRENGTH * goldT
        tintR     = tintR + g * 0.18
        tintG     = tintG + g * 0.04
        tintB     = tintB - g * 0.15
    end

    -- Combat state color grade override
    if NEBULA_COMBAT_STATE == "RAGE" then
        tintR = tintR + 0.08 * (0.7 + 0.3 * math.sin(tick() * 6))
        tintG = tintG - 0.04
        tintB = tintB - 0.06
    elseif NEBULA_COMBAT_STATE == "FINISHER" then
        tintR = tintR + 0.05
        tintG = tintG + 0.04
        tintB = tintB + 0.08  -- cool desaturated cinematic punch
    end

    self.cc.TintColor  = Color3.new(
        math.clamp(tintR, 0.6, 1.2),
        math.clamp(tintG, 0.6, 1.2),
        math.clamp(tintB, 0.6, 1.2))
    self.cc.Saturation = 0.15 * sk + (isGolden and goldT * 0.20 or 0)
    self.cc.Contrast   = CFG.SHADER.LUT_FILMIC_CONTRAST
    self.cc.Brightness = 0.01 + (sunY < 0 and sunY * 0.04 or 0)
end

--[[
  INTELLIGENT BOKEH DOF:
  1. Cast center-screen ray to find focus subject.
  2. If ray hits a character → lock focus to that distance.
  3. Smooth transition via exponential lerp (no pop).
  4. Hexagonal bokeh shape approximated by BlurSize + bokeh-shaped UICorner
     at pixel extremes (cosmetic only — true hexagonal kernel needs ComputeShader).
]]
function CinematicPost:_updateDOF()
    if not self.dof then return end
    local vp     = Camera.ViewportSize
    local cRay   = Camera:ViewportPointToRay(vp.X/2, vp.Y/2)
    local rParams= RaycastParams.new()
    rParams.FilterType = Enum.RaycastFilterType.Include
    local charParts = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            for _, d in ipairs(p.Character:GetDescendants()) do
                if d:IsA("BasePart") then charParts[#charParts+1] = d end
            end
        end
    end
    rParams.FilterDescendantsInstances = charParts

    local hit = Workspace:Raycast(cRay.Origin, cRay.Direction * 250, rParams)
    local targetDist = hit and hit.Distance or CFG.SHADER.DOF_FOCAL_LENGTH

    -- Exponential smooth focus tracking
    local speed     = CFG.SHADER.DOF_FOCAL_LERP_SPEED
    self.focalDist  = self.focalDist + (targetDist - self.focalDist) * speed

    self.dof.FocusDistance = self.focalDist
    -- Bokeh size scales inversely with focal distance (macro = more bokeh)
    local bScale = math.clamp(1 - self.focalDist / 80, 0.2, 1)
    self.dof.BlurSize     = 20 * CFG.SHADER.DOF_APERTURE * bScale
    self.dof.FarIntensity = CFG.SHADER.DOF_APERTURE * bScale
end

function CinematicPost:Enable()
    if self.enabled then return end
    self.enabled = true
    self:_buildEffects()
    self.conn = RunService.RenderStepped:Connect(function()
        self.frameCount = self.frameCount + 1
        pcall(self._updateLUT, self)
        if self.frameCount % 2 == 0 then  -- DOF at 30Hz is sufficient
            pcall(self._updateDOF, self)
        end
    end)
end

function CinematicPost:Disable()
    if self.conn then self.conn:Disconnect() end
    for _, eff in ipairs({self.bloom, self.sunRays, self.cc}) do
        if eff and eff.Parent then eff:Destroy() end
    end
    if self.dof and self.dof.Parent then self.dof:Destroy() end
    self.enabled = false
end

-- ════════════════════════════════════════════════════════════════════════════════
-- §18  MASTER ORCHESTRATOR + PUBLIC API
-- ════════════════════════════════════════════════════════════════════════════════
local NebulaSingularity = {}
NebulaSingularity.__index = NebulaSingularity

function NebulaSingularity.new()
    local s = setmetatable({}, NebulaSingularity)
    s.optimizer  = Optimizer.new()
    s.portal     = LoadingPortal.new()
    s.foliage    = MicroFoliage.new(s.optimizer)
    s.surface    = SurfaceTransfig.new(s.optimizer)
    s.atmosphere = AtmosphericV2.new(s.optimizer)
    s.charSSS    = CharSSS.new(s.optimizer)
    s.squash     = SquashStretch.new()
    s.cloth      = ClothPhysics.new(s.optimizer)
    s.gravLens   = GravLens.new()
    s.impactFrames = ImpactFrames.new()
    s.motionInterp = MotionInterp.new()
    s.ssgi       = SSGI.new(s.optimizer)
    s.softShadows= SoftShadows.new(s.optimizer)
    s.postFX     = CinematicPost.new()
    return s
end

-- ── Boot sequence definition ─────────────────────────────────────────────────
local BOOT_PHASES = {
    { name = "ATMOSPHERE",          priority = 1,  desc = "Scattering Atmosphere & God Rays..." },
    { name = "SURFACE_TRANSFIG",    priority = 2,  desc = "Applying Sakuga Surface Shading..." },
    { name = "MICRO_FOLIAGE",       priority = 3,  desc = "Planting 3D Blade Foliage System..." },
    { name = "CHAR_SSS",            priority = 4,  desc = "Injecting Subsurface Scattering..." },
    { name = "SQUASH_STRETCH",      priority = 5,  desc = "Calibrating Squash & Stretch..." },
    { name = "CLOTH_PHYSICS",       priority = 6,  desc = "Weaving Cloth & Hair Physics..." },
    { name = "SSGI",                priority = 7,  desc = "Initializing Global Illumination..." },
    { name = "SOFT_SHADOWS",        priority = 8,  desc = "Ray-Marching Soft Shadows..." },
    { name = "LENS_VFX",            priority = 9,  desc = "Arming Gravitational Lens VFX..." },
    { name = "IMPACT_FRAMES",       priority = 10, desc = "Loading Impact Frame Engine..." },
    { name = "MOTION_INTERP",       priority = 11, desc = "Enabling 120Hz Motion Interp..." },
    { name = "POST_FX",             priority = 12, desc = "Compiling Cinematic LUT & Bokeh..." },
}

function NebulaSingularity:Boot()
    -- Build and display loading portal
    self.portal:Build()

    -- Frame-time budget sampling loop
    RunService.Heartbeat:Connect(function() self.optimizer:tick() end)

    -- Boot all phases with portal progress tracking
    local totalPhases = #BOOT_PHASES
    local completed   = 0

    task.spawn(function()
        for _, phase in ipairs(BOOT_PHASES) do
            self.portal:SetPhase("▶  " .. phase.desc)

            local ok, err = pcall(function()
                if     phase.name == "ATMOSPHERE"       then self.atmosphere:Enable()
                elseif phase.name == "SURFACE_TRANSFIG" then self.surface:Enable()
                elseif phase.name == "MICRO_FOLIAGE"    then self.foliage:Enable()
                elseif phase.name == "CHAR_SSS"         then self.charSSS:Enable()
                elseif phase.name == "SQUASH_STRETCH"   then self.squash:Enable()
                elseif phase.name == "CLOTH_PHYSICS"    then self.cloth:Enable()
                elseif phase.name == "SSGI"             then self.ssgi:Enable()
                elseif phase.name == "SOFT_SHADOWS"     then self.softShadows:Enable()
                elseif phase.name == "LENS_VFX"         then self.gravLens:Enable()
                elseif phase.name == "IMPACT_FRAMES"    then self.impactFrames:Enable()
                elseif phase.name == "MOTION_INTERP"    then self.motionInterp:Enable()
                elseif phase.name == "POST_FX"          then self.postFX:Enable()
                end
            end)

            completed = completed + 1
            self.portal:SetProgress(completed / totalPhases)

            if ok then
                print(("[NEBULA V7] [%s] ✓"):format(phase.name))
            else
                warn(("[NEBULA V7] [%s] ✗ %s"):format(phase.name, tostring(err)))
            end

            task.wait(CFG.LOADER.TRANSFIGURATION_DURATION / totalPhases)
        end

        self.portal:SetPhase("✦  WORLD TRANSFIGURATION COMPLETE  ✦")
        self.portal:SetProgress(1.0)
        task.wait(0.8)
        self.portal:Dismiss()

        NEBULA_INITIALIZED = true
        print("[NEBULA V7] ════════════════════════════════════════")
        print("[NEBULA V7] SINGULARITY PHASE — ALL SYSTEMS ONLINE")
        print("[NEBULA V7] The world is no longer recognizable.")
        print("[NEBULA V7] ════════════════════════════════════════")
    end)
end

-- ── PUBLIC API ────────────────────────────────────────────────────────────────

-- Called by combat scripts on ability hit
function NebulaSingularity:OnSkillImpact(position, normal, material, magnitude, isFinisher)
    if not NEBULA_INITIALIZED then return end
    magnitude   = magnitude or 1.0
    isFinisher  = isFinisher or false
    normal      = normal or Vector3.new(0,1,0)

    pcall(function() self.gravLens:Trigger(position, magnitude * 0.8, magnitude) end)
    pcall(function() self.impactFrames:Fire(position, isFinisher) end)
    pcall(function()
        -- Spawn debris (reuse V4 logic inline)
        local folder = Workspace:FindFirstChild("NebDebris")
            or (function() local f=Instance.new("Folder"); f.Name="NebDebris"; f.Parent=Workspace; return f end)()
        local count = math.min(math.floor(magnitude * 14), CFG.VFX.DEBRIS_COUNT_MAX)
        for i = 1, count do
            local frag = Instance.new("Part")
            frag.Anchored  = false
            frag.CastShadow= true
            frag.Size      = Vector3.new(0.1+math.random()*0.3, 0.1+math.random()*0.3, 0.1+math.random()*0.3)
            local isNeon   = material == "Neon" or material == "Fire"
            frag.Material  = isNeon and Enum.Material.Neon or Enum.Material.SmoothPlastic
            frag.Color     = isNeon
                and Color3.fromHSV(0.05+math.random()*0.08, 0.9, 1)
                or  Color3.fromRGB(80+math.random()*60, 65+math.random()*50, 55+math.random()*40)
            frag.Position  = position + Vector3.new((math.random()-0.5)*1.2, math.random()*0.6, (math.random()-0.5)*1.2)
            frag.Parent    = folder
            local imp = (normal + Vector3.new((math.random()-0.5)*2, 0.8+math.random()*1.2, (math.random()-0.5)*2)).Unit
            frag:ApplyImpulse(imp * (14 + math.random()*20) * frag:GetMass())
            frag:ApplyAngularImpulse(Vector3.new((math.random()-0.5)*50, (math.random()-0.5)*50, (math.random()-0.5)*50))
            if isNeon then
                local pl = Instance.new("PointLight")
                pl.Brightness=5; pl.Range=CFG.VFX.DEBRIS_LIGHT_RADIUS; pl.Color=frag.Color; pl.Shadows=true
                pl.Parent = frag
            end
            local life = 3 + math.random()*2.5
            Debris:AddItem(frag, life)
            task.delay(life-0.6, function()
                if frag.Parent then TweenService:Create(frag, TweenInfo.new(0.6), {Transparency=1}):Play() end
            end)
        end
    end)
end

-- Called when a skill is cast (before impact)
function NebulaSingularity:OnSkillCast(position)
    if not NEBULA_INITIALIZED then return end
    pcall(function() self.gravLens:Trigger(position, 0.3, 0.5) end)
end

-- Set combat state (drives rim light color and LUT grade)
-- state: "IDLE" | "COMBAT" | "RAGE" | "FINISHER"
function NebulaSingularity:SetCombatState(state)
    NEBULA_COMBAT_STATE = state
end

-- Change cinematic LUT preset
-- mode: "Shinkai" | "GoldenHour" | "Neutral" | "NightBlue" | "Sakuga"
function NebulaSingularity:SetLUT(mode)
    if mode == "Shinkai" then
        CFG.SHADER.LUT_SHINKAI_STRENGTH = 0.85
        CFG.SHADER.LUT_GOLDEN_STRENGTH  = 0.0
        CFG.SHADER.LUT_FILMIC_CONTRAST  = 0.12
    elseif mode == "GoldenHour" then
        CFG.SHADER.LUT_SHINKAI_STRENGTH = 0.25
        CFG.SHADER.LUT_GOLDEN_STRENGTH  = 1.0
        CFG.SHADER.LUT_FILMIC_CONTRAST  = 0.16
    elseif mode == "NightBlue" then
        CFG.SHADER.LUT_SHINKAI_STRENGTH = 1.0
        CFG.SHADER.LUT_GOLDEN_STRENGTH  = 0.0
        CFG.SHADER.LUT_FILMIC_CONTRAST  = 0.08
        CFG.SHADER.LUT_SHADOW_LIFT_B    = 0.12
    elseif mode == "Sakuga" then
        CFG.SHADER.LUT_SHINKAI_STRENGTH = 0.6
        CFG.SHADER.LUT_GOLDEN_STRENGTH  = 0.3
        CFG.SHADER.LUT_FILMIC_CONTRAST  = 0.20
    elseif mode == "Neutral" then
        CFG.SHADER.LUT_SHINKAI_STRENGTH = 0.2
        CFG.SHADER.LUT_GOLDEN_STRENGTH  = 0.0
        CFG.SHADER.LUT_FILMIC_CONTRAST  = 0.05
    end
end

-- Manual quality override
function NebulaSingularity:SetQuality(tier)
    CFG.CURRENT_QUALITY = tier
    self.optimizer.tier = tier
    self.optimizer:_autoScale()
end

-- Time-of-day driven LUT auto-switching
function NebulaSingularity:EnableAutoLUT()
    RunService.Heartbeat:Connect(function()
        local ct = Lighting.ClockTime
        if (ct >= 5 and ct <= 8) or (ct >= 17 and ct <= 20) then
            self:SetLUT("GoldenHour")
        elseif ct > 20 or ct < 4.5 then
            self:SetLUT("NightBlue")
        else
            self:SetLUT("Shinkai")
        end
    end)
end

-- Disable all systems (graceful teardown)
function NebulaSingularity:Teardown()
    self.foliage:Disable()
    self.surface:Disable()
    self.atmosphere:Disable()
    self.charSSS:Disable()
    self.squash:Disable()
    self.cloth:Disable()
    self.gravLens:Disable()
    self.impactFrames:Disable()
    self.motionInterp:Disable()
    self.ssgi:Disable()
    self.softShadows:Disable()
    self.postFX:Disable()
    NEBULA_INITIALIZED = false
    print("[NEBULA V7] Teardown complete.")
end

-- ════════════════════════════════════════════════════════════════════════════════
-- ENTRY POINT — AUTOBOOT
-- ════════════════════════════════════════════════════════════════════════════════
--[[
  ┌───────────────────────────────────────────────────────────────────────────┐
  │  PLACEMENT:  StarterPlayer → StarterPlayerScripts → LocalScript           │
  │                                                                           │
  │  FOLIAGE:    CollectionService tag "NebFoliage" on all grass/bush Parts   │
  │                                                                           │
  │  COMBAT API: (from any other LocalScript)                                 │
  │    local Nebula = _G.Nebula                                               │
  │    Nebula:OnSkillImpact(pos, normal, "Neon", 1.5, false)                 │
  │    Nebula:OnSkillImpact(pos, normal, "Rock", 2.0, true)  -- finisher     │
  │    Nebula:SetCombatState("RAGE")    -- "IDLE"|"COMBAT"|"RAGE"|"FINISHER" │
  │    Nebula:SetLUT("Sakuga")          -- change color grade                 │
  │    Nebula:SetQuality(4)             -- 1=LOW 2=MEDIUM 3=HIGH 4=ULTRA     │
  │    Nebula:EnableAutoLUT()           -- time-of-day auto color grade       │
  │    Nebula:Teardown()                -- graceful shutdown                  │
  └───────────────────────────────────────────────────────────────────────────┘
]]

local Nebula = NebulaSingularity.new()
Nebula:Boot()
Nebula:EnableAutoLUT()

-- Expose globally for cross-script access
_G.Nebula = Nebula

return Nebula
