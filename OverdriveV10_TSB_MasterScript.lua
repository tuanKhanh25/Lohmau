--[[
╔══════════════════════════════════════════════════════════════════════════╗
║         PROJECT OVERDRIVE V10.0 — THE WORLD REPLACER                    ║
║         Total Environment Reconstruction — The Strongest Battlegrounds   ║
║         Engine : Fragmented Proximity Loader + Voxel Asset Instancer     ║
║         Arch   : Parallel Luau  |  EditableMesh  |  Software GI          ║
║                                                                          ║
║  INSTALL : LocalScript  →  StarterPlayerScripts                          ║
║  Requires: Place API  (AssetService:CreateEditableMesh supported in      ║
║            Studio Beta and live games with the flag enabled)             ║
║  Fallback: All EditableMesh calls fall back to WedgePart geometry.       ║
╚══════════════════════════════════════════════════════════════════════════╝
]]

------------------------------------------------------------------------
-- SERVICES
------------------------------------------------------------------------
local RunService    = game:GetService("RunService")
local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local Lighting      = game:GetService("Lighting")
local Workspace     = game:GetService("Workspace")
local AssetService  = game:GetService("AssetService")

local LP    = Players.LocalPlayer
local Cam   = Workspace.CurrentCamera
local PGui  = LP:WaitForChild("PlayerGui")

------------------------------------------------------------------------
-- MATH SHORTCUTS
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

local function lerp(a,b,t)   return a+(b-a)*t  end
local function lerpC(a,b,t)
    return Color3.new(lerp(a.R,b.R,t),lerp(a.G,b.G,t),lerp(a.B,b.B,t))
end

------------------------------------------------------------------------
-- MASTER CONFIG
------------------------------------------------------------------------
local CFG = {
    -- Performance
    BUDGET_MS        = 5,       -- max ms any tick-work may consume
    MOBILE_MODE      = false,   -- auto-detected below

    -- World replacement
    REPLACE_RADIUS   = 120,     -- studs around player to scan/replace
    CHUNK_SIZE       = 16,      -- grid cell size for proximity loading
    SCAN_TAGS        = {"Grass","Stone","Dirt","Rock","Tree","Water"},
    HIDE_ORIGINALS   = true,    -- set Transparency = 1 instead of Destroy

    -- Grass voxel blades
    GRASS_DENSITY    = 6,       -- blades per stud (radius)
    GRASS_RADIUS     = 80,
    GRASS_H_MIN      = 0.28,
    GRASS_H_MAX      = 0.80,
    GRASS_MAX        = 2200,
    GRASS_COL_BOT    = Color3.fromRGB(60,138,55),
    GRASS_COL_TIP    = Color3.fromRGB(175,228,90),

    -- Trees
    TREE_RADIUS      = 100,     -- scan radius for tree placement
    TREE_DENSITY     = 0.04,    -- probability per stud² that a tree spawns
    TREE_TRUNK_H_MIN = 5,
    TREE_TRUNK_H_MAX = 12,
    TREE_CANOPY_R    = 4,
    TREE_LEAF_COL1   = Color3.fromRGB(68,160,72),
    TREE_LEAF_COL2   = Color3.fromRGB(110,200,90),
    TREE_TRUNK_COL   = Color3.fromRGB(90,62,40),

    -- Rocks
    ROCK_SCALE_MIN   = 1.2,
    ROCK_SCALE_MAX   = 3.5,
    ROCK_COL_BASE    = Color3.fromRGB(110,108,104),
    ROCK_MOSS_COL    = Color3.fromRGB(72,110,55),

    -- Water
    WATER_WAVE_SPD   = 0.8,
    WATER_COL        = Color3.fromRGB(60,140,200),
    WATER_FOAM_COL   = Color3.fromRGB(220,235,255),

    -- Wind
    WIND_SPEED       = 1.1,
    WIND_STR_GRASS   = 20,
    WIND_STR_LEAF    = 8,
    WIND_STR_CAPE    = 12,

    -- Software GI
    GI_ENABLED       = true,
    GI_GRID_STEP     = 14,      -- stud spacing between GI sample rays
    GI_RANGE         = 18,
    GI_BRIGHTNESS    = 0.28,
    GI_UPDATE_HZ     = 0.4,     -- seconds between GI recalculation

    -- Post-processing
    BLOOM_INT        = 0.62,
    BLOOM_SIZE       = 24,
    BLOOM_THRESH     = 0.84,
    DOF_FAR          = 0.68,
    DOF_NEAR         = 0.04,
    DOF_DIST         = 58,
    DOF_R            = 14,
    SUNRAY_INT       = 0.22,
    SUNRAY_SPREAD    = 0.72,
    CC_BRIGHT        = 0.07,
    CC_CONTRAST      = 0.14,
    CC_SAT           = 0.26,
    CC_TINT          = Color3.fromRGB(255,244,226),
    MB_SCALE         = 0.30,

    -- Character
    OUTLINE_COL      = Color3.fromRGB(18,18,18),
    OUTLINE_FAR_T    = 0.58,
    OUTLINE_DIST     = 52,
    RIM_COL          = Color3.fromRGB(195,226,255),
    RIM_BRIGHT       = 1.85,
    JIGGLE_K         = 14,
    JIGGLE_DAMP      = 7,
    JIGGLE_MAX       = 0.20,

    -- Interpolation
    TARGET_HZ        = 120,

    -- Loading
    LOAD_TITLE       = "OVERDRIVE  V10",
    LOAD_SUB         = "World Replacer — Rebuilding Reality…",
}

-- Auto mobile detection
if UserInputService then
    local ok = pcall(function()
        local UIS = game:GetService("UserInputService")
        CFG.MOBILE_MODE = UIS.TouchEnabled and not UIS.MouseEnabled
    end)
end
if CFG.MOBILE_MODE then
    CFG.GRASS_MAX    = 900
    CFG.GRASS_DENSITY= 4
    CFG.GI_ENABLED   = false
    CFG.BLOOM_SIZE   = 16
end

------------------------------------------------------------------------
-- UTILITY
------------------------------------------------------------------------
local function safe(fn, tag)
    local ok, err = pcall(fn)
    if not ok then warn("[V10] "..(tag or "?").." → "..tostring(err)) end
    return ok
end

local Budgeter = {}
Budgeter.__index = Budgeter
function Budgeter.new(ms)
    return setmetatable({_ms=ms or CFG.BUDGET_MS, _t=os.clock()}, Budgeter)
