--[[
    Main.lua - Animation Pack Changer (Core) v1.1.0
    Bagian dari: Animation Pack Changer
    
    CHANGELOG v1.1.0:
    - Edit manual per kategori pakai dropdown pack (tanpa input asset ID)
--]]

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer       = Players.LocalPlayer

local Config = _G.__ANIMPACK_CONFIG
if not Config then
    warn("[Main] Config tidak ditemukan!")
    return
end

local AnimationPacks = Config.AnimationPacks
local CATEGORIES     = Config.Categories
local COLORS         = Config.Colors
local UI_CFG         = Config.UI

-- ═══════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════

-- categoryPackOverrides: { [categoryKey] = packName }
-- Contoh: { Idle1 = "Ninja", Walk = "Zombie" }
local categoryPackOverrides = {}

local currentPack = nil
local isApplying  = false

-- ═══════════════════════════════════════════════════════════════
-- CORE LOGIC
-- ═══════════════════════════════════════════════════════════════

local function getFinalPack()
    local pack = {}

    -- Basis: dari pack utama yang dipilih, atau Default
    if currentPack and AnimationPacks[currentPack] then
        for k, v in pairs(AnimationPacks[currentPack]) do
            pack[k] = v
        end
    else
        for k, v in pairs(AnimationPacks["Default"]) do
            pack[k] = v
        end
    end

    -- Timpa per kategori kalau user sudah pilih override
    for catKey, packName in pairs(categoryPackOverrides) do
        local overridePack = AnimationPacks[packName]
        if overridePack and overridePack[catKey] then
            pack[catKey] = overridePack[catKey]
        end
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

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, UI_CFG.titleHeight)
TitleBar.BackgroundColor3 = COLORS.bgTitle
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
makeCorner(TitleBar, 10)

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

local Content = Instance.new("ScrollingFrame")
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
-- COMPONENTS
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
-- CATEGORY ROW dengan DROPDOWN PACK
-- ═══════════════════════════════════════════════════════════════

-- Kumpulkan nama pack yang tersedia, sorted
local packNames = {}
for k in pairs(AnimationPacks) do
    table.insert(packNames, k)
end
table.sort(packNames)

-- Daftar opsi dropdown: "-- Ikut Pack Utama --" + semua nama pack
local dropdownOptions = { "-- Ikut Pack Utama --" }
for _, name in ipairs(packNames) do
    table.insert(dropdownOptions, name)
end

-- Simpan UI state tiap kategori untuk keperluan sync
local categoryUIRefs = {}

local function createCategoryRow(cat)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 34)
    row.BackgroundColor3 = COLORS.bgInput
    row.BorderSizePixel = 0
    row.Parent = Content
    makeCorner(row, 6)

    -- Label kategori
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 70, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = cat.label
    lbl.TextColor3 = COLORS.textDim
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    -- Tombol dropdown
    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(1, -90, 0, 26)
    dropBtn.Position = UDim2.new(0, 78, 0, 4)
    dropBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    dropBtn.BorderSizePixel = 0
    dropBtn.Text = "  " .. dropdownOptions[1]
    dropBtn.TextColor3 = COLORS.text
    dropBtn.TextSize = 11
    dropBtn.Font = Enum.Font.Gotham
    dropBtn.TextXAlignment = Enum.TextXAlignment.Left
    dropBtn.AutoButtonColor = false
    dropBtn.Parent = row
    makeCorner(dropBtn, 4)

    -- Panah dropdown
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -22, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = COLORS.textDim
    arrow.TextSize = 9
    arrow.Font = Enum.Font.GothamBold
    arrow.Parent = dropBtn

    -- ===== Dropdown popup =====
    local popup = Instance.new("Frame")
    popup.Name = cat.key .. "Popup"
    popup.Size = UDim2.new(0, dropBtn.AbsoluteSize.X, 0, 0)
    popup.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
    popup.BorderSizePixel = 0
    popup.Visible = false
    popup.ZIndex = 50
    popup.Parent = ScreenGui
    makeCorner(popup, 6)
    makeStroke(popup, COLORS.stroke, 1)

    local popupScroll = Instance.new("ScrollingFrame")
    popupScroll.Size = UDim2.new(1, -4, 1, -4)
    popupScroll.Position = UDim2.new(0, 2, 0, 2)
    popupScroll.BackgroundTransparency = 1
    popupScroll.BorderSizePixel = 0
    popupScroll.ScrollBarThickness = 4
    popupScroll.ScrollBarImageColor3 = COLORS.accent
    popupScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    popupScroll.Parent = popup

    local popupLayout = Instance.new("UIListLayout")
    popupLayout.Padding = UDim.new(0, 2)
    popupLayout.SortOrder = Enum.SortOrder.LayoutOrder
    popupLayout.Parent = popupScroll

    local popupPad = Instance.new("UIPadding")
    popupPad.PaddingLeft = UDim.new(0, 2)
    popupPad.PaddingRight = UDim.new(0, 2)
    popupPad.PaddingTop = UDim.new(0, 2)
    popupPad.PaddingBottom = UDim.new(0, 2)
    popupPad.Parent = popupScroll

    -- Isi popup dengan opsi
    for _, optName in ipairs(dropdownOptions) do
        local opt = Instance.new("TextButton")
        opt.Size = UDim2.new(1, 0, 0, 26)
        opt.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        opt.BorderSizePixel = 0
        opt.Text = "  " .. optName
        opt.TextColor3 = COLORS.text
        opt.TextSize = 11
        opt.Font = Enum.Font.Gotham
        opt.TextXAlignment = Enum.TextXAlignment.Left
        opt.AutoButtonColor = false
        opt.Parent = popupScroll
        makeCorner(opt, 4)

        -- Tandai kalau ini yang sedang terpilih
        if categoryPackOverrides[cat.key] == optName 
           or (not categoryPackOverrides[cat.key] and optName == "-- Ikut Pack Utama --") then
            opt.BackgroundColor3 = COLORS.accent
        end

        opt.MouseEnter:Connect(function()
            if opt.BackgroundColor3 ~= COLORS.accent then
                opt.BackgroundColor3 = COLORS.bgBtnHover
            end
        end)
        opt.MouseLeave:Connect(function()
            if opt.BackgroundColor3 ~= COLORS.accent then
                opt.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
            end
        end)

        opt.MouseButton1Click:Connect(function()
            -- Update state
            if optName == "-- Ikut Pack Utama --" then
                categoryPackOverrides[cat.key] = nil
            else
                categoryPackOverrides[cat.key] = optName
            end

            -- Update tombol tampilan
            dropBtn.Text = "  " .. optName

            -- Update warna semua opsi
            for _, child in ipairs(popupScroll:GetChildren()) do
                if child:IsA("TextButton") then
                    if child.Text == "  " .. optName then
                        child.BackgroundColor3 = COLORS.accent
                    else
                        child.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
                    end
                end
            end

            -- Tutup popup
            popup.Visible = false

            -- Apply ke karakter
            applyCurrentConfig()
        end)
    end

    -- Hitung tinggi popup (max 180px)
    local totalH = #dropdownOptions * 28 + 8
    local popupHeight = math.min(totalH, 180)
    popup.Size = UDim2.new(0, dropBtn.AbsoluteSize.X, 0, popupHeight)
    popupScroll.CanvasSize = UDim2.new(0, 0, 0, popupLayout.AbsoluteContentSize.Y + 8)

    -- Toggle popup saat tombol diklik
    local isOpen = false
    dropBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            -- Posisi popup di bawah tombol
            local absPos = dropBtn.AbsolutePosition
            local absSize = dropBtn.AbsoluteSize
            popup.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 2)
            popup.Size = UDim2.new(0, absSize.X, 0, popupHeight)
            popup.Visible = true
        else
            popup.Visible = false
        end
    end)

    -- Simpan ref untuk keperluan lain
    categoryUIRefs[cat.key] = {
        row = row,
        dropBtn = dropBtn,
        popup = popup,
        popupScroll = popupScroll
    }

    return row
