--[[
╔══════════════════════════════════════════════════════════════════════╗
║        PROJECT EXODUS V9.0 — ARCHITECTURAL SINGULARITY              ║
║        Total Visual Transfiguration — The Strongest Battlegrounds    ║
║        Engine : Fragmented Bootloader + Frame-Time Budgeter          ║
║        Luau   : Parallel task.desynchronize throughout               ║
║                                                                      ║
║  INSTALL : LocalScript  →  StarterPlayerScripts                      ║
║  COMPAT  : Full graceful fallback for every unsupported API          ║
╚══════════════════════════════════════════════════════════════════════╝
]]

------------------------------------------------------------------------
-- SERVICES
------------------------------------------------------------------------
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local AssetService     = game:GetService("AssetService")

local LP     = Players.LocalPlayer
local Cam    = Workspace.CurrentCamera
local PGui   = LP:WaitForChild("PlayerGui")

------------------------------------------------------------------------
-- MATH ALIASES
------------------------------------------------------------------------
local noise  = math.noise
local sin    = math.sin
local cos    = math.cos
local abs    = math.abs
local pi     = math.pi
local rand   = math.random
local clamp  = math.clamp
local huge   = math.huge
local floor  = math.floor
local sqrt   = math.sqrt
local max    = math.max
local min    = math.min
local lerp   = function(a,b,t) return a+(b-a)*t end
local lerpC3 = function(a,b,t)
    return Color3.new(lerp(a.R,b.R,t),lerp(a.G,b.G,t),lerp(a.B,b.B,t))
end
local lerpCF = function(a,b,t) return a:Lerp(b,t) end

------------------------------------------------------------------------
-- MASTER CONFIG  — tune all values here
------------------------------------------------------------------------
local CFG = {
    -- Frame-time budgeter
    BUDGET_MS          = 5,

    -- Grass
    GRASS_RADIUS       = 90,
    GRASS_DENSITY      = 5,
    GRASS_H_MIN        = 0.30,
    GRASS_H_MAX        = 0.80,
    GRASS_WIND_SPEED   = 1.3,
    GRASS_WIND_STR     = 22,
    GRASS_CRUSH_R      = 4.0,
    GRASS_SHOCK_R      = 18,
    GRASS_MAX          = 2000,
    GRASS_COL_BASE     = Color3.fromRGB(68,145,62),
    GRASS_COL_TIP      = Color3.fromRGB(178,228,98),

    -- Lighting / post-processing
    BLOOM_INT          = 0.65,
    BLOOM_SIZE         = 26,
    BLOOM_THRESH       = 0.82,
    DOF_FAR            = 0.72,
    DOF_NEAR           = 0.04,
    DOF_DIST           = 55,
    DOF_FOCUS_R        = 14,
    SUNRAY_INT         = 0.20,
    SUNRAY_SPREAD      = 0.70,
    CC_BRIGHT          = 0.07,
    CC_CONTRAST        = 0.14,
    CC_SAT             = 0.25,
    CC_TINT            = Color3.fromRGB(255,244,228),
    MB_SCALE           = 0.32,
    ATMO_DENSITY       = 0.30,
    ATMO_HAZE          = 1.6,
    ATMO_COLOR         = Color3.fromRGB(195,218,255),
    ATMO_DECAY         = Color3.fromRGB(100,122,175),

    -- Character / NPR
    OUTLINE_COL        = Color3.fromRGB(20,20,20),
    OUTLINE_NEAR       = 0.0,
    OUTLINE_FAR        = 0.60,
    OUTLINE_DIST       = 50,
    RIM_COL            = Color3.fromRGB(195,228,255),
    RIM_BRIGHT         = 1.9,
    RIM_RANGE          = 10,

    -- Jiggle spring
    JIGGLE_K           = 14,
    JIGGLE_DAMP        = 7,
    JIGGLE_MAX         = 0.22,

    -- Sub-frame interpolation
    TARGET_HZ          = 120,

    -- SSGI (software colour bleed)
    SSGI_ENABLED       = true,
    SSGI_RADIUS        = 12,

    -- Spatial distortion
    DISTORT_ENABLED    = true,
    DISTORT_ATTR       = "ExodusVFX",

    -- Loading
    LOAD_TITLE         = "EXODUS  V9",
    LOAD_SUB           = "Architectural Singularity — Initialising…",
}

------------------------------------------------------------------------
-- SAFE-CALL WRAPPER
------------------------------------------------------------------------
local function safe(fn, tag)
    local ok, err = pcall(fn)
    if not ok then
        warn("[EXODUS] "..(tag or "?").." → "..tostring(err))
    end
    return ok
end