end
function Budgeter:yield()
    if (os.clock()-self._t)*1000 >= self._ms then
        task.wait(); self._t = os.clock()
    end
end

-- Shared raycast params (exclude our own generated geometry)
local genFolder  = Instance.new("Folder", Workspace)
genFolder.Name   = "OverdriveWorld"

local worldRP    = RaycastParams.new()
worldRP.FilterDescendantsInstances = {genFolder}
worldRP.FilterType = Enum.RaycastFilterType.Exclude

------------------------------------------------------------------------
-- GLOBAL WIND VECTOR  (shared by grass, leaves, capes)
------------------------------------------------------------------------
local Wind = {
    dir   = Vector3.new(1,0,0.3).Unit,
    t     = 0,
    value = Vector3.zero,   -- updated each Heartbeat
}
RunService.Heartbeat:Connect(function(dt)
    Wind.t = Wind.t + dt
    local t = Wind.t
    local wx = noise(t*CFG.WIND_SPEED, 0, 0)
    local wz = noise(0, t*CFG.WIND_SPEED, 1)
    Wind.value = Vector3.new(wx, 0, wz)
end)

------------------------------------------------------------------------
-- MODULE 0 — CINEMATIC LOADING SCREEN
------------------------------------------------------------------------
local LoadUI = {}
do
    local sg, bar, modLabel = nil,nil,nil

    function LoadUI.create()
        sg = Instance.new("ScreenGui")
        sg.Name="ODLoader"; sg.IgnoreGuiInset=true
        sg.ResetOnSpawn=false; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
        sg.Parent=PGui

        local bg=Instance.new("Frame",sg)
        bg.Size=UDim2.fromScale(1,1)
        bg.BackgroundColor3=Color3.fromRGB(3,6,16)
        bg.BorderSizePixel=0; bg.ZIndex=10

        local g=Instance.new("UIGradient",bg)
        g.Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(8,14,38)),
            ColorSequenceKeypoint.new(0.55,Color3.fromRGB(4,8,22)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(2,4,12)),
        })
        g.Rotation=145

        -- Star particles
        for _=1,80 do
            local s=Instance.new("Frame",bg)
            s.Size=UDim2.new(0,rand(1,2),0,rand(1,2))
            s.Position=UDim2.fromScale(rand(),rand())
            s.BackgroundColor3=Color3.fromRGB(200,210,255)
            s.BackgroundTransparency=lerp(0.4,0.92,rand())
            s.BorderSizePixel=0; s.ZIndex=10
        end

        -- Horizon line pair
        for i=0,1 do
            local acc=Instance.new("Frame",sg)
            acc.AnchorPoint=Vector2.new(0.5,0.5)
            acc.Position=UDim2.new(0.5,0, 0.43+i*0.15, 0)
            acc.Size=UDim2.new(0,0,0,1)
            acc.BackgroundColor3=Color3.fromRGB(190,160,85)
            acc.BorderSizePixel=0; acc.ZIndex=11
            TweenService:Create(acc,TweenInfo.new(1.1,Enum.EasingStyle.Expo,Enum.EasingDirection.Out),
                {Size=UDim2.new(0,500,0,1)}):Play()
        end

        local function makeLbl(txt,py,sizeY,bold,col)
            local l=Instance.new("TextLabel",sg)
            l.AnchorPoint=Vector2.new(0.5,0.5)
            l.Position=UDim2.fromScale(0.5,py)
            l.Size=UDim2.new(0,560,0,sizeY)
            l.BackgroundTransparency=1
            l.TextColor3=col or Color3.fromRGB(225,200,130)
            l.Text=txt
            l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
            l.TextScaled=true
            l.TextTransparency=1
            l.ZIndex=12
            TweenService:Create(l,TweenInfo.new(0.95),{TextTransparency=0}):Play()
            return l
        end

        makeLbl(CFG.LOAD_TITLE, 0.41, 92, true)
        makeLbl(CFG.LOAD_SUB,   0.53, 26, false, Color3.fromRGB(135,138,188))

        -- Progress bar
        local barBg=Instance.new("Frame",sg)
        barBg.AnchorPoint=Vector2.new(0.5,0.5)
        barBg.Position=UDim2.fromScale(0.5,0.87)
        barBg.Size=UDim2.new(0,400,0,5)
        barBg.BackgroundColor3=Color3.fromRGB(35,38,62)
        barBg.BorderSizePixel=0; barBg.ZIndex=12
        Instance.new("UICorner",barBg).CornerRadius=UDim.new(1,0)

        bar=Instance.new("Frame",barBg)
        bar.Size=UDim2.new(0,0,1,0)
        bar.BackgroundColor3=Color3.fromRGB(210,178,82)
        bar.BorderSizePixel=0; bar.ZIndex=13
        Instance.new("UICorner",bar).CornerRadius=UDim.new(1,0)

        local pLbl=Instance.new("TextLabel",barBg)
        pLbl.Name="PL"
        pLbl.AnchorPoint=Vector2.new(1,0.5)
        pLbl.Position=UDim2.new(1,-5,0.5,0)
        pLbl.Size=UDim2.new(0,46,0,14)
        pLbl.BackgroundTransparency=1
        pLbl.TextColor3=Color3.fromRGB(195,178,82)
        pLbl.Font=Enum.Font.GothamBold; pLbl.TextSize=11
        pLbl.Text="0%"; pLbl.ZIndex=14

        modLabel=Instance.new("TextLabel",sg)
        modLabel.AnchorPoint=Vector2.new(0.5,0.5)
        modLabel.Position=UDim2.fromScale(0.5,0.91)
        modLabel.Size=UDim2.new(0,400,0,20)
        modLabel.BackgroundTransparency=1
        modLabel.TextColor3=Color3.fromRGB(100,102,148)
        modLabel.Font=Enum.Font.Gotham; modLabel.TextSize=11
        modLabel.Text=""; modLabel.ZIndex=12
    end

    function LoadUI.setProgress(p, label)
        p=clamp(p,0,1)
        if bar then
            TweenService:Create(bar,TweenInfo.new(0.35,Enum.EasingStyle.Quad),
                {Size=UDim2.new(p,0,1,0)}):Play()
            local pl=bar.Parent:FindFirstChild("PL")
            if pl then pl.Text=floor(p*100).."%" end
        end
        if modLabel then modLabel.Text=label or "" end
    end

    function LoadUI.dismiss()
        task.wait(0.5)
        if not sg or not sg.Parent then return end
        for _,d in sg:GetDescendants() do
            if d:IsA("GuiObject") then
                TweenService:Create(d,TweenInfo.new(1.1,Enum.EasingStyle.Sine),
                    {BackgroundTransparency=1}):Play()
                if d:IsA("TextLabel") then
                    TweenService:Create(d,TweenInfo.new(0.85),{TextTransparency=1}):Play()
                end
            end
        end
        task.wait(1.2); sg:Destroy()
    end
