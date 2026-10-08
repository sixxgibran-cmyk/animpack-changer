--[[
    Config.lua - Database Animation Pack
    Bagian dari: Animation Pack Changer
    Version: 1.0.0
--]]

local Config = {}

-- ═══════════════════════════════════════════════════════════════
-- DAFTAR ANIMATION PACK
-- ═══════════════════════════════════════════════════════════════

Config.AnimationPacks = {
    ["Default"] = {
        Idle1    = "rbxassetid://507766666",
        Idle2    = "rbxassetid://507766951",
        Walk     = "rbxassetid://507777826",
        Run      = "rbxassetid://507767714",
        Jump     = "rbxassetid://507765000",
        Fall     = "rbxassetid://507767968",
        Swim     = "rbxassetid://507784897",
        SwimIdle = "rbxassetid://507785072"
    },
    ["Ninja"] = {
        Idle1    = "rbxassetid://656117400",
        Idle2    = "rbxassetid://656118341",
        Walk     = "rbxassetid://656121766",
        Run      = "rbxassetid://656118852",
        Jump     = "rbxassetid://656117878",
        Fall     = "rbxassetid://656115606",
        Swim     = "rbxassetid://656119055",
        SwimIdle = "rbxassetid://656119244"
    },
    ["Zombie"] = {
        Idle1    = "rbxassetid://616158929",
        Idle2    = "rbxassetid://616159131",
        Walk     = "rbxassetid://616160915",
        Run      = "rbxassetid://616161208",
        Jump     = "rbxassetid://616161617",
        Fall     = "rbxassetid://616160327",
        Swim     = "rbxassetid://616162178",
        SwimIdle = "rbxassetid://616162532"
    },
    ["Astronaut"] = {
        Idle1    = "rbxassetid://891621366",
        Idle2    = "rbxassetid://891633237",
        Walk     = "rbxassetid://891636393",
        Run      = "rbxassetid://891636393",
        Jump     = "rbxassetid://891627522",
        Fall     = "rbxassetid://891617961",
        Swim     = "rbxassetid://891639666",
        SwimIdle = "rbxassetid://891663592"
    },
    ["Cartoony"] = {
        Idle1    = "rbxassetid://742637544",
        Idle2    = "rbxassetid://742638445",
        Walk     = "rbxassetid://742640026",
        Run      = "rbxassetid://742638842",
        Jump     = "rbxassetid://742637942",
        Fall     = "rbxassetid://742639719",
        Swim     = "rbxassetid://742641479",
        SwimIdle = "rbxassetid://742643243"
    },
    ["Bubbly"] = {
        Idle1    = "rbxassetid://910004836",
        Idle2    = "rbxassetid://910009958",
        Walk     = "rbxassetid://910034870",
        Run      = "rbxassetid://910025107",
        Jump     = "rbxassetid://910016857",
        Fall     = "rbxassetid://910001910",
        Swim     = "rbxassetid://910028158",
        SwimIdle = "rbxassetid://910030921"
    },
    ["Toy"] = {
        Idle1    = "rbxassetid://782841498",
        Idle2    = "rbxassetid://782845736",
        Walk     = "rbxassetid://782843345",
        Run      = "rbxassetid://782842708",
        Jump     = "rbxassetid://782847020",
        Fall     = "rbxassetid://782846423",
        Swim     = "rbxassetid://782849870",
        SwimIdle = "rbxassetid://782850062"
    },
    ["Rthro"] = {
        Idle1    = "rbxassetid://1092134325",
        Idle2    = "rbxassetid://1092135751",
        Walk     = "rbxassetid://1092128822",
        Run      = "rbxassetid://1092128822",
        Jump     = "rbxassetid://1092129924",
        Fall     = "rbxassetid://1092128654",
        Swim     = "rbxassetid://1092132578",
        SwimIdle = "rbxassetid://1092133621"
    },
    ["Superhero"] = {
        Idle1    = "rbxassetid://1092134325",
        Idle2    = "rbxassetid://1092135751",
        Walk     = "rbxassetid://1092128822",
        Run      = "rbxassetid://1092128822",
        Jump     = "rbxassetid://1092129924",
        Fall     = "rbxassetid://1092128654",
        Swim     = "rbxassetid://1092132578",
        SwimIdle = "rbxassetid://1092133621"
    },
    ["Stylish"] = {
        Idle1    = "rbxassetid://1092134325",
        Idle2    = "rbxassetid://1092135751",
        Walk     = "rbxassetid://1092128822",
        Run      = "rbxassetid://1092128822",
        Jump     = "rbxassetid://1092129924",
        Fall     = "rbxassetid://1092128654",
        Swim     = "rbxassetid://1092132578",
        SwimIdle = "rbxassetid://1092133621"
    }
    -- Tambahkan pack lain di sini. Contoh:
    -- ["Catwalk Glam"] = {
    --     Idle1 = "rbxassetid://ID_KAMU",
    --     Idle2 = "rbxassetid://ID_KAMU",
    --     Walk  = "rbxassetid://ID_KAMU",
    --     Run   = "rbxassetid://ID_KAMU",
    --     Jump  = "rbxassetid://ID_KAMU",
    --     Fall  = "rbxassetid://ID_KAMU",
    --     Swim  = "rbxassetid://ID_KAMU",
    --     SwimIdle = "rbxassetid://ID_KAMU"
    -- }
}

-- ═══════════════════════════════════════════════════════════════
-- KATEGORI UNTUK SETTING MANUAL
-- ═══════════════════════════════════════════════════════════════

Config.Categories = {
    { key = "Idle1",    label = "Idle 1"    },
    { key = "Idle2",    label = "Idle 2"    },
    { key = "Walk",     label = "Walk"      },
    { key = "Run",      label = "Run"       },
    { key = "Jump",     label = "Jump"      },
    { key = "Fall",     label = "Fall"      },
    { key = "Swim",     label = "Swim"      },
    { key = "SwimIdle", label = "Swim Idle" }
}

-- ═══════════════════════════════════════════════════════════════
-- WARNA UI
-- ═══════════════════════════════════════════════════════════════

Config.Colors = {
    bg          = Color3.fromRGB(22, 22, 32),
    bgTitle     = Color3.fromRGB(38, 38, 58),
    bgBtn       = Color3.fromRGB(45, 45, 68),
    bgBtnHover  = Color3.fromRGB(65, 65, 98),
    bgActive    = Color3.fromRGB(50, 180, 90),
    bgError     = Color3.fromRGB(180, 50, 50),
    bgMin       = Color3.fromRGB(255, 180, 0),
    bgClose     = Color3.fromRGB(255, 80, 80),
    bgInput     = Color3.fromRGB(35, 35, 50),
    text        = Color3.fromRGB(210, 210, 240),
    textDim     = Color3.fromRGB(130, 130, 170),
    stroke      = Color3.fromRGB(60, 60, 95),
    accent      = Color3.fromRGB(110, 130, 255)
}

-- ═══════════════════════════════════════════════════════════════
-- KONFIGURASI UI
-- ═══════════════════════════════════════════════════════════════

Config.UI = {
    width       = 340,
    height      = 480,
    titleHeight = 42
}

return Config