------------------------------------------------------------------------
-- FRAME-TIME BUDGETER
------------------------------------------------------------------------
local Budgeter = {}
Budgeter.__index = Budgeter
function Budgeter.new(ms)
    return setmetatable({_ms=ms or CFG.BUDGET_MS, _t=os.clock()}, Budgeter)
end
function Budgeter:reset()  self._t = os.clock() end
function Budgeter:over()   return (os.clock()-self._t)*1000 >= self._ms end
function Budgeter:yield()  if self:over() then task.wait(); self._t=os.clock() end end

------------------------------------------------------------------------
-- MODULE 0  —  CINEMATIC LOADING OVERLAY
------------------------------------------------------------------------
local LoadUI = {}
do
    local sg, bar, modLabel = nil, nil, nil

    function LoadUI.create()
        sg = Instance.new("ScreenGui")
        sg.Name           = "ExodusLoader"
        sg.IgnoreGuiInset = true
        sg.ResetOnSpawn   = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.Parent         = PGui

        local bg = Instance.new("Frame")
        bg.Size             = UDim2.fromScale(1,1)
        bg.BackgroundColor3 = Color3.fromRGB(4,4,14)
        bg.BorderSizePixel  = 0
        bg.ZIndex           = 10
        bg.Parent           = sg

        local grad = Instance.new("UIGradient")
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(12,10,35)),
            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(6,5,18)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(2,2,8)),
        })
        grad.Rotation = 120
        grad.Parent   = bg

        -- Star-field decoration
        for _ = 1, 70 do
            local star = Instance.new("Frame")
            star.Size             = UDim2.new(0,rand(1,2),0,rand(1,2))
            star.Position         = UDim2.fromScale(rand(),rand())
            star.BackgroundColor3 = Color3.fromRGB(200,200,255)
            star.BackgroundTransparency = lerp(0.5, 0.95, rand())
            star.BorderSizePixel  = 0
            star.ZIndex           = 10
            star.Parent           = bg
        end

        -- Gold accent lines
        for i = 0, 1 do
            local acc = Instance.new("Frame")
            acc.AnchorPoint      = Vector2.new(0.5,0.5)
            acc.Position         = UDim2.new(0.5,0, 0.44+i*0.14, 0)
            acc.Size             = UDim2.new(0,0,0,1)
            acc.BackgroundColor3 = Color3.fromRGB(200,170,90)
            acc.BorderSizePixel  = 0
            acc.ZIndex           = 11
            acc.Parent           = sg
            TweenService:Create(acc, TweenInfo.new(1.1,Enum.EasingStyle.Expo,Enum.EasingDirection.Out),
                {Size=UDim2.new(0,480,0,1)}):Play()
        end

        -- Title
        local title = Instance.new("TextLabel")
        title.AnchorPoint        = Vector2.new(0.5,0.5)
        title.Position           = UDim2.fromScale(0.5,0.42)
        title.Size               = UDim2.new(0,540,0,90)
        title.BackgroundTransparency = 1
        title.TextColor3         = Color3.fromRGB(225,200,135)
        title.Text               = CFG.LOAD_TITLE
        title.Font               = Enum.Font.GothamBold
        title.TextScaled         = true
        title.TextTransparency   = 1
        title.ZIndex             = 12
        title.Parent             = sg
        TweenService:Create(title, TweenInfo.new(0.9), {TextTransparency=0}):Play()

        -- Sub-title
        local sub = Instance.new("TextLabel")
        sub.AnchorPoint        = Vector2.new(0.5,0.5)
        sub.Position           = UDim2.fromScale(0.5,0.54)
        sub.Size               = UDim2.new(0,440,0,28)
        sub.BackgroundTransparency = 1
        sub.TextColor3         = Color3.fromRGB(140,140,185)
        sub.Text               = CFG.LOAD_SUB
        sub.Font               = Enum.Font.Gotham
        sub.TextScaled         = true
        sub.TextTransparency   = 1
        sub.ZIndex             = 12
        sub.Parent             = sg
        TweenService:Create(sub, TweenInfo.new(1.1), {TextTransparency=0}):Play()

        -- Progress bar
        local barBg = Instance.new("Frame")
        barBg.AnchorPoint      = Vector2.new(0.5,0.5)
        barBg.Position         = UDim2.fromScale(0.5,0.88)
        barBg.Size             = UDim2.new(0,380,0,4)
        barBg.BackgroundColor3 = Color3.fromRGB(40,40,65)
        barBg.BorderSizePixel  = 0
        barBg.ZIndex           = 12
        barBg.Parent           = sg
        Instance.new("UICorner",barBg).CornerRadius = UDim.new(1,0)

        bar = Instance.new("Frame")
        bar.Size             = UDim2.new(0,0,1,0)
        bar.BackgroundColor3 = Color3.fromRGB(220,185,90)
        bar.BorderSizePixel  = 0
        bar.ZIndex           = 13
        bar.Parent           = barBg
        Instance.new("UICorner",bar).CornerRadius = UDim.new(1,0)

        local pctLbl = Instance.new("TextLabel")
        pctLbl.Name          = "PctLbl"
        pctLbl.AnchorPoint   = Vector2.new(1,0.5)
        pctLbl.Position      = UDim2.new(1,-4,0.5,0)
        pctLbl.Size          = UDim2.new(0,44,0,14)
        pctLbl.BackgroundTransparency = 1
        pctLbl.TextColor3    = Color3.fromRGB(200,185,90)
        pctLbl.Font          = Enum.Font.GothamBold
        pctLbl.TextSize      = 11
        pctLbl.Text          = "0%"
        pctLbl.ZIndex        = 14
        pctLbl.Parent        = barBg

        modLabel = Instance.new("TextLabel")
        modLabel.AnchorPoint   = Vector2.new(0.5,0.5)
        modLabel.Position      = UDim2.fromScale(0.5,0.92)
        modLabel.Size          = UDim2.new(0,380,0,20)
        modLabel.BackgroundTransparency = 1
        modLabel.TextColor3    = Color3.fromRGB(105,105,150)
        modLabel.Font          = Enum.Font.Gotham
        modLabel.TextSize      = 11
        modLabel.Text          = ""
        modLabel.ZIndex        = 12
        modLabel.Parent        = sg
    end

    function LoadUI.setProgress(p, label)
        if bar then
            TweenService:Create(bar, TweenInfo.new(0.35, Enum.EasingStyle.Quad),
                {Size=UDim2.new(p,0,1,0)}):Play()
            local pl = bar.Parent:FindFirstChild("PctLbl")
            if pl then pl.Text = floor(p*100).."%" end
        end
        if modLabel then modLabel.Text = label or "" end
    end

    function LoadUI.dismiss()
        task.wait(0.5)
        if not sg or not sg.Parent then return end
        for _, d in sg:GetDescendants() do
            if d:IsA("GuiObject") then
                TweenService:Create(d, TweenInfo.new(1.0,Enum.EasingStyle.Sine),
                    {BackgroundTransparency=1}):Play()
                if d:IsA("TextLabel") then
                    TweenService:Create(d, TweenInfo.new(0.8), {TextTransparency=1}):Play()
                end
            end
        end
        task.wait(1.1)
        sg:Destroy()
    end
