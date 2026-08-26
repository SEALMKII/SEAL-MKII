--// SEAL MKII LOADER v2.2
--// Delta + Render + Supabase + PlatoBoost
--//
--// Features:
--//   • Supabase SEAL keys
--//   • PlatoBoost 24h keys
--//   • LootLabs through PlatoBoost
--//   • Roblox UserId binding
--//   • Dynamic Get Key link
--//   • Saved-key auto login
--//   • Forget saved key
--//   • Render health check
--//   • One-time payload JWT
--//   • Mobile key normalization

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------

local API_URL = "https://seal-hub-key-mlnz.onrender.com"

local DISCORD_URL = "https://discord.gg/YOURINVITE"

local LOADER_VERSION = "2.2.0"

local SAVE_KEY_LOCALLY = true

local SAVED_KEY_FILE = "SEAL_MKII_saved_key.txt"


------------------------------------------------------------
-- SERVICES
------------------------------------------------------------

local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")


------------------------------------------------------------
-- HTTP SUPPORT
------------------------------------------------------------

if type(request) ~= "function" then
    warn("[SEAL MKII] request() is unavailable.")
    return
end


------------------------------------------------------------
-- COLORS
------------------------------------------------------------

local COLORS = {
    background = Color3.fromRGB(20, 20, 25),
    surface = Color3.fromRGB(32, 32, 39),
    surface2 = Color3.fromRGB(38, 38, 46),

    text = Color3.fromRGB(255, 255, 255),
    muted = Color3.fromRGB(150, 150, 160),

    purple = Color3.fromRGB(92, 74, 255),
    discord = Color3.fromRGB(88, 101, 242),

    success = Color3.fromRGB(80, 255, 140),
    warning = Color3.fromRGB(255, 190, 80),
    error = Color3.fromRGB(255, 90, 90),
}


------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end


local function normalizeKey(value)
    local key = tostring(value or "")

    -- Remove BOM / zero-width characters.
    key = key
        :gsub("\239\187\191", "")
        :gsub("\226\128\139", "")
        :gsub("\226\128\140", "")
        :gsub("\226\128\141", "")
        :gsub("\226\129\160", "")

    -- Normalize mobile dash characters.
    key = key
        :gsub("\226\128\147", "-")
        :gsub("\226\128\148", "-")
        :gsub("\226\136\146", "-")

    -- Normalize non-breaking spaces.
    key = key:gsub("\194\160", " ")

    -- Remove newline/tab/control chars.
    key = key:gsub("[%c]", "")

    return trim(key)
end


local function responseStatus(response)
    if type(response) ~= "table" then
        return 0
    end

    return tonumber(
        response.StatusCode
        or response.Status
        or response.status_code
        or response.status
        or 0
    ) or 0
end


local function responseBody(response)
    if type(response) ~= "table" then
        return ""
    end

    return tostring(
        response.Body
        or response.body
        or ""
    )
end


local function decodeJson(body)
    if type(body) ~= "string" or body == "" then
        return nil
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if ok and type(data) == "table" then
        return data
    end

    return nil
end


------------------------------------------------------------
-- LOCAL KEY STORAGE
------------------------------------------------------------

local function canReadFiles()
    return type(isfile) == "function"
        and type(readfile) == "function"
end


local function canWriteFiles()
    return type(writefile) == "function"
end


local function hasSavedKey()
    if not SAVE_KEY_LOCALLY or not canReadFiles() then
        return false
    end

    local ok, exists = pcall(function()
        return isfile(SAVED_KEY_FILE)
    end)

    return ok and exists == true
end


local function readSavedKey()
    if not hasSavedKey() then
        return nil
    end

    local ok, value = pcall(function()
        return readfile(SAVED_KEY_FILE)
    end)

    if not ok then
        return nil
    end

    local key = normalizeKey(value)

    if key == "" then
        return nil
    end

    return key
end


local function saveKey(key)
    if not SAVE_KEY_LOCALLY or not canWriteFiles() then
        return false
    end

    local normalized = normalizeKey(key)

    if normalized == "" then
        return false
    end

    local ok = pcall(function()
        writefile(
            SAVED_KEY_FILE,
            normalized
        )
    end)

    return ok
