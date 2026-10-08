-- ═══════════════════════════════════════════════════════════════
-- LOADER v2 - Semua output via Notifikasi
-- ═══════════════════════════════════════════════════════════════

local function N(title, text, dur)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = tostring(title),
            Text = tostring(text),
            Duration = dur or 4
        })
    end)
end

N("Step 1", "Loader mulai", 2)

-- ═══════════════════════════════════════════════════════════════
-- GANTI 3 BARIS INI DENGAN PUNYAMU
-- ═══════════════════════════════════════════════════════════════
local GITHUB_USER = "sixxgibran-cmyk"
local GITHUB_REPO = "animpack-changer"
local BRANCH      = "main"
-- ═══════════════════════════════════════════════════════════════

N("Step 2", "Config: " .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/" .. BRANCH, 5)

if GITHUB_USER == "username_kamu" then
    N("❌ STOP", "Kamu belum ganti GITHUB_USER!", 10)
    return
end

-- ── Fetch function ────────────────────────────────────────────
local function fetch(url)
    local methods = {
        function() return game:HttpGet(url, true) end,
    }
    if syn and syn.request then
        table.insert(methods, function()
            local r = syn.request({Url = url, Method = "GET"})
            return r and r.Body
        end)
    end
    if http and http.request then
        table.insert(methods, function()
            local r = http.request({Url = url, Method = "GET"})
            return r and r.Body
        end)
    end
    if request then
        table.insert(methods, function()
            local r = request({Url = url, Method = "GET"})
            return r and r.Body
        end)
    end

    for i, fn in ipairs(methods) do
        local ok, result = pcall(fn)
        if ok and type(result) == "string" and #result > 0 then
            return result, "method_" .. i
        end
    end
    return nil, "all_failed"
end

-- ── Build URLs ────────────────────────────────────────────────
local CONFIG_URL = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/Config.lua",
    GITHUB_USER, GITHUB_REPO, BRANCH
)
local MAIN_URL = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/Main.lua",
    GITHUB_USER, GITHUB_REPO, BRANCH
)

-- ── Fetch Config ──────────────────────────────────────────────
N("Step 3", "Mengambil Config.lua...", 2)

local configCode, cfgMethod = fetch(CONFIG_URL)

if not configCode then
    N("❌ Config Gagal", "Fetch error: " .. tostring(cfgMethod), 10)
    return
end

N("Step 4", "Config: " .. #configCode .. " bytes via " .. cfgMethod, 3)

-- Cek response HTML 404
local head = configCode:sub(1, 300):lower()
if head:find("404: not found") or head:find("<!doctype") or head:find("<html") then
    N("❌ Config 404", "File Config.lua tidak ada di GitHub!", 10)
    return
end

N("Step 5", "Config OK, loadstring...", 2)

-- ── Loadstring Config ─────────────────────────────────────────
local configChunk, loadErr = loadstring(configCode, "Config.lua")
if not configChunk then
    N("❌ Syntax Error", tostring(loadErr):sub(1, 150), 10)
    return
end

local ok, ConfigTable = pcall(configChunk)
if not ok then
    N("❌ Runtime Error", tostring(ConfigTable):sub(1, 150), 10)
    return
end

if type(ConfigTable) ~= "table" then
    N("❌ Config Invalid", "Return bukan table: " .. type(ConfigTable), 10)
    return
end

if not ConfigTable.AnimationPacks then
    N("❌ Config Invalid", "AnimationPacks tidak ada", 10)
    return
end

N("Step 6", "Config OK! Lanjut ke Main.lua", 3)

-- ── Fetch Main ────────────────────────────────────────────────
local mainCode, mainMethod = fetch(MAIN_URL)

if not mainCode then
    N("❌ Main Gagal", "Fetch error: " .. tostring(mainMethod), 10)
    return
end

N("Step 7", "Main: " .. #mainCode .. " bytes", 3)

local mainHead = mainCode:sub(1, 300):lower()
if mainHead:find("404: not found") or mainHead:find("<!doctype") then
    N("❌ Main 404", "File Main.lua tidak ada di GitHub!", 10)
    return
end

-- ── Execute Main ──────────────────────────────────────────────
_G.__ANIMPACK_CONFIG = ConfigTable

local mainChunk, mainLoadErr = loadstring(mainCode, "Main.lua")
if not mainChunk then
    N("❌ Main Syntax", tostring(mainLoadErr):sub(1, 150), 10)
    return
end

local mainOK, mainRunErr = pcall(mainChunk)
if not mainOK then
    N("❌ Main Runtime", tostring(mainRunErr):sub(1, 150), 10)
    return
end

N("✅ Sukses", "Animation Pack Changer siap!", 5)