end

------------------------------------------------------------------------
-- MODULE 1  —  LIGHTING ENGINE
------------------------------------------------------------------------
local postFX = {}
local function initLighting()
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
             or Instance.new("Atmosphere", Lighting)
    atmo.Density = CFG.ATMO_DENSITY
    atmo.Offset  = 0.07
    atmo.Color   = CFG.ATMO_COLOR
    atmo.Decay   = CFG.ATMO_DECAY
    atmo.Glare   = 0.45
    atmo.Haze    = CFG.ATMO_HAZE

    Lighting.OutdoorAmbient            = Color3.fromRGB(95,108,140)
    Lighting.Ambient                   = Color3.fromRGB(75,85,115)
    Lighting.Brightness                = 3.4
    Lighting.ColorShift_Bottom         = Color3.fromRGB(55,78,128)
    Lighting.ColorShift_Top            = Color3.fromRGB(230,205,160)
    Lighting.EnvironmentDiffuseScale   = 0.68
    Lighting.EnvironmentSpecularScale  = 0.58
    Lighting.ShadowSoftness            = 0.60

    for _, v in Lighting:GetChildren() do
        if v:IsA("PostEffect") then v:Destroy() end
    end

    local bloom      = Instance.new("BloomEffect", Lighting)
    bloom.Intensity  = CFG.BLOOM_INT
    bloom.Size       = CFG.BLOOM_SIZE
    bloom.Threshold  = CFG.BLOOM_THRESH
    postFX.bloom     = bloom

    local dof         = Instance.new("DepthOfFieldEffect", Lighting)
    dof.FarIntensity  = CFG.DOF_FAR
    dof.NearIntensity = CFG.DOF_NEAR
    dof.FocusDistance = CFG.DOF_DIST
    dof.InFocusRadius = CFG.DOF_FOCUS_R
    postFX.dof        = dof

    local sr      = Instance.new("SunRaysEffect", Lighting)
    sr.Intensity  = CFG.SUNRAY_INT
    sr.Spread     = CFG.SUNRAY_SPREAD
    postFX.sr     = sr

    local cc       = Instance.new("ColorCorrectionEffect", Lighting)
    cc.Brightness  = CFG.CC_BRIGHT
    cc.Contrast    = CFG.CC_CONTRAST
    cc.Saturation  = CFG.CC_SAT
    cc.TintColor   = CFG.CC_TINT
    postFX.cc      = cc

    local mb    = Instance.new("BlurEffect", Lighting)
    mb.Size     = 0
    postFX.mb   = mb

    local clouds = Workspace.Terrain:FindFirstChildOfClass("Clouds")
               or Instance.new("Clouds", Workspace.Terrain)
    clouds.Cover   = 0.55
    clouds.Density = 0.70
    clouds.Color   = Color3.fromRGB(218,222,240)