end


local function deleteSavedKey()
    if not SAVE_KEY_LOCALLY then
        return false
    end

    if type(delfile) ~= "function" then
        return false
    end

    if not hasSavedKey() then
        return true
    end

    local ok = pcall(function()
        delfile(SAVED_KEY_FILE)
    end)

    return ok
end


------------------------------------------------------------
-- REMOVE OLD GUI
------------------------------------------------------------

local old = CoreGui:FindFirstChild("SEALKeyLoader")

if old then
    old:Destroy()
end


------------------------------------------------------------
-- GUI ROOT
------------------------------------------------------------

local gui = Instance.new("ScreenGui")

gui.Name = "SEALKeyLoader"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui


------------------------------------------------------------
-- MAIN WINDOW
------------------------------------------------------------

local NORMAL_SIZE = UDim2.new(
    0,
    390,
    0,
    355
)

local MINIMIZED_SIZE = UDim2.new(
    0,
    390,
    0,
    55
)


local main = Instance.new("Frame")

main.Size = NORMAL_SIZE

main.Position = UDim2.new(
    0.5,
    -195,
    0.5,
    -177
)

main.BackgroundColor3 = COLORS.background
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui


local mainCorner = Instance.new("UICorner")

mainCorner.CornerRadius = UDim.new(
    0,
    14
)

mainCorner.Parent = main


local uiScale = Instance.new("UIScale")

uiScale.Scale = 0.94
uiScale.Parent = main


TweenService:Create(
    uiScale,

    TweenInfo.new(
        0.18,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    ),

    {
        Scale = 1
    }
):Play()


------------------------------------------------------------
-- TOP BAR
------------------------------------------------------------

local topBar = Instance.new("Frame")

topBar.Size = UDim2.new(
    1,
    0,
    0,
    55
)

topBar.BackgroundTransparency = 1
topBar.Active = true
topBar.Parent = main


local title = Instance.new("TextLabel")

title.Size = UDim2.new(
    1,
    -115,
    0,
    32
)

title.Position = UDim2.new(
    0,
    20,
    0,
    9
)

title.BackgroundTransparency = 1
title.Text = "SEAL MKII HUB"
title.TextColor3 = COLORS.text
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar


local minimize = Instance.new("TextButton")

minimize.Size = UDim2.new(
    0,
    32,
    0,
    32
)

minimize.Position = UDim2.new(
    1,
    -78,
    0,
    10
)

minimize.BackgroundColor3 = COLORS.surface2
minimize.BorderSizePixel = 0
minimize.Text = "—"
minimize.TextColor3 = Color3.fromRGB(220, 220, 225)
minimize.Font = Enum.Font.GothamBold
minimize.TextSize = 18
minimize.Parent = topBar


local minimizeCorner = Instance.new("UICorner")

minimizeCorner.CornerRadius = UDim.new(
    0,
    8
)

minimizeCorner.Parent = minimize


local close = Instance.new("TextButton")

close.Size = UDim2.new(
    0,
    32,
    0,
    32
)

close.Position = UDim2.new(
    1,
    -40,
    0,
    10
)

close.BackgroundColor3 = Color3.fromRGB(
    55,
    35,
    40
)

close.BorderSizePixel = 0
close.Text = "×"
close.TextColor3 = Color3.fromRGB(255, 150, 155)
close.Font = Enum.Font.GothamBold
close.TextSize = 20
close.Parent = topBar


local closeCorner = Instance.new("UICorner")

closeCorner.CornerRadius = UDim.new(
    0,
    8
)

closeCorner.Parent = close


------------------------------------------------------------
-- CONTENT
------------------------------------------------------------

local content = Instance.new("Frame")

content.Size = UDim2.new(
    1,
    0,
    1,
    -55
)

content.Position = UDim2.new(
    0,
    0,
    0,
    55
)

content.BackgroundTransparency = 1
content.Parent = main


