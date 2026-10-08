--[[
    Main.lua - Animation Pack Changer (Core)
    Bagian dari: Animation Pack Changer
    Version: 1.0.0
    
    CATATAN: File ini di-load oleh Loader.lua.
    Config.lua di-inject sebagai variabel CONFIG_FROM_REPO sebelum eksekusi.
--]]

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer       = Players.LocalPlayer

-- CONFIG di-inject oleh Loader (dari Config.lua)
local Config = _G.__ANIMPACK_CONFIG

if not Config then
    warn("[Main] Config tidak ditemukan! Pastikan Loader.lua memuat Config.lua dulu.")
    return
end

local AnimationPacks = Config.AnimationPacks
local CATEGORIES     = Config.Categories
local COLORS         = Config.Colors
local UI_CFG         = Config.UI

-- ═══════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════

local customOverrides = {}
local currentPack     = nil
local isApplying      = false

-- ═══════════════════════════════════════════════════════════════
-- CORE LOGIC
-- ═══════════════════════════════════════════════════════════════

local function getFinalPack()
    local pack = {}

    if currentPack and AnimationPacks[currentPack] then
        for k, v in pairs(AnimationPacks[currentPack]) do
            pack[k] = v
        end
    else
        for k, v in pairs(AnimationPacks["Default"]) do
            pack[k] = v
        end
    end

    for k, v in pairs(customOverrides) do
        pack[k] = v
    end

    return pack
end

local function applyPackToCharacter(pack, character)
    if not character then return false, "Karakter tidak ada" end
    if not pack then return false, "Pack kosong" end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local animate  = character:FindFirstChild("Animate")

    if not humanoid or not animate then
        return false, "Animate belum siap"
    end

    local ok, err = pcall(function()
        local idle = animate:FindFirstChild("idle")
        if idle then
            if idle:FindFirstChild("Animation1") then
                idle.Animation1.AnimationId = pack.Idle1 or ""
            end
            if idle:FindFirstChild("Animation2") then
                idle.Animation2.AnimationId = pack.Idle2 or ""
            end
        end

        local walk = animate:FindFirstChild("walk")
        if walk and walk:FindFirstChild("WalkAnim") then
            walk.WalkAnim.AnimationId = pack.Walk or ""
        end

        local run = animate:FindFirstChild("run")
        if run and run:FindFirstChild("RunAnim") then
            run.RunAnim.AnimationId = pack.Run or ""
        end

        local jump = animate:FindFirstChild("jump")
        if jump and jump:FindFirstChild("JumpAnim") then
            jump.JumpAnim.AnimationId = pack.Jump or ""
        end

        local fall = animate:FindFirstChild("fall")
        if fall and fall:FindFirstChild("FallAnim") then
            fall.FallAnim.AnimationId = pack.Fall or ""
        end

        local swim = animate:FindFirstChild("swim")
        if swim and swim:FindFirstChild("Swim") then
            swim.Swim.AnimationId = pack.Swim or ""
        end

        local swimidle = animate:FindFirstChild("swimidle")
        if swimidle and swimidle:FindFirstChild("SwimIdle") then
            swimidle.SwimIdle.AnimationId = pack.SwimIdle or ""
        end
    end)

    return ok, ok and "OK" or tostring(err)
end

local function applyCurrentConfig()
    if isApplying then return false, "Sedang apply" end
    isApplying = true
    local pack = getFinalPack()
    local ok, msg = applyPackToCharacter(pack, LocalPlayer.Character)
    isApplying = false
    return ok, msg
end

local function selectPack(packName)
    if not AnimationPacks[packName] then
        return false, "Pack tidak ditemukan"
    end
    currentPack = packName
    return applyCurrentConfig()
end

-- ═══════════════════════════════════════════════════════════════
-- RESPAWN PERSISTENCE
-- ═══════════════════════════════════════════════════════════════