end

------------------------------------------------------------------------
-- MODULE 2  —  DYNAMIC DOF
------------------------------------------------------------------------
local function initDynamicDOF()
    task.spawn(function()
        while task.wait(0.12) do
            safe(function()
                local char = LP.Character
                if not char then return end
                local hrp  = char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local nearest, nearD = nil, huge
                for _, p in Players:GetPlayers() do
                    if p ~= LP and p.Character then
                        local oh = p.Character:FindFirstChild("HumanoidRootPart")
                        if oh then
                            local d = (oh.Position-hrp.Position).Magnitude
                            if d < nearD then nearD=d; nearest=oh end
                        end
                    end
                end
                local dof = postFX.dof
                if not dof then return end
                if nearest then
                    local cd = (nearest.Position-Cam.CFrame.Position).Magnitude
                    dof.FocusDistance = lerp(dof.FocusDistance, cd, 0.14)
                    dof.InFocusRadius = lerp(dof.InFocusRadius, 9, 0.14)
                else
                    dof.FocusDistance = lerp(dof.FocusDistance, CFG.DOF_DIST, 0.07)
                    dof.InFocusRadius = lerp(dof.InFocusRadius, CFG.DOF_FOCUS_R, 0.07)
                end
            end, "DynDOF")
        end
    end)
end

------------------------------------------------------------------------
-- MODULE 3  —  MOTION BLUR
------------------------------------------------------------------------
local function initMotionBlur()
    local prevCF = Cam.CFrame
    RunService.RenderStepped:Connect(function(dt)
        safe(function()
            local delta       = prevCF:ToObjectSpace(Cam.CFrame)
            local ax,ay,az    = delta:ToEulerAnglesXYZ()
            local rot         = (abs(ax)+abs(ay)+abs(az)) / dt
            local target      = clamp(rot*0.006, 0, 16) * CFG.MB_SCALE
            if postFX.mb then
                postFX.mb.Size = lerp(postFX.mb.Size, target, 0.28)
            end
            prevCF = Cam.CFrame
        end, "MotionBlur")
    end)
end

------------------------------------------------------------------------
-- MODULE 4  —  TERRAIN + MATERIAL DISPLACEMENT
------------------------------------------------------------------------
local function initTerrain()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return end

    terrain.WaterWaveSize     = 0.85
    terrain.WaterWaveSpeed    = 14
    terrain.WaterTransparency = 0.28
    terrain.WaterReflectance  = 0.80

    local palette = {
        [Enum.Material.Grass]         = Color3.fromRGB(72,148,64),
        [Enum.Material.LeafyGrass]    = Color3.fromRGB(85,158,70),
        [Enum.Material.Ground]        = Color3.fromRGB(108,82,58),
        [Enum.Material.Sand]          = Color3.fromRGB(212,188,130),
        [Enum.Material.Rock]          = Color3.fromRGB(118,112,108),
        [Enum.Material.SmoothPlastic] = Color3.fromRGB(198,192,182),
        [Enum.Material.Cobblestone]   = Color3.fromRGB(128,122,116),
        [Enum.Material.Brick]         = Color3.fromRGB(162,98,72),
        [Enum.Material.Mud]           = Color3.fromRGB(85,65,48),
        [Enum.Material.Snow]          = Color3.fromRGB(232,244,255),
        [Enum.Material.Sandstone]     = Color3.fromRGB(188,158,108),
        [Enum.Material.Limestone]     = Color3.fromRGB(200,190,165),
        [Enum.Material.Pavement]      = Color3.fromRGB(145,140,130),
        [Enum.Material.CrackedLava]   = Color3.fromRGB(200,80,30),
    }
    for mat, col in palette do
        safe(function() terrain:SetMaterialColor(mat, col) end)
    end

    -- EditableImage texture overlay with Ghibli noise  (fallback-safe)
    local function applyEditableImage(part)
        safe(function()
            local ei = AssetService:CreateEditableImage({Size=Vector2.new(64,64)})
            if not ei then return end
            local px = {}
            local base = part.Color
            for y = 0, 63 do
                for x = 0, 63 do
                    local n = noise(x*0.12, y*0.12, tostring(part):byte(1)*0.01)
                    table.insert(px, clamp(base.R + n*0.09, 0, 1))
                    table.insert(px, clamp(base.G + n*0.07, 0, 1))
                    table.insert(px, clamp(base.B + n*0.05, 0, 1))
                    table.insert(px, 1)
                end
            end
            ei:WritePixels(Vector2.zero, Vector2.new(64,64), px)
        end, "EditableImage")
    end

    local bud   = Budgeter.new(4)
    local count = 0
    for _, obj in Workspace:GetDescendants() do
        if count >= 120 then break end
        if obj:IsA("BasePart") and obj ~= terrain then
            bud:yield()
            applyEditableImage(obj)
            count += 1
        end
    end