local subtitle = Instance.new("TextLabel")

subtitle.Size = UDim2.new(
    1,
    -40,
    0,
    22
)

subtitle.Position = UDim2.new(
    0,
    20,
    0,
    0
)

subtitle.BackgroundTransparency = 1
subtitle.Text = "Loader v" .. LOADER_VERSION
subtitle.TextColor3 = COLORS.muted
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 12
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = content


local serverStatus = Instance.new("TextLabel")

serverStatus.Size = UDim2.new(
    1,
    -40,
    0,
    22
)

serverStatus.Position = UDim2.new(
    0,
    20,
    0,
    22
)

serverStatus.BackgroundTransparency = 1
serverStatus.Text = "Render: Checking..."
serverStatus.TextColor3 = COLORS.warning
serverStatus.Font = Enum.Font.Gotham
serverStatus.TextSize = 12
serverStatus.TextXAlignment = Enum.TextXAlignment.Left
serverStatus.Parent = content


local keyBox = Instance.new("TextBox")

keyBox.Size = UDim2.new(
    1,
    -40,
    0,
    44
)

keyBox.Position = UDim2.new(
    0,
    20,
    0,
    52
)

keyBox.BackgroundColor3 = COLORS.surface
keyBox.BorderSizePixel = 0

keyBox.Text = ""

keyBox.PlaceholderText =
    "Enter SEAL or PlatoBoost key..."

keyBox.ClearTextOnFocus = false
keyBox.TextEditable = true

keyBox.TextColor3 = COLORS.text

keyBox.PlaceholderColor3 =
    Color3.fromRGB(
        120,
        120,
        130
    )

keyBox.Font = Enum.Font.Gotham
keyBox.TextSize = 14
keyBox.Parent = content


local keyCorner = Instance.new("UICorner")

keyCorner.CornerRadius = UDim.new(
    0,
    8
)

keyCorner.Parent = keyBox


local unlock = Instance.new("TextButton")

unlock.Size = UDim2.new(
    1,
    -40,
    0,
    44
)

unlock.Position = UDim2.new(
    0,
    20,
    0,
    107
)

unlock.BackgroundColor3 = COLORS.purple
unlock.BorderSizePixel = 0
unlock.Text = "Unlock"
unlock.TextColor3 = COLORS.text
unlock.Font = Enum.Font.GothamBold
unlock.TextSize = 14
unlock.AutoButtonColor = true
unlock.Parent = content


local unlockCorner = Instance.new("UICorner")

unlockCorner.CornerRadius = UDim.new(
    0,
    8
)

unlockCorner.Parent = unlock


local getKey = Instance.new("TextButton")

getKey.Size = UDim2.new(
    0.5,
    -25,
    0,
    39
)

getKey.Position = UDim2.new(
    0,
    20,
    0,
    162
)

getKey.BackgroundColor3 = COLORS.surface2
getKey.BorderSizePixel = 0
getKey.Text = "Get Key"

getKey.TextColor3 = Color3.fromRGB(
    235,
    235,
    240
)

getKey.Font = Enum.Font.GothamBold
getKey.TextSize = 13
getKey.Parent = content


local getKeyCorner = Instance.new("UICorner")

getKeyCorner.CornerRadius = UDim.new(
    0,
    8
)

getKeyCorner.Parent = getKey


local discord = Instance.new("TextButton")

discord.Size = UDim2.new(
    0.5,
    -25,
    0,
    39
)

discord.Position = UDim2.new(
    0.5,
    5,
    0,
    162
)

discord.BackgroundColor3 = COLORS.discord
discord.BorderSizePixel = 0
discord.Text = "Join Discord"
discord.TextColor3 = COLORS.text
discord.Font = Enum.Font.GothamBold
discord.TextSize = 13
discord.Parent = content


local discordCorner = Instance.new("UICorner")

discordCorner.CornerRadius = UDim.new(
    0,
    8
)

discordCorner.Parent = discord


local forgetKey = Instance.new("TextButton")

