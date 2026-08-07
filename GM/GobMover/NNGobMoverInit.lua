--[[ GM/GobMover/NNGobMoverInit.lua — редактирование GameObject (C++: .movego) ]]

if not _G.NN_BOOTSTRAP_ACTIVE then return end

local NobleNext = require("NobleNext")
if not NobleNext.IsMainState() then
    return {}
end

if _G.NN_GM_GOBMOVER_BOOTSTRAPPED then
    return package.loaded["GM.GobMover.NNGobMoverInit"] or {}
end
_G.NN_GM_GOBMOVER_BOOTSTRAPPED = true

local HANDLER_NAME = "NN_GobMover"
local COOLDOWN_MS = 300
local SEARCH_RADIUS = 50
local FIND_BY_GUID_RADIUS = 100

local AIO = NobleNext.AIO
local playersCooldowns = {}

local function IsReady(player)
    local name = player:GetName()
    local now = GetCurrTime()
    if not playersCooldowns[name] or (now - playersCooldowns[name]) >= COOLDOWN_MS then
        playersCooldowns[name] = now
        return true
    end
    return false
end

local function HasPermission(player)
    return NobleNext.HasStaffPermission(player)
end

local function GuidEquals(a, b)
    local na = tonumber(a)
    local nb = tonumber(b)
    if na and nb then
        return na == nb
    end
    return tostring(a) == tostring(b)
end

local function GetDistance3(player, go)
    local dx = player:GetX() - go:GetX()
    local dy = player:GetY() - go:GetY()
    local dz = player:GetZ() - go:GetZ()
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

--- Spawn-store lookup (no phase filter). Requires Map:GetGameObjectBySpawnId (Eluna).
local function FindGoBySpawnId(player, guid)
    local want = tonumber(guid)
    if not want or want <= 0 then
        return nil
    end
    local map = player:GetMap()
    if map and map.GetGameObjectBySpawnId then
        local go = map:GetGameObjectBySpawnId(want)
        if go then
            return go
        end
    end
    return nil
end

--- Nearest live GO in range (Eluna grid; phase-filtered). Prefer .movego / spawn-store Select.
local function FindNearestGo(player, radius)
    radius = radius or SEARCH_RADIUS
    local gos = player:GetGameObjectsInRange(radius)
    if not gos then
        return nil
    end
    local nearest, nearestDist
    for _, go in ipairs(gos) do
        if go then
            local dist = GetDistance3(player, go)
            if dist <= radius and (not nearestDist or dist < nearestDist) then
                nearest = go
                nearestDist = dist
            end
        end
    end
    return nearest
end

local function FindGoByGuid(player, guid)
    local want = tonumber(guid) or guid
    if want == nil or want == 0 or want == "" then
        return nil
    end
    local bySpawn = FindGoBySpawnId(player, want)
    if bySpawn then
        return bySpawn
    end
    local gos = player:GetGameObjectsInRange(FIND_BY_GUID_RADIUS)
    if not gos then
        return nil
    end
    for _, go in ipairs(gos) do
        if go and GuidEquals(go:GetDBTableGUIDLow(), want) then
            return go
        end
    end
    return nil
end

local function HintSelectMessage()
    return "[GobMover]|r Live GO не найден (радиус "
        .. tostring(SEARCH_RADIUS)
        .. "). Housing/phase: .gob near → клик [Sel]/[Move] или .movego <guid>."
end

-- Silent relative-pose sync for soft groups (errors ignored).
-- Player:RunCommand → ChatHandler::_ParseCommands (без ведущей точки).
local function CaptureGroupSilent(player, guid)
    pcall(function()
        player:RunCommand("gobject group capture " .. tostring(guid) .. " silent")
    end)
end

local GobMoverHandlers = AIO.AddHandlers(HANDLER_NAME, {})

function GobMoverHandlers.Open(player)
    if not HasPermission(player) then return end
    -- C++ .movego: IgnorePhases + радиус 50 (надёжнее Eluna grid на housing).
    local ran = pcall(function()
        player:RunCommand("movego")
    end)
    if ran then
        return
    end
    -- Fallback без C++ команды
    local go = FindNearestGo(player, SEARCH_RADIUS)
    if not go then
        player:SendBroadcastMessage(NobleNext.Color("error", HintSelectMessage()))
        return
    end
    NobleNext.GobMoverSetTarget(player, go:GetDBTableGUIDLow(), go:GetName() or "")
end

function GobMoverHandlers.Select(player, guid)
    if not HasPermission(player) then return end
    local want = tonumber(guid)
    if not want or want <= 0 then
        player:SendBroadcastMessage(NobleNext.Color("error", "[GobMover]|r Укажите DB GUID (spawnId)."))
        return
    end
    local ran = pcall(function()
        player:RunCommand("movego " .. tostring(want))
    end)
    if ran then
        return
    end
    local go = FindGoByGuid(player, want)
    if not go then
        player:SendBroadcastMessage(NobleNext.Color("error",
            "[GobMover]|r GO GUID " .. tostring(want)
            .. " не загружен на карте. Подойдите ближе (грид) или проверьте .gob near."))
        return
    end
    NobleNext.GobMoverSetTarget(player, go:GetDBTableGUIDLow(), go:GetName() or "")
end

function GobMoverHandlers.Move(player, guid, dx, dy, dz)
    if not HasPermission(player) or not IsReady(player) then return end
    local go = FindGoByGuid(player, guid)
    if not go then
        player:SendBroadcastMessage(NobleNext.Color("error",
            "[GobMover]|r GO не найден в радиусе " .. tostring(FIND_BY_GUID_RADIUS)
            .. ". Подойдите ближе к объекту."))
        return
    end
    dx = tonumber(dx) or 0
    dy = tonumber(dy) or 0
    dz = tonumber(dz) or 0
    go:ChangePosition(go:GetX() + dx, go:GetY() + dy, go:GetZ() + dz, go:GetO())
    CaptureGroupSilent(player, guid)
    NobleNext.LogAudit("GobMover", "move", player,
        string.format("guid=%s delta=%.3f,%.3f,%.3f", tostring(guid), dx, dy, dz))
end

function GobMoverHandlers.RotateYaw(player, guid, deltaDeg)
    if not HasPermission(player) or not IsReady(player) then return end
    local go = FindGoByGuid(player, guid)
    if not go then return end
    local delta = math.rad(tonumber(deltaDeg) or 0)
    go:ChangePosition(go:GetX(), go:GetY(), go:GetZ(), go:GetO() + delta)
    CaptureGroupSilent(player, guid)
    NobleNext.LogAudit("GobMover", "rotate", player,
        string.format("guid=%s deltaDeg=%s", tostring(guid), tostring(deltaDeg)))
end

function GobMoverHandlers.ResetRotation(player, guid)
    if not HasPermission(player) or not IsReady(player) then return end
    local go = FindGoByGuid(player, guid)
    if not go then return end
    go:Turn(0, 0, 0)
    CaptureGroupSilent(player, guid)
end

function GobMoverHandlers.Scale(player, guid, scale)
    if not HasPermission(player) or not IsReady(player) then return end
    local go = FindGoByGuid(player, guid)
    if not go then return end
    scale = tonumber(scale) or 1
    if scale <= 0 then scale = 0.001 end
    go:SetScale(scale)
    NobleNext.LogAudit("GobMover", "scale", player,
        string.format("guid=%s scale=%.3f", tostring(guid), scale))
end

NobleNext.RegisterModule("GobMover", { layer = "GM", aio = "NN_GobMover", core = "Custom/NobleNext/GobMover" })
NobleNext.Log("GobMover", "registered (C++ .movego + AIO)")