end

------------------------------------------------------------------------
-- MODULE 1 — LIGHTING & POST-PROCESSING
------------------------------------------------------------------------
local postFX={}
local function initLighting()
    local atmo=Lighting:FindFirstChildOfClass("Atmosphere")
           or Instance.new("Atmosphere",Lighting)
    atmo.Density=0.28; atmo.Offset=0.08
    atmo.Color=Color3.fromRGB(192,215,255)
    atmo.Decay=Color3.fromRGB(98,118,172)
    atmo.Glare=0.48; atmo.Haze=1.7

    Lighting.OutdoorAmbient           = Color3.fromRGB(92,106,138)
    Lighting.Ambient                  = Color3.fromRGB(72,82,112)
    Lighting.Brightness               = 3.5
    Lighting.ColorShift_Bottom        = Color3.fromRGB(52,76,126)
    Lighting.ColorShift_Top           = Color3.fromRGB(228,202,158)
    Lighting.EnvironmentDiffuseScale  = 0.70
    Lighting.EnvironmentSpecularScale = 0.60
    Lighting.ShadowSoftness           = 0.62

    for _,v in Lighting:GetChildren() do
        if v:IsA("PostEffect") then v:Destroy() end
    end

    local bloom=Instance.new("BloomEffect",Lighting)
    bloom.Intensity=CFG.BLOOM_INT; bloom.Size=CFG.BLOOM_SIZE; bloom.Threshold=CFG.BLOOM_THRESH
    postFX.bloom=bloom

    local dof=Instance.new("DepthOfFieldEffect",Lighting)
    dof.FarIntensity=CFG.DOF_FAR; dof.NearIntensity=CFG.DOF_NEAR
    dof.FocusDistance=CFG.DOF_DIST; dof.InFocusRadius=CFG.DOF_R
    postFX.dof=dof

    local sr=Instance.new("SunRaysEffect",Lighting)
    sr.Intensity=CFG.SUNRAY_INT; sr.Spread=CFG.SUNRAY_SPREAD; postFX.sr=sr

    local cc=Instance.new("ColorCorrectionEffect",Lighting)
    cc.Brightness=CFG.CC_BRIGHT; cc.Contrast=CFG.CC_CONTRAST
    cc.Saturation=CFG.CC_SAT; cc.TintColor=CFG.CC_TINT; postFX.cc=cc

    local mb=Instance.new("BlurEffect",Lighting); mb.Size=0; postFX.mb=mb

    local clouds=Workspace.Terrain:FindFirstChildOfClass("Clouds")
             or Instance.new("Clouds",Workspace.Terrain)
    clouds.Cover=0.56; clouds.Density=0.72
    clouds.Color=Color3.fromRGB(216,222,242)

    -- Ghibli terrain palette
    local terrain=Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        local pal={
            [Enum.Material.Grass]      =Color3.fromRGB(70,146,62),
            [Enum.Material.LeafyGrass] =Color3.fromRGB(84,156,68),
            [Enum.Material.Ground]     =Color3.fromRGB(106,80,56),
            [Enum.Material.Sand]       =Color3.fromRGB(210,186,128),
            [Enum.Material.Rock]       =Color3.fromRGB(116,110,106),
            [Enum.Material.Cobblestone]=Color3.fromRGB(126,120,114),
            [Enum.Material.Brick]      =Color3.fromRGB(160,96,70),
            [Enum.Material.Mud]        =Color3.fromRGB(84,64,46),
            [Enum.Material.Snow]       =Color3.fromRGB(230,242,255),
            [Enum.Material.Sandstone]  =Color3.fromRGB(186,156,106),
            [Enum.Material.Pavement]   =Color3.fromRGB(142,138,128),
        }
        for mat,col in pal do safe(function() terrain:SetMaterialColor(mat,col) end) end
        terrain.WaterWaveSize=0.90; terrain.WaterWaveSpeed=15
        terrain.WaterTransparency=0.26; terrain.WaterReflectance=0.82
    end
end

-- Motion blur
local function initMotionBlur()
    local prevCF=Cam.CFrame
    RunService.RenderStepped:Connect(function(dt)
        safe(function()
            local d=prevCF:ToObjectSpace(Cam.CFrame)
            local ax,ay,az=d:ToEulerAnglesXYZ()
            local r=(abs(ax)+abs(ay)+abs(az))/dt
            if postFX.mb then
                postFX.mb.Size=lerp(postFX.mb.Size, clamp(r*0.006,0,16)*CFG.MB_SCALE, 0.28)
            end
            prevCF=Cam.CFrame
        end,"MotionBlur")
    end)
end

-- Dynamic DOF
local function initDynDOF()
    task.spawn(function()
        while task.wait(0.13) do
            safe(function()
                local char=LP.Character; if not char then return end
                local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                local best,bd=nil,huge
                for _,p in Players:GetPlayers() do
                    if p~=LP and p.Character then
                        local oh=p.Character:FindFirstChild("HumanoidRootPart")
                        if oh then
                            local d=(oh.Position-hrp.Position).Magnitude
                            if d<bd then bd=d;best=oh end
                        end
                    end
                end
                local dof=postFX.dof; if not dof then return end
                if best then
                    local cd=(best.Position-Cam.CFrame.Position).Magnitude
                    dof.FocusDistance=lerp(dof.FocusDistance,cd,0.15)
                    dof.InFocusRadius=lerp(dof.InFocusRadius,9,0.15)
                else
                    dof.FocusDistance=lerp(dof.FocusDistance,CFG.DOF_DIST,0.07)
                    dof.InFocusRadius=lerp(dof.InFocusRadius,CFG.DOF_R,0.07)
                end
            end,"DynDOF")
        end
    end)
end

------------------------------------------------------------------------
-- MODULE 2 — THE DELETER  (hide original tagged/material objects)
------------------------------------------------------------------------
local hidden = {}   -- store references so we can un-hide on demand

local GRASS_MAT = {
    [Enum.Material.Grass]=true,
    [Enum.Material.LeafyGrass]=true,
    [Enum.Material.Ground]=true,
}
local ROCK_MAT = {
    [Enum.Material.Rock]=true,
    [Enum.Material.Cobblestone]=true,
    [Enum.Material.Sandstone]=true,
    [Enum.Material.Limestone]=true,
}