forgetKey.Size = UDim2.new(
    1,
    -40,
    0,
    34
)

forgetKey.Position = UDim2.new(
    0,
    20,
    0,
    212
)

forgetKey.BackgroundColor3 = Color3.fromRGB(
    45,
    38,
    45
)

forgetKey.BorderSizePixel = 0
forgetKey.Text = "Forget Saved Key"

forgetKey.TextColor3 = Color3.fromRGB(
    220,
    190,
    200
)

forgetKey.Font = Enum.Font.Gotham
forgetKey.TextSize = 12
forgetKey.Visible = hasSavedKey()
forgetKey.Parent = content


local forgetCorner = Instance.new("UICorner")

forgetCorner.CornerRadius = UDim.new(
    0,
    8
)

forgetCorner.Parent = forgetKey


local status = Instance.new("TextLabel")

status.Size = UDim2.new(
    1,
    -40,
    0,
    54
)

status.Position = UDim2.new(
    0,
    20,
    0,
    252
)

status.BackgroundTransparency = 1
status.Text = "Checking server..."
status.TextColor3 = COLORS.muted
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextWrapped = true

status.TextXAlignment =
    Enum.TextXAlignment.Center

status.TextYAlignment =
    Enum.TextYAlignment.Center

status.Parent = content


------------------------------------------------------------
-- UI STATE
------------------------------------------------------------

local busy = false
local serverOnline = false

local apiVersion = nil
local payloadVersion = nil

local loadingNonce = 0


local function setStatus(text, color)
    status.Text = tostring(text or "")

    status.TextColor3 =
        color or COLORS.muted
end


local function setServer(text, color)
    serverStatus.Text = tostring(text or "")

    serverStatus.TextColor3 =
        color or COLORS.muted
end


local function refreshForgetButton()
    forgetKey.Visible = hasSavedKey()
end


local function setBusy(value, label)
    busy = value == true

    loadingNonce =
        loadingNonce + 1

    local myNonce =
        loadingNonce

    keyBox.TextEditable =
        not busy

    unlock.AutoButtonColor =
        not busy

    unlock.Active =
        not busy

    if not busy then
        unlock.Text = "Unlock"
        return
    end

    local base =
        label or "Checking"

    task.spawn(function()
        local dots = 0

        while
            busy
            and loadingNonce == myNonce
        do
            dots =
                (dots % 3) + 1

            unlock.Text =
                base ..
                string.rep(
                    ".",
                    dots
                )

            task.wait(0.28)
        end
    end)
end


------------------------------------------------------------
-- CLIPBOARD
------------------------------------------------------------

local function copyToClipboard(
    text,
    successMessage
)
    local clipboard =
        setclipboard
        or toclipboard
        or writeclipboard

    if type(clipboard) ~= "function" then
        setStatus(
            "Clipboard is not supported.",
            COLORS.warning
        )

        return false
    end

    local ok = pcall(function()
        clipboard(text)
    end)

    if ok then
        setStatus(
            successMessage,
            COLORS.success
        )

        return true
    end

    setStatus(
        "Could not copy link.",
        COLORS.error
    )

    return false
end


------------------------------------------------------------
-- RENDER HEALTH CHECK
------------------------------------------------------------

local function checkServer()
    setServer(
        "Render: Checking...",
        COLORS.warning
    )

    local ok, response = pcall(function()
        return request({
            Url = API_URL,
            Method = "GET",

            Headers = {
                ["Accept"] =
                    "application/json"
            }
        })
    end)

    if
        not ok
        or type(response) ~= "table"
    then
        serverOnline = false

        setServer(
            "Render: Offline",
            COLORS.error
        )

        return false,
            "Could not reach Render."
    end

    local code =
        responseStatus(response)

    local body =
        responseBody(response)

    local data =
        decodeJson(body)

    if
        data
        and data.success == true
    then
        serverOnline = true

        apiVersion =
            tostring(
                data.version or ""
            )

        payloadVersion =
            tostring(
                data.payloadVersion or ""
            )

        local suffix = ""

        if apiVersion ~= "" then
            suffix =
                " • API v" ..
                apiVersion
        end

        setServer(
            "Render: Online" ..
            suffix,

            COLORS.success
        )

        return true
    end

    if
        code >= 200
        and code < 300
    then
        serverOnline = true

        setServer(
            "Render: Online",
            COLORS.success
        )

        return true
    end

    serverOnline = false

    setServer(
        "Render: Offline",
        COLORS.error
    )

    return false,
        "Render returned HTTP " ..
        tostring(code) ..
        "."