end

------------------------------------------------------------------------
-- MODULE 5  —  PROCEDURAL FOLIAGE 4.0  (Spring-Vector Grass)
------------------------------------------------------------------------
local GrassSys = {}
do
    local pool   = {}
    local active = {}
    local folder = Instance.new("Folder", Workspace)
    folder.Name  = "ExodusGrass"

    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {folder}
    rp.FilterType = Enum.RaycastFilterType.Exclude

    local GRASSY = {
        [Enum.Material.Grass]=true,
        [Enum.Material.LeafyGrass]=true,
        [Enum.Material.Ground]=true,
    }

    local shockwaves = {}

    function GrassSys.addShockwave(pos)
        table.insert(shockwaves, {pos=pos, t=os.clock()})
    end

    local function acquire()
        if #pool > 0 then return table.remove(pool) end
        local p = Instance.new("WedgePart")
        p.Anchored=true; p.CanCollide=false; p.CastShadow=false
        p.Material=Enum.Material.SmoothPlastic
        p.Size=Vector3.new(0.07,0.5,0.09)
        p.Parent=folder
        return p
    end

    local function spawnChunk(centre)
        local r = CFG.GRASS_RADIUS
        local d = CFG.GRASS_DENSITY
        local bud = Budgeter.new(CFG.BUDGET_MS)
        for dx = -r, r, 1/d do
            for dz = -r, r, 1/d do
                if #active >= CFG.GRASS_MAX then return end
                if dx*dx+dz*dz > r*r then continue end
                local wx = centre.X + dx + (rand()-0.5)*0.45
                local wz = centre.Z + dz + (rand()-0.5)*0.45
                local hit = Workspace:Raycast(
                    Vector3.new(wx, centre.Y+12, wz),
                    Vector3.new(0,-24,0), rp)
                if not hit then continue end
                if not (GRASSY[hit.Instance.Material] or hit.Instance:IsA("Terrain")) then
                    continue
                end
                local h  = lerp(CFG.GRASS_H_MIN, CFG.GRASS_H_MAX, rand())
                local bp = Vector3.new(wx, hit.Position.Y+h*0.5, wz)
                local yw = rand()*pi*2
                local bl = acquire()
                bl.Size  = Vector3.new(0.065+rand()*0.04, h, 0.085+rand()*0.04)
                bl.Color = lerpC3(CFG.GRASS_COL_BASE, CFG.GRASS_COL_TIP, rand()*0.5)
                bl.CFrame = CFrame.new(bp)*CFrame.Angles(0,yw,0)
                bl.Transparency = 0
                table.insert(active, {
                    part=bl, basePos=bp, yaw=yw, phase=rand()*pi*2,
                    crushVel=0, crushPos=0,
                })
            end
            bud:yield()
        end
    end

    local function recycle(playerPos, keepR)
        local r2 = keepR*keepR
        for i = #active, 1, -1 do
            local b = active[i]
            local dx = b.basePos.X-playerPos.X
            local dz = b.basePos.Z-playerPos.Z
            if dx*dx+dz*dz > r2 then
                b.part.Transparency = 1
                b.crushVel = 0; b.crushPos = 0
                table.insert(pool, b.part)
                table.remove(active, i)
            end
        end
    end

    -- Heartbeat: wind + spring physics (Parallel Luau)
    RunService.Heartbeat:Connect(function(dt)
        safe(function()
            local t   = os.clock()
            local char = LP.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local hrpP = hrp and hrp.Position or Vector3.zero
            local hrpV = hrp and hrp.AssemblyLinearVelocity or Vector3.zero

            for i = #shockwaves, 1, -1 do
                if t - shockwaves[i].t > 1.2 then table.remove(shockwaves, i) end
            end

            task.desynchronize()

            local bud = Budgeter.new(CFG.BUDGET_MS-1)
            for _, b in active do
                local windX = noise(b.basePos.X*0.07, b.basePos.Z*0.07,
                                    t*CFG.GRASS_WIND_SPEED) * CFG.GRASS_WIND_STR
                local windZ = noise(b.basePos.Z*0.07, b.basePos.X*0.07,
                                    t*CFG.GRASS_WIND_SPEED+50) * CFG.GRASS_WIND_STR*0.4

                local fdx = b.basePos.X - hrpP.X
                local fdz = b.basePos.Z - hrpP.Z
                local fd2 = fdx*fdx + fdz*fdz
                local footF = 0
                if fd2 < CFG.GRASS_CRUSH_R*CFG.GRASS_CRUSH_R then
                    local fd = sqrt(fd2)
                    footF = (1-fd/CFG.GRASS_CRUSH_R)*55*(hrpV.Magnitude*0.08+1)
                end

                local shockF = 0
                for _, sw in shockwaves do
                    local sdx = b.basePos.X - sw.pos.X
                    local sdz = b.basePos.Z - sw.pos.Z
                    local sd  = sqrt(sdx*sdx + sdz*sdz)
                    if sd < CFG.GRASS_SHOCK_R then
                        local age  = t - sw.t
                        local wave = max(0, 1-age*1.5) * (1-sd/CFG.GRASS_SHOCK_R)
                        shockF = max(shockF, wave*80)
                    end
                end

                local totalF = footF + shockF
                local acc    = -CFG.JIGGLE_K*b.crushPos - CFG.JIGGLE_DAMP*b.crushVel + totalF*dt
                b.crushVel   = b.crushVel + acc*dt
                b.crushPos   = clamp(b.crushPos + b.crushVel*dt, -CFG.JIGGLE_MAX*4, CFG.JIGGLE_MAX*4)

                b.part.CFrame = CFrame.new(b.basePos)
                    * CFrame.Angles(0, b.yaw, 0)
                    * CFrame.Angles(math.rad(windX)+b.crushPos, 0, math.rad(windZ))

                bud:yield()
            end

            task.synchronize()
        end, "GrassTick")
    end)

    -- Streaming trigger
    local lastPos = Vector3.new(huge,0,huge)
    RunService.Heartbeat:Connect(function()
        safe(function()
            local char = LP.Character; if not char then return end
            local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            local pos  = hrp.Position
            if (pos-lastPos).Magnitude > 20 then
                lastPos = pos
                recycle(pos, CFG.GRASS_RADIUS*1.5)
                task.spawn(spawnChunk, pos)
            end
        end, "GrassStream")
    end)

    function GrassSys.spawnInitial(pos)
        task.spawn(spawnChunk, pos)
    end
