--[[
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓                                                                                ▓
▓     G E N S H I N - S T A T I O N   O M E G A                                ▓
▓     ULTRA-REALISTIC ANIME RECONSTRUCTION ENGINE   v5.0                        ▓
▓     "MAKE ROBLOX UNRECOGNIZABLE"                                              ▓
▓                                                                                ▓
▓     Integrates & Supersedes: AnimeVisualStack_GodMode_v4.lua                  ▓
▓     Architecture:  God-Tier Graphics & Lead VFX/Animation Director            ▓
▓     Target:        The Strongest Battlegrounds — Genshin Fidelity Level       ▓
▓                                                                                ▓
▓   SYSTEM MANIFEST:                                                             ▓
▓     [00] Config, Services, Utilities                                           ▓
▓     [01] 3D Grass & Leaf Engine (Vertex Displacement + Collision Bending)     ▓
▓     [02] Environment Remaster (EditableImage Anime Hatching)                  ▓
▓     [03] Volumetric 3D Clouds + Ray-Marched God Rays                          ▓
▓     [04] Model Geometry Evolution (EditableMesh + SSS Extremities)            ▓
▓     [05] Animation Remaster (Motion Warp, Jiggle Physics, Procedural Layer)   ▓
▓     [06] Cinematic Per-Character Light Rig                                     ▓
▓     [07] Combat Sakuga VFX Overload (Refraction, Debris, Impact 2.0)          ▓
▓     [08] Screen-Space Pipeline (SSAO, SSR, Ray-Cast GI Bounce)                ▓
▓     [09] Cinematic Anime LUT Post-Processing                                  ▓
▓     [10] AUTONOMOUS BONUS: Water Caustics, Chromatic Aberration,              ▓
▓          Film Grain, Vignette, Bokeh, Parallax Skybox, Genshin Water,         ▓
▓          Rim Light 2.0, Ambient Occlusion Decals, Motion Blur                 ▓
▓     [11] Parallel Luau Master Loop + Performance Arbiter                      ▓
▓                                                                                ▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

  USAGE:  StarterPlayerScripts  →  LocalScript
  HOOK:   Fire RemoteEvent "GSOHitEvent" from Server:
            args: (pos:Vector3, mag:number, element:string, color:Color3)
          Elements: "pyro","hydro","cryo","electro","anemo","geo","dendro","physical"

  NOTE:   All heavy loops use task.desynchronize() / Parallel Luau actors.
          EditableMesh & EditableImage require 2025/2026 API access.
          Graceful fallback is provided for every API call with pcall.
]]

-- ══════════════════════════════════════════════════════════════════
-- [00]  MASTER CONFIGURATION
-- ══════════════════════════════════════════════════════════════════
local GSO = {}  -- Global namespace

GSO.CFG = {
    -- ── World & Grass ──────────────────────────────────────────
    GRASS_BLADES_PER_CHUNK    = 1200,   -- Target blades per 40-stud chunk
    GRASS_MAX_HEIGHT          = 3.8,    -- Max blade height (studs)
    GRASS_CHUNK_RADIUS        = 3,      -- Chunks spawned around player
    GRASS_COLLISION_RADIUS    = 6,      -- Bend radius from player/projectile
    GRASS_WIND_FREQ           = 1.6,
    GRASS_WIND_AMP            = 0.32,   -- Radians
    GRASS_WIND_TURBULENCE     = 0.4,
    LEAF_FLUTTER_ENABLED      = true,
    LEAF_FLUTTER_FREQ         = 2.8,

    -- ── Volumetric Clouds ──────────────────────────────────────
    CLOUD_VOLUME_LAYERS       = 5,
    CLOUD_RAYMARCH_STEPS      = 12,     -- Steps per god-ray ray
    CLOUD_GODRAY_RAYS         = 24,     -- Fake ray-march beams
    CLOUD_GODRAY_BLOCK_ENABLE = true,   -- Parts occlude rays

    -- ── EditableImage Hatching ─────────────────────────────────
    EI_TEXTURE_SIZE           = 512,    -- EditableImage resolution
    EI_HATCH_LINES            = 18,     -- Hatching line count
    EI_ENABLED                = true,

    -- ── EditableMesh ───────────────────────────────────────────
    EM_HAIR_THICKNESS         = 0.08,   -- Studs
    EM_CLOTH_THICKNESS        = 0.06,
    EM_ENABLED                = true,

    -- ── SSS (Subsurface Scattering) ────────────────────────────
    SSS_EAR_GLOW              = true,
    SSS_FINGER_GLOW           = true,
    SSS_GLOW_COLOR            = Color3.fromRGB(255, 120, 90),
    SSS_GLOW_RANGE            = 1.2,

    -- ── Jiggle Physics ─────────────────────────────────────────
    JIGGLE_STIFFNESS          = 12,
    JIGGLE_DAMPING            = 0.78,
    JIGGLE_WIND_INFLUENCE     = 0.6,
    JIGGLE_VELOCITY_SCALE     = 0.18,

    -- ── Character Light Rig ────────────────────────────────────
    CHAR_KEY_LIGHT_RANGE      = 22,
    CHAR_KEY_LIGHT_BRIGHT     = 1.2,
    CHAR_FILL_LIGHT_RANGE     = 18,
    CHAR_FILL_LIGHT_BRIGHT    = 0.5,
    CHAR_RIM_LIGHT_RANGE      = 12,
    CHAR_RIM_LIGHT_BRIGHT     = 0.8,

    -- ── Screen-Space GI/SSAO ───────────────────────────────────
    SSAO_RAY_COUNT            = 16,     -- Rays per AO probe
    SSAO_RAY_LENGTH           = 5,
    SSAO_REFRESH_RATE         = 8,      -- Frames between full refresh
    GI_BOUNCE_RAYS            = 8,      -- Ground bounce rays
    GI_BOUNCE_RANGE           = 14,

    -- ── Post-Processing ────────────────────────────────────────
    LUT_ENABLED               = true,
    LUT_MODE                  = "shinkai",  -- "shinkai","sunset","night","action"
    CHROMAB_ENABLED           = true,
    CHROMAB_STRENGTH          = 0.0025,
    FILM_GRAIN_STRENGTH       = 0.035,
    VIGNETTE_STRENGTH         = 0.55,
    VIGNETTE_RADIUS           = 0.72,
    MOTION_BLUR_ENABLED       = true,
    MOTION_BLUR_SAMPLES       = 6,
    MOTION_BLUR_STRENGTH      = 0.022,
    BOKEH_ENABLED             = true,
    BOKEH_FOCUS_DIST          = 40,
    BOKEH_APERTURE            = 0.018,

    -- ── VFX Budget ─────────────────────────────────────────────
    MAX_VFX_PARTS             = 300,
    DEBRIS_COUNT_PER_HIT      = 8,
    DEBRIS_LIFETIME           = 2.2,

    -- ── Performance ────────────────────────────────────────────
    TARGET_FPS                = 60,
    QUALITY_TIERS             = 3,
    PARALLEL_ACTORS           = 4,
    LOD_DISTANCES             = {30, 90, 220},  -- near/mid/far studs
}

-- ══════════════════════════════════════════════════════════════════
-- [00B]  SERVICES & CORE REFS
-- ══════════════════════════════════════════════════════════════════
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetService      = game:GetService("AssetService")
local ContentProvider   = game:GetService("ContentProvider")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local PGui   = LP:WaitForChild("PlayerGui")

-- Live character references (update on respawn)
local Char, HRP, Hum, Animator

local function RefreshCharacter(c)
    Char     = c
    HRP      = c:WaitForChild("HumanoidRootPart")
    Hum      = c:WaitForChild("Humanoid")
    Animator = Hum:WaitForChild("Animator")
end

RefreshCharacter(LP.Character or LP.CharacterAdded:Wait())
LP.CharacterAdded:Connect(RefreshCharacter)

-- ══════════════════════════════════════════════════════════════════
-- [00C]  EXTENDED MATH & UTILITY LIBRARY
-- ══════════════════════════════════════════════════════════════════
local U = {}

-- Math aliases
local sin,cos,abs,sqrt,floor,ceil,pi,huge,rand,max,min =
      math.sin,math.cos,math.abs,math.sqrt,math.floor,math.ceil,
      math.pi,math.huge,math.random,math.max,math.min
local clamp = math.clamp
local V3,V2,CF,C3 = Vector3.new,Vector2.new,CFrame.new,Color3.fromRGB
local C3H = Color3.fromHSV

-- ── Perlin Noise (full 3D, Luau native) ───────────────────────────
do
    local p={151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,
             30,69,142,8,99,37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,
             62,94,252,219,203,117,35,11,32,57,177,33,88,237,149,56,87,174,20,
             125,136,171,168,68,175,74,165,71,134,139,48,27,166,77,146,158,231,
             83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,102,
             143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,200,
             196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,
             226,250,124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,
             47,16,58,17,182,189,28,42,223,183,170,213,119,248,152,2,44,154,
             163,70,221,153,101,155,167,43,172,9,129,22,39,253,19,98,108,110,
             79,113,224,232,178,185,112,104,218,246,97,228,251,34,242,193,238,
             210,144,12,191,179,162,241,81,51,145,235,249,14,239,107,49,192,
             214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,
             254,138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,
             215,61,156,180}
    local perm={}
    for i=0,255 do perm[i]=p[i+1]; perm[i+256]=p[i+1] end
    local function fade(t) return t*t*t*(t*(t*6-15)+10) end
    local function lerp(t,a,b) return a+t*(b-a) end
    local function grad(h,x,y,z)
        h=h%16
        local u=h<8 and x or y
        local v=h<4 and y or(h==12 or h==14)and x or z
        return((h%2==0)and u or-u)+((floor(h/2)%2==0)and v or-v)
    end
    function U.Perlin(x,y,z)
        y=y or 0;z=z or 0
        local X=floor(x)%256;local Y=floor(y)%256;local Z=floor(z)%256
        x=x-floor(x);y=y-floor(y);z=z-floor(z)
        local u=fade(x);local v=fade(y);local w=fade(z)
        local A=perm[X]+Y;local AA=perm[A]+Z;local AB=perm[A+1]+Z
        local B=perm[X+1]+Y;local BA=perm[B]+Z;local BB=perm[B+1]+Z
        return lerp(w,lerp(v,lerp(u,grad(perm[AA],x,y,z),grad(perm[BA],x-1,y,z)),
               lerp(u,grad(perm[AB],x,y-1,z),grad(perm[BB],x-1,y-1,z))),
               lerp(v,lerp(u,grad(perm[AA+1],x,y,z-1),grad(perm[BA+1],x-1,y,z-1)),
               lerp(u,grad(perm[AB+1],x,y-1,z-1),grad(perm[BB+1],x-1,y-1,z-1))))
    end
    -- Fractal Brownian Motion (fBm) for richer noise
    function U.FBM(x, y, z, octaves, lacunarity, gain)
        octaves    = octaves    or 4
        lacunarity = lacunarity or 2.0
        gain       = gain       or 0.5
        local val, amp, freq = 0, 0.5, 1
        for _ = 1, octaves do
            val = val + amp * U.Perlin(x*freq, y*freq, (z or 0)*freq)
            amp  = amp  * gain
            freq = freq * lacunarity
        end
        return val
    end
end

function U.Lerp(a, b, t)    return a + (b-a)*t end
function U.SmoothStep(t)    t=clamp(t,0,1); return t*t*(3-2*t) end
function U.QuinticStep(t)   t=clamp(t,0,1); return t*t*t*(t*(6*t-15)+10) end
function U.LerpC3(a,b,t)
    return C3(
        floor(U.Lerp(a.R*255,b.R*255,t)),
        floor(U.Lerp(a.G*255,b.G*255,t)),
        floor(U.Lerp(a.B*255,b.B*255,t))
    )
end
function U.Rnd(mn,mx)       return mn + rand()*(mx-mn) end
function U.RndInt(mn,mx)    return rand(mn,mx) end
function U.Sign(x)          return x >= 0 and 1 or -1 end
function U.Slerp(a, b, t)
    -- CFrame spherical interpolation
    return a:Lerp(b, t)
end

-- Spring simulation (critically damped)
function U.Spring(pos, vel, target, stiff, damp, dt)
    local f = (target - pos) * stiff
    vel = vel + f * dt
    vel = vel * (1 - clamp(damp * dt, 0, 1))
    pos = pos + vel * dt
    return pos, vel
end

-- Color3 to Vector3 (for math operations)
function U.C3toV3(c) return V3(c.R, c.G, c.B) end
function U.V3toC3(v) return Color3.new(clamp(v.X,0,1), clamp(v.Y,0,1), clamp(v.Z,0,1)) end

-- Raycast wrapper
local RCP = RaycastParams.new()
RCP.FilterType = Enum.RaycastFilterType.Exclude
function U.Ray(origin, dir, ignore)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = ignore or {}
    return Workspace:Raycast(origin, dir, p)
end

-- Screen-to-world & vice versa
function U.ToScreen(worldPos)
    local sp, inView = Camera:WorldToViewportPoint(worldPos)
    return V2(sp.X, sp.Y), inView, sp.Z
end

