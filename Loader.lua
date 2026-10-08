--[[
    ═══════════════════════════════════════════════════════════════
    Animation Pack Changer - GitHub Loader
    ═══════════════════════════════════════════════════════════════
    
    Cara pakai:
    1. Ganti GITHUB_USER & GITHUB_REPO sesuai punyamu
    2. Execute script ini di Delta Executor
    
    Loader ini akan:
    - Fetch Config.lua dari GitHub
    - Fetch Main.lua dari GitHub
    - Jalankan Config dulu (inject ke _G), lalu Main
    
    ═══════════════════════════════════════════════════════════════
--]]

-- ═══════════════════════════════════════════════════════════════
-- KONFIGURASI GITHUB - GANTI BAGIAN INI
-- ═══════════════════════════════════════════════════════════════

local GITHUB_USER = "username_kamu"       -- ← ganti
local GITHUB_REPO = "AnimPackChanger"     -- ← ganti
local BRANCH      = "main"                -- "main" atau "master"

local CONFIG_FILE = "Config.lua"
local MAIN_FILE   = "Main.lua"

-- ═══════════════════════════════════════════════════════════════
-- BUILD URLS
-- ═══════════════════════════════════════════════════════════════

local function buildURL(filename)
    return string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/%s",
        GITHUB_USER, GITHUB_REPO, BRANCH, filename
    )
end

local CONFIG_URL = buildURL(CONFIG_FILE)
local MAIN_URL   = buildURL(MAIN_FILE)

-- ═══════════════════════════════════════════════════════════════
-- NOTIFIKASI
-- ═══════════════════════════════════════════════════════════════

local function notify(title, text, duration)
    duration = duration or 3
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration
        })
    end)
    print(string.format("[Loader] %s - %s", title, text))
end

-- ═══════════════════════════════════════════════════════════════
-- FETCH (multi-method fallback)
-- ═══════════════════════════════════════════════════════════════

local function fetch(url)
    -- Method 1: game:HttpGet
    local ok, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    if ok and type(result) == "string" and #result > 0 then
        return result
    end

    -- Method 2: syn.request
    if syn and syn.request then
        local ok2, res = pcall(function()
            return syn.request({ Url = url, Method = "GET" })
        end)
        if ok2 and res and res.Body then
            return res.Body
        end
    end

    -- Method 3: http.request
    if http and http.request then
        local ok3, res = pcall(function()
            return http.request({ Url = url, Method = "GET" })
        end)
        if ok3 and res and res.Body then
            return res.Body
        end
    end

    -- Method 4: request (generic)
    if request then
        local ok4, res = pcall(function()
            return request({ Url = url, Method = "GET" })
        end)
        if ok4 and res and res.Body then
            return res.Body
        end
    end

    -- Method 5: fetch
    if fetch then
        local ok5, res = pcall(function()
            return fetch({ Url = url, Method = "GET" })
        end)
        if ok5 and res and res.Body then
            return res.Body
        end
    end

    return nil, "Semua metode fetch gagal"
end

-- Cek apakah response valid (bukan HTML 404)
local function isValidLua(code)
    if not code or #code < 20 then return false end
    local head = code:sub(1, 200):lower()
    if head:find("<!doctype") then return false end
    if head:find("404: not found") then return false end
    if head:find("<html") then return false end
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN EXECUTION
-- ═══════════════════════════════════════════════════════════════

notify("⏳ Loading", "Mengambil script dari GitHub...", 2)

-- ── Step 1: Fetch Config.lua ─────────────────────────────────
local configCode, cfgErr = fetch(CONFIG_URL)

if not isValidLua(configCode) then
    notify("❌ Config Gagal", "Tidak bisa fetch Config.lua: " .. tostring(cfgErr or "invalid response"), 6)
    warn("[Loader] Config URL: " .. CONFIG_URL)
    return
end

-- Eksekusi Config.lua dan simpan hasilnya
local configChunk, cfgLoadErr = loadstring(configCode, "Config.lua")
if not configChunk then
    notify("❌ Config Error", "Syntax error: " .. tostring(cfgLoadErr), 6)
    return
end

local cfgOK, ConfigTable = pcall(configChunk)
if not cfgOK or type(ConfigTable) ~= "table" then
    notify("❌ Config Invalid", "Config.lua tidak return table. Cek file!", 6)
    warn("[Loader] Hasil: " .. tostring(ConfigTable))
    return
end

print("[Loader] Config.lua OK (" .. #configCode .. " bytes)")

-- Inject ke _G agar Main bisa baca
_G.__ANIMPACK_CONFIG = ConfigTable

-- ── Step 2: Fetch Main.lua ───────────────────────────────────
notify("⏳ Loading", "Mengambil Main.lua...", 1)

local mainCode, mainErr = fetch(MAIN_URL)

if not isValidLua(mainCode) then
    notify("❌ Main Gagal", "Tidak bisa fetch Main.lua: " .. tostring(mainErr or "invalid response"), 6)
    warn("[Loader] Main URL: " .. MAIN_URL)
    return
end

print("[Loader] Main.lua OK (" .. #mainCode .. " bytes)")

-- ── Step 3: Eksekusi Main.lua ────────────────────────────────
local mainChunk, mainLoadErr = loadstring(mainCode, "Main.lua")
if not mainChunk then
    notify("❌ Main Error", "Syntax error: " .. tostring(mainLoadErr), 6)
    return
end

local mainOK, mainRunErr = pcall(mainChunk)
if not mainOK then
    notify("❌ Runtime Error", tostring(mainRunErr), 6)
    warn("[Loader] Runtime: " .. tostring(mainRunErr))
    return
end

notify("✅ Sukses", "Animation Pack Changer siap dipakai!", 3)
print("[Loader] Semua file berhasil di-load.")