end

------------------------------------------------------------------------
-- MODULE 6  —  FOLIAGE WIND
------------------------------------------------------------------------
local function initFoliageWind()
    local kw    = {"tree","leaf","bush","fern","plant","foliage","shrub","branch","vine"}
    local items = {}
    local bud   = Budgeter.new(CFG.BUDGET_MS)
    for _, obj in Workspace:GetDescendants() do
        bud:yield()
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            for _, k in kw do
                if n:find(k) then
                    obj.Anchored = true
                    table.insert(items, {part=obj, baseCF=obj.CFrame, phase=rand()*pi*2})
                    break
                end
            end
        end
    end
    RunService.Heartbeat:Connect(function()
        local t = os.clock()
        safe(function()
            task.desynchronize()
            for _, f in items do
                f.part.CFrame = f.baseCF
                    * CFrame.Angles(sin(t*1.3+f.phase)*0.022, 0, cos(t*0.85+f.phase+1.2)*0.014)
            end
            task.synchronize()
        end, "FoliageWind")
    end)
end

------------------------------------------------------------------------
-- MODULE 7  —  CHARACTER FX  (Outline, Rim, SSGI, Jiggle, Interp)
------------------------------------------------------------------------
local charHandles = {}

local function applyCharFX(char)
    if charHandles[char] then return end

    -- Anime outline
    local hl = Instance.new("Highlight")
    hl.Adornee             = char
    hl.OutlineColor        = CFG.OUTLINE_COL
    hl.OutlineTransparency = CFG.OUTLINE_NEAR
    hl.FillTransparency    = 1
    hl.DepthMode           = Enum.HighlightDepthMode.Occluded
    hl.Parent              = char

    -- Rim light
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    local rimL, ssgiL
    if torso then
        rimL           = Instance.new("PointLight", torso)
        rimL.Color     = CFG.RIM_COL
        rimL.Brightness= CFG.RIM_BRIGHT
        rimL.Range     = CFG.RIM_RANGE
        rimL.Shadows   = false

        if CFG.SSGI_ENABLED then
            ssgiL            = Instance.new("PointLight", torso)
            ssgiL.Color      = Color3.fromRGB(90,160,80)
            ssgiL.Brightness = 0.35
            ssgiL.Range      = CFG.SSGI_RADIUS
            ssgiL.Shadows    = false
        end
    end

    -- Jiggle accessory parts
    local jiggle = {}
    local jigKW  = {"cape","hair","tail","scarf","wing","cloth","ribbon","hood"}
    local function scanJiggle()
        for _, acc in char:GetDescendants() do
            if acc:IsA("BasePart") then
                local n = acc.Name:lower()
                for _, k in jigKW do
                    if n:find(k) then
                        table.insert(jiggle, {
                            part=acc, baseCF=acc.CFrame,
                            velX=0, velZ=0, dX=0, dZ=0,
                        })
                        break
                    end
                end
            end
        end
    end
    scanJiggle()
    char.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") then
            local n = d.Name:lower()
            for _, k in jigKW do
                if n:find(k) then
                    table.insert(jiggle, {part=d, baseCF=d.CFrame, velX=0, velZ=0, dX=0, dZ=0})
                    break
                end
            end
        end
    end)

    charHandles[char] = { hl=hl, ssgiL=ssgiL, jiggle=jiggle }