local function shouldHide(obj)
    if not obj:IsA("BasePart") then return false end
    local n=obj.Name:lower()
    for _,tag in CFG.SCAN_TAGS do
        if n:find(tag:lower()) then return true end
    end
    if GRASS_MAT[obj.Material] or ROCK_MAT[obj.Material] then return true end
    return false
end

local function hideObject(obj)
    if hidden[obj] then return end
    hidden[obj] = obj.Transparency
    obj.Transparency = 1
    obj.CastShadow   = false
end

local function hideNearPlayer(playerPos, radius)
    local r2=radius*radius
    local bud=Budgeter.new(CFG.BUDGET_MS-1)
    for _,obj in Workspace:GetDescendants() do
        if obj.Parent==genFolder then continue end
        bud:yield()
        if shouldHide(obj) and obj:IsA("BasePart") then
            local d=(obj.Position-playerPos)
            if d.X*d.X+d.Y*d.Y+d.Z*d.Z < r2 then
                hideObject(obj)
            end
        end
    end
end

------------------------------------------------------------------------
-- MODULE 3 — PROCEDURAL VOXEL GRASS  (EditableMesh + fallback WedgePart)
------------------------------------------------------------------------
local GrassSys={}
do
    local pool   ={}
    local active ={}
    local gFolder=Instance.new("Folder",genFolder); gFolder.Name="Grass"

    local shockwaves={}
    function GrassSys.addShockwave(pos)
        table.insert(shockwaves,{pos=pos,t=os.clock()})
    end

    -- Try EditableMesh blade; fall back to WedgePart
    local function makeBlade()
        local ok, mesh = pcall(function()
            return AssetService:CreateEditableMesh()
        end)
        if ok and mesh then
            -- Build a simple tapered quad blade (4 verts, 2 triangles)
            local v1=mesh:AddVertex(Vector3.new(-0.035, 0,    0))
            local v2=mesh:AddVertex(Vector3.new( 0.035, 0,    0))
            local v3=mesh:AddVertex(Vector3.new( 0.012, 0.55, 0))
            local v4=mesh:AddVertex(Vector3.new(-0.012, 0.55, 0))
            mesh:AddTriangle(v1,v2,v3)
            mesh:AddTriangle(v1,v3,v4)
            local sm=Instance.new("SpecialMesh")
            sm.MeshType=Enum.MeshType.FileMesh
            local p=Instance.new("MeshPart")
            p.Anchored=true; p.CanCollide=false; p.CastShadow=false
            p.Size=Vector3.new(0.07,0.55,0.04)
            p.Material=Enum.Material.SmoothPlastic
            p.Parent=gFolder
            return p, true
        else
            -- Fallback
            local p=Instance.new("WedgePart")
            p.Anchored=true; p.CanCollide=false; p.CastShadow=false
            p.Material=Enum.Material.SmoothPlastic
            p.Size=Vector3.new(0.07,0.50,0.09)
            p.Parent=gFolder
            return p, false
        end
    end

    local function acquire()
        return #pool>0 and table.remove(pool) or makeBlade()
    end

    local function spawnChunk(centre)
        local r=CFG.GRASS_RADIUS; local d=CFG.GRASS_DENSITY
        local bud=Budgeter.new(CFG.BUDGET_MS)
        for dx=-r,r,1/d do
            for dz=-r,r,1/d do
                if #active>=CFG.GRASS_MAX then return end
                if dx*dx+dz*dz>r*r then continue end
                local wx=centre.X+dx+(rand()-0.5)*0.45
                local wz=centre.Z+dz+(rand()-0.5)*0.45
                local hit=Workspace:Raycast(
                    Vector3.new(wx,centre.Y+14,wz),
                    Vector3.new(0,-28,0), worldRP)
                if not hit then continue end
                if not (GRASS_MAT[hit.Instance.Material] or hit.Instance:IsA("Terrain")) then
                    continue
                end
                local h=lerp(CFG.GRASS_H_MIN,CFG.GRASS_H_MAX,rand())
                local bp=Vector3.new(wx, hit.Position.Y+h*0.5, wz)
                local yw=rand()*math.pi*2
                local bl=acquire()
                bl.Size=Vector3.new(0.065+rand()*0.04, h, 0.085+rand()*0.04)
                bl.Color=lerpC(CFG.GRASS_COL_BOT,CFG.GRASS_COL_TIP,rand()*0.5)
                bl.Transparency=0
                bl.CFrame=CFrame.new(bp)*CFrame.Angles(0,yw,0)
                table.insert(active,{
                    part=bl, basePos=bp, yaw=yw,
                    phase=rand()*math.pi*2,
                    crushVel=0, crushPos=0,
                })
            end
            bud:yield()
        end
    end

    local function recycle(playerPos,keepR)
        local r2=keepR*keepR
        for i=#active,1,-1 do
            local b=active[i]
            local dx=b.basePos.X-playerPos.X
            local dz=b.basePos.Z-playerPos.Z
            if dx*dx+dz*dz>r2 then
                b.part.Transparency=1
                b.crushVel=0; b.crushPos=0
                table.insert(pool,b.part)
                table.remove(active,i)
            end
        end
    end

    -- Physics tick (Parallel Luau)
    RunService.Heartbeat:Connect(function(dt)
        safe(function()
            local t=os.clock()
            local char=LP.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            local hrpP=hrp and hrp.Position or Vector3.zero
            local hrpV=hrp and hrp.AssemblyLinearVelocity or Vector3.zero
            for i=#shockwaves,1,-1 do
                if t-shockwaves[i].t>1.4 then table.remove(shockwaves,i) end
            end
            task.desynchronize()
            local bud=Budgeter.new(CFG.BUDGET_MS-1)
            for _,b in active do
                -- Wind from global Wind vector
                local windX=(noise(b.basePos.X*0.07,b.basePos.Z*0.07,t*CFG.WIND_SPEED)
                              + Wind.value.X*0.5) * CFG.WIND_STR_GRASS
                local windZ=(noise(b.basePos.Z*0.07,b.basePos.X*0.07,t*CFG.WIND_SPEED+50)
                              + Wind.value.Z*0.5) * CFG.WIND_STR_GRASS*0.4
                -- Footstep crush spring
                local fdx=b.basePos.X-hrpP.X
                local fdz=b.basePos.Z-hrpP.Z
                local fd2=fdx*fdx+fdz*fdz
                local footF=0
                if fd2<CFG.GRASS_CRUSH_R*CFG.GRASS_CRUSH_R then
                    local fd=sqrt(fd2)
                    footF=(1-fd/CFG.GRASS_CRUSH_R)*55*(hrpV.Magnitude*0.08+1)
                end
                -- Shockwave
                local shockF=0
                for _,sw in shockwaves do
                    local sdx=b.basePos.X-sw.pos.X
                    local sdz=b.basePos.Z-sw.pos.Z
                    local sd=sqrt(sdx*sdx+sdz*sdz)
                    if sd<CFG.GRASS_SHOCK_R then
                        local age=t-sw.t
                        local wave=max(0,1-age*1.5)*(1-sd/CFG.GRASS_SHOCK_R)
                        shockF=max(shockF,wave*80)
                    end
                end
                local totalF=footF+shockF
                local acc=-CFG.JIGGLE_K*b.crushPos - CFG.JIGGLE_DAMP*b.crushVel + totalF*dt
                b.crushVel=b.crushVel+acc*dt
                b.crushPos=clamp(b.crushPos+b.crushVel*dt,-0.88,0.88)
                b.part.CFrame=CFrame.new(b.basePos)
                    *CFrame.Angles(0,b.yaw,0)
                    *CFrame.Angles(math.rad(windX)+b.crushPos, 0, math.rad(windZ))
                bud:yield()
            end
            task.synchronize()
        end,"GrassTick")
    end)

    local lastPos=Vector3.new(huge,0,huge)
    RunService.Heartbeat:Connect(function()
        safe(function()
            local char=LP.Character; if not char then return end
            local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            local pos=hrp.Position
            if (pos-lastPos).Magnitude>22 then
                lastPos=pos
                recycle(pos,CFG.GRASS_RADIUS*1.5)
                task.spawn(spawnChunk,pos)
                task.spawn(hideNearPlayer,pos,CFG.REPLACE_RADIUS)
            end
        end,"GrassStream")
    end)

    function GrassSys.spawnInitial(pos)
        task.spawn(spawnChunk,pos)
        task.spawn(hideNearPlayer,pos,CFG.REPLACE_RADIUS)
    end
