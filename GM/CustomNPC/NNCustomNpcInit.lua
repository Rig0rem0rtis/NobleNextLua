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

local function RequireStaff(player)
    return NobleNext.HasStaffPermission(player)
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

function Handlers.List(player)
    if not RequireStaff(player) then return end
    RunService(player, "cnpc list")
    AIO.Handle(player, HANDLER_NAME, "Status", true, "Запрошен список custom NPC (.cnpc list).")
end

function Handlers.Reload(player, key)
    if not RequireStaff(player) then return end
    key = NobleNext.Trim(key or "")
    if key == "" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Укажите ключ или all.")
        return
    end
    RunService(player, "cnpc reload " .. key)
    AIO.Handle(player, HANDLER_NAME, "Status", true, "Отправлена команда reload для '" .. key .. "'.")
end

function Handlers.CloneSelf(player, key)
    if not RequireStaff(player) then return end
    key = NobleNext.Trim(key or "")
    if key == "" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Укажите ключ NPC.")
        return
    end
    RunService(player, "cnpc clone " .. key)
    AIO.Handle(player, HANDLER_NAME, "Status", true, "Отправлена команда clone для '" .. key .. "'.")
end

function Handlers.CloneTarget(player, key)
    if not RequireStaff(player) then return end
    key = NobleNext.Trim(key or "")
    if key == "" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Укажите ключ NPC.")
        return
    end
    RunService(player, "cnpc clone target " .. key)
    AIO.Handle(player, HANDLER_NAME, "Status", true, "Отправлена команда clone target для '" .. key .. "'.")
end

function Handlers.ApplySelected(player, key, variation)
    if not RequireStaff(player) then return end
    key = NobleNext.Trim(key or "")
    variation = tonumber(variation) or 1
    if key == "" then
        AIO.Handle(player, HANDLER_NAME, "Status", false, "Укажите ключ NPC.")
        return
    end
    RunService(player, "cnpc apply " .. key .. " " .. tostring(math.floor(variation)))
    AIO.Handle(player, HANDLER_NAME, "Status", true, "Отправлена команда apply для '" .. key .. "'.")
end

function Handlers.RunCommand(player, command)
    if not RequireStaff(player) then return end
    command = NobleNext.Trim(command or ""):gsub("^[%./]+", "")
    if command == "" or #command > 512 then return end
    local ok, err = RunService(player, command)
    AIO.Handle(player, HANDLER_NAME, "Status", ok, ok and ("Команда: ." .. command) or (err or "Ошибка"))
end

NobleNext.RegisterModule("CustomNPC", { role = "staff-tools", layer = "GM" })
NobleNext.Log("CustomNPC", "server handlers loaded")

return Handlers