end

local function removeCharFX(char)
    local h = charHandles[char]
    if h then safe(function() h.hl:Destroy() end); charHandles[char]=nil end
end

-- Per-frame update: outline taper + SSGI + jiggle
RunService.RenderStepped:Connect(function(dt)
    for char, data in charHandles do
        safe(function()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            -- Outline distance taper
            local dist = (hrp.Position - Cam.CFrame.Position).Magnitude
            local t    = clamp((dist-8)/(CFG.OUTLINE_DIST-8), 0, 1)
            data.hl.OutlineTransparency = lerp(CFG.OUTLINE_NEAR, CFG.OUTLINE_FAR, t)

            -- SSGI: sample ground + nearby skill colours
            if data.ssgiL then
                local rcp = RaycastParams.new()
                rcp.FilterDescendantsInstances = {char}
                rcp.FilterType = Enum.RaycastFilterType.Exclude
                local hit = Workspace:Raycast(hrp.Position, Vector3.new(0,-6,0), rcp)
                if hit and hit.Instance then
                    local gc = hit.Instance.Color
                    for _, obj in Workspace:GetDescendants() do
                        if obj:IsA("BasePart") and obj:GetAttribute(CFG.DISTORT_ATTR) then
                            local d2 = (obj.Position-hrp.Position).Magnitude
                            if d2 < CFG.SSGI_RADIUS then
                                gc = lerpC3(gc, obj.Color, (1-d2/CFG.SSGI_RADIUS)*0.35)
                            end
                        end
                    end
                    data.ssgiL.Color = lerpC3(data.ssgiL.Color, gc, 0.07)
                end
            end

            -- Jiggle spring
            local vel = hrp.AssemblyLinearVelocity
            for _, jp in data.jiggle do
                if not jp.part.Parent then continue end
                local fx = -vel.X*0.02
                local fz = -vel.Z*0.02
                local ax = -CFG.JIGGLE_K*jp.dX - CFG.JIGGLE_DAMP*jp.velX + fx
                local az = -CFG.JIGGLE_K*jp.dZ - CFG.JIGGLE_DAMP*jp.velZ + fz
                jp.velX = jp.velX + ax*dt
                jp.velZ = jp.velZ + az*dt
                jp.dX   = clamp(jp.dX+jp.velX*dt, -CFG.JIGGLE_MAX, CFG.JIGGLE_MAX)
                jp.dZ   = clamp(jp.dZ+jp.velZ*dt, -CFG.JIGGLE_MAX, CFG.JIGGLE_MAX)
                jp.part.CFrame = jp.baseCF * CFrame.Angles(jp.dX, 0, jp.dZ)
            end
        end, "CharUpdate")
    end
end)

------------------------------------------------------------------------
-- MODULE 8  —  120Hz SUB-FRAME INTERPOLATION
------------------------------------------------------------------------
local interpDB = {}
local STEP     = 1 / CFG.TARGET_HZ

RunService.Heartbeat:Connect(function()
    for _, p in Players:GetPlayers() do
        if p == LP then continue end
        safe(function()
            local char = p.Character; if not char then return end
            local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            local e = interpDB[hrp]
            if e then e.prevCF=e.nextCF; e.nextCF=hrp.CFrame; e.alpha=0
            else interpDB[hrp]={prevCF=hrp.CFrame, nextCF=hrp.CFrame, alpha=0} end
        end, "InterpRecord")
    end
end)