end


------------------------------------------------------------
-- GET PLATOBOOST LINK
------------------------------------------------------------

local function getPlatoBoostLink()
    local player =
        Players.LocalPlayer

    if not player then
        return nil, {
            code = "BAD_USER",
            message =
                "Could not identify Roblox account."
        }
    end

    local url =
        API_URL ..
        "/get-key-link?userId=" ..
        tostring(
            player.UserId
        )

    local ok, response = pcall(function()
        return request({
            Url = url,
            Method = "GET",

            Headers = {
                ["Accept"] =
                    "application/json"
            }
        })
    end)

    if
        not ok
        or type(response) ~= "table"
    then
        return nil, {
            code = "NETWORK",
            message =
                "Could not reach Get Key server."
        }
    end

    local code =
        responseStatus(response)

    local data =
        decodeJson(
            responseBody(response)
        )

    if
        data
        and data.success == true
        and type(data.url) == "string"
        and data.url ~= ""
    then
        return data.url, nil
    end

    if
        data
        and data.success == false
    then
        return nil, {
            code =
                tostring(
                    data.code
                    or "GET_KEY_ERROR"
                ),

            message =
                tostring(
                    data.message
                    or
                    "Could not create Get Key link."
                ),

            http = code
        }
    end

    return nil, {
        code = "GET_KEY_ERROR",
        message =
            "Could not create Get Key link."
    }
end


------------------------------------------------------------
-- ACTIVATE KEY
------------------------------------------------------------

local function activateKey(key)
    local normalized =
        normalizeKey(key)

    local player =
        Players.LocalPlayer

    if not player then
        return nil, {
            code = "NO_PLAYER",
            message =
                "Could not identify Roblox player."
        }
    end

    local ok, response = pcall(function()
        return request({
            Url =
                API_URL ..
                "/activate",

            Method =
                "POST",

            Headers = {
                ["Content-Type"] =
                    "application/json",

                ["Accept"] =
                    "application/json"
            },

            Body =
                HttpService:JSONEncode({
                    key = normalized,

                    userId =
                        tostring(
                            player.UserId
                        )
                })
        })
    end)

    if not ok then
        serverOnline = false

        setServer(
            "Render: Offline",
            COLORS.error
        )

        return nil, {
            code = "NETWORK",
            message =
                "Could not connect to Render."
        }
    end

    if type(response) ~= "table" then
        return nil, {
            code = "BAD_RESPONSE",
            message =
                "Executor returned an invalid HTTP response."
        }
    end

    local code =
        responseStatus(response)

    local body =
        responseBody(response)

    local data =
        decodeJson(body)

    if data then
        if
            data.success == true
            and type(data.token) == "string"
            and data.token ~= ""
        then
            payloadVersion =
                tostring(
                    data.payloadVersion
                    or payloadVersion
                    or ""
                )

            return data.token, nil
        end

        if data.success == false then
            return nil, {
                code =
                    tostring(
                        data.code
                        or "KEY_REJECTED"
                    ),

                message =
                    tostring(
                        data.message
                        or "Key rejected."
                    ),

                http = code
            }
        end
    end

    if code == 429 then
        return nil, {
            code = "RATE_LIMIT",
            message =
                "Too many attempts. Try again shortly."
        }
    end

    if code >= 500 then
        return nil, {
            code = "SERVER_ERROR",
            message =
                "Authentication server error."
        }
    end

    return nil, {
        code = "BAD_RESPONSE",
        message =
            "Unexpected server response."
    }
end


------------------------------------------------------------
-- GET PAYLOAD
------------------------------------------------------------