local function waitForAnimateReady(character, timeout)
    timeout = timeout or 10
    local start = tick()

    while tick() - start < timeout do
        local animate = character:FindFirstChild("Animate")
        if animate
           and animate:FindFirstChild("idle")
           and animate.idle:FindFirstChild("Animation1")
           and animate:FindFirstChild("walk")
           and animate.walk:FindFirstChild("WalkAnim")
           and animate:FindFirstChild("run") then
            return animate
        end
        task.wait(0.1)
    end
    return character:FindFirstChild("Animate")
end

local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid then return end

    waitForAnimateReady(character, 10)
    task.wait(0.3)

    local pack = getFinalPack()
    local ok = applyPackToCharacter(pack, character)
    if ok then
        print("[AnimPack] Re-applied setelah respawn")
    end

    -- Watchdog 10 detik
    task.spawn(function()
        local checks = 0
        while checks < 20 and character.Parent do
            task.wait(0.5)
            checks += 1
            local animate = character:FindFirstChild("Animate")
            if not animate then continue end
            local walkAnim = animate:FindFirstChild("walk")
                and animate.walk:FindFirstChild("WalkAnim")
            if walkAnim and pack.Walk and walkAnim.AnimationId ~= pack.Walk then
                applyPackToCharacter(pack, character)
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then
    task.spawn(onCharacterAdded, LocalPlayer.Character)
end

-- ═══════════════════════════════════════════════════════════════
-- UI HELPERS
-- ═══════════════════════════════════════════════════════════════

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function makeStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.stroke
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

-- ═══════════════════════════════════════════════════════════════
-- UI ROOT
-- ═══════════════════════════════════════════════════════════════

-- Hapus GUI lama jika ada
pcall(function()
    local old = (gethui and gethui() or CoreGui):FindFirstChild("AnimPackChanger")
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AnimPackChanger"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, UI_CFG.width, 0, UI_CFG.height)
Main.Position = UDim2.new(0.5, -UI_CFG.width/2, 0.5, -UI_CFG.height/2)
Main.BackgroundColor3 = COLORS.bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui
makeCorner(Main, 10)
makeStroke(Main, COLORS.stroke, 1.5)

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, UI_CFG.titleHeight)
TitleBar.BackgroundColor3 = COLORS.bgTitle
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
makeCorner(TitleBar, 10)

-- Fix sudut bawah titlebar jadi kotak
local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 10)
titleFix.Position = UDim2.new(0, 0, 1, -10)
titleFix.BackgroundColor3 = COLORS.bgTitle
titleFix.BorderSizePixel = 0
titleFix.Parent = TitleBar

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -90, 1, 0)
TitleLbl.Position = UDim2.new(0, 14, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "🎭 Animation Pack Changer"
TitleLbl.TextColor3 = COLORS.text
TitleLbl.TextSize = 14
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -78, 0, 6)
MinBtn.BackgroundColor3 = COLORS.bgMin
MinBtn.BorderSizePixel = 0
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(30, 30, 30)
MinBtn.TextSize = 20
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TitleBar
makeCorner(MinBtn, 6)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -42, 0, 6)
CloseBtn.BackgroundColor3 = COLORS.bgClose
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
makeCorner(CloseBtn, 6)

-- Content
local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -16, 1, -UI_CFG.titleHeight - 16)
Content.Position = UDim2.new(0, 8, 0, UI_CFG.titleHeight + 8)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 5
Content.ScrollBarImageColor3 = COLORS.accent
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 6)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Content

local Pad = Instance.new("UIPadding")
Pad.PaddingLeft = UDim.new(0, 6)
Pad.PaddingRight = UDim.new(0, 6)
Pad.PaddingTop = UDim.new(0, 6)
Pad.PaddingBottom = UDim.new(0, 6)
Pad.Parent = Content

-- ═══════════════════════════════════════════════════════════════
-- UI COMPONENTS
-- ═══════════════════════════════════════════════════════════════

