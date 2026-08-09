--[[ GM/CustomNPC/NNCustomNpcInit.lua — серверный AIO для custom NPC ]]

if not _G.NN_BOOTSTRAP_ACTIVE then return end

local NobleNext = require("NobleNext")
if not NobleNext.IsMainState() then
    return {}
end

if _G.NN_GM_CUSTOMNPC_BOOTSTRAPPED then
    return package.loaded["GM.CustomNPC.NNCustomNpcInit"] or {}
end
_G.NN_GM_CUSTOMNPC_BOOTSTRAPPED = true

local HANDLER_NAME = "CustomNpcHandlers"
local AIO = NobleNext.AIO
local Handlers = AIO.AddHandlers(HANDLER_NAME, {})

local DEFAULT_LIST_LIMIT = 50

local function RequireStaff(player)
    return NobleNext.HasStaffPermission(player)
end

local function Trim(value)
    return NobleNext.Trim(value or "")
end

local function RunService(player, command)
    if not RequireStaff(player) then
        return false, "Недостаточно прав."
    end

    local ok, err = pcall(function()
        player:RunCommand(command)
    end)

    if not ok then
        NobleNext.LogError("CustomNPC", "RunCommand failed: " .. tostring(err) .. " cmd=" .. command)
        return false, "Команда не выполнена."
    end

    NobleNext.LogAudit("CustomNPC", "run", player, command)
    return true, nil
end

local function QuoteDisplayName(name)
    -- ChatCommand Tail accepts the rest of the line; keep as single trailing arg.
    return Trim(name)
end

function Handlers.GetNpcList(player, includeAll, offset, limit)
    if not RequireStaff(player) then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Недостаточно прав.")
        return
    end
    includeAll = includeAll and true or false
    offset = tonumber(offset) or 0
    limit = tonumber(limit) or DEFAULT_LIST_LIMIT
    if limit < 1 then limit = DEFAULT_LIST_LIMIT end
    if limit > 200 then limit = 200 end
    if offset < 0 then offset = 0 end

    local rows = {}
    if type(player.GetCustomNpcList) == "function" then
        local ok, result = pcall(player.GetCustomNpcList, player, includeAll, offset, limit)
        if ok and type(result) == "table" then
            rows = result
        else
            NobleNext.LogError("CustomNPC", "GetCustomNpcList failed: " .. tostring(result))
            AIO.Handle(player, HANDLER_NAME, "Status", false, "Список NPC недоступен (нужен обновлённый core).")
            return
        end
    else
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Список NPC недоступен (нужен обновлённый core).")
        return
    end

    AIO.Handle(player, HANDLER_NAME, "NpcList", rows, {
        includeAll = includeAll,
        offset = offset,
        limit = limit,
    })
end

function Handlers.GetCatalog(player, availableOnly)
    if not RequireStaff(player) then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Недостаточно прав.")
        return
    end
    if availableOnly == nil then availableOnly = true end

    local races = {}
    if type(player.GetCustomNpcRaceCatalog) == "function" then
        local ok, result = pcall(player.GetCustomNpcRaceCatalog, player, availableOnly and true or false)
        if ok and type(result) == "table" then
            races = result
        else
            NobleNext.LogError("CustomNPC", "GetCustomNpcRaceCatalog failed: " .. tostring(result))
            AIO.Handle(player, HANDLER_NAME, "Status", false, "Каталог рас недоступен (нужен обновлённый core).")
            return
        end
    else
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Каталог рас недоступен (нужен обновлённый core).")
        return
    end

    AIO.Handle(player, HANDLER_NAME, "Catalog", {
        rev = 1,
        races = races,
    })
end

--- Look hydrate: race/gender/subname/display/scale for one key + variation.
function Handlers.GetNpcDetail(player, key, variation)
    if not RequireStaff(player) then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Недостаточно прав.")
        return
    end
    key = Trim(key or "")
    variation = tonumber(variation) or 1
    if key == "" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Укажите ключ NPC.")
        return
    end
    if variation < 1 then
        variation = 1
    end

    if type(player.GetCustomNpcDetail) ~= "function" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Detail NPC недоступен (нужен обновлённый core).")
        return
    end

    local ok, detailOrErr, err = pcall(player.GetCustomNpcDetail, player, key, variation)
    if not ok then
        NobleNext.LogError("CustomNpc", "GetCustomNpcDetail pcall: " .. tostring(detailOrErr))
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Не удалось загрузить детали NPC.")
        return
    end
    if type(detailOrErr) ~= "table" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, tostring(err or detailOrErr or "not found"))
        return
    end

    AIO.Handle(player, HANDLER_NAME, "NpcDetail", detailOrErr)