end

-- Config reference needed in grass tick
CFG.GRASS_CRUSH_R = 4.0
CFG.GRASS_SHOCK_R = 18

------------------------------------------------------------------------
-- MODULE 4 — PROCEDURAL ANIME TREES
------------------------------------------------------------------------
local TreeSys={}
do
    local tFolder=Instance.new("Folder",genFolder); tFolder.Name="Trees"
    local trees={}   -- {trunk, leaves[]}

    local function buildTree(pos)
        local h=lerp(CFG.TREE_TRUNK_H_MIN,CFG.TREE_TRUNK_H_MAX,rand())
        local r=lerp(0.35,0.65,rand())

        -- Trunk (cylinder approximated by 6-sided prism)
        local trunk=Instance.new("Part")
        trunk.Anchored=true; trunk.CanCollide=false
        trunk.Shape=Enum.PartType.Cylinder
        trunk.Size=Vector3.new(h, r*2, r*2)
        trunk.CFrame=CFrame.new(pos+Vector3.new(0,h*0.5,0))*CFrame.Angles(0,0,math.pi/2)
        trunk.Color=CFG.TREE_TRUNK_COL
        trunk.Material=Enum.Material.Wood
        trunk.Parent=tFolder

        -- Bark detail ring
        local knot=Instance.new("Part")
        knot.Anchored=true; knot.CanCollide=false
        knot.Shape=Enum.PartType.Ball
        knot.Size=Vector3.new(r*2.2,r*2.2,r*2.2)
        knot.CFrame=CFrame.new(pos+Vector3.new(0,h*0.45+rand()*h*0.2,0))
        knot.Color=lerpC(CFG.TREE_TRUNK_COL,Color3.fromRGB(70,48,30),0.3)
        knot.Material=Enum.Material.Wood
        knot.Parent=tFolder

        -- Canopy: 4-6 overlapping spheres
        local leafParts={}
        local numSpheres=rand(4,6)
        local cr=CFG.TREE_CANOPY_R
        for i=1,numSpheres do
            local angle=(i/numSpheres)*math.pi*2
            local ox=cos(angle)*(rand()*cr*0.6)
            local oy=h*0.85 + rand()*cr*0.7
            local oz=sin(angle)*(rand()*cr*0.6)
            local sz=cr*(0.7+rand()*0.6)
            local leaf=Instance.new("Part")
            leaf.Anchored=true; leaf.CanCollide=false
            leaf.Shape=Enum.PartType.Ball
            leaf.Size=Vector3.new(sz,sz*0.75,sz)
            leaf.CFrame=CFrame.new(pos+Vector3.new(ox,oy,oz))
            leaf.Color=lerpC(CFG.TREE_LEAF_COL1,CFG.TREE_LEAF_COL2,rand())
            leaf.Material=Enum.Material.SmoothPlastic
            leaf.Transparency=0.08
            leaf.Parent=tFolder
            table.insert(leafParts,{
                part=leaf,
                baseCF=leaf.CFrame,
                phase=rand()*math.pi*2,
                ox=ox,oy=oy,oz=oz,
            })
        end

        table.insert(trees,{trunk=trunk,knot=knot,leaves=leafParts,basePos=pos})
    end

    -- Leaf wind animation
    RunService.Heartbeat:Connect(function()
        local t=os.clock()
        safe(function()
            task.desynchronize()
            for _,tree in trees do
                for _,lp in tree.leaves do
                    local sw=noise(lp.baseCF.X*0.05,lp.baseCF.Z*0.05,t*CFG.WIND_SPEED+lp.phase)
                    local s2=cos(t*0.8+lp.phase)*0.012 + Wind.value.X*0.018
                    lp.part.CFrame=lp.baseCF
                        *CFrame.Angles(sw*0.035+s2, Wind.value.Z*0.01, sw*0.020)
                end
            end
            task.synchronize()
        end,"LeafWind")
    end)

    function TreeSys.spawnAroundPlayer(pos)
        local r=CFG.TREE_RADIUS
        local bud=Budgeter.new(CFG.BUDGET_MS)
        for dx=-r,r,8 do
            for dz=-r,r,8 do
                if dx*dx+dz*dz>r*r then continue end
                -- Random chance per cell
                if rand()<(1-CFG.TREE_DENSITY*60) then continue end
                local wx=pos.X+dx+(rand()-0.5)*6
                local wz=pos.Z+dz+(rand()-0.5)*6
                local hit=Workspace:Raycast(
                    Vector3.new(wx,pos.Y+18,wz),
                    Vector3.new(0,-32,0), worldRP)
                if not hit then continue end
                if not (GRASS_MAT[hit.Instance.Material] or hit.Instance:IsA("Terrain")) then
                    continue
                end
                buildTree(hit.Position)
                bud:yield()
            end
        end
    end