local function getPayload(token)
    local ok, response = pcall(function()
        return request({
            Url =
                API_URL ..
                "/payload",

            Method =
                "GET",

            Headers = {
                ["Authorization"] =
                    "Bearer " ..
                    token,

                ["Accept"] =
                    "text/plain"
            }
        })
    end)

    if not ok then
        return nil,
            "Could not connect while loading payload."
    end

    if type(response) ~= "table" then
        return nil,
            "Invalid payload response."
    end

    local code =
        responseStatus(response)

    local body =
        responseBody(response)

    if body == "" then
        return nil,
            "Payload is empty."
    end

    if
        body:sub(
            1,
            2
        ) == "--"
    then
        if
            body:find(
                "expired",
                1,
                true
            )
        then
            return nil,
                "Payload token expired. Try Unlock again."

        elseif
            body:find(
                "already used",
                1,
                true
            )
        then
            return nil,
                "Payload token was already used."

        elseif
            body:find(
                "user mismatch",
                1,
                true
            )
        then
            return nil,
                "This license belongs to another Roblox account."

        elseif
            body:find(
                "license",
                1,
                true
            )
        then
            return nil,
                "Your license is no longer active."
        end

        return nil, body
    end

    if
        code == 0
        or
        (
            code >= 200
            and code < 300
        )
    then
        return body
    end

    return nil,
        "Payload request failed (HTTP " ..
        tostring(code) ..
        ")."
end


------------------------------------------------------------
-- FRIENDLY AUTH ERRORS
------------------------------------------------------------

local function friendlyAuthError(err)
    local code =
        tostring(
            err
            and err.code
            or ""
        )

    local message =
        tostring(
            err
            and err.message
            or
            "Could not validate key."
        )

    if code == "KEY_INVALID" then
        return "Invalid SEAL key."

    elseif code == "KEY_EXPIRED" then
        return "This SEAL key has expired."

    elseif code == "KEY_DISABLED" then
        return "This SEAL key has been disabled."

    elseif code == "KEY_LIMIT" then
        return "This SEAL key reached its usage limit."

    elseif code == "KEY_USER_MISMATCH" then
        return "This key belongs to another Roblox account."

    elseif code == "PLATO_KEY_INVALID" then
        return "Invalid or expired PlatoBoost key."

    elseif code == "PLATO_ACTIVE_KEY" then
        return message

    elseif
        code == "BAD_USER"
        or code == "NO_PLAYER"
    then
        return "Could not identify your Roblox account."

    elseif code == "RATE_LIMIT" then
        return "Too many attempts. Try again shortly."

    elseif code == "NETWORK" then
        return "Render is unreachable right now."

    elseif code == "PLATO_LINK_ERROR" then
        return "Could not create PlatoBoost link."

    elseif code == "GET_KEY_ERROR" then
        return "Could not create Get Key link."

    elseif code == "SERVER_ERROR" then
        return "Authentication server error."
    end

    return message
end


local function shouldForgetSavedKey(err)
    local code =
        tostring(
            err
            and err.code
            or ""
        )

    return
        code == "KEY_INVALID"
        or code == "KEY_EXPIRED"
        or code == "KEY_DISABLED"
        or code == "KEY_LIMIT"
        or code == "KEY_USER_MISMATCH"
        or code == "PLATO_KEY_INVALID"
end


------------------------------------------------------------
-- CLOSE GUI
------------------------------------------------------------

local function closeGui()
    local tween =
        TweenService:Create(
            uiScale,

            TweenInfo.new(
                0.13,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.In
            ),

            {
                Scale = 0.94
            }
        )

    tween:Play()
    tween.Completed:Wait()

    if gui then
        gui:Destroy()
    end
end


------------------------------------------------------------
-- UNLOCK FLOW
------------------------------------------------------------

local unlockScript