end

-- Legacy chat dump (kept for /debug); UI uses GetNpcList.
function Handlers.List(player)
    if not RequireStaff(player) then return end
    RunService(player, "cnpc list")
    AIO.Handle(player, HANDLER_NAME, "Status", true, "Запрошен список custom NPC (.cnpc list).")
end

function Handlers.Reload(player, key)
    if not RequireStaff(player) then return end
    key = Trim(key or "")
    if key == "" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Укажите ключ NPC (не all без подтверждения в UI).")
        return
    end
    RunService(player, "cnpc reload " .. key)
    AIO.Handle(player, HANDLER_NAME, "Status", true, "Отправлена команда reload для '" .. key .. "'.")
end

local function ApplySubnameAfterCreate(player, displayName, subName)
    subName = Trim(subName or "")
    if subName == "" or type(player.GetCustomNpcList) ~= "function" then
        return
    end
    local ok, rows = pcall(player.GetCustomNpcList, player, false, 0, DEFAULT_LIST_LIMIT)
    if not ok or type(rows) ~= "table" then
        return
    end
    local matchKey
    for i = #rows, 1, -1 do
        local row = rows[i]
        if row and tostring(row.name or "") == displayName and row.key then
            matchKey = tostring(row.key)
            break
        end
    end
    if not matchKey then
        return
    end
    RunService(player, "cnpc set subname " .. matchKey .. " " .. subName)
end

function Handlers.CreateBlank(player, displayName, subName)
    if not RequireStaff(player) then return end
    displayName = QuoteDisplayName(displayName)
    if displayName == "" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Укажите отображаемое имя.")
        return
    end
    local ok = RunService(player, "cnpc add " .. displayName)
    if ok then
        ApplySubnameAfterCreate(player, displayName, subName)
    end
    AIO.Handle(player, HANDLER_NAME, "Status", ok, ok and ("Создан пустой NPC: " .. displayName) or "Не удалось создать NPC.")
    if ok then
        Handlers.GetNpcList(player, false, 0, DEFAULT_LIST_LIMIT)
    end
end

function Handlers.CloneSelf(player, displayName, subName)
    if not RequireStaff(player) then return end
    displayName = QuoteDisplayName(displayName)
    if displayName == "" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Укажите отображаемое имя.")
        return
    end
    local ok = RunService(player, "cnpc clone " .. displayName)
    if ok then
        ApplySubnameAfterCreate(player, displayName, subName)
    end
    AIO.Handle(player, HANDLER_NAME, "Status", ok, ok and ("Клон себя: " .. displayName) or "Не удалось клонировать.")
    if ok then
        Handlers.GetNpcList(player, false, 0, DEFAULT_LIST_LIMIT)
    end
end

function Handlers.CloneTarget(player, displayName, subName)
    if not RequireStaff(player) then return end
    displayName = QuoteDisplayName(displayName)
    if displayName == "" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Укажите отображаемое имя.")
        return
    end
    local ok = RunService(player, "cnpc clone target " .. displayName)
    if ok then
        ApplySubnameAfterCreate(player, displayName, subName)
    end
    AIO.Handle(player, HANDLER_NAME, "Status", ok, ok and ("Клон цели: " .. displayName) or "Не удалось клонировать цель.")
    if ok then
        Handlers.GetNpcList(player, false, 0, DEFAULT_LIST_LIMIT)
    end
end

function Handlers.ApplySelected(player, variation)
    if not RequireStaff(player) then return end
    variation = tonumber(variation) or 1
    if variation < 1 then variation = 1 end
    local ok = RunService(player, "cnpc apply " .. tostring(math.floor(variation)))
    AIO.Handle(player, HANDLER_NAME, "Status", ok, ok and ("Apply variation " .. tostring(math.floor(variation)) .. " к выбранному NPC.") or "Apply не выполнен (нужен .npc select).")