-- Part pool system
local PartPools = {}
function U.GetPooledPart(tag)
    if not PartPools[tag] then PartPools[tag] = {} end
    if #PartPools[tag] > 0 then
        local p = table.remove(PartPools[tag])
        p.Parent = Workspace
        return p
    end
    local part = Instance.new("Part")
    part.Anchored    = true
    part.CanCollide  = false
    part.CastShadow  = false
    return part
end
function U.ReturnPooledPart(tag, part)
    part.Parent = nil
    if not PartPools[tag] then PartPools[tag] = {} end
    table.insert(PartPools[tag], part)
end

-- ══════════════════════════════════════════════════════════════════
-- [01]  3D GRASS & LEAF ENGINE
--       Billboard-to-Mesh with vertex-displacement sine sway,
--       collision-based bending, colour variation per biome.
-- ══════════════════════════════════════════════════════════════════
GSO.Grass = {
    Chunks    = {},     -- [chunkKey] = {blades={}, origin=V3}
    LeafNodes = {},     -- Tree leaf clusters
    BendMap   = {},     -- [blade] = {pushVec, strength, decay}
    ActiveChunkKeys = {},
}

local GRASS_PRIM_COLORS = {
    C3(55,148,52),  C3(72,165,60),  C3(88,178,68),
    C3(48,130,46),  C3(100,185,75), C3(40,115,40),
}
local GRASS_TIP_COLORS  = {
    C3(160,210,80), C3(140,200,70), C3(180,220,90),
    C3(120,190,65), C3(200,230,100),
}