unlockScript = function(isAutoLogin)
    if busy then
        return
    end

    status.TextSize = 12

    local enteredKey =
        normalizeKey(
            keyBox.Text
        )

    keyBox.Text =
        enteredKey

    if enteredKey == "" then
        setStatus(
            "Enter your key first.",
            COLORS.warning
        )

        return
    end

    setBusy(
        true,
        "Checking"
    )

    if isAutoLogin then
        setStatus(
            "Signing in with saved key...",
            COLORS.muted
        )
    else
        setStatus(
            "Validating key...",
            COLORS.muted
        )
    end


    if not serverOnline then
        local online =
            checkServer()

        if not online then
            setBusy(false)

            setStatus(
                "Render is offline or unreachable.",
                COLORS.error
            )

            return
        end
    end


    local token, authError =
        activateKey(
            enteredKey
        )


    if not token then
        setBusy(false)

        if
            isAutoLogin
            and shouldForgetSavedKey(
                authError
            )
        then
            deleteSavedKey()
            refreshForgetButton()

            keyBox.Text = ""

            setStatus(
                friendlyAuthError(
                    authError
                ),

                COLORS.error
            )

            return
        end

        setStatus(
            friendlyAuthError(
                authError
            ),

            COLORS.error
        )

        return
    end


    --------------------------------------------------------
    -- SAVE ACCEPTED KEY
    --------------------------------------------------------

    if SAVE_KEY_LOCALLY then
        saveKey(
            enteredKey
        )

        refreshForgetButton()
    end


    --------------------------------------------------------
    -- LOAD PAYLOAD
    --------------------------------------------------------

    local versionText = ""

    if
        payloadVersion
        and payloadVersion ~= ""
    then
        versionText =
            " v" ..
            payloadVersion
    end

    setStatus(
        "Key accepted. Loading payload" ..
        versionText ..
        "...",

        COLORS.success
    )

    setBusy(
        true,
        "Loading"
    )

    local source, payloadError =
        getPayload(
            token
        )

    if not source then
        setBusy(false)

        setStatus(
            payloadError
            or
            "Could not load payload.",

            COLORS.error
        )

        return
    end


    --------------------------------------------------------
    -- COMPILE
    --------------------------------------------------------

    if type(loadstring) ~= "function" then
        setBusy(false)

        setStatus(
            "loadstring is unavailable in this environment.",
            COLORS.error
        )

        return
    end

    local compiled, compileError =
        loadstring(source)

    if not compiled then
        setBusy(false)

        local errorText =
            tostring(
                compileError
                or
                "Unknown compile error"
            )

        warn(
            "[SEAL MKII] Compile error:",
            errorText
        )

        status.TextSize = 10

        status.Text =
            "COMPILE ERROR:\n" ..
            errorText

        status.TextColor3 =
            COLORS.error

        local clipboard =
            setclipboard
            or toclipboard
            or writeclipboard

        if type(clipboard) == "function" then
            pcall(function()
                clipboard(
                    errorText
                )
            end)
        end

        unlock.Text =
            "Compile Error"

        return
    end


    --------------------------------------------------------
    -- SUCCESS
    --------------------------------------------------------

    setStatus(
        "Authorized.",
        COLORS.success
    )

    unlock.Text =
        "Unlocked"

    busy = false

    task.wait(0.25)

    closeGui()


    --------------------------------------------------------
    -- RUN PAYLOAD
    --------------------------------------------------------

    local runOk, runtimeError =
        pcall(compiled)

    if not runOk then
        warn(
            "[SEAL MKII] Payload runtime error:",
            runtimeError
        )
    end
end


------------------------------------------------------------
-- UNLOCK BUTTON
------------------------------------------------------------

unlock.MouseButton1Click:Connect(function()
    unlockScript(false)
end)


keyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        unlockScript(false)
    end
end)


------------------------------------------------------------
-- GET KEY BUTTON
------------------------------------------------------------