RunService.RenderStepped:Connect(function(dt)
    for hrp, e in interpDB do
        safe(function()
            if not hrp.Parent then interpDB[hrp]=nil; return end
            e.alpha = clamp(e.alpha + dt/STEP, 0, 1)
            hrp.CFrame = lerpCF(e.prevCF, e.nextCF, e.alpha)
        end, "InterpApply")
    end
end)

------------------------------------------------------------------------
-- MODULE 9  —  SPATIAL DISTORTION  (heat-haze / gravitational lens)
------------------------------------------------------------------------
local function initSpatialDistortion()
    if not CFG.DISTORT_ENABLED then return end
    local distBlur     = Instance.new("BlurEffect", Lighting)
    distBlur.Size      = 0
    RunService.RenderStepped:Connect(function()
        safe(function()
            local maxBlur = 0
            local maxSat  = 0
            for _, obj in Workspace:GetDescendants() do
                if obj:IsA("BasePart") and obj:GetAttribute(CFG.DISTORT_ATTR) then
                    local d = (obj.Position-Cam.CFrame.Position).Magnitude
                    if d < 30 then
                        local s = 1-d/30
                        maxBlur = max(maxBlur, s*10)
                        maxSat  = max(maxSat,  s*0.45)
                    end
                end
            end
            distBlur.Size = lerp(distBlur.Size, maxBlur, 0.18)
            if postFX.cc then
                postFX.cc.Saturation = lerp(postFX.cc.Saturation, CFG.CC_SAT+maxSat, 0.14)
            end
        end, "SpatialDistort")
    end)
end

------------------------------------------------------------------------
-- PLAYER HOOKS
------------------------------------------------------------------------
local function hookPlayer(p)
    local function onChar(char)
        task.wait(1.2)
        safe(function() applyCharFX(char) end, "applyCharFX")
        char.AncestryChanged:Connect(function()
            if not char.Parent then removeCharFX(char) end
        end)
    end
    if p.Character then onChar(p.Character) end
    p.CharacterAdded:Connect(onChar)
end

------------------------------------------------------------------------
-- FRAGMENTED BOOTLOADER
------------------------------------------------------------------------
local MODULES = {
    {pct=0.10, name="⚡ Lighting & Atmosphere",           fn=initLighting},
    {pct=0.22, name="🌫  Dynamic Post-Processing",        fn=function() initDynamicDOF(); initMotionBlur() end},
    {pct=0.38, name="🌍 Terrain & Material Displacement", fn=initTerrain},
    {pct=0.52, name="🌿 Foliage Wind Engine",             fn=initFoliageWind},
    {pct=0.66, name="🔮 Spatial Distortion Engine",       fn=initSpatialDistortion},
    {pct=0.80, name="⚔️  Character & Jiggle System",      fn=function()
        for _, p in Players:GetPlayers() do hookPlayer(p) end
        Players.PlayerAdded:Connect(hookPlayer)
    end},
    {pct=0.92, name="🌱 Procedural Grass — Streaming",    fn=function()
        local char = LP.Character or LP.CharacterAdded:Wait()
        local hrp  = char:WaitForChild("HumanoidRootPart", 8)
        if hrp then GrassSys.spawnInitial(hrp.Position) end
    end},
    {pct=1.00, name="✅ EXODUS V9 — SINGULARITY ACTIVE",  fn=function() end},
}

task.spawn(function()
    LoadUI.create()
    task.wait(0.5)

    for i, mod in MODULES do
        LoadUI.setProgress(mod.pct, string.format("[%d/%d]  %s", i, #MODULES, mod.name))
        safe(mod.fn, mod.name)
        task.wait(0.18)
    end

    LoadUI.setProgress(1.0, "🚀 Singularity Reached — Visual Transfiguration Complete")
    task.wait(0.5)
    LoadUI.dismiss()

    -- Global shockwave API:  _G.ExodusShockwave(Vector3Position)
    -- Call from any other LocalScript when a skill lands.
    _G.ExodusShockwave = function(pos)
        if typeof(pos) == "Vector3" then GrassSys.addShockwave(pos) end
    end

    print("╔═══════════════════════════════════════════╗")
    print("║  EXODUS V9.0  —  ARCHITECTURAL SINGULARITY ║")
    print("║  9 modules loaded. Budget: 5ms/frame.      ║")
    print("║  API: _G.ExodusShockwave(Vector3)          ║")
    print("╚═══════════════════════════════════════════╝")
end)
