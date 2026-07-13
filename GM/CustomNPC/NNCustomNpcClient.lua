--[[ GM/CustomNPC/NNCustomNpcClient.lua — клиентский AIO для custom NPC ]]

if not _G.NN_BOOTSTRAP_ACTIVE then return end
if package.loaded["GM.CustomNPC.NNCustomNpcClient"] then return end

local AIO = AIO or require("AIO")
if AIO.AddAddon() then
    return
end

local HANDLER_NAME = "CustomNpcHandlers"
local Handlers = AIO.AddHandlers(HANDLER_NAME, {})

_G.NobleNextCustomNpc = _G.NobleNextCustomNpc or {}

function Handlers.Status(player, ok, message)
    _G.NobleNextCustomNpc.lastStatus = {
        ok = ok and true or false,
        message = message or "",
        time = GetTime(),
    }
    if _G.NobleNextCustomNpc.OnStatus then
        _G.NobleNextCustomNpc.OnStatus(ok, message)
    end
end

return Handlers