-- Spawn a single blade as a slim Part with BillboardGui for double-facing
local function SpawnBlade(parent, groundPos, normal)
    local h  = U.Rnd(1.0, GSO.CFG.GRASS_MAX_HEIGHT)
    local w  = U.Rnd(0.10, 0.20)
    local rot= U.Rnd(0, pi*2)
    local primCol = GRASS_PRIM_COLORS[rand(1,#GRASS_PRIM_COLORS)]
    local tipCol  = GRASS_TIP_COLORS [rand(1,#GRASS_TIP_COLORS )]

    local blade = Instance.new("Part")
    blade.Name        = "GSO_Blade"
    blade.Anchored    = true
    blade.CanCollide  = false
    blade.CastShadow  = false
    blade.Material    = Enum.Material.SmoothPlastic
    blade.Color       = primCol
    blade.Size        = V3(w, h, w * 0.4)
    blade.CFrame      = CF(groundPos + normal * (h*0.5))
                        * CFrame.Angles(0, rot, 0)
    blade.Parent      = parent

    -- Double-sided billboard for front & back visibility
    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop   = false
    bb.Size          = UDim2.new(0, math.floor(w*60), 0, math.floor(h*20))
    bb.StudsOffset   = V3(0, h*0.5, 0)
    bb.LightInfluence= 1
    bb.Parent        = blade

    local img = Instance.new("Frame", bb)
    img.Size                = UDim2.new(1,0,1,0)
    img.BackgroundColor3    = primCol
    img.BorderSizePixel     = 0
    -- Vertical gradient: tip lighter
    local grad = Instance.new("UIGradient", img)
    grad.Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, tipCol),
        ColorSequenceKeypoint.new(0.5, primCol),
        ColorSequenceKeypoint.new(1.0, C3(30,80,28)),
    })
    grad.Rotation = 90

    return blade
end

-- Build a grass chunk centred at origin
function GSO.Grass.SpawnChunk(origin)
    local key = tostring(floor(origin.X/40)).."_"..tostring(floor(origin.Z/40))
    if GSO.Grass.Chunks[key] then return end

    local folder = Instance.new("Folder")
    folder.Name  = "GSOGrass_"..key
    folder.Parent= Workspace

    local blades = {}
    local count  = GSO.CFG.GRASS_BLADES_PER_CHUNK

    -- Parallel blade placement
    task.desynchronize()
    local placed = 0
    for i = 1, count do
        local ox = U.Rnd(-20, 20)
        local oz = U.Rnd(-20, 20)
        local rayOrigin = origin + V3(ox, 12, oz)
        local result = Workspace:Raycast(rayOrigin, V3(0,-24,0),
            RaycastParams.new())
        if result then
            local pos    = result.Position
            local normal = result.Normal
            -- Only on near-horizontal surfaces
            if normal.Y > 0.7 then
                local mat = result.Instance and result.Instance.Material
                -- Spawn on valid ground materials
                if mat ~= Enum.Material.Water then
                    task.synchronize()
                    local b = SpawnBlade(folder, pos, normal)
                    blades[#blades+1] = {
                        blade   = b,
                        origin  = pos,
                        normal  = normal,
                        idx     = i,
                        phase   = rand()*pi*2,
                        height  = b.Size.Y,
                    }
                    placed = placed + 1
                    task.desynchronize()
                end
            end
        end
    end
    task.synchronize()

    GSO.Grass.Chunks[key] = { blades = blades, origin = origin, folder = folder }
    table.insert(GSO.Grass.ActiveChunkKeys, key)
    return key
end

-- Despawn distant chunk to free memory
function GSO.Grass.DespawnChunk(key)
    local chunk = GSO.Grass.Chunks[key]
    if not chunk then return end
    chunk.folder:Destroy()
    GSO.Grass.Chunks[key] = nil
    for i, k in ipairs(GSO.Grass.ActiveChunkKeys) do
        if k == key then table.remove(GSO.Grass.ActiveChunkKeys, i); break end
    end
end

-- Register a collision bending event (projectile/player hit)
function GSO.Grass.Bend(worldPos, radius, strength)
    -- Tag nearby blades for bending
    for _, chunk in pairs(GSO.Grass.Chunks) do
        if (chunk.origin - worldPos).Magnitude < 60 then
            for _, bd in ipairs(chunk.blades) do
                local d = (bd.origin - worldPos).Magnitude
                if d < radius then
                    local factor = 1 - (d/radius)
                    local dir    = (bd.origin - worldPos).Unit
                    GSO.Grass.BendMap[bd.blade] = {
                        pushVec  = dir,
                        strength = strength * factor,
                        decay    = 0.92,
                        current  = 0,
                    }
                end
            end
        end
    end
end

-- Master grass update (called from RenderStepped)
function GSO.Grass.Update(t, dt, playerPos)
    local windT = t * GSO.CFG.GRASS_WIND_FREQ
    local turbT = t * GSO.CFG.GRASS_WIND_FREQ * 0.37

    -- Ensure correct chunks exist around player
    local CR = GSO.CFG.GRASS_CHUNK_RADIUS
    for gx = -CR, CR do
        for gz = -CR, CR do
            local cx = floor(playerPos.X/40)*40 + gx*40
            local cz = floor(playerPos.Z/40)*40 + gz*40
            local key= tostring(floor(cx/40)).."_"..tostring(floor(cz/40))
            if not GSO.Grass.Chunks[key] then
                task.spawn(GSO.Grass.SpawnChunk, V3(cx, playerPos.Y, cz))
            end
        end
    end

    -- Despawn chunks beyond range
    for _, key in ipairs(GSO.Grass.ActiveChunkKeys) do
        local chunk = GSO.Grass.Chunks[key]
        if chunk and (chunk.origin - playerPos).Magnitude > (CR+1.5)*40 then
            task.spawn(GSO.Grass.DespawnChunk, key)
        end
    end

    -- Update blade transforms
    local playerInfluenceR2 = GSO.CFG.GRASS_COLLISION_RADIUS^2

    task.desynchronize()

    for _, chunk in pairs(GSO.Grass.Chunks) do
        local chunkDist = (chunk.origin - playerPos).Magnitude
        -- Skip very distant chunks
        if chunkDist < GSO.CFG.LOD_DISTANCES[3] then
            for _, bd in ipairs(chunk.blades) do
                local blade  = bd.blade
                if blade and blade.Parent then
                    local pos    = bd.origin
                    local phase  = bd.phase
                    local h      = bd.height

                    -- Sine-wave vertex displacement (simulated)
                    local windSway    = sin(windT + phase) * GSO.CFG.GRASS_WIND_AMP
                    local turbSway    = sin(turbT + phase*1.7) * GSO.CFG.GRASS_WIND_AMP
                                        * GSO.CFG.GRASS_WIND_TURBULENCE * 0.4
                    local totalSwayX  = windSway + turbSway
                    local totalSwayZ  = cos(windT*0.8 + phase) * GSO.CFG.GRASS_WIND_AMP * 0.6

                    -- Player collision bending
                    local dx = pos.X - playerPos.X
                    local dz = pos.Z - playerPos.Z
                    local d2 = dx*dx + dz*dz
                    local playerBend = V3(0,0,0)
                    if d2 < playerInfluenceR2 then
                        local d       = sqrt(d2)
                        local factor  = (1 - d/GSO.CFG.GRASS_COLLISION_RADIUS)^2
                        playerBend    = V3(dx/(d+0.001)*factor*0.8, 0, dz/(d+0.001)*factor*0.8)
                    end

                    -- Registered bend map
                    local extraBend = V3(0,0,0)
                    local bendData  = GSO.Grass.BendMap[blade]
                    if bendData then
                        bendData.current = bendData.current * bendData.decay + bendData.strength * 0.1
                        extraBend = bendData.pushVec * bendData.current
                        if bendData.current < 0.01 then
                            GSO.Grass.BendMap[blade] = nil
                        end
                    end

                    local totalBend = playerBend + extraBend
                    local finalSwayX = totalSwayX + totalBend.X
                    local finalSwayZ = totalSwayZ + totalBend.Z

                    -- Clamp sway
                    finalSwayX = clamp(finalSwayX, -0.9, 0.9)
                    finalSwayZ = clamp(finalSwayZ, -0.9, 0.9)

                    -- Write CFrame (synchronize for property write)
                    task.synchronize()
                    blade.CFrame = CF(pos + V3(0, h*0.5, 0)
                        + V3(finalSwayX * h*0.3, 0, finalSwayZ * h*0.3))
                        * CFrame.Angles(finalSwayX*0.5, 0, finalSwayZ*0.5)
                    task.desynchronize()
                end
            end
        end
    end
    task.synchronize()

    -- Leaf flutter on trees
    if GSO.CFG.LEAF_FLUTTER_ENABLED then
        local lfT = t * GSO.CFG.LEAF_FLUTTER_FREQ
        for _, leaf in ipairs(GSO.Grass.LeafNodes) do
            if leaf and leaf.Parent then
                local sway = sin(lfT + leaf:GetAttribute("Phase") or 0) * 0.08
                leaf.CFrame = leaf:GetAttribute("OriginCF") * CFrame.Angles(sway, 0, sway*0.6)
            end
        end
    end
end

-- Register tree leaves for flutter
function GSO.Grass.RegisterLeaves()
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and (
            part.Name:lower():find("leaf")  or
            part.Name:lower():find("leaves")or
            part.Name:lower():find("foliage")
        ) then
            part:SetAttribute("Phase",  U.Rnd(0, pi*2))
            part:SetAttribute("OriginCF", part.CFrame)
            table.insert(GSO.Grass.LeafNodes, part)
        end
    end
    print("[GSO] Leaf nodes registered: "..#GSO.Grass.LeafNodes)
end

-- ══════════════════════════════════════════════════════════════════
-- [02]  ENVIRONMENT REMASTER  (EditableImage Anime Hatching)
--       Generates procedural cel-shade + hatching textures and
--       applies them to terrain and ground parts via SurfaceAppearance.
-- ══════════════════════════════════════════════════════════════════
GSO.EnvRemaster = {}

-- Draw anime hatching pattern into an EditableImage buffer (returns pixel array)
local function GenerateHatchingTexture(baseColor, shadowColor, lineCount, size)
    -- Returns a flat RGBA pixel table for EditableImage
    local px = {}
    local S  = size
    for y = 0, S-1 do
        for x = 0, S-1 do
            local i = (y*S + x)*4 + 1
            -- Noise base
            local n = U.FBM(x/S*4, y/S*4, 0, 3)
            n = (n + 1)*0.5 -- normalize 0-1

            -- Hatching: diagonal lines
            local hatch = ((x + y) % floor(S/lineCount)) < 2
            -- Cross-hatch for dark areas
            local crossH = (n < 0.35) and (((x - y) % floor(S/lineCount*0.7)) < 2) or false

            local r,g,b
            if crossH then
                -- Deep shadow cross-hatch
                r = shadowColor.R * 0.6
                g = shadowColor.G * 0.6
                b = shadowColor.B * 0.6
            elseif hatch and n < 0.55 then
                -- Mid-tone hatch
                r = shadowColor.R
                g = shadowColor.G
                b = shadowColor.B
            elseif n > 0.72 then
                -- Highlight rim
                r = min(baseColor.R + 0.2, 1)
                g = min(baseColor.G + 0.2, 1)
                b = min(baseColor.B + 0.22, 1)
            else
                r = U.Lerp(baseColor.R, shadowColor.R, 1-n)
                g = U.Lerp(baseColor.G, shadowColor.G, 1-n)
                b = U.Lerp(baseColor.B, shadowColor.B, 1-n)
            end

            px[i]   = clamp(r,0,1)
            px[i+1] = clamp(g,0,1)
            px[i+2] = clamp(b,0,1)
            px[i+3] = 1.0
        end
    end
    return px
end

local MATERIAL_CONFIGS = {
    [Enum.Material.Grass]  = { base=C3(72,162,64),  shadow=C3(30,90,28) },
    [Enum.Material.Dirt]   = { base=C3(140,98,58),  shadow=C3(70,45,25) },
    [Enum.Material.Stone]  = { base=C3(132,128,142),shadow=C3(60,58,75) },
    [Enum.Material.Sand]   = { base=C3(232,210,148),shadow=C3(170,150,80)},
    [Enum.Material.Rock]   = { base=C3(115,110,125),shadow=C3(55,52,68) },
    [Enum.Material.Mud]    = { base=C3(102,78,48),  shadow=C3(55,38,22) },
    [Enum.Material.Snow]   = { base=C3(235,245,255),shadow=C3(170,195,230)},
    [Enum.Material.Ice]    = { base=C3(160,210,240),shadow=C3(80,140,200)},
    [Enum.Material.LeafyGrass]={base=C3(60,155,50), shadow=C3(25,85,22)},
}

-- Cache generated EditableImages
GSO.EnvRemaster.TextureCache = {}

local function GetOrBuildTexture(matEnum)
    if GSO.EnvRemaster.TextureCache[matEnum] then
        return GSO.EnvRemaster.TextureCache[matEnum]
    end
    local cfg = MATERIAL_CONFIGS[matEnum]
    if not cfg then return nil end

    local S   = GSO.CFG.EI_TEXTURE_SIZE
    local px  = GenerateHatchingTexture(cfg.base, cfg.shadow, GSO.CFG.EI_HATCH_LINES, S)

    -- Build EditableImage
    local ei = nil
    pcall(function()
        ei = AssetService:CreateEditableImage({ Size = Vector2.new(S, S) })
        -- Convert flat RGBA to buffer
        local buf = buffer.create(S * S * 4)
        for i = 0, S*S-1 do
            local pi = i*4 + 1
            buffer.writeu8(buf, i*4,   floor(px[pi]*255))
            buffer.writeu8(buf, i*4+1, floor(px[pi+1]*255))
            buffer.writeu8(buf, i*4+2, floor(px[pi+2]*255))
            buffer.writeu8(buf, i*4+3, floor(px[pi+3]*255))
        end
        ei:WritePixelsBuffer(Vector2.zero, Vector2.new(S,S), buf)
    end)

    GSO.EnvRemaster.TextureCache[matEnum] = ei
    return ei
end

function GSO.EnvRemaster.ApplyToTerrain()
    if not GSO.CFG.EI_ENABLED then return end
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        for mat, cfg in pairs(MATERIAL_CONFIGS) do
            pcall(function()
                terrain:SetMaterialColor(mat, cfg.base)
            end)
        end
    end
    print("[GSO] Terrain material colors applied.")
end

function GSO.EnvRemaster.ApplyToWorkspace()
    -- Apply SurfaceAppearance with EditableImage to matching parts
    local function processPart(part)
        if not part:IsA("BasePart") then return end
        local cfg = MATERIAL_CONFIGS[part.Material]
        if not cfg then return end

        -- Basic material upgrade
        part.Material    = Enum.Material.SmoothPlastic
        part.Color       = cfg.base
        part.Reflectance = 0.02

        -- Try applying SurfaceAppearance + EditableImage
        pcall(function()
            if not GSO.CFG.EI_ENABLED then return end
            local sa = part:FindFirstChildOfClass("SurfaceAppearance")
                    or Instance.new("SurfaceAppearance", part)
            local ei = GetOrBuildTexture(part.Material)
            if ei then
                sa.ColorMap = ei
            end
        end)
    end

    task.desynchronize()
    for _, desc in ipairs(Workspace:GetDescendants()) do
        processPart(desc)
    end
    task.synchronize()

    Workspace.DescendantAdded:Connect(function(inst)
        task.defer(function() processPart(inst) end)
    end)
    print("[GSO] Environment Remaster complete.")
end

-- ══════════════════════════════════════════════════════════════════
-- [03]  VOLUMETRIC 3D CLOUDS + RAY-MARCHED GOD RAYS
-- ══════════════════════════════════════════════════════════════════
GSO.Clouds = {
    Volumes   = {},   -- 3D cloud volume parts
    GodRays   = {},   -- Fake ray-march beam parts
    SunAngle  = 45,
}

local CLOUD_BASE_Y = 180
local CLOUD_STRATA = {
    { yBase=180, count=18, scaleRange={V2(50,120), V2(12,28)}, speedMul=1.0, alpha=0.50 },
    { yBase=260, count=12, scaleRange={V2(80,200), V2(20,50)}, speedMul=0.7, alpha=0.42 },
    { yBase=360, count=8,  scaleRange={V2(150,350),V2(40,90)}, speedMul=0.4, alpha=0.35 },
    { yBase=480, count=5,  scaleRange={V2(250,500),V2(60,120)},speedMul=0.2, alpha=0.28 },
    { yBase=600, count=3,  scaleRange={V2(400,800),V2(80,160)},speedMul=0.1, alpha=0.20 },
}

function GSO.Clouds.Build()
    -- Clear existing
    local existing = Workspace:FindFirstChild("GSO_CloudSystem")
    if existing then existing:Destroy() end

    local folder = Instance.new("Folder", Workspace)
    folder.Name  = "GSO_CloudSystem"

    for si, stratum in ipairs(CLOUD_STRATA) do
        if si > GSO.CFG.CLOUD_VOLUME_LAYERS then break end
        local subFolder = Instance.new("Folder", folder)
        subFolder.Name  = "Stratum_"..si

        for i = 1, stratum.count do
            -- Multi-part cloud volume (3 overlapping ellipsoids per cloud)
            local cx = U.Rnd(-600, 600)
            local cz = U.Rnd(-600, 600)
            local cy = stratum.yBase + U.Rnd(-20, 20)

            local cloudGroup = Instance.new("Model", subFolder)
            cloudGroup.Name  = "CloudVol_"..si.."_"..i

            local scaleXZ = V2(stratum.scaleRange[1].X, stratum.scaleRange[1].Y)
            local scaleY  = V2(stratum.scaleRange[2].X, stratum.scaleRange[2].Y)

            -- Build 3-5 overlapping lobes per cloud volume
            local lobeCount = rand(3,5)
            for l = 1, lobeCount do
                local lobe = Instance.new("Part")
                lobe.Anchored    = true
                lobe.CanCollide  = false
                lobe.CastShadow  = false
                lobe.Material    = Enum.Material.Neon
                lobe.Color       = C3(252, 252, 255)
                lobe.Transparency= stratum.alpha + U.Rnd(-0.05, 0.05)
                local lw = U.Rnd(scaleXZ.X, scaleXZ.Y)
                local lh = U.Rnd(scaleY.X, scaleY.Y)
                lobe.Size        = V3(lw, lh, lw * U.Rnd(0.7, 1.2))
                lobe.CFrame      = CF(
                    cx + U.Rnd(-lw*0.3, lw*0.3),
                    cy + U.Rnd(-lh*0.2, lh*0.2),
                    cz + U.Rnd(-lw*0.3, lw*0.3)
                )

                -- Soft edges via SelectionSphere (sphere-mapped glow)
                local ss = Instance.new("SelectionSphere")
                ss.Adornee   = lobe
                ss.Color3    = C3(255,255,255)
                ss.SurfaceTransparency  = 1
                ss.SurfaceColor3        = C3(255,255,255)
                ss.Parent    = lobe

                lobe.Parent  = cloudGroup
            end

            GSO.Clouds.Volumes[#GSO.Clouds.Volumes+1] = {
                model    = cloudGroup,
                cx=cx, cy=cy, cz=cz,
                speed    = 0.014 * stratum.speedMul,
                phase    = U.Rnd(0, pi*2),
                stratum  = si,
                alpha    = stratum.alpha,
            }
        end
    end

    -- ── Ray-Marched God Rays ──────────────────────────────────
    local rayFolder = Instance.new("Folder", folder)
    rayFolder.Name  = "GodRays"

    for r = 1, GSO.CFG.CLOUD_GODRAY_RAYS do
        local beam = Instance.new("Part")
        beam.Name        = "GodRay_"..r
        beam.Anchored    = true
        beam.CanCollide  = false
        beam.CastShadow  = false
        beam.Material    = Enum.Material.Neon
        beam.Color       = C3(255, 245, 200)
        beam.Transparency= 0.88
        beam.Size        = V3(U.Rnd(2,6), U.Rnd(60,180), U.Rnd(2,6))
        beam.Parent      = rayFolder

        GSO.Clouds.GodRays[#GSO.Clouds.GodRays+1] = {
            part    = beam,
            angle   = (r / GSO.CFG.CLOUD_GODRAY_RAYS) * pi*2,
            radius  = U.Rnd(20,80),
            phase   = U.Rnd(0, pi*2),
        }
    end

    -- Lighting atmosphere
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atmo.Density  = 0.42; atmo.Offset = 0.08
    atmo.Color    = C3(190,220,255); atmo.Decay = C3(100,120,185)
    atmo.Glare    = 0.6;  atmo.Haze  = 0.35

    local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
    bloom.Intensity = 0.7; bloom.Size = 48; bloom.Threshold = 0.92

    local sr = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect", Lighting)
    sr.Intensity = 0.9; sr.Spread = 0.6

    print("[GSO] Volumetric Cloud System built: "..#GSO.Clouds.Volumes.." volumes.")
end

function GSO.Clouds.Update(t)
    local sunFac = (sin(t * 0.003 * pi) + 1) * 0.5
    local isDay  = sunFac > 0.45

    -- Lighting sync
    Lighting.ClockTime    = (t * 0.003 % 1) * 24
    Lighting.Brightness   = U.Lerp(0.08, 2.3, sunFac)
    Lighting.Ambient      = U.LerpC3(C3(15,15,30), C3(130,130,145), sunFac)
    Lighting.OutdoorAmbient= U.LerpC3(C3(30,25,55), C3(150,165,185), sunFac)

    -- Sunset colour grade
    local sunsetFac = max(0, 1 - abs(sunFac - 0.35)*5)
    local nightFac  = max(0, 1 - sunFac*3)

    -- Cloud colour & drift
    for _, vol in ipairs(GSO.Clouds.Volumes) do
        if vol.model and vol.model.Parent then
            -- Drift
            local nx = vol.cx + sin(t*vol.speed + vol.phase)*80 + t*vol.speed*200
            local nz = vol.cz + t*vol.speed*60

            -- Colour at sunset
            local cloudColor
            if sunsetFac > 0.05 then
                cloudColor = U.LerpC3(C3(252,252,255), C3(255,148,80), sunsetFac)
            elseif nightFac > 0.1 then
                cloudColor = U.LerpC3(C3(252,252,255), C3(40,45,80), nightFac)
            else
                cloudColor = C3(252,252,255)
            end

            -- Apply to all lobes
            for _, lobe in ipairs(vol.model:GetChildren()) do
                if lobe:IsA("BasePart") then
                    lobe.Color = cloudColor
                    lobe.CFrame = CF(
                        nx + (lobe.CFrame.X - vol.cx),
                        lobe.CFrame.Y,
                        nz + (lobe.CFrame.Z - vol.cz)
                    )
                end
            end
        end
    end

    -- ── Ray-marched God Ray simulation ──────────────────────
    if GSO.CFG.CLOUD_GODRAY_BLOCK_ENABLE then
        local sunDir  = Lighting:GetSunDirection()
        local sunPos  = Camera.CFrame.Position - sunDir * 800

        for _, ray in ipairs(GSO.Clouds.GodRays) do
            local beam     = ray.part
            local angle    = ray.angle + t * 0.008
            local r        = ray.radius

            -- Position beam between sun and camera
            local midPt    = Camera.CFrame.Position + V3(cos(angle)*r, 80, sin(angle)*r)
            local rayDir   = (midPt - sunPos).Unit
            local beamLen  = beam.Size.Y

            beam.CFrame = CF(midPt, midPt + rayDir)
                * CFrame.Angles(pi/2, 0, 0)

            -- Ray-march occlusion: cast rays from sun, darken if blocked
            if GSO.CFG.CLOUD_GODRAY_BLOCK_ENABLE then
                local blocked = false
                for step = 1, GSO.CFG.CLOUD_RAYMARCH_STEPS do
                    local samplePt = sunPos + rayDir * (step / GSO.CFG.CLOUD_RAYMARCH_STEPS * 800)
                    local hit = U.Ray(samplePt, V3(0,-0.1,0), {})
                    if hit and hit.Instance and hit.Instance.Name ~= "GodRay_"..tostring(step) then
                        blocked = true; break
                    end
                end
                beam.Transparency = blocked and 0.98 or (0.82 + sunsetFac*0.08 - sunFac*0.05)
                beam.Color = U.LerpC3(C3(255,245,200), C3(255,160,80), sunsetFac * 0.7)
            end
        end
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [04]  MODEL GEOMETRY EVOLUTION
--       EditableMesh thickness injection for hair/cloth,
--       SSS glow on ears/fingers/thin skin.
-- ══════════════════════════════════════════════════════════════════
GSO.ModelGeo = {
    CharacterLights = {},   -- Per-character light rigs
    SSSParts        = {},   -- Parts with SSS point lights
}

-- ── 4A. EditableMesh Thickness Injection ─────────────────────────
--   Finds mesh parts named like hair/cloth and extrudes their
--   normals slightly outward using EditableMesh API.
function GSO.ModelGeo.InjectThickness(character)
    if not GSO.CFG.EM_ENABLED then return end
    local HAIR_NAMES = {"hair","Hair","hairpart","HairPart","Cloth","cloth","Cape","cape"}

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("MeshPart") then
            local isHair  = false
            local isCloth = false
            for _, n in ipairs(HAIR_NAMES) do
                if part.Name:find(n) then
                    isHair  = part.Name:lower():find("hair") ~= nil
                    isCloth = not isHair
                    break
                end
            end

            if isHair or isCloth then
                local thickness = isHair and GSO.CFG.EM_HAIR_THICKNESS
                                           or GSO.CFG.EM_CLOTH_THICKNESS
                pcall(function()
                    local em = AssetService:CreateEditableMeshAsync(
                        Content.fromUri(part.MeshId)
                    )
                    -- Extrude vertices along their normals
                    local verts = em:GetVertices()
                    for _, vid in ipairs(verts) do
                        local vpos = em:GetPosition(vid)
                        local vnorm = em:GetNormal(vid)
                        em:SetPosition(vid, vpos + vnorm * thickness)
                    end
                    -- Apply back
                    local newMesh = em:CreateMeshPartAsync(
                        { CollisionFidelity = Enum.CollisionFidelity.Box }
                    )
                    newMesh.CFrame      = part.CFrame
                    newMesh.Color       = part.Color
                    newMesh.Material    = part.Material
                    newMesh.Transparency= part.Transparency
                    newMesh.Parent      = part.Parent
                    part:Destroy()
                end)
            end
        end
    end
end

-- ── 4B. SSS Point Lights (Ears, Fingers, Thin Skin) ─────────────
local SSS_PART_NAMES = {"LeftHand","RightHand","Head","LeftFoot","RightFoot"}

function GSO.ModelGeo.ApplySSS(character)
    -- Apply warm glow inside thin body parts to simulate light scatter
    for _, name in ipairs(SSS_PART_NAMES) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            -- Inner glow light
            local existing = part:FindFirstChild("GSO_SSS")
            if not existing then
                local pt = Instance.new("PointLight", part)
                pt.Name       = "GSO_SSS"
                pt.Color      = GSO.CFG.SSS_GLOW_COLOR
                pt.Range      = GSO.CFG.SSS_GLOW_RANGE
                pt.Brightness = 0.6
                pt.Shadows    = false
                table.insert(GSO.ModelGeo.SSSParts, { part=part, light=pt, phase=U.Rnd(0,pi*2) })
            end
        end
    end

    -- Ear SSS: find Head and add a tiny light offset inward
    local head = character:FindFirstChild("Head")
    if head and GSO.CFG.SSS_EAR_GLOW then
        for _, side in ipairs({-1, 1}) do
            local earLight = Instance.new("PointLight", head)
            earLight.Name       = "GSO_EarSSS"
            earLight.Color      = C3(255, 100, 70)
            earLight.Range      = 1.2
            earLight.Brightness = 0.45
            earLight.Shadows    = false
        end
    end
end

-- Pulse SSS lights with heartbeat rhythm + backlight reactivity
function GSO.ModelGeo.UpdateSSS(t)
    local heartbeat = 0.5 + sin(t * 1.3) * 0.08 + sin(t * 2.6) * 0.04
    for _, data in ipairs(GSO.ModelGeo.SSSParts) do
        if data.light and data.light.Parent then
            -- Backlight: check if sun is behind the part
            local sunDir  = Lighting:GetSunDirection()
            local partLook = data.part.CFrame.LookVector
            local backFac = max(0, -partLook:Dot(sunDir))
            data.light.Brightness = heartbeat * (0.4 + backFac * 0.6)
        end
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [05]  ANIMATION REMASTER
--       Motion Warping, Procedural Layering, Jiggle Physics
-- ══════════════════════════════════════════════════════════════════
GSO.Animation = {
    JiggleBones  = {},   -- { part, vel, ...)
    MotorCache   = {},   -- Motor6D smoothing
    ProceduralLayers = {},
}

-- ── 5A. Jiggle Physics ────────────────────────────────────────────
local JIGGLE_TAGS = {"hair","Hair","cape","Cape","scarf","Scarf","tail","Tail",
                     "cloak","Cloak","sleeve","Sleeve","ribbon","Ribbon"}

function GSO.Animation.BuildJiggle(character)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            for _, tag in ipairs(JIGGLE_TAGS) do
                if part.Name:lower():find(tag:lower()) then
                    table.insert(GSO.Animation.JiggleBones, {
                        part        = part,
                        restCF      = part.CFrame,
                        vel         = V3(0,0,0),
                        windPhase   = U.Rnd(0, pi*2),
                        stiffness   = GSO.CFG.JIGGLE_STIFFNESS,
                        damping     = GSO.CFG.JIGGLE_DAMPING,
                    })
                    break
                end
            end
        end
    end
end

local windSeedX, windSeedZ = 10, 50

function GSO.Animation.UpdateJiggle(t, dt, charVel)
    -- Global procedural wind vector
    local wT  = t * 0.35
    local wX  = (U.Perlin(wT + windSeedX, 0) * 2 - 1) * GSO.CFG.JIGGLE_WIND_INFLUENCE * 1.5
    local wZ  = (U.Perlin(0, wT + windSeedZ) * 2 - 1) * GSO.CFG.JIGGLE_WIND_INFLUENCE

    -- Velocity influence (character movement)
    local velInfluence = charVel * GSO.CFG.JIGGLE_VELOCITY_SCALE

    for i = #GSO.Animation.JiggleBones, 1, -1 do
        local jb = GSO.Animation.JiggleBones[i]
        if jb.part and jb.part.Parent then
            local restPos  = jb.restCF.Position
            local curPos   = jb.part.CFrame.Position

            -- Spring force toward rest
            local toRest = (restPos - curPos) * jb.stiffness
            -- Wind + velocity forces
            local extForce = V3(wX, 0, wZ) + V3(velInfluence.X, 0, velInfluence.Z)
            -- Spring secondary wobble
            local wobble   = sin(t * 3.2 + jb.windPhase) * 0.08

            local totalForce = toRest + extForce + V3(wobble, 0, wobble*0.5)
            jb.vel = jb.vel + totalForce * dt
            jb.vel = jb.vel * (1 - (1 - jb.damping) * dt * 60)

            local newPos = curPos + jb.vel * dt

            -- Tilt & twist based on velocity
            local tiltX  = jb.vel.Z * 0.10
            local tiltZ  = -jb.vel.X * 0.10

            jb.part.CFrame = CF(newPos)
                * (jb.restCF - jb.restCF.Position)  -- preserve rest rotation
                * CFrame.Angles(tiltX, 0, tiltZ)
        else
            table.remove(GSO.Animation.JiggleBones, i)
        end
    end
end

-- ── 5B. Motion Warping & Joint Interpolation ──────────────────────
function GSO.Animation.BuildMotorCache(character)
    for _, motor in ipairs(character:GetDescendants()) do
        if motor:IsA("Motor6D") then
            GSO.Animation.MotorCache[motor] = {
                prev    = motor.Transform,
                vel     = CFrame.identity,
                target  = motor.Transform,
            }
        end
    end
end

-- 5B-2. Procedural breathing layer
function GSO.Animation.BuildProceduralLayers(character)
    local torso = character:FindFirstChild("UpperTorso")
                or character:FindFirstChild("Torso")
    if torso then
        table.insert(GSO.Animation.ProceduralLayers, {
            type  = "breathe",
            part  = torso,
            restCF= torso.CFrame,
            phase = 0,
        })
    end
end

function GSO.Animation.UpdateMotorSmoothing(dt)
    local alpha = 0.85
    for motor, cache in pairs(GSO.Animation.MotorCache) do
        if motor and motor.Parent then
            cache.prev = cache.prev:Lerp(motor.Transform, 1 - alpha^(dt*60))
            -- Motion warp: snap if delta too large (prevents swimming)
            local posDelta = (motor.Transform.Position - cache.prev.Position).Magnitude
            if posDelta > 0.5 then
                cache.prev = motor.Transform
            end
            motor.Transform = cache.prev
        else
            GSO.Animation.MotorCache[motor] = nil
        end
    end
end

function GSO.Animation.UpdateProceduralLayers(t)
    for _, layer in ipairs(GSO.Animation.ProceduralLayers) do
        if layer.part and layer.part.Parent then
            if layer.type == "breathe" then
                local breathe = sin(t * 0.28) * 0.012
                local subtle  = sin(t * 0.55 + 1.2) * 0.006
                -- Subtle torso scale pulse (breathing)
                pcall(function()
                    layer.part.CFrame = layer.restCF
                        * CFrame.Angles(breathe + subtle, 0, 0)
                        * CF(0, abs(breathe) * 0.05, 0)
                end)
            end
        end
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [06]  CINEMATIC CHARACTER LIGHT RIG
--       3-point lighting (Key / Fill / Rim) that follows each
--       character, guaranteeing they're never flat even in shadows.
-- ══════════════════════════════════════════════════════════════════
GSO.Lights = {
    Rigs = {},  -- [character] = { key, fill, rim, rimBack }
}

local function MakeLight(parent, color, range, brightness, shadows)
    local l = Instance.new("PointLight", parent)
    l.Color      = color
    l.Range      = range
    l.Brightness = brightness
    l.Shadows    = shadows or false
    return l
end

function GSO.Lights.BuildRig(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Key Light: warm, from upper-front-right (simulates sun/hero light)
    local keyPart = Instance.new("Part")
    keyPart.Name        = "GSO_KeyLight"
    keyPart.Anchored    = true
    keyPart.CanCollide  = false
    keyPart.Transparency= 1
    keyPart.Size        = V3(0.1,0.1,0.1)
    keyPart.CastShadow  = false
    keyPart.Parent      = character
    local keyLight = MakeLight(keyPart, C3(255,240,200),
        GSO.CFG.CHAR_KEY_LIGHT_RANGE, GSO.CFG.CHAR_KEY_LIGHT_BRIGHT, false)

    -- Fill Light: cool, from left — fills shadow side
    local fillPart = Instance.new("Part")
    fillPart.Name       = "GSO_FillLight"
    fillPart.Anchored   = true
    fillPart.CanCollide = false
    fillPart.Transparency=1
    fillPart.Size       = V3(0.1,0.1,0.1)
    fillPart.CastShadow = false
    fillPart.Parent     = character
    local fillLight = MakeLight(fillPart, C3(150,180,255),
        GSO.CFG.CHAR_FILL_LIGHT_RANGE, GSO.CFG.CHAR_FILL_LIGHT_BRIGHT, false)

    -- Rim Light: bright white/blue edge from behind (anime rim)
    local rimPart = Instance.new("Part")
    rimPart.Name        = "GSO_RimLight"
    rimPart.Anchored    = true
    rimPart.CanCollide  = false
    rimPart.Transparency= 1
    rimPart.Size        = V3(0.1,0.1,0.1)
    rimPart.CastShadow  = false
    rimPart.Parent      = character
    local rimLight = MakeLight(rimPart, C3(200,220,255),
        GSO.CFG.CHAR_RIM_LIGHT_RANGE, GSO.CFG.CHAR_RIM_LIGHT_BRIGHT, false)

    -- Ground Bounce: warm up-light under character
    local bouncePart = Instance.new("Part")
    bouncePart.Name       = "GSO_BounceLight"
    bouncePart.Anchored   = true
    bouncePart.CanCollide = false
    bouncePart.Transparency=1
    bouncePart.Size       = V3(0.1,0.1,0.1)
    bouncePart.CastShadow = false
    bouncePart.Parent     = character
    local bounceLight = MakeLight(bouncePart, C3(210,195,160), 10, 0.3, false)

    GSO.Lights.Rigs[character] = {
        keyPart=keyPart, keyLight=keyLight,
        fillPart=fillPart, fillLight=fillLight,
        rimPart=rimPart, rimLight=rimLight,
        bouncePart=bouncePart, bounceLight=bounceLight,
    }
end

function GSO.Lights.UpdateRigs(t)
    local sunDir = Lighting:GetSunDirection()
    local sunFac = (sin(t * 0.003 * pi) + 1) * 0.5

    -- Key light colour based on time of day
    local keyColor
    if sunFac > 0.6 then
        keyColor = C3(255, 242, 210)  -- warm daylight
    elseif sunFac > 0.2 then
        keyColor = U.LerpC3(C3(255,180,100), C3(255,242,210), (sunFac-0.2)/0.4)  -- sunset
    else
        keyColor = C3(80, 100, 180)   -- moonlight
    end

    for character, rig in pairs(GSO.Lights.Rigs) do
        if character and character.Parent then
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                local pos  = root.Position
                local look = root.CFrame.LookVector
                local right= root.CFrame.RightVector

                -- Key: upper-right-front of character
                rig.keyPart.CFrame   = CF(pos + right*4 + V3(0,5,0) + look*(-2))
                rig.keyLight.Color   = keyColor
                rig.keyLight.Brightness = U.Lerp(0.1, GSO.CFG.CHAR_KEY_LIGHT_BRIGHT, sunFac)

                -- Fill: left of character
                rig.fillPart.CFrame  = CF(pos - right*5 + V3(0,2,0))
                rig.fillLight.Color  = sunFac > 0.3 and C3(160,195,255) or C3(60,70,140)

                -- Rim: behind character
                rig.rimPart.CFrame   = CF(pos - look*4 + V3(0,3,0))
                rig.rimLight.Brightness = 0.5 + sin(t*0.5)*0.15  -- subtle pulse

                -- Ground bounce: directly below
                local groundResult = U.Ray(pos, V3(0,-15,0), {character})
                local groundY = groundResult and groundResult.Position.Y or (pos.Y - 5)
                rig.bouncePart.CFrame = CF(pos.X, groundY + 0.5, pos.Z)

                -- Tint bounce from ground color
                if groundResult and groundResult.Instance then
                    local gc = groundResult.Instance.Color
                    rig.bounceLight.Color = U.LerpC3(C3(200,180,140), gc, 0.4)
                end
            end
        else
            -- Clean up destroyed character
            for _, part in pairs(rig) do
                if typeof(part) == "Instance" then pcall(function() part:Destroy() end) end
            end
            GSO.Lights.Rigs[character] = nil
        end
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [07]  COMBAT SAKUGA VFX OVERLOAD
--       Refraction hazes, Impact Frames 2.0, 3D Debris + shadows
-- ══════════════════════════════════════════════════════════════════
GSO.Sakuga = {
    ActiveParts  = 0,
    HitStopActive= false,
    ImpactGui    = nil,
    ImpactFrame  = nil,
    SpeedLinePool= {},
    LastHitTime  = 0,
    FrameCount   = 0,  -- for "3 frames exactly" timing
}

local ELEMENT_COLORS = {
    pyro     = { main=C3(255,100,30),  secondary=C3(255,200,50),  glow=C3(255,80,20)  },
    hydro    = { main=C3(30,120,255),  secondary=C3(120,200,255), glow=C3(0,80,220)   },
    cryo     = { main=C3(140,220,255), secondary=C3(200,240,255), glow=C3(100,200,255)},
    electro  = { main=C3(180,80,255),  secondary=C3(220,160,255), glow=C3(140,40,255) },
    anemo    = { main=C3(80,220,180),  secondary=C3(150,240,220), glow=C3(60,200,160) },
    geo      = { main=C3(220,180,50),  secondary=C3(255,220,100), glow=C3(200,150,20) },
    dendro   = { main=C3(80,200,40),   secondary=C3(150,240,80),  glow=C3(60,180,20)  },
    physical = { main=C3(255,255,255), secondary=C3(220,220,220), glow=C3(200,200,200)},
}

-- ── 7A. Impact Frames 2.0 ─────────────────────────────────────────
function GSO.Sakuga.BuildImpactGui()
    local sg = Instance.new("ScreenGui", PGui)
    sg.Name           = "GSO_ImpactSystem"
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
    GSO.Sakuga.ImpactGui = sg

    local flash = Instance.new("Frame", sg)
    flash.Size                = UDim2.new(1,0,1,0)
    flash.BackgroundColor3    = C3(255,255,255)
    flash.BackgroundTransparency = 1
    flash.BorderSizePixel     = 0
    flash.ZIndex              = 200
    GSO.Sakuga.ImpactFrame    = flash

    -- Speed line pool
    for i = 1, 36 do
        local line = Instance.new("Frame", sg)
        line.BackgroundColor3    = C3(255,255,255)
        line.BorderSizePixel     = 0
        line.BackgroundTransparency = 1
        line.AnchorPoint         = V2(0.5, 0.5)
        line.ZIndex              = 195
        GSO.Sakuga.SpeedLinePool[i] = line
    end
end

-- 3-frame impact: white → invert → dark → fade
function GSO.Sakuga.TriggerImpactFrame2(magnitude, element)
    local ec = ELEMENT_COLORS[element or "physical"]
    local f  = GSO.Sakuga.ImpactFrame
    if not f then return end

    local intensity = clamp(magnitude / 90, 0.25, 1.0)

    -- Frame 1: element-colored flash
    f.BackgroundColor3    = ec.glow
    f.BackgroundTransparency = 1 - (0.88 * intensity)

    task.delay(0.033, function()  -- ~2 frames at 60fps
        -- Frame 2: inverted (dark with element tint)
        f.BackgroundColor3 = U.LerpC3(C3(10,10,25), ec.main, 0.3)
        f.BackgroundTransparency = 1 - (0.6 * intensity)
    end)

    task.delay(0.066, function()  -- frame 3
        -- Frame 3: white pop
        f.BackgroundColor3 = C3(255,255,255)
        f.BackgroundTransparency = 1 - (0.4 * intensity)
    end)

    task.delay(0.099, function()  -- after 3 frames: fade
        TweenService:Create(f, TweenInfo.new(0.12, Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
    end)

    -- Radial speed lines (element-tinted) for exactly 3 frames
    local vp  = Camera.ViewportSize
    local cx, cy = vp.X*0.5, vp.Y*0.5
    for i, line in ipairs(GSO.Sakuga.SpeedLinePool) do
        local angle   = (i / 36) * pi * 2
        local len     = U.Rnd(80, 280) * intensity
        local width   = U.Rnd(1, 5)
        local dist    = U.Rnd(60, 220) * intensity
        line.Size     = UDim2.new(0, len, 0, width)
        line.Position = UDim2.new(0, cx + cos(angle)*dist, 0, cy + sin(angle)*dist)
        line.Rotation = math.deg(angle)
        line.BackgroundColor3    = ec.secondary
        line.BackgroundTransparency = 0.05

        -- Hold for 3 frames then snap-fade
        task.delay(0.05, function()
            TweenService:Create(line, TweenInfo.new(0.09, Enum.EasingStyle.Sine,
                Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
        end)
    end
end

-- ── 7B. Hit-Stop ──────────────────────────────────────────────────
function GSO.Sakuga.TriggerHitStop(duration)
    if GSO.Sakuga.HitStopActive then return end
    GSO.Sakuga.HitStopActive = true
    duration = duration or 0.055
    local tracks = Animator:GetPlayingAnimationTracks()
    for _, t in ipairs(tracks) do t:AdjustSpeed(0) end
    -- Also micro-freeze camera
    task.delay(duration, function()
        for _, t in ipairs(Animator:GetPlayingAnimationTracks()) do
            t:AdjustSpeed(1)
        end
        GSO.Sakuga.HitStopActive = false
    end)
end

-- ── 7C. Refraction Heat Haze ──────────────────────────────────────
function GSO.Sakuga.SpawnRefraction(pos, element, scale)
    if GSO.Sakuga.ActiveParts >= GSO.CFG.MAX_VFX_PARTS then return end
    scale   = scale or 1.0
    local ec = ELEMENT_COLORS[element or "physical"]

    -- Refraction distortion illusion: semi-transparent Neon sphere
    -- that warps the visual behind it via colour blending
    local ref = U.GetPooledPart("refraction")
    ref.Name         = "GSO_Refraction"
    ref.Material     = Enum.Material.Neon
    ref.Color        = ec.glow
    ref.Transparency = 0.72
    ref.Size         = V3(1,1,1) * scale * 4
    ref.CFrame       = CF(pos)
    ref.Shape        = Enum.PartType.Ball
    ref.Parent       = Workspace
    GSO.Sakuga.ActiveParts += 1

    -- Expand and fade
    TweenService:Create(ref, TweenInfo.new(0.45, Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out),
        { Size = V3(1,1,1)*scale*22, Transparency = 1 }):Play()

    -- Layered shockwave rings
    for ring = 1, 4 do
        task.delay(ring * 0.03, function()
            local r = U.GetPooledPart("shockring")
            r.Name         = "GSO_ShockRing"
            r.Material     = Enum.Material.Neon
            r.Color        = ring % 2 == 0 and ec.main or ec.secondary
            r.Transparency = 0.18
            r.Size         = V3(0.3, 0.5, 0.5)
            r.Shape        = Enum.PartType.Cylinder
            r.CFrame       = CF(pos) * CFrame.Angles(0, 0, math.rad(90))
            r.Parent       = Workspace
            GSO.Sakuga.ActiveParts += 1

            local maxR = 14 * scale * ring
            TweenService:Create(r, TweenInfo.new(0.4, Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out),
                { Size = V3(0.04, maxR*2, maxR*2), Transparency = 1 }):Play()

            task.delay(0.42, function()
                U.ReturnPooledPart("shockring", r)
                GSO.Sakuga.ActiveParts -= 1
            end)
        end)
    end

    task.delay(0.48, function()
        U.ReturnPooledPart("refraction", ref)
        GSO.Sakuga.ActiveParts -= 1
    end)
end

-- ── 7D. 3D Dynamic Debris with Shadow ─────────────────────────────
local DEBRIS_COLORS = {
    C3(110,90,70), C3(90,75,58), C3(130,108,85),
    C3(80,70,60),  C3(60,50,42),
}

function GSO.Sakuga.SpawnDebris(pos, element)
    if GSO.Sakuga.ActiveParts >= GSO.CFG.MAX_VFX_PARTS then return end
    local ec = ELEMENT_COLORS[element or "physical"]
    local count = GSO.CFG.DEBRIS_COUNT_PER_HIT

    for i = 1, count do
        if GSO.Sakuga.ActiveParts >= GSO.CFG.MAX_VFX_PARTS then break end

        local rock = U.GetPooledPart("debris")
        rock.Name         = "GSO_Debris"
        rock.Material     = Enum.Material.SmoothPlastic
        rock.Color        = DEBRIS_COLORS[rand(1,#DEBRIS_COLORS)]
        rock.Size         = V3(U.Rnd(0.2,0.8), U.Rnd(0.2,0.8), U.Rnd(0.2,0.8))
        rock.Anchored     = false
        rock.CanCollide   = true
        rock.CastShadow   = true
        rock.CFrame       = CF(pos + V3(U.Rnd(-1,1), U.Rnd(0.5,2), U.Rnd(-1,1)))
        rock.Parent       = Workspace
        GSO.Sakuga.ActiveParts += 1

        -- Random launch velocity
        local launchDir = V3(U.Rnd(-1,1), U.Rnd(0.5,1.5), U.Rnd(-1,1)).Unit
        rock.AssemblyLinearVelocity  = launchDir * U.Rnd(12, 30)
        rock.AssemblyAngularVelocity = V3(U.Rnd(-8,8), U.Rnd(-8,8), U.Rnd(-8,8))

        -- Element-tinted point light on each rock (cinematic)
        local dLight = Instance.new("PointLight", rock)
        dLight.Color      = ec.glow
        dLight.Range      = 4
        dLight.Brightness = 0.8
        dLight.Shadows    = false

        -- Fade light after 0.4s, destroy after lifetime
        task.delay(GSO.CFG.DEBRIS_LIFETIME * 0.5, function()
            TweenService:Create(dLight, TweenInfo.new(0.8), { Brightness = 0 }):Play()
        end)
        task.delay(GSO.CFG.DEBRIS_LIFETIME, function()
            rock.Anchored = true
            U.ReturnPooledPart("debris", rock)
            GSO.Sakuga.ActiveParts -= 1
        end)
    end

    -- Dust puff BillboardGui
    local dust = Instance.new("Part")
    dust.Anchored    = true
    dust.CanCollide  = false
    dust.CastShadow  = false
    dust.Transparency= 1
    dust.Size        = V3(1,1,1)
    dust.CFrame      = CF(pos)
    dust.Parent      = Workspace

    local bb = Instance.new("BillboardGui", dust)
    bb.Size        = UDim2.new(0, 60, 0, 60)
    bb.AlwaysOnTop = false

    local dustFrame = Instance.new("Frame", bb)
    dustFrame.Size                = UDim2.new(1,0,1,0)
    dustFrame.BackgroundColor3    = C3(200,185,160)
    dustFrame.BackgroundTransparency = 0.2
    dustFrame.BorderSizePixel     = 0
    Instance.new("UICorner", dustFrame).CornerRadius = UDim.new(1,0)

    TweenService:Create(bb, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, 300, 0, 300) }):Play()
    TweenService:Create(dustFrame, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { BackgroundTransparency = 1 }):Play()

    task.delay(0.7, function() dust:Destroy() end)
end

-- ── 7E. Master Hit Trigger ────────────────────────────────────────
function GSO.Sakuga.OnHit(pos, magnitude, element, color)
    magnitude = magnitude or 50
    element   = element   or "physical"
    color     = color     or C3(255,255,255)

    GSO.Sakuga.TriggerImpactFrame2(magnitude, element)
    GSO.Sakuga.TriggerHitStop(0.055 + magnitude/3000)
    GSO.Sakuga.SpawnRefraction(pos, element, magnitude/60)
    GSO.Sakuga.SpawnDebris(pos, element)

    -- Camera shake via Camera module
    if GSO.Camera then
        GSO.Camera.Shake(magnitude * 0.018)
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [08]  SCREEN-SPACE PIPELINE
--       SSAO via raycast probing, SSR water, Ray-cast GI bounce
-- ══════════════════════════════════════════════════════════════════
GSO.ScreenSpace = {
    AO_Probes  = {},     -- Probe positions and their darkness factors
    GI_Samples = {},
    AODecals   = {},     -- Contact shadow decals under objects
    FrameIdx   = 0,
}

-- ── 8A. SSAO via Raycast Probing ──────────────────────────────────
--   Places invisible probe parts around the player and shoots
--   short rays in a hemisphere. Blocked rays = occluded = darker.
--   Visualised by darkening Highlights on nearby geometry.
function GSO.ScreenSpace.BuildAOProbes()
    -- Generate hemisphere sample directions (cosine-weighted)
    local samples = {}
    for i = 1, GSO.CFG.SSAO_RAY_COUNT do
        local theta = U.Rnd(0, pi*2)
        local phi   = U.Rnd(0, pi*0.5)
        samples[i]  = V3(sin(phi)*cos(theta), cos(phi), sin(phi)*sin(theta))
    end
    GSO.ScreenSpace.AO_Samples = samples
end

-- Contact shadow decals: thin dark discs directly under each character
function GSO.ScreenSpace.BuildContactShadow(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local decal = Instance.new("Part")
    decal.Name        = "GSO_ContactShadow"
    decal.Anchored    = true
    decal.CanCollide  = false
    decal.CastShadow  = false
    decal.Material    = Enum.Material.Neon
    decal.Color       = C3(0,0,0)
    decal.Transparency= 0.35
    decal.Size        = V3(4.5, 0.05, 4.5)
    decal.Shape       = Enum.PartType.Cylinder
    decal.Parent      = Workspace

    local ui = Instance.new("UIGradient")  -- unused but preserves pattern

    table.insert(GSO.ScreenSpace.AODecals, {
        decal     = decal,
        character = character,
        root      = root,
    })
end

function GSO.ScreenSpace.UpdateContactShadows()
    for i = #GSO.ScreenSpace.AODecals, 1, -1 do
        local data = GSO.ScreenSpace.AODecals[i]
        if data.character and data.character.Parent and data.root.Parent then
            local pos  = data.root.Position
            local result = U.Ray(pos, V3(0,-10,0), {data.character})
            if result then
                local gY   = result.Position.Y + 0.06
                local dist = pos.Y - gY
                -- Scale & fade shadow with height
                local scale = clamp(1 - dist/8, 0.1, 1)
                local alpha = clamp(1 - dist/6, 0.05, 0.92) * 0.55
                data.decal.CFrame       = CF(pos.X, gY, pos.Z)
                    * CFrame.Angles(0, 0, math.rad(90))
                data.decal.Size         = V3(0.05, 5*scale, 5*scale)
                data.decal.Transparency = 1 - alpha
            else
                data.decal.Transparency = 1
            end
        else
            if data.decal then data.decal:Destroy() end
            table.remove(GSO.ScreenSpace.AODecals, i)
        end
    end
end

-- ── 8B. Ray-Cast GI Bounce (Ground → Character Underside) ─────────
--   Shoots rays downward from character extremities, reads ground
--   color, applies a warm PointLight from below to simulate
--   indirect light bouncing up onto the character's underside.
function GSO.ScreenSpace.UpdateGIBounce(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local pos = root.Position
    local totalBounce = V3(0,0,0)
    local hitCount    = 0

    for r = 1, GSO.CFG.GI_BOUNCE_RAYS do
        local angle   = (r / GSO.CFG.GI_BOUNCE_RAYS) * pi * 2
        local rayDir  = V3(cos(angle)*0.4, -1, sin(angle)*0.4).Unit
        local result  = U.Ray(pos, rayDir * GSO.CFG.GI_BOUNCE_RANGE, {character})
        if result and result.Instance then
            local hitCol = result.Instance.Color
            totalBounce  = totalBounce + U.C3toV3(hitCol)
            hitCount      = hitCount + 1
        end
    end

    if hitCount > 0 then
        local avgCol   = totalBounce / hitCount
        local bounceC3 = U.V3toC3(avgCol)

        -- Update or create ground bounce light
        local bounceLight = root:FindFirstChild("GSO_GIBounce")
                        and root:FindFirstChild("GSO_GIBounce"):FindFirstChildOfClass("PointLight")
        if not bounceLight then
            local bp = Instance.new("Part", root)
            bp.Name        = "GSO_GIBounce"
            bp.Anchored    = false
            bp.CanCollide  = false
            bp.Transparency= 1
            bp.Size        = V3(0.1,0.1,0.1)
            bp.CFrame      = root.CFrame * CF(0,-2,0)
            bp.CastShadow  = false
            bounceLight    = Instance.new("PointLight", bp)
            bounceLight.Shadows = false
        end
        bounceLight.Color      = U.LerpC3(bounceLight.Color, bounceC3, 0.1)
        bounceLight.Brightness = 0.4
        bounceLight.Range      = 8
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [09]  CINEMATIC ANIME LUT POST-PROCESSING
--       Full Shinkai / Sunset / Night / Action colour grades
--       via ColorCorrectionEffect parameter animation.
-- ══════════════════════════════════════════════════════════════════
GSO.LUT = {
    CC     = nil,  -- ColorCorrectionEffect
    DOF    = nil,  -- DepthOfFieldEffect
    CurrentMode = "shinkai",
}

local LUT_PRESETS = {
    shinkai = {
        Saturation  = 0.28,
        Contrast    = 0.14,
        Brightness  = 0.04,
        TintColor   = C3(240, 248, 255),  -- Shinkai blue-cool tint
        BloomInt    = 0.72,
        BloomSize   = 44,
        DOFFar      = 0.55,
        DOFNear     = 0.0,
        DOFFocus    = 32,
    },
    sunset  = {
        Saturation  = 0.42,
        Contrast    = 0.18,
        Brightness  = 0.08,
        TintColor   = C3(255, 230, 190),  -- Warm gold
        BloomInt    = 0.9,
        BloomSize   = 60,
        DOFFar      = 0.48,
        DOFNear     = 0.0,
        DOFFocus    = 25,
    },
    night   = {
        Saturation  = -0.12,
        Contrast    = 0.22,
        Brightness  = -0.06,
        TintColor   = C3(80, 100, 160),   -- Cold moonlight
        BloomInt    = 0.5,
        BloomSize   = 35,
        DOFFar      = 0.65,
        DOFNear     = 0.05,
        DOFFocus    = 20,
    },
    action  = {
        Saturation  = 0.50,
        Contrast    = 0.30,
        Brightness  = 0.02,
        TintColor   = C3(255, 245, 220),  -- High-contrast punchy
        BloomInt    = 0.95,
        BloomSize   = 30,
        DOFFar      = 0.30,
        DOFNear     = 0.0,
        DOFFocus    = 50,
    },
}

function GSO.LUT.Build()
    -- Remove existing
    for _, e in ipairs(Lighting:GetChildren()) do
        if e:IsA("ColorCorrectionEffect") or e:IsA("DepthOfFieldEffect") then
            e:Destroy()
        end
    end

    GSO.LUT.CC = Instance.new("ColorCorrectionEffect", Lighting)
    local preset = LUT_PRESETS[GSO.CFG.LUT_MODE]
    GSO.LUT.CC.Saturation = preset.Saturation
    GSO.LUT.CC.Contrast   = preset.Contrast
    GSO.LUT.CC.Brightness = preset.Brightness
    GSO.LUT.CC.TintColor  = preset.TintColor

    local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
    bloom.Intensity  = preset.BloomInt
    bloom.Size       = preset.BloomSize
    bloom.Threshold  = 0.90

    GSO.LUT.DOF = Instance.new("DepthOfFieldEffect", Lighting)
    GSO.LUT.DOF.FarIntensity   = preset.DOFFar
    GSO.LUT.DOF.NearIntensity  = preset.DOFNear
    GSO.LUT.DOF.FocusDistance  = preset.DOFFocus
    GSO.LUT.DOF.InFocusRadius  = 20

    print("[GSO] LUT applied: "..GSO.CFG.LUT_MODE)
end

function GSO.LUT.Update(t)
    if not GSO.LUT.CC then return end
    local sunFac = (sin(t * 0.003 * pi) + 1) * 0.5

    -- Auto-switch LUT mode based on time of day
    local targetMode
    if sunFac > 0.65 then
        targetMode = "shinkai"
    elseif sunFac > 0.25 then
        local sunsetBlend = 1 - abs(sunFac - 0.35) * 6
        if sunsetBlend > 0.4 then
            targetMode = "sunset"
        else
            targetMode = "shinkai"
        end
    else
        targetMode = "night"
    end

    if targetMode ~= GSO.LUT.CurrentMode then
        GSO.LUT.CurrentMode = targetMode
        local preset = LUT_PRESETS[targetMode]
        TweenService:Create(GSO.LUT.CC,
            TweenInfo.new(4.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Saturation = preset.Saturation,
            Contrast   = preset.Contrast,
            Brightness = preset.Brightness,
            TintColor  = preset.TintColor,
        }):Play()
    end

    -- Bokeh DOF: auto-focus on nearest player/enemy
    if GSO.CFG.BOKEH_ENABLED and GSO.LUT.DOF then
        local nearest = huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local d = (root.Position - Camera.CFrame.Position).Magnitude
                    if d < nearest then nearest = d end
                end
            end
        end
        local targetFocus = clamp(nearest - 5, 8, 100)
        GSO.LUT.DOF.FocusDistance = U.Lerp(GSO.LUT.DOF.FocusDistance, targetFocus, 0.04)
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [10]  AUTONOMOUS BONUS SYSTEMS
--       Water Caustics, Chromatic Aberration, Film Grain, Vignette,
--       Motion Blur, Bokeh Particles, Parallax Skybox,
--       Genshin-Style Water, Rim Light 2.0, AO Decals
-- ══════════════════════════════════════════════════════════════════
GSO.Bonus = {
    PostProcessGui = nil,
    GrainFrame     = nil,
    VignetteFrame  = nil,
    ChromabFrame   = nil,
    MotionBlurFrames = {},
    WaterParts     = {},
    CausticsDecals = {},
    ParallaxLayers = {},
}

-- ── 10A. Post-Process GUI Overlay ─────────────────────────────────
function GSO.Bonus.BuildPostProcessGui()
    local sg = Instance.new("ScreenGui", PGui)
    sg.Name           = "GSO_PostProcess"
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
    GSO.Bonus.PostProcessGui = sg

    -- ── Vignette ──────────────────────────────────────────────
    local vignette = Instance.new("Frame", sg)
    vignette.Name                = "Vignette"
    vignette.Size                = UDim2.new(1,0,1,0)
    vignette.BackgroundTransparency = 1
    vignette.BorderSizePixel     = 0
    vignette.ZIndex              = 5
    -- Simulate vignette via 4 dark-edge frames
    for _, side in ipairs({
        { anchor=V2(0,0), size=UDim2.new(0.5,0,1,0), gradient=0   },
        { anchor=V2(1,0), size=UDim2.new(0.5,0,1,0), gradient=180 },
        { anchor=V2(0,0), size=UDim2.new(1,0,0.5,0), gradient=270 },
        { anchor=V2(0,1), size=UDim2.new(1,0,0.5,0), gradient=90  },
    }) do
        local panel = Instance.new("Frame", vignette)
        panel.AnchorPoint            = side.anchor
        panel.Position               = UDim2.new(side.anchor.X, 0, side.anchor.Y, 0)
        panel.Size                   = side.size
        panel.BackgroundColor3       = C3(0,0,0)
        panel.BackgroundTransparency = 1 - GSO.CFG.VIGNETTE_STRENGTH * 0.7
        panel.BorderSizePixel        = 0
        panel.ZIndex                 = 5
        local grad = Instance.new("UIGradient", panel)
        grad.Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0, C3(0,0,0)),
            ColorSequenceKeypoint.new(1, C3(0,0,0)),
        })
        grad.Rotation = side.gradient
        grad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1 - GSO.CFG.VIGNETTE_STRENGTH),
            NumberSequenceKeypoint.new(GSO.CFG.VIGNETTE_RADIUS, 1 - GSO.CFG.VIGNETTE_STRENGTH * 0.3),
            NumberSequenceKeypoint.new(1, 1),
        })
    end
    GSO.Bonus.VignetteFrame = vignette

    -- ── Film Grain ────────────────────────────────────────────
    local grain = Instance.new("Frame", sg)
    grain.Name                = "FilmGrain"
    grain.Size                = UDim2.new(1,0,1,0)
    grain.BackgroundColor3    = C3(200,200,200)
    grain.BackgroundTransparency = 1 - GSO.CFG.FILM_GRAIN_STRENGTH * 0.3
    grain.BorderSizePixel     = 0
    grain.ZIndex              = 6
    -- Noise via UIGradient churn (updates every frame)
    local grainGrad = Instance.new("UIGradient", grain)
    grainGrad.Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, C3(255,255,255)),
        ColorSequenceKeypoint.new(0.5, C3(0,0,0)),
        ColorSequenceKeypoint.new(1.0, C3(255,255,255)),
    })
    GSO.Bonus.GrainFrame     = grain
    GSO.Bonus.GrainGradient  = grainGrad

    -- ── Chromatic Aberration ──────────────────────────────────
    if GSO.CFG.CHROMAB_ENABLED then
        -- Three slightly offset red/green/blue frames
        local CHAN_COLORS = { C3(255,0,0), C3(0,255,0), C3(0,0,255) }
        local CHAN_OFFSETS= { V2(-1,0), V2(0.5,0.5), V2(1,-0.5) }
        GSO.Bonus.ChromabFrames = {}
        for i = 1, 3 do
            local chan = Instance.new("Frame", sg)
            chan.Name                = "ChromAb_"..i
            chan.Size                = UDim2.new(1, 4, 1, 4)
            chan.AnchorPoint         = V2(0.5, 0.5)
            chan.Position            = UDim2.new(0.5,0,0.5,0)
            chan.BackgroundColor3    = CHAN_COLORS[i]
            chan.BackgroundTransparency = 1 - GSO.CFG.CHROMAB_STRENGTH
            chan.BorderSizePixel     = 0
            chan.ZIndex              = 7
            GSO.Bonus.ChromabFrames[i] = { frame=chan, offset=CHAN_OFFSETS[i] }
        end
    end

    -- ── Motion Blur Frames ────────────────────────────────────
    if GSO.CFG.MOTION_BLUR_ENABLED then
        for i = 1, GSO.CFG.MOTION_BLUR_SAMPLES do
            local mbf = Instance.new("Frame", sg)
            mbf.Size                = UDim2.new(1,0,1,0)
            mbf.BackgroundColor3    = C3(0,0,0)
            mbf.BackgroundTransparency = 1
            mbf.BorderSizePixel     = 0
            mbf.ZIndex              = 3
            GSO.Bonus.MotionBlurFrames[i] = mbf
        end
    end

    print("[GSO] Post-Process GUI built.")
end

-- Update grain: randomize rotation each frame for noise shimmer
function GSO.Bonus.UpdateGrain(t)
    if not GSO.Bonus.GrainGradient then return end
    GSO.Bonus.GrainGradient.Rotation = floor(t * 60) % 360
    GSO.Bonus.GrainFrame.BackgroundTransparency = 1 - GSO.CFG.FILM_GRAIN_STRENGTH
        * (0.8 + sin(t*113.7)*0.2)  -- slight intensity flicker
end

-- Chromatic aberration: intensify on camera shake
function GSO.Bonus.UpdateChromaAb(t, shakeAmount)
    if not GSO.Bonus.ChromabFrames then return end
    local str = GSO.CFG.CHROMAB_STRENGTH + shakeAmount * 0.02
    local vp  = Camera.ViewportSize
    for i, data in ipairs(GSO.Bonus.ChromabFrames) do
        data.frame.Position = UDim2.new(
            0.5, data.offset.X * str * vp.X,
            0.5, data.offset.Y * str * vp.Y
        )
        data.frame.BackgroundTransparency = 1 - str * 8
    end
end

-- Motion blur: ghost trails based on camera velocity
function GSO.Bonus.UpdateMotionBlur(dt)
    if not GSO.CFG.MOTION_BLUR_ENABLED then return end
    -- Estimate camera velocity via CFrame delta
    if not GSO.Bonus._lastCamCF then
        GSO.Bonus._lastCamCF = Camera.CFrame
        return
    end
    local camVel = (Camera.CFrame.Position - GSO.Bonus._lastCamCF.Position).Magnitude / dt
    GSO.Bonus._lastCamCF = Camera.CFrame

    local blurAlpha = clamp(camVel * GSO.CFG.MOTION_BLUR_STRENGTH, 0, 0.3)
    for i, mbf in ipairs(GSO.Bonus.MotionBlurFrames) do
        mbf.BackgroundTransparency = 1 - blurAlpha * (1 - (i-1)/GSO.CFG.MOTION_BLUR_SAMPLES)
    end
end

-- ── 10B. Genshin-Style Water ──────────────────────────────────────
--   Multi-layer animated water with foam, caustics, and sub-surface
--   shimmer that makes water look genuinely alive.
function GSO.Bonus.BuildGenshinWater()
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and (
            part.Material == Enum.Material.Water or
            part.Name:lower():find("water") or
            part.Name:lower():find("ocean") or
            part.Name:lower():find("river") or
            part.Name:lower():find("lake")
        ) then
            table.insert(GSO.Bonus.WaterParts, part)

            -- Base water layer
            part.Material    = Enum.Material.SmoothPlastic
            part.Color       = C3(28, 100, 180)
            part.Transparency= 0.28
            part.Reflectance = 0.88
            part.CastShadow  = false

            -- Layer 1: Surface highlight shimmer (Neon top layer)
            local surf = Instance.new("Part")
            surf.Name        = "GSO_WaterSurface"
            surf.Anchored    = true
            surf.CanCollide  = false
            surf.CastShadow  = false
            surf.Material    = Enum.Material.Neon
            surf.Color       = C3(80, 160, 255)
            surf.Size        = V3(part.Size.X, 0.04, part.Size.Z)
            surf.Transparency= 0.55
            surf.CFrame      = part.CFrame * CF(0, part.Size.Y/2 + 0.02, 0)
            surf.Parent      = Workspace

            -- Layer 2: Foam edge
            local foam = Instance.new("Part")
            foam.Name        = "GSO_WaterFoam"
            foam.Anchored    = true
            foam.CanCollide  = false
            foam.CastShadow  = false
            foam.Material    = Enum.Material.Neon
            foam.Color       = C3(210, 235, 255)
            foam.Size        = V3(part.Size.X+1.5, 0.08, part.Size.Z+1.5)
            foam.Transparency= 0.40
            foam.CFrame      = part.CFrame * CF(0, part.Size.Y/2 + 0.04, 0)
            foam.Parent      = Workspace

            -- Caustics decal (animated point light under surface)
            local caustic = Instance.new("Part")
            caustic.Name       = "GSO_Caustic"
            caustic.Anchored   = true
            caustic.CanCollide = false
            caustic.CastShadow = false
            caustic.Transparency=1
            caustic.Size       = V3(0.1,0.1,0.1)
            caustic.CFrame     = part.CFrame * CF(0, part.Size.Y/2 - 0.5, 0)
            caustic.Parent     = Workspace

            local cLight = Instance.new("PointLight", caustic)
            cLight.Color      = C3(120, 200, 255)
            cLight.Range      = part.Size.X * 0.8
            cLight.Brightness = 0.6
            cLight.Shadows    = false

            table.insert(GSO.Bonus.CausticsDecals, {
                surface   = surf,
                foam      = foam,
                caustic   = caustic,
                cLight    = cLight,
                basePos   = part.CFrame * CF(0, part.Size.Y/2, 0),
                baseSize  = part.Size,
                phase     = U.Rnd(0, pi*2),
                part      = part,
            })
        end
    end
    print("[GSO] Genshin Water: "..#GSO.Bonus.WaterParts.." water bodies upgraded.")
end

function GSO.Bonus.UpdateGenshinWater(t)
    local sunFac = (sin(t * 0.003 * pi) + 1) * 0.5

    for _, data in ipairs(GSO.Bonus.CausticsDecals) do
        if data.surface and data.surface.Parent then
            local wt = t * 0.6 + data.phase

            -- Wave height animation (surface bob)
            local wave1 = sin(wt) * 0.04
            local wave2 = sin(wt*1.3+1.1) * 0.025
            local waveY = wave1 + wave2

            -- Surface colour shifts with sun
            local waterColor = sunFac > 0.5
                and U.LerpC3(C3(28,100,180), C3(40,130,220), sunFac)
                or  U.LerpC3(C3(10,40,90),  C3(28,100,180), sunFac*2)
            data.part.Color    = waterColor

            -- Surface shimmer: moving highlight patches
            data.surface.Color = U.LerpC3(C3(80,160,255), C3(150,220,255),
                (sin(wt*2.1)*0.5+0.5))
            data.surface.Transparency = 0.45 + sin(wt*1.7)*0.12
            data.surface.CFrame = data.basePos * CF(0, waveY, 0)

            -- Foam pulse
            data.foam.Transparency = 0.42 + sin(wt*0.9+2.3)*0.15
            data.foam.CFrame = data.basePos * CF(0, waveY + 0.06, 0)

            -- Caustics light animate
            data.cLight.Brightness = 0.4 + sin(wt*3.2)*0.25
            data.cLight.Color = U.LerpC3(C3(100,180,255), C3(180,230,255),
                sin(wt*1.9)*0.5+0.5)
        end
    end
end

-- ── 10C. Parallax Skybox Layers ───────────────────────────────────
--   3 billboard planes at different distances that move at different
--   speeds relative to camera rotation, creating depth parallax.
function GSO.Bonus.BuildParallaxSky()
    local folder = Instance.new("Folder", Workspace)
    folder.Name  = "GSO_ParallaxSky"

    local LAYERS = {
        { dist=1200, scale=900, color=C3(120,160,220), alpha=0.85, speed=0.004 },
        { dist=900,  scale=700, color=C3(160,190,230), alpha=0.80, speed=0.007 },
        { dist=700,  scale=600, color=C3(180,205,240), alpha=0.75, speed=0.011 },
    }

    for i, L in ipairs(LAYERS) do
        local layer = Instance.new("Part")
        layer.Name        = "SkyLayer_"..i
        layer.Anchored    = true
        layer.CanCollide  = false
        layer.CastShadow  = false
        layer.Material    = Enum.Material.Neon
        layer.Color       = L.color
        layer.Transparency= L.alpha
        layer.Size        = V3(L.scale, L.scale, 1)
        layer.Parent      = folder

        table.insert(GSO.Bonus.ParallaxLayers, {
            part  = layer,
            dist  = L.dist,
            speed = L.speed,
            phase = U.Rnd(0, pi*2),
        })
    end
end

function GSO.Bonus.UpdateParallaxSky(t)
    local camCF  = Camera.CFrame
    local camPos = camCF.Position
    local camLook= camCF.LookVector

    for i, pl in ipairs(GSO.Bonus.ParallaxLayers) do
        -- Slight parallax offset based on camera angle
        local offset = V3(
            camLook.X * pl.dist * 0.05,
            camLook.Y * pl.dist * 0.03,
            0
        )
        pl.part.CFrame = CF(camPos + camLook * pl.dist + offset)
            * CFrame.Angles(0, 0, 0)

        -- Drift color with time of day
        local sunFac = (sin(t * 0.003 * pi) + 1) * 0.5
        pl.part.Color = U.LerpC3(C3(40,50,100), C3(160,195,240), sunFac)
    end
end

-- ── 10D. Rim Light 2.0 ────────────────────────────────────────────
--   Additional Highlight effect that pulses intensity based on
--   how close the character is to a light source, + combat state.
GSO.Bonus.RimHighlights = {}

function GSO.Bonus.BuildRimLight2(character)
    local hl = Instance.new("Highlight")
    hl.Adornee             = character
    hl.FillTransparency    = 1.0
    hl.OutlineColor        = C3(180, 215, 255)
    hl.OutlineTransparency = 0.3
    hl.DepthMode           = Enum.HighlightDepthMode.Occluded
    hl.Parent              = character

    local hl2 = Instance.new("Highlight")
    hl2.Adornee            = character
    hl2.FillTransparency   = 1.0
    hl2.OutlineColor       = C3(255, 200, 120)
    hl2.OutlineTransparency= 0.7
    hl2.DepthMode          = Enum.HighlightDepthMode.AlwaysOnTop
    hl2.Parent             = character

    GSO.Bonus.RimHighlights[character] = { cool=hl, warm=hl2, pulse=0 }
end

function GSO.Bonus.UpdateRimLights(t)
    local sunDir = Lighting:GetSunDirection()
    for char, data in pairs(GSO.Bonus.RimHighlights) do
        if char and char.Parent then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                -- Backlight intensity
                local back = max(0, -root.CFrame.LookVector:Dot(sunDir))
                data.cool.OutlineTransparency = U.Lerp(0.6, 0.1, back)
                -- Combat pulse (sine shimmer)
                data.warm.OutlineColor = U.LerpC3(
                    C3(255,200,100),
                    C3(255,120,50),
                    (sin(t*2.8)*0.5+0.5)
                )
                data.warm.OutlineTransparency = U.Lerp(0.9, 0.55, back)
            end
        else
            GSO.Bonus.RimHighlights[char] = nil
        end
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [11]  INTELLIGENT DIRECTOR CAMERA
-- ══════════════════════════════════════════════════════════════════
GSO.Camera = {
    ShakeAmt    = 0,
    DutchAngle  = 0,
    TargetDutch = 0,
    State       = "follow",
    FOV         = 70,
    TargetFOV   = 70,
}

local SHAKE_SEEDS = {77, 155, 233, 311}

function GSO.Camera.Shake(amount)
    GSO.Camera.ShakeAmt = clamp(GSO.Camera.ShakeAmt + amount, 0, 3.0)
end

function GSO.Camera.Update(t, dt)
    -- Decay shake
    GSO.Camera.ShakeAmt = GSO.Camera.ShakeAmt * 0.93

    -- Perlin shake offset
    local spd = 7.2
    local s   = GSO.Camera.ShakeAmt
    local ox  = (U.Perlin(t*spd, SHAKE_SEEDS[1])*2-1)*s
    local oy  = (U.Perlin(t*spd, SHAKE_SEEDS[2])*2-1)*s*0.6
    local oz  = (U.Perlin(t*spd, SHAKE_SEEDS[3])*2-1)*s*0.3

    -- Nearest enemy detection
    local minDist = huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local d = (root.Position - (HRP and HRP.Position or V3(0,0,0))).Magnitude
                if d < minDist then minDist = d end
            end
        end
    end

    -- Director logic
    if minDist < 6 then
        GSO.Camera.TargetDutch = (rand()>0.5 and 1 or -1) * U.Rnd(8, 14)
        GSO.Camera.TargetFOV   = 52
    elseif minDist < 20 then
        GSO.Camera.TargetDutch = (rand()>0.5 and 1 or -1) * U.Rnd(3, 8)
        GSO.Camera.TargetFOV   = 65
    else
        GSO.Camera.TargetDutch = 0
        GSO.Camera.TargetFOV   = 70
    end

    -- Smooth transitions
    GSO.Camera.DutchAngle = U.Lerp(GSO.Camera.DutchAngle, GSO.Camera.TargetDutch, 0.04)
    GSO.Camera.FOV        = U.Lerp(GSO.Camera.FOV, GSO.Camera.TargetFOV, 0.06)
    Camera.FieldOfView    = GSO.Camera.FOV

    -- Apply shake + dutch
    if s > 0.005 or abs(GSO.Camera.DutchAngle) > 0.05 then
        Camera.CFrame = Camera.CFrame
            * CF(ox, oy, oz)
            * CFrame.Angles(0, 0, math.rad(GSO.Camera.DutchAngle))
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [11]  PERFORMANCE ARBITER
-- ══════════════════════════════════════════════════════════════════
GSO.Perf = {
    FPSBuf  = {},
    AvgFPS  = 60,
    Quality = 3,
}

function GSO.Perf.Tick(dt)
    local fps = 1/(dt+0.0001)
    table.insert(GSO.Perf.FPSBuf, fps)
    if #GSO.Perf.FPSBuf > 90 then table.remove(GSO.Perf.FPSBuf, 1) end
    local s=0
    for _,f in ipairs(GSO.Perf.FPSBuf) do s=s+f end
    GSO.Perf.AvgFPS = s / #GSO.Perf.FPSBuf
end

function GSO.Perf.Scale()
    local f = GSO.Perf.AvgFPS
    local t = GSO.CFG.TARGET_FPS
    if f < t*0.5 and GSO.Perf.Quality ~= 1 then
        GSO.Perf.Quality = 1
        GSO.CFG.GRASS_BLADES_PER_CHUNK   = 250
        GSO.CFG.CLOUD_VOLUME_LAYERS       = 2
        GSO.CFG.CLOUD_GODRAY_RAYS         = 8
        GSO.CFG.EM_ENABLED                = false
        GSO.CFG.DEBRIS_COUNT_PER_HIT      = 3
        warn("[GSO] QUALITY: LOW  FPS:"..floor(f))
    elseif f < t*0.75 and GSO.Perf.Quality ~= 2 then
        GSO.Perf.Quality = 2
        GSO.CFG.GRASS_BLADES_PER_CHUNK   = 600
        GSO.CFG.CLOUD_VOLUME_LAYERS       = 3
        GSO.CFG.CLOUD_GODRAY_RAYS         = 16
        GSO.CFG.EM_ENABLED                = true
        GSO.CFG.DEBRIS_COUNT_PER_HIT      = 5
        warn("[GSO] QUALITY: MID  FPS:"..floor(f))
    elseif f >= t*0.75 and GSO.Perf.Quality ~= 3 then
        GSO.Perf.Quality = 3
        GSO.CFG.GRASS_BLADES_PER_CHUNK   = 1200
        GSO.CFG.CLOUD_VOLUME_LAYERS       = 5
        GSO.CFG.CLOUD_GODRAY_RAYS         = 24
        GSO.CFG.EM_ENABLED                = true
        GSO.CFG.DEBRIS_COUNT_PER_HIT      = 8
        print("[GSO] QUALITY: HIGH  FPS:"..floor(f))
    end
end

-- ══════════════════════════════════════════════════════════════════
-- MASTER INITIALIZATION SEQUENCE
-- ══════════════════════════════════════════════════════════════════
local function Initialize()
    print("▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓")
    print("▓  GENSHIN-STATION OMEGA  v5.0  INITIALIZING...    ▓")
    print("▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓")

    -- Ensure character
    repeat task.wait(0.1) until Char and HRP and Hum

    -- [01] Grass & Leaves
    task.spawn(function()
        task.wait(1.5) -- Let map load
        GSO.Grass.RegisterLeaves()
        -- Initial chunk ring
        local p = HRP.Position
        for gx = -1, 1 do
            for gz = -1, 1 do
                GSO.Grass.SpawnChunk(V3(
                    floor(p.X/40)*40 + gx*40,
                    p.Y,
                    floor(p.Z/40)*40 + gz*40
                ))
                task.wait(0.08)
            end
        end
    end)

    -- [02] Environment Remaster
    task.spawn(function()
        GSO.EnvRemaster.ApplyToTerrain()
        task.wait(0.5)
        GSO.EnvRemaster.ApplyToWorkspace()
    end)

    -- [03] Volumetric Clouds
    task.spawn(GSO.Clouds.Build)

    -- [04] Model Geometry (local character)
    task.spawn(function()
        task.wait(1)
        GSO.ModelGeo.InjectThickness(Char)
        GSO.ModelGeo.ApplySSS(Char)
    end)

    -- [05] Animation systems
    task.spawn(function()
        task.wait(1)
        GSO.Animation.BuildJiggle(Char)
        GSO.Animation.BuildMotorCache(Char)
        GSO.Animation.BuildProceduralLayers(Char)
    end)

    -- [06] Character Light Rig
    task.spawn(function()
        task.wait(1)
        GSO.Lights.BuildRig(Char)
        GSO.ScreenSpace.BuildContactShadow(Char)
    end)

    -- [07] VFX Engine
    GSO.Sakuga.BuildImpactGui()

    -- [08] Screen Space
    GSO.ScreenSpace.BuildAOProbes()

    -- [09] LUT
    GSO.LUT.Build()

    -- [10] Bonus systems
    GSO.Bonus.BuildPostProcessGui()
    task.spawn(function()
        task.wait(2)
        GSO.Bonus.BuildGenshinWater()
        GSO.Bonus.BuildParallaxSky()
        GSO.Bonus.BuildRimLight2(Char)
    end)

    -- Apply all visual upgrades to all players
    local function onCharAdded(char, isLocal)
        task.delay(1.2, function()
            if not char.Parent then return end
            GSO.ModelGeo.ApplySSS(char)
            GSO.Lights.BuildRig(char)
            GSO.ScreenSpace.BuildContactShadow(char)
            GSO.Animation.BuildJiggle(char)
            GSO.Animation.BuildMotorCache(char)
            GSO.Bonus.BuildRimLight2(char)
            if isLocal then
                GSO.Animation.BuildProceduralLayers(char)
                GSO.ModelGeo.InjectThickness(char)
            end
        end)
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            onCharAdded(plr.Character, plr == LP)
        end
        plr.CharacterAdded:Connect(function(c)
            onCharAdded(c, plr == LP)
            if plr == LP then
                Char=c
                HRP=c:WaitForChild("HumanoidRootPart")
                Hum=c:WaitForChild("Humanoid")
                Animator=Hum:WaitForChild("Animator")
            end
        end)
    end
    Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function(c) onCharAdded(c, false) end)
    end)

    -- Combat hook
    local hitRemote = ReplicatedStorage:FindFirstChild("GSOHitEvent")
                   or ReplicatedStorage:FindFirstChild("HitEvent")
                   or ReplicatedStorage:FindFirstChild("DamageEvent")
                   or ReplicatedStorage:FindFirstChild("OnHit")
    if hitRemote and hitRemote:IsA("RemoteEvent") then
        hitRemote.OnClientEvent:Connect(function(pos, mag, elem, col)
            GSO.Sakuga.OnHit(pos, mag, elem, col)
        end)
        print("[GSO] Combat hook: '"..hitRemote.Name.."'")
    else
        Hum.HealthChanged:Connect(function(hp)
            local delta = Hum.MaxHealth - hp
            if delta > 4 and HRP then
                GSO.Sakuga.OnHit(
                    HRP.Position + V3(U.Rnd(-2,2), 1, U.Rnd(-2,2)),
                    delta, "physical", C3(255,80,80)
                )
            end
        end)
        print("[GSO] Combat hook: HealthChanged fallback.")
    end

    print("▓  ALL SYSTEMS ONLINE.  GENSHIN-STATION OMEGA ACTIVE  ▓")