local function sectionHeader(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -6, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = COLORS.accent
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Content
    return lbl
end

local function divider()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -6, 0, 1)
    f.BackgroundColor3 = COLORS.stroke
    f.BorderSizePixel = 0
    f.Parent = Content
    return f
end

-- ═══════════════════════════════════════════════════════════════
-- PACK BUTTONS
-- ═══════════════════════════════════════════════════════════════

local packButtons = {}

local function createPackButton(packName)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 34)
    btn.BackgroundColor3 = COLORS.bgBtn
    btn.BorderSizePixel = 0
    btn.Text = "  " .. packName
    btn.TextColor3 = COLORS.text
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamMedium
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.Parent = Content
    makeCorner(btn, 6)

    btn.MouseEnter:Connect(function()
        if currentPack ~= packName then
            TweenService:Create(btn, TweenInfo.new(0.12), {
                BackgroundColor3 = COLORS.bgBtnHover
            }):Play()
        end
    end)

    btn.MouseLeave:Connect(function()
        if currentPack ~= packName then
            TweenService:Create(btn, TweenInfo.new(0.12), {
                BackgroundColor3 = COLORS.bgBtn
            }):Play()
        end
    end)

    btn.MouseButton1Click:Connect(function()
        for _, b in pairs(packButtons) do
            TweenService:Create(b, TweenInfo.new(0.15), {
                BackgroundColor3 = COLORS.bgBtn
            }):Play()
        end

        local ok = selectPack(packName)
        if ok then
            btn.BackgroundColor3 = COLORS.bgActive
            print("[AnimPack] Applied: " .. packName)
        else
            btn.BackgroundColor3 = COLORS.bgError
            task.wait(0.5)
            btn.BackgroundColor3 = COLORS.bgBtn
        end
    end)

    packButtons[packName] = btn
    return btn
end

-- ═══════════════════════════════════════════════════════════════
-- CATEGORY ROWS (custom override)
-- ═══════════════════════════════════════════════════════════════

local categoryInputs = {}

local function createCategoryRow(cat)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 30)
    row.BackgroundColor3 = COLORS.bgInput
    row.BorderSizePixel = 0
    row.Parent = Content
    makeCorner(row, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 65, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = cat.label
    lbl.TextColor3 = COLORS.textDim
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -140, 0, 22)
    box.Position = UDim2.new(0, 75, 0, 4)
    box.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    box.BorderSizePixel = 0
    box.Text = customOverrides[cat.key] or ""
    box.PlaceholderText = "rbxassetid://..."
    box.PlaceholderColor3 = Color3.fromRGB(90, 90, 120)
    box.TextColor3 = COLORS.text
    box.TextSize = 11
    box.Font = Enum.Font.Code
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Parent = row
    makeCorner(box, 4)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 6)
    pad.Parent = box

    local setBtn = Instance.new("TextButton")
    setBtn.Size = UDim2.new(0, 52, 0, 22)
    setBtn.Position = UDim2.new(1, -60, 0, 4)
    setBtn.BackgroundColor3 = COLORS.accent
    setBtn.BorderSizePixel = 0
    setBtn.Text = "Set"
    setBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    setBtn.TextSize = 11
    setBtn.Font = Enum.Font.GothamBold
    setBtn.AutoButtonColor = false
    setBtn.Parent = row
    makeCorner(setBtn, 4)

    setBtn.MouseButton1Click:Connect(function()
        local text = box.Text:gsub("%s+", "")

        if text == "" then
            customOverrides[cat.key] = nil
            setBtn.Text = "✓ Clear"
            setBtn.BackgroundColor3 = COLORS.bgError
            task.wait(0.8)
            setBtn.Text = "Set"
            setBtn.BackgroundColor3 = COLORS.accent
            applyCurrentConfig()
            return
        end

        if not text:match("^rbxassetid://") then
            text = text:gsub("^%D*", "")
            if text ~= "" then
                text = "rbxassetid://" .. text
            end
        end

        if not text:match("^rbxassetid://%d+$") then
            setBtn.Text = "✗ Error"
            setBtn.BackgroundColor3 = COLORS.bgError
            task.wait(0.8)
            setBtn.Text = "Set"
            setBtn.BackgroundColor3 = COLORS.accent
            return
        end

        customOverrides[cat.key] = text
        box.Text = text

        local ok = applyCurrentConfig()
        if ok then
            setBtn.Text = "✓ OK"
            setBtn.BackgroundColor3 = COLORS.bgActive
        else
            setBtn.Text = "✗ Gagal"
            setBtn.BackgroundColor3 = COLORS.bgError
        end
        task.wait(0.8)
        setBtn.Text = "Set"
        setBtn.BackgroundColor3 = COLORS.accent
    end)

    categoryInputs[cat.key] = box
    return row