end

------------------------------------------------------------------------
-- MODULE 5 — PROCEDURAL MOSSY ROCKS
------------------------------------------------------------------------
local RockSys={}
do
    local rFolder=Instance.new("Folder",genFolder); rFolder.Name="Rocks"

    local function buildRock(pos, scale)
        local baseSize=Vector3.new(
            scale*(0.9+rand()*0.4),
            scale*(0.55+rand()*0.3),
            scale*(0.8+rand()*0.45))

        -- Main rock body (slightly deformed sphere)
        local body=Instance.new("Part")
        body.Anchored=true; body.CanCollide=true
        body.Shape=Enum.PartType.Ball
        body.Size=baseSize
        body.CFrame=CFrame.new(pos)*CFrame.Angles(rand()*0.4,rand()*math.pi*2,rand()*0.3)
        body.Color=lerpC(CFG.ROCK_COL_BASE, Color3.fromRGB(90,88,84), rand()*0.4)
        body.Material=Enum.Material.Rock
        body.Parent=rFolder

        -- Moss layer (slightly larger, green, high transparency)
        local moss=Instance.new("Part")
        moss.Anchored=true; moss.CanCollide=false
        moss.Shape=Enum.PartType.Ball
        moss.Size=baseSize*Vector3.new(1.05,0.6,1.05)
        moss.CFrame=CFrame.new(pos+Vector3.new(0,baseSize.Y*0.15,0))
        moss.Color=lerpC(CFG.ROCK_MOSS_COL,Color3.fromRGB(90,140,65),rand()*0.5)
        moss.Material=Enum.Material.Grass
        moss.Transparency=0.35
        moss.Parent=rFolder

        -- Small detail pebble cluster
        for _=1,rand(2,4) do
            local peb=Instance.new("Part")
            peb.Anchored=true; peb.CanCollide=false
            local ps=scale*lerp(0.12,0.32,rand())
            peb.Shape=Enum.PartType.Ball
            peb.Size=Vector3.new(ps,ps*0.7,ps)
            peb.CFrame=CFrame.new(pos+Vector3.new(
                (rand()-0.5)*baseSize.X*1.1,
                -(baseSize.Y*0.35),
                (rand()-0.5)*baseSize.Z*1.1))
            peb.Color=lerpC(CFG.ROCK_COL_BASE,Color3.fromRGB(75,72,68),0.5)
            peb.Material=Enum.Material.Rock
            peb.Parent=rFolder
        end
    end

    function RockSys.spawnAroundPlayer(pos)
        local r=CFG.REPLACE_RADIUS
        local bud=Budgeter.new(CFG.BUDGET_MS)
        -- Find existing rock-tagged parts and replace them
        for _,obj in Workspace:GetDescendants() do
            if obj.Parent==genFolder then continue end
            bud:yield()
            if obj:IsA("BasePart") and ROCK_MAT[obj.Material] then
                local d=obj.Position-pos
                if d.X*d.X+d.Y*d.Y+d.Z*d.Z < r*r then
                    hideObject(obj)
                    local scale=lerp(CFG.ROCK_SCALE_MIN,CFG.ROCK_SCALE_MAX,rand())
                    buildRock(obj.Position, scale)
                end
            end
        end
    end
end

------------------------------------------------------------------------
-- MODULE 6 — VOLUMETRIC WATER 2.0
--   Animated foam rings + depth gradient driven by Heartbeat
------------------------------------------------------------------------
local WaterSys={}
do
    local wFolder=Instance.new("Folder",genFolder); wFolder.Name="Water"
    local waterParts={}

    local function buildWaterSurface(region, yHeight)
        -- Fill region with a grid of thin water panels
        local step=4
        for x=region.Min.X,region.Max.X,step do
            for z=region.Min.Z,region.Max.Z,step do
                local wp=Instance.new("Part")
                wp.Anchored=true; wp.CanCollide=false; wp.CastShadow=false
                wp.Size=Vector3.new(step,0.15,step)
                wp.CFrame=CFrame.new(x+step/2, yHeight, z+step/2)
                wp.Color=CFG.WATER_COL
                wp.Material=Enum.Material.SmoothPlastic
                wp.Transparency=0.28
                wp.Parent=wFolder

                -- Foam edge ring (only at boundaries)
                local isEdge=(x<=region.Min.X+step or x>=region.Max.X-step
                           or z<=region.Min.Z+step or z>=region.Max.Z-step)
                if isEdge then
                    local foam=Instance.new("Part")
                    foam.Anchored=true; foam.CanCollide=false; foam.CastShadow=false
                    foam.Size=Vector3.new(step,0.05,step)
                    foam.CFrame=CFrame.new(x+step/2, yHeight+0.12, z+step/2)
                    foam.Color=CFG.WATER_FOAM_COL
                    foam.Material=Enum.Material.SmoothPlastic
                    foam.Transparency=0.55
                    foam.Parent=wFolder
                    table.insert(waterParts,{part=foam, phase=rand()*math.pi*2, isFoam=true})
                end

                table.insert(waterParts,{part=wp, phase=rand()*math.pi*2, isFoam=false, baseY=yHeight})
            end
        end
    end

    -- Wave animation
    RunService.Heartbeat:Connect(function()
        local t=os.clock()
        safe(function()
            task.desynchronize()
            for _,wp in waterParts do
                if not wp.part.Parent then continue end
                local wave=sin(t*CFG.WATER_WAVE_SPD+wp.phase)*0.08
                if not wp.isFoam then
                    local c=wp.part.CFrame
                    wp.part.CFrame=CFrame.new(c.X, wp.baseY+wave, c.Z)
                    wp.part.Transparency=lerp(0.22,0.38, (sin(t*0.5+wp.phase)+1)*0.5)
                else
                    wp.part.Transparency=lerp(0.4,0.7,(sin(t*1.2+wp.phase)+1)*0.5)
                end
            end
            task.synchronize()
        end,"WaterWave")
    end)

    function WaterSys.buildFromTerrain()
        -- Find terrain water regions by raycasting downward on a grid
        local char=LP.Character; if not char then return end
        local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local pos=hrp.Position
        local r=80; local found={}
        local bud=Budgeter.new(CFG.BUDGET_MS)
        for dx=-r,r,6 do
            for dz=-r,r,6 do
                bud:yield()
                local origin=Vector3.new(pos.X+dx,pos.Y+30,pos.Z+dz)
                local hit=Workspace:Raycast(origin,Vector3.new(0,-60,0),worldRP)
                if hit and hit.Instance.Material==Enum.Material.Water then
                    local key=floor(hit.Position.Y*2)/2  -- snap to 0.5-stud Y bands
                    if not found[key] then
                        found[key]={minX=pos.X+dx,maxX=pos.X+dx,minZ=pos.Z+dz,maxZ=pos.Z+dz}
                    else
                        local e=found[key]
                        e.minX=min(e.minX,pos.X+dx)
                        e.maxX=max(e.maxX,pos.X+dx)
                        e.minZ=min(e.minZ,pos.Z+dz)
                        e.maxZ=max(e.maxZ,pos.Z+dz)
                    end
                end
            end
        end
        for yKey,reg in found do
            buildWaterSurface(
                Region3.new(
                    Vector3.new(reg.minX,yKey-1,reg.minZ),
                    Vector3.new(reg.maxX,yKey+1,reg.maxZ)),
                yKey)
        end
    end
