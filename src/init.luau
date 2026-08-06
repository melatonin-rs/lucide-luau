local Lucide = {
    _cacheDir = "lucide-cache",
    _repo = "melatonin-rs/lucide-luau",
    _userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    _inFlight = {},
    _semaphore = 0,
    _maxParallel = 4,
}

local SOURCES = {
    "https://cdn.jsdelivr.net/gh/%s@main/icons/%s_%d.png",
}

local PNG_SIG = string.char(137, 80, 78, 71)

local env = {
    hasRequest = request ~= nil,
    hasHttpGet = game and game.HttpGet,
    hasWritefile = writefile ~= nil,
    hasIsfile = isfile ~= nil,
    hasMakefolder = makefolder ~= nil,
    hasGetcustomasset = getcustomasset ~= nil,
}

local function envCheck()
    if not env.hasGetcustomasset then
        error("[Lucide] getcustomasset not found")
    end
    if not env.hasRequest and not env.hasHttpGet then
        error("[Lucide] No network access")
    end
end

local function httpGet(url)
    if env.hasRequest then
        local ok, response = pcall(function()
            return request({
                Url = url,
                Method = "GET",
                Headers = {
                    ["User-Agent"] = Lucide._userAgent,
                    ["Accept"] = "image/png,image/*,*/*;q=0.8",
                },
            })
        end)
        if ok and response and response.StatusCode == 200 and response.Body then
            return true, response.Body
        end
    end

    if env.hasHttpGet then
        local ok, body = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and body and #body > 100 then
            return true, body
        end
    end

    return false, nil
end

local function validateName(name)
    if type(name) ~= "string" then return false end
    return name:match("^[a-z0-9%-_]+$") ~= nil and #name <= 64
end

local function fetchPng(name, size)
    for _, template in ipairs(SOURCES) do
        local url
        if template:find("jsdelivr%.net/gh") then
            url = template:format(Lucide._repo, name, size)
        else
            url = template:format(name, size)
        end

        local ok, body = httpGet(url)
        if ok and body then
            if #body >= 4 and body:sub(1, 4) == PNG_SIG then
                return body
            end
        end
    end
    return nil
end

function Lucide.get(name, size)
    assert(validateName(name), string.format("[Lucide] Invalid icon name: %q", tostring(name)))

    size = size or 96
    local cachePath = string.format("%s/%s_%d.png", Lucide._cacheDir, name, size)

    if env.hasIsfile and isfile(cachePath) then
        return getcustomasset(cachePath)
    end

    local key = cachePath
    if Lucide._inFlight[key] then
        while Lucide._inFlight[key] do task.wait(0.05) end
        if env.hasIsfile and isfile(cachePath) then
            return getcustomasset(cachePath)
        end
    end

    while Lucide._semaphore >= Lucide._maxParallel do task.wait(0.05) end

    Lucide._inFlight[key] = true
    Lucide._semaphore = Lucide._semaphore + 1

    local png = nil
    local ok, err = pcall(function()
        png = fetchPng(name, size)
    end)

    Lucide._inFlight[key] = nil
    Lucide._semaphore = Lucide._semaphore - 1

    if not ok then
        error(string.format("[Lucide] Error loading %s: %s", name, tostring(err)))
    end
    if not png then
        error(string.format("[Lucide] Icon %q not found", name))
    end

    if env.hasWritefile then
        pcall(function()
            if not isfolder(Lucide._cacheDir) then makefolder(Lucide._cacheDir) end
            writefile(cachePath, png)
        end)
    end

    return getcustomasset(cachePath)
end

function Lucide.apply(label, name, size)
    assert(typeof(label) == "Instance", "[Lucide] apply: expected Instance")
    label.Image = Lucide.get(name, size)
    label.ScaleType = Enum.ScaleType.Fit
end

function Lucide.preload(names, size)
    assert(type(names) == "table", "[Lucide] preload: expected array")
    size = size or 96

    local done = 0
    for _, name in ipairs(names) do
        task.spawn(function()
            pcall(Lucide.get, Lucide, name, size)
            done = done + 1
        end)
    end

    while done < #names do task.wait(0.1) end
end

function Lucide.clearCache()
    if not env.hasWritefile then return end
    pcall(function()
        if isfolder(Lucide._cacheDir) and listfiles then
            for _, f in ipairs(listfiles(Lucide._cacheDir)) do
                pcall(delfile, f)
            end
            pcall(delfolder, Lucide._cacheDir)
        end
    end)
end

envCheck()
return Lucide