getKey.MouseButton1Click:Connect(function()
    if busy then
        return
    end

    setStatus(
        "Creating PlatoBoost link...",
        COLORS.muted
    )

    getKey.Text =
        "Creating..."

    getKey.Active =
        false

    getKey.AutoButtonColor =
        false


    local link, linkError =
        getPlatoBoostLink()


    getKey.Text =
        "Get Key"

    getKey.Active =
        true

    getKey.AutoButtonColor =
        true


    if not link then
        setStatus(
            friendlyAuthError(
                linkError
            ),

            COLORS.error
        )

        return
    end


    copyToClipboard(
        link,
        "PlatoBoost Get Key link copied."
    )
end)


------------------------------------------------------------
-- DISCORD BUTTON
------------------------------------------------------------

discord.MouseButton1Click:Connect(function()
    copyToClipboard(
        DISCORD_URL,
        "Discord invite copied."
    )
end)


------------------------------------------------------------
-- FORGET KEY BUTTON
------------------------------------------------------------

forgetKey.MouseButton1Click:Connect(function()
    if busy then
        return
    end

    local removed =
        deleteSavedKey()

    keyBox.Text = ""

    refreshForgetButton()

    if removed then
        setStatus(
            "Saved key removed.",
            COLORS.success
        )
    else
        setStatus(
            "No saved key was removed.",
            COLORS.muted
        )
    end
end)


------------------------------------------------------------
-- CLOSE BUTTON
------------------------------------------------------------

close.MouseButton1Click:Connect(function()
    if busy then
        return
    end

    closeGui()
end)


------------------------------------------------------------
-- MINIMIZE
------------------------------------------------------------

local minimized = false


minimize.MouseButton1Click:Connect(function()
    if busy then
        return
    end

    minimized =
        not minimized

    if minimized then
        content.Visible = false

        minimize.Text = "+"

        TweenService:Create(
            main,

            TweenInfo.new(
                0.16,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            ),

            {
                Size =
                    MINIMIZED_SIZE
            }
        ):Play()

    else
        minimize.Text = "—"

        local tween =
            TweenService:Create(
                main,

                TweenInfo.new(
                    0.16,
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.Out
                ),

                {
                    Size =
                        NORMAL_SIZE
                }
            )

        tween:Play()
        tween.Completed:Wait()

        content.Visible = true
    end
end)


------------------------------------------------------------
-- DRAGGING
------------------------------------------------------------

local dragging = false

local dragInput = nil
local dragStart = nil
local startPosition = nil


local function updateDrag(input)
    local delta =
        input.Position -
        dragStart

    main.Position =
        UDim2.new(
            startPosition.X.Scale,

            startPosition.X.Offset +
            delta.X,

            startPosition.Y.Scale,

            startPosition.Y.Offset +
            delta.Y
        )
end


topBar.InputBegan:Connect(function(input)
    if
        input.UserInputType ==
            Enum.UserInputType.MouseButton1
        or
        input.UserInputType ==
            Enum.UserInputType.Touch
    then
        dragging = true

        dragStart =
            input.Position

        startPosition =
            main.Position

        input.Changed:Connect(function()
            if
                input.UserInputState ==
                    Enum.UserInputState.End
            then
                dragging = false
            end
        end)
    end
end)


topBar.InputChanged:Connect(function(input)
    if
        input.UserInputType ==
            Enum.UserInputType.MouseMovement
        or
        input.UserInputType ==
            Enum.UserInputType.Touch
    then
        dragInput = input
    end
end)


UserInputService.InputChanged:Connect(function(input)
    if
        input == dragInput
        and dragging
    then
        updateDrag(input)
    end
end)


------------------------------------------------------------
-- STARTUP
------------------------------------------------------------

task.spawn(function()
    local online, healthError =
        checkServer()

    if not online then
        setStatus(
            healthError
            or
            "Render is offline.",

            COLORS.error
        )

        return
    end


    --------------------------------------------------------
    -- AUTO LOGIN
    --------------------------------------------------------

    local saved =
        readSavedKey()

    if saved then
        keyBox.Text = saved

        refreshForgetButton()

        setStatus(
            "Saved key found. Signing in...",
            COLORS.muted
        )

        task.wait(0.2)

        unlockScript(true)

    else
        setStatus(
            "Enter a key or press Get Key.",
            COLORS.muted
        )
    end
end)