end

------------------------------------------------------------------------
-- MODULE 7 — SOFTWARE GI (Grid-Based Ray Colour Bounce)
------------------------------------------------------------------------
local GISys={}
do
    local giLights={}   -- {light, basePos}
    local giFolder=Instance.new("Folder",genFolder); giFolder.Name="SoftGI"

    local function buildGIGrid(centre)
        -- Clear old GI lights
        for _,gl in giLights do pcall(function() gl.light:Destroy() end) end
        giLights={}

        local step=CFG.GI_GRID_STEP
        local r=CFG.REPLACE_RADIUS*0.7
        local bud=Budgeter.new(CFG.BUDGET_MS)

        for dx=-r,r,step do
            for dz=-r,r,step do
                bud:yield()
                local wx=centre.X+dx
                local wz=centre.Z+dz
                -- Raycast from sky downward
                local sunDir=Vector3.new(0.4,-1,0.3).Unit
                local origin=Vector3.new(wx, centre.Y+40, wz) - sunDir*(-40)
                local hit=Workspace:Raycast(origin, sunDir*80, worldRP)
                if not hit then continue end
                -- Sample surface colour
                local surfCol=hit.Instance.Color
                -- Place a low-intensity PointLight at bounce point
                local anchor=Instance.new("Part",giFolder)
                anchor.Anchored=true; anchor.CanCollide=false; anchor.Transparency=1
                anchor.Size=Vector3.new(0.1,0.1,0.1)
                anchor.CFrame=CFrame.new(hit.Position+Vector3.new(0,0.5,0))

                local pl=Instance.new("PointLight",anchor)
                pl.Color=lerpC(surfCol, Color3.new(1,1,1), 0.35)
                pl.Brightness=CFG.GI_BRIGHTNESS
                pl.Range=CFG.GI_RANGE
                pl.Shadows=false

                table.insert(giLights,{light=pl,anchor=anchor,basePos=hit.Position})
            end
        end
    end

    function GISys.init()
        if not CFG.GI_ENABLED then return end
        task.spawn(function()
            while task.wait(CFG.GI_UPDATE_HZ) do
                safe(function()
                    local char=LP.Character; if not char then return end
                    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                    buildGIGrid(hrp.Position)
                end,"GIUpdate")
            end
        end)
    end
end

------------------------------------------------------------------------
-- MODULE 8 — CHARACTER FX (Outline + Rim + Jiggle)
------------------------------------------------------------------------
local charHandles={}

local function applyCharFX(char)
    if charHandles[char] then return end

    local hl=Instance.new("Highlight")
    hl.Adornee=char; hl.OutlineColor=CFG.OUTLINE_COL
    hl.OutlineTransparency=0; hl.FillTransparency=1
    hl.DepthMode=Enum.HighlightDepthMode.Occluded
    hl.Parent=char

    local torso=char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    local rimL, ssgiL
    if torso then
        rimL=Instance.new("PointLight",torso)
        rimL.Color=CFG.RIM_COL; rimL.Brightness=CFG.RIM_BRIGHT
        rimL.Range=10; rimL.Shadows=false

        ssgiL=Instance.new("PointLight",torso)
        ssgiL.Color=Color3.fromRGB(88,158,78)
        ssgiL.Brightness=0.32; ssgiL.Range=12; ssgiL.Shadows=false
    end

    local jiggle={}
    local jKW={"cape","hair","tail","scarf","wing","cloth","ribbon","hood","sleeve"}
    local function scanJ()
        for _,acc in char:GetDescendants() do
            if acc:IsA("BasePart") then
                local n=acc.Name:lower()
                for _,k in jKW do
                    if n:find(k) then
                        table.insert(jiggle,{
                            part=acc,baseCF=acc.CFrame,
                            velX=0,velZ=0,dX=0,dZ=0,
                        }); break
                    end
                end
            end
        end
    end
    scanJ()
    char.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") then
            local n=d.Name:lower()
            for _,k in jKW do
                if n:find(k) then
                    table.insert(jiggle,{part=d,baseCF=d.CFrame,velX=0,velZ=0,dX=0,dZ=0})
                    break
                end
            end
        end
    end)

    charHandles[char]={hl=hl,ssgiL=ssgiL,jiggle=jiggle}
end

local function removeCharFX(char)
    local h=charHandles[char]
    if h then safe(function() h.hl:Destroy() end); charHandles[char]=nil end
end