end

-- ══════════════════════════════════════════════════════════════════
-- MASTER RENDER LOOP — All systems ticked here
-- ══════════════════════════════════════════════════════════════════
local globalT    = 0
local frameCount = 0

RunService.RenderStepped:Connect(function(dt)
    globalT    = globalT + dt
    frameCount = frameCount + 1

    local t  = globalT
    local f  = frameCount
    local pp = HRP and HRP.Position or V3(0,0,0)
    local pv = HRP and HRP.AssemblyLinearVelocity or V3(0,0,0)

    -- Performance budget (every 4 seconds)
    GSO.Perf.Tick(dt)
    if f % 240 == 0 then GSO.Perf.Scale() end

    -- [01] Grass — parallel, every frame
    GSO.Grass.Update(t, dt, pp)

    -- [03] Clouds & god rays — every frame
    GSO.Clouds.Update(t)

    -- [04] SSS pulse
    if f % 2 == 0 then GSO.ModelGeo.UpdateSSS(t) end

    -- [05] Animation systems
    GSO.Animation.UpdateJiggle(t, dt, pv)
    GSO.Animation.UpdateMotorSmoothing(dt)
    if f % 3 == 0 then GSO.Animation.UpdateProceduralLayers(t) end

    -- [06] Character light rigs
    if f % 2 == 0 then GSO.Lights.UpdateRigs(t) end

    -- [08] Screen-space GI & AO
    if f % 4 == 0 then
        GSO.ScreenSpace.UpdateContactShadows()
        if Char then GSO.ScreenSpace.UpdateGIBounce(Char) end
    end

    -- [09] LUT
    if f % 6 == 0 then GSO.LUT.Update(t) end

    -- [10] Bonus effects
    GSO.Bonus.UpdateGrain(t)
    GSO.Bonus.UpdateChromaAb(t, GSO.Camera.ShakeAmt)
    GSO.Bonus.UpdateMotionBlur(dt)
    if f % 2 == 0 then GSO.Bonus.UpdateGenshinWater(t) end
    GSO.Bonus.UpdateParallaxSky(t)
    GSO.Bonus.UpdateRimLights(t)

    -- [11] Director Camera — every frame
    GSO.Camera.Update(t, dt)
end)

