-- ═══════════════════════════════════════════════════════════════
-- DEBUG LOADER - Versi diagnosa
-- ═══════════════════════════════════════════════════════════════

local GITHUB_USER = "sixxgibran-cmyk"
local GITHUB_REPO = "AnimPackChanger"
local BRANCH      = "main"

local CONFIG_FILE = "Config.lua"
local MAIN_FILE   = "Main.lua"

local function buildURL(f)
    return string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/%s",
        GITHUB_USER, GITHUB_REPO, BRANCH, f
    )
end

local CONFIG_URL = buildURL(CONFIG_FILE)
local MAIN_URL   = buildURL(MAIN_FILE)

print("═══════════════════════════════════════")
print("[DEBUG] GITHUB_USER : " .. GITHUB_USER)
print("[DEBUG] GITHUB_REPO : " .. GITHUB_REPO)
print("[DEBUG] BRANCH      : " .. BRANCH)
print("[DEBUG] CONFIG URL  : " .. CONFIG_URL)
print("[DEBUG] MAIN URL    : " .. MAIN_URL)
print("═══════════════════════════════════════")

local function fetch(url)
    local ok, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    if ok and type(result) == "string" and #result > 0 then
        return result
    end

    if syn and syn.request then
        local ok2, res = pcall(function()
            return syn.request({ Url = url, Method = "GET" })
        end)
        if ok2 and res and res.Body then return res.Body end
    end

    if http and http.request then
        local ok3, res = pcall(function()
            return http.request({ Url = url, Method = "GET" })
        end)
        if ok3 and res and res.Body then return res.Body end
    end

    if request then
        local ok4, res = pcall(function()
            return request({ Url = url, Method = "GET" })
        end)
        if ok4 and res and res.Body then return res.Body end
    end

    if fetch then
        local ok5, res = pcall(function()
            return fetch({ Url = url, Method = "GET" })
        end)
        if ok5 and res and res.Body then return res.Body end
    end

    return nil, "semua metode fetch gagal"
end

-- ── Fetch Config ─────────────────────────────────────────────
print("[DEBUG] Mengambil Config.lua...")
local configCode, cfgErr = fetch(CONFIG_URL)

if not configCode then
    warn("[DEBUG] ❌ Fetch gagal: " .. tostring(cfgErr))
    return
end

print("[DEBUG] Response length: " .. #configCode .. " bytes")
print("[DEBUG] 200 char pertama:")
print("─────")
print(configCode:sub(1, 200))
print("─────")

-- Cek apakah HTML 404
local head = configCode:sub(1, 300):lower()
if head:find("404: not found") or head:find("<!doctype") or head:find("<html") then
    warn("[DEBUG] ❌ Response bukan Lua — file tidak ditemukan di GitHub!")
    warn("[DEBUG] Pastikan:")
    warn("  1. Repo PUBLIC")
    warn("  2. Nama file persis: " .. CONFIG_FILE)
    warn("  3. Branch benar: " .. BRANCH)
    warn("  4. File sudah di-commit")
    return
end

print("[DEBUG] Response terlihat seperti Lua. Mencoba loadstring...")

-- ── Load Config ──────────────────────────────────────────────
local configChunk, loadErr = loadstring(configCode, CONFIG_FILE)
if not configChunk then
    warn("[DEBUG] ❌ Syntax error di Config.lua:")
    warn(tostring(loadErr))
    return
end

local ok, ConfigTable = pcall(configChunk)
if not ok then
    warn("[DEBUG] ❌ Runtime error saat execute Config.lua:")
    warn(tostring(ConfigTable))
    return
end

print("[DEBUG] Config.lua tipe hasil: " .. type(ConfigTable))

if type(ConfigTable) ~= "table" then
    warn("[DEBUG] ❌ Config.lua TIDAK return table.")
    warn("[DEBUG] Nilai yang di-return: " .. tostring(ConfigTable))
    warn("[DEBUG] Pastikan baris terakhir Config.lua: return Config")
    return
end

-- Cek isi table
local keys = {}
for k, _ in pairs(ConfigTable) do
    table.insert(keys, k)
end
print("[DEBUG] ✅ Config OK. Keys: " .. table.concat(keys, ", "))

if not ConfigTable.AnimationPacks then
    warn("[DEBUG] ❌ Config.AnimationPacks tidak ada!")
    return
end

if not ConfigTable.Categories then
    warn("[DEBUG] ❌ Config.Categories tidak ada!")
    return
end

-- ── Inject & Load Main ───────────────────────────────────────
_G.__ANIMPACK_CONFIG = ConfigTable
print("[DEBUG] Config di-inject ke _G. Mengambil Main.lua...")

local mainCode, mainErr = fetch(MAIN_URL)

if not mainCode then
    warn("[DEBUG] ❌ Fetch Main gagal: " .. tostring(mainErr))
    return
end

print("[DEBUG] Main.lua length: " .. #mainCode .. " bytes")

local mainHead = mainCode:sub(1, 300):lower()
if mainHead:find("404: not found") or mainHead:find("<!doctype") then
    warn("[DEBUG] ❌ Main.lua tidak ditemukan di GitHub!")
    return
end

local mainChunk, mainLoadErr = loadstring(mainCode, MAIN_FILE)
if not mainChunk then
    warn("[DEBUG] ❌ Syntax error di Main.lua:")
    warn(tostring(mainLoadErr))
    return
end

local mainOK, mainRunErr = pcall(mainChunk)
if not mainOK then
    warn("[DEBUG] ❌ Runtime error di Main.lua:")
    warn(tostring(mainRunErr))
    return
end

print("═══════════════════════════════════════")
print("[DEBUG] ✅ SEMUA FILE BERHASIL DI-LOAD")
print("═══════════════════════════════════════")