end

-- ═══════════════════════════════════════════════════════════════
-- BUILD UI
-- ═══════════════════════════════════════════════════════════════

sectionHeader("▼  PILIH ANIMATION PACK")

local packNames = {}
for k in pairs(AnimationPacks) do
    table.insert(packNames, k)
end
table.sort(packNames)

for _, name in ipairs(packNames) do
    createPackButton(name)
end

divider()
sectionHeader("▼  SETTING PER KATEGORI (Override)")

for _, cat in ipairs(CATEGORIES) do
    createCategoryRow(cat)
end

divider()

-- Reset button
local ResetBtn = Instance.new("TextButton")
ResetBtn.Size = UDim2.new(1, -6, 0, 32)
ResetBtn.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
ResetBtn.BorderSizePixel = 0
ResetBtn.Text = "🔄 Reset Semua Custom"
ResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetBtn.TextSize = 12
ResetBtn.Font = Enum.Font.GothamBold
ResetBtn.AutoButtonColor = false
ResetBtn.Parent = Content
makeCorner(ResetBtn, 6)

ResetBtn.MouseButton1Click:Connect(function()
    customOverrides = {}
    for _, box in pairs(categoryInputs) do
        box.Text = ""
    end
    applyCurrentConfig()
    ResetBtn.Text = "✓ Direset!"
    task.wait(0.8)
    ResetBtn.Text = "🔄 Reset Semua Custom"
end)

-- Info
local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, -6, 0, 56)
Info.BackgroundTransparency = 1
Info.Text = "✅ Animasi persist setelah respawn\n💡 Isi rbxassetid:// untuk override per kategori\n📌 Kosongkan kotak + klik Set untuk clear"
Info.TextColor3 = COLORS.textDim
Info.TextSize = 10
Info.Font = Enum.Font.Gotham
Info.TextWrapped = true
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.TextYAlignment = Enum.TextYAlignment.Top
Info.Parent = Content

-- Update canvas
local function updateCanvas()
    Content.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 16)
end
Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
task.wait(0.1)
updateCanvas()

-- ═══════════════════════════════════════════════════════════════
-- DRAG HANDLE
-- ═══════════════════════════════════════════════════════════════

do
    local dragging = false
    local dragStart, startPos

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)

    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
           or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- MINIMIZE / CLOSE
-- ═══════════════════════════════════════════════════════════════

local isMinimized = false
local expandedSize = UDim2.new(0, UI_CFG.width, 0, UI_CFG.height)
local minimizedSize = UDim2.new(0, UI_CFG.width, 0, UI_CFG.titleHeight)

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        TweenService:Create(Main, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
            Size = minimizedSize
        }):Play()
        Content.Visible = false
        MinBtn.Text = "+"
    else
        TweenService:Create(Main, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
            Size = expandedSize
        }):Play()
        Content.Visible = true
        MinBtn.Text = "−"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

print("[AnimPack] v1.0.0 loaded. UI siap.")