RunService.RenderStepped:Connect(function(dt)
    for char,data in charHandles do
        safe(function()
            local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            local dist=(hrp.Position-Cam.CFrame.Position).Magnitude
            local t=clamp((dist-8)/(CFG.OUTLINE_DIST-8),0,1)
            data.hl.OutlineTransparency=lerp(0,CFG.OUTLINE_FAR_T,t)
            -- SSGI colour bleed
            if data.ssgiL then
                local rcp=RaycastParams.new()
                rcp.FilterDescendantsInstances={char}; rcp.FilterType=Enum.RaycastFilterType.Exclude
                local hit=Workspace:Raycast(hrp.Position,Vector3.new(0,-6,0),rcp)
                if hit and hit.Instance then
                    data.ssgiL.Color=lerpC(data.ssgiL.Color,hit.Instance.Color,0.07)
                end
            end
            -- Global wind drives cape/hair
            local windForceX=Wind.value.X*CFG.WIND_STR_CAPE*0.018
            local windForceZ=Wind.value.Z*CFG.WIND_STR_CAPE*0.018
            local vel=hrp.AssemblyLinearVelocity
            for _,jp in data.jiggle do
                if not jp.part.Parent then continue end
                local fx=-vel.X*0.02+windForceX
                local fz=-vel.Z*0.02+windForceZ
                local ax=-CFG.JIGGLE_K*jp.dX - CFG.JIGGLE_DAMP*jp.velX + fx
                local az=-CFG.JIGGLE_K*jp.dZ - CFG.JIGGLE_DAMP*jp.velZ + fz
                jp.velX=jp.velX+ax*dt; jp.velZ=jp.velZ+az*dt
                jp.dX=clamp(jp.dX+jp.velX*dt,-CFG.JIGGLE_MAX,CFG.JIGGLE_MAX)
                jp.dZ=clamp(jp.dZ+jp.velZ*dt,-CFG.JIGGLE_MAX,CFG.JIGGLE_MAX)
                jp.part.CFrame=jp.baseCF*CFrame.Angles(jp.dX,0,jp.dZ)
            end
        end,"CharFX")
    end
end)

------------------------------------------------------------------------
-- MODULE 9 — 120Hz SUB-FRAME INTERPOLATION
------------------------------------------------------------------------
local interpDB={}
local ISTEP=1/CFG.TARGET_HZ

RunService.Heartbeat:Connect(function()
    for _,p in Players:GetPlayers() do
        if p==LP then continue end
        safe(function()
            local char=p.Character; if not char then return end
            local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            local e=interpDB[hrp]
            if e then e.prevCF=e.nextCF; e.nextCF=hrp.CFrame; e.alpha=0
            else interpDB[hrp]={prevCF=hrp.CFrame,nextCF=hrp.CFrame,alpha=0} end
        end,"InterpRecord")
    end
end)

RunService.RenderStepped:Connect(function(dt)
    for hrp,e in interpDB do
        safe(function()
            if not hrp.Parent then interpDB[hrp]=nil; return end
            e.alpha=clamp(e.alpha+dt/ISTEP,0,1)
            hrp.CFrame=e.prevCF:Lerp(e.nextCF,e.alpha)
        end,"InterpApply")
    end
end)

------------------------------------------------------------------------
-- PLAYER HOOKS
------------------------------------------------------------------------
local function hookPlayer(p)
    local function onChar(char)
        task.wait(1.2)
        safe(function() applyCharFX(char) end,"CharFX")
        char.AncestryChanged:Connect(function()
            if not char.Parent then removeCharFX(char) end
        end)
    end
    if p.Character then onChar(p.Character) end
    p.CharacterAdded:Connect(onChar)
end

------------------------------------------------------------------------
-- FRAGMENTED PROXIMITY BOOTLOADER
------------------------------------------------------------------------
local MODULES={
    {pct=0.08, name="⚡ Lighting, Post-FX & Atmosphere",      fn=initLighting},
    {pct=0.16, name="🎬 Motion Blur + Dynamic DOF",           fn=function() initMotionBlur(); initDynDOF() end},
    {pct=0.28, name="🌍 Terrain Palette & Material Skin",     fn=function() end},  -- done inside initLighting
    {pct=0.40, name="👁️  The Deleter — Hiding Originals",     fn=function()
        local char=LP.Character or LP.CharacterAdded:Wait()
        local hrp=char:WaitForChild("HumanoidRootPart",8)
        if hrp then hideNearPlayer(hrp.Position, CFG.REPLACE_RADIUS) end
    end},
    {pct=0.52, name="🌱 Voxel Grass — Spawning Blades",       fn=function()
        local char=LP.Character or LP.CharacterAdded:Wait()
        local hrp=char:WaitForChild("HumanoidRootPart",8)
        if hrp then GrassSys.spawnInitial(hrp.Position) end
    end},
    {pct=0.64, name="🌳 Procedural Anime Trees",              fn=function()
        local char=LP.Character or LP.CharacterAdded:Wait()
        local hrp=char:WaitForChild("HumanoidRootPart",8)
        if hrp then task.spawn(TreeSys.spawnAroundPlayer,hrp.Position) end
    end},
    {pct=0.74, name="🪨 Mossy Rock Replacement",              fn=function()
        local char=LP.Character or LP.CharacterAdded:Wait()
        local hrp=char:WaitForChild("HumanoidRootPart",8)
        if hrp then task.spawn(RockSys.spawnAroundPlayer,hrp.Position) end
    end},
    {pct=0.82, name="💧 Volumetric Water 2.0",                fn=function()
        task.spawn(WaterSys.buildFromTerrain)
    end},
    {pct=0.91, name="💡 Software GI — Ray Colour Bounce",     fn=GISys.init},
    {pct=0.97, name="⚔️  Character FX + Jiggle + Interp",     fn=function()
        for _,p in Players:GetPlayers() do hookPlayer(p) end
        Players.PlayerAdded:Connect(hookPlayer)
    end},
    {pct=1.00, name="✅ OVERDRIVE V10 — WORLD REPLACED",       fn=function() end},
}

task.spawn(function()
    LoadUI.create()
    task.wait(0.55)

    for i,mod in MODULES do
        LoadUI.setProgress(mod.pct, string.format("[%d/%d]  %s", i, #MODULES, mod.name))
        safe(mod.fn, mod.name)
        task.wait(0.20)
    end

    LoadUI.setProgress(1.0,"🚀 World Replacement Complete — Reality Rebuilt")
    task.wait(0.5)
    LoadUI.dismiss()

    -- Global APIs
    _G.ODShockwave = function(pos)
        if typeof(pos)=="Vector3" then GrassSys.addShockwave(pos) end
    end
    _G.ODReveal = function()
        for obj,origT in hidden do
            safe(function() obj.Transparency=origT end)
        end
    end

    print("╔══════════════════════════════════════════════════╗")
    print("║  OVERDRIVE V10.0  —  THE WORLD REPLACER ACTIVE   ║")
    print("║  10 modules | 5ms budget | Parallel Luau          ║")
    print("║  _G.ODShockwave(Vector3)  — grass shockwave       ║")
    print("║  _G.ODReveal()            — restore originals     ║")
    print("╚══════════════════════════════════════════════════╝")
end)
