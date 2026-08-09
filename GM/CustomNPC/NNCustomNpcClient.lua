--[[ GM/CustomNPC/NNCustomNpcClient.lua — клиентский AIO для custom NPC

    Важно: не проверять NN_BOOTSTRAP_ACTIVE до AddAddon — на клиенте флага нет,
    иначе handlers не регистрируются (Unknown AIO block handle).
]]

local AIO = AIO or require("AIO")
if AIO.AddAddon() then
    return
end

if _G.__NN_CUSTOMNPC_AIO_CLIENT then
    return
end
_G.__NN_CUSTOMNPC_AIO_CLIENT = true

local HANDLER_NAME = "CustomNpcHandlers"
local Handlers = AIO.AddHandlers(HANDLER_NAME, {})

_G.NobleNextCustomNpc = _G.NobleNextCustomNpc or {}

function Handlers.Status(player, ok, message)
    _G.NobleNextCustomNpc.lastStatus = {
        ok = ok and true or false,
        message = message or "",
        time = GetTime and GetTime() or 0,
    }
    if _G.NobleNextCustomNpc.OnStatus then
        _G.NobleNextCustomNpc.OnStatus(ok, message)
    end
end

function Handlers.NpcList(player, rows, meta)
    _G.NobleNextCustomNpc.lastNpcList = {
        rows = rows or {},
        meta = meta or {},
        time = GetTime and GetTime() or 0,
    }
    if _G.NobleNextCustomNpc.OnNpcList then
        _G.NobleNextCustomNpc.OnNpcList(rows or {}, meta or {})
    end
end

function Handlers.Catalog(player, catalog)
    _G.NobleNextCustomNpc.lastCatalog = {
        catalog = catalog or {},
        time = GetTime and GetTime() or 0,
    }
    if _G.NobleNextCustomNpc.OnCatalog then
        _G.NobleNextCustomNpc.OnCatalog(catalog or {})
    end
end

function Handlers.NpcDetail(player, detail)
    _G.NobleNextCustomNpc.lastNpcDetail = {
        detail = detail or {},
        time = GetTime and GetTime() or 0,
    }
    if _G.NobleNextCustomNpc.OnNpcDetail then
        _G.NobleNextCustomNpc.OnNpcDetail(detail or {})
    end
end

function Handlers.FaceOptions(player, payload)
    _G.NobleNextCustomNpc.lastFaceOptions = {
        payload = payload or {},
        time = GetTime and GetTime() or 0,
    }
    if _G.NobleNextCustomNpc.OnFaceOptions then
        _G.NobleNextCustomNpc.OnFaceOptions(payload or {})
    end
end

function Handlers.FaceChoices(player, payload)
    _G.NobleNextCustomNpc.lastFaceChoices = {
        payload = payload or {},
        time = GetTime and GetTime() or 0,
    }
    if _G.NobleNextCustomNpc.OnFaceChoices then
        _G.NobleNextCustomNpc.OnFaceChoices(payload or {})
    end
end

function Handlers.ModelList(player, payload)
    _G.NobleNextCustomNpc.lastModelList = {
        payload = payload or {},
        time = GetTime and GetTime() or 0,
    }
    if _G.NobleNextCustomNpc.OnModelList then
        _G.NobleNextCustomNpc.OnModelList(payload or {})
    end
end