end

function Handlers.GetFaceOptions(player, key, variation)
    if not RequireStaff(player) then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Недостаточно прав.")
        return
    end
    key = Trim(key or "")
    variation = tonumber(variation) or 1
    if key == "" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Укажите ключ NPC.")
        return
    end
    if variation < 1 then variation = 1 end

    if type(player.GetCustomNpcFaceOptions) ~= "function" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Face options недоступны (нужен обновлённый core).")
        return
    end

    local ok, payloadOrErr, err = pcall(player.GetCustomNpcFaceOptions, player, key, variation)
    if not ok then
        NobleNext.LogError("CustomNpc", "GetCustomNpcFaceOptions pcall: " .. tostring(payloadOrErr))
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Не удалось загрузить опции лица.")
        return
    end
    if type(payloadOrErr) ~= "table" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, tostring(err or payloadOrErr or "not found"))
        return
    end

    AIO.Handle(player, HANDLER_NAME, "FaceOptions", payloadOrErr)
end

function Handlers.GetFaceChoices(player, key, optionIndex, variation)
    if not RequireStaff(player) then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Недостаточно прав.")
        return
    end
    key = Trim(key or "")
    optionIndex = tonumber(optionIndex)
    variation = tonumber(variation) or 1
    if key == "" or not optionIndex then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Нужны key и optionIndex.")
        return
    end
    if variation < 1 then variation = 1 end

    if type(player.GetCustomNpcFaceChoices) ~= "function" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Face choices недоступны (нужен обновлённый core).")
        return
    end

    local ok, payloadOrErr, err = pcall(player.GetCustomNpcFaceChoices, player, key, math.floor(optionIndex), variation)
    if not ok then
        NobleNext.LogError("CustomNpc", "GetCustomNpcFaceChoices pcall: " .. tostring(payloadOrErr))
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Не удалось загрузить варианты лица.")
        return
    end
    if type(payloadOrErr) ~= "table" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, tostring(err or payloadOrErr or "not found"))
        return
    end

    AIO.Handle(player, HANDLER_NAME, "FaceChoices", payloadOrErr)
end

function Handlers.GetModelList(player, key)
    if not RequireStaff(player) then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Недостаточно прав.")
        return
    end
    key = Trim(key or "")
    if key == "" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Укажите ключ NPC.")
        return
    end

    if type(player.GetCustomNpcModelList) ~= "function" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Model list недоступен (нужен обновлённый core).")
        return
    end

    local ok, payloadOrErr, err = pcall(player.GetCustomNpcModelList, player, key)
    if not ok then
        NobleNext.LogError("CustomNpc", "GetCustomNpcModelList pcall: " .. tostring(payloadOrErr))
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Не удалось загрузить список видов.")
        return
    end
    if type(payloadOrErr) ~= "table" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, tostring(err or payloadOrErr or "not found"))
        return
    end

    AIO.Handle(player, HANDLER_NAME, "ModelList", payloadOrErr)
end

--- Thin wrapper: same path as chat `.cnpc set face <key> <optionIndex> <choiceIndex> [variation]`.
function Handlers.SetFace(player, key, optionIndex, choiceIndex, variation)
    if not RequireStaff(player) then return end
    key = Trim(key or "")
    optionIndex = tonumber(optionIndex)
    choiceIndex = tonumber(choiceIndex)
    if key == "" or not optionIndex or not choiceIndex then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Нужны key, optionIndex, choiceIndex.")
        return
    end
    local cmd = string.format(
        "cnpc set face %s %d %d",
        key,
        math.floor(optionIndex),
        math.floor(choiceIndex)
    )
    variation = tonumber(variation)
    if variation and variation >= 1 then
        cmd = cmd .. " " .. tostring(math.floor(variation))
    end
    local ok = RunService(player, cmd)
    AIO.Handle(player, HANDLER_NAME, "Status", ok,
        ok and ("Face обновлён: " .. key) or "set face не выполнен.")
end

NobleNext.RegisterModule("CustomNPC", { role = "staff-tools", layer = "GM" })
NobleNext.Log("CustomNPC", "server handlers loaded")

return Handlers