end

-- ═══════════════════════════════════════════════════════════════
-- BUILD UI
-- ═══════════════════════════════════════════════════════════════

sectionHeader("▼  PILIH ANIMATION PACK")

for _, name in ipairs(packNames) do
    createPackButton(name)
end

divider()
sectionHeader("▼  SETTING PER KATEGORI")
sectionHeader("   (Pilih pack untuk tiap kategori)")

for _, cat in ipairs(CATEGORIES) do
    createCategoryRow(cat)
end

divider()

-- Reset button
local ResetBtn = Instance.new("TextButton")
ResetBtn.Size = UDim2.new(1, -6, 0, 32)
ResetBtn.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
ResetBtn.BorderSizePixel = 0
ResetBtn.Text = "🔄 Reset Semua Kategori"
ResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetBtn.TextSize = 12
ResetBtn.Font = Enum.Font.GothamBold
ResetBtn.AutoButtonColor = false
ResetBtn.Parent = Content
makeCorner(ResetBtn, 6)

ResetBtn.MouseButton1Click:Connect(function()
    categoryPackOverrides = {}

    -- Reset tampilan semua dropdown
    for catKey, refs in pairs(categoryUIRefs) do
        refs.dropBtn.Text = "  " .. dropdownOptions[1]
        for _, child in ipairs(refs.popupScroll:GetChildren()) do
            if child:IsA("TextButton") then
                if child.Text == "  " .. dropdownOptions[1] then
                    child.BackgroundColor3 = COLORS.accent
                else
                    child.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
                end
            end
        end
    end

    applyCurrentConfig()
    ResetBtn.Text = "✓ Direset!"
    task.wait(0.8)
    ResetBtn.Text = "🔄 Reset Semua Kategori"
end)

-- Info
local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, -6, 0, 70)
Info.BackgroundTransparency = 1
Info.Text = "✅ Animasi persist setelah respawn\n💡 Klik dropdown per kategori untuk mix animasi\n📌 Contoh: Idle dari Ninja, Walk dari Zombie\n🎯 \"Ikut Pack Utama\" = pakai pack yang dipilih di atas"
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

-- Tutup popup kalau klik di luar
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        for _, refs in pairs(categoryUIRefs) do
            if refs.popup.Visible then
                -- Cek apakah klik di dalam popup / tombol
                local guiObjs = ScreenGui:GetGuiObjectsAtPosition(
                    input.Position.X, input.Position.Y
                )
                local insidePopup = false
                for _, obj in ipairs(guiObjs) do
                    if obj == refs.popup or obj:IsDescendantOf(refs.popup)
                       or obj == refs.dropBtn then
                        insidePopup = true
                        break
                    end
                end
                if not insidePopup then
                    refs.popup.Visible = false
                end
            end
        end
    end
end)

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
local expandedSize  = UDim2.new(0, UI_CFG.width, 0, UI_CFG.height)
local minimizedSize = UDim2.new(0, UI_CFG.width, 0, UI_CFG.titleHeight)

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        TweenService:Create(Main, TweenInfo.new(0.18), {
            Size = minimizedSize
        }):Play()
        Content.Visible = false
        MinBtn.Text = "+"
    else
        TweenService:Create(Main, TweenInfo.new(0.18), {
            Size = expandedSize
        }):Play()
        Content.Visible = true
        MinBtn.Text = "−"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

print("[AnimPack] v1.1.0 loaded. UI siap.")