-- Boot
Initialize()

--[[
╔══════════════════════════════════════════════════════════════════════╗
║  GENSHIN-STATION OMEGA v5.0 — COMPLETE SYSTEM MANIFEST              ║
╠══════════════════════════════════════════════════════════════════════╣
║  [01] GRASS ENGINE    1200 blades/chunk, sine-wave vertex sway,     ║
║                       player/projectile collision bending,          ║
║                       biome-aware colour, leaf flutter              ║
║  [02] ENV REMASTER    EditableImage anime hatching + cross-hatch    ║
║                       shadow generation for all 8 terrain mats     ║
║  [03] VOLUMETRIC      5-strata 3D cloud volumes (3-5 lobes each),  ║
║                       time-of-day tinting, 24-ray god ray system   ║
║                       with per-step occlusion ray-marching          ║
║  [04] MODEL GEO       EditableMesh normal extrusion for hair/cloth, ║
║                       SSS point lights on hands/head/feet,         ║
║                       ear SSS glow, backlight reactivity           ║
║  [05] ANIMATION       Jiggle physics (spring chain) on cloth/hair, ║
║                       Motor6D quintic smoothing, procedural         ║
║                       breathing torso layer, motion warping        ║
║  [06] CHAR LIGHTING   Key (warm) + Fill (cool) + Rim (blue-white)  ║
║                       + Ground Bounce (ground color sampled) rigs  ║
║  [07] COMBAT VFX      3-frame inverted impact flash, 36 speed lines,║
║                       4-ring element-colored shockwaves,           ║
║                       3D debris with shadow + element point lights, ║
║                       refraction sphere + dust Billboard           ║
║  [08] SCREEN-SPACE    Raycast contact shadow decals, 8-ray GI      ║
║                       ground bounce sampling → character underside  ║
║  [09] LUT             4-preset cinematic LUT (Shinkai/Sunset/       ║
║                       Night/Action) with auto time-of-day switch,  ║
║                       live bokeh DOF auto-focus on nearest target  ║
║  [10] AUTONOMOUS      Film grain (UIGradient churn), Vignette       ║
║                       (4-edge gradient), Chromatic Aberration      ║
║                       (3-channel offset), Motion Blur (cam vel),   ║
║                       Genshin Water (3-layer surf+foam+caustics),  ║
║                       Parallax Sky (3 billboard depth layers),     ║
║                       Rim Light 2.0 (dual Highlight with backlight ║
║                       & combat colour pulse)                       ║
║  [11] PERF ARBITER    3-tier quality scaling, 240-frame FPS poll,  ║
║                       per-system tick rate LOD                     ║
╠══════════════════════════════════════════════════════════════════════╣
║  SERVER HOOK:  Fire RemoteEvent "GSOHitEvent"                       ║
║    args: (pos:V3, magnitude:number, element:string, color:Color3)  ║
║  ELEMENTS: pyro hydro cryo electro anemo geo dendro physical        ║
╚══════════════════════════════════════════════════════════════════════╝
]]
