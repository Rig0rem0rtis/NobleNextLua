--[[ GM/POI/NNPoiClient.lua — AIO client stub (no NN_BOOTSTRAP_ACTIVE gate before AddAddon) ]]

local AIO = AIO or require("AIO")
if AIO.AddAddon() then
    return
end

if _G.__NN_POI_AIO_CLIENT then
    return
end
_G.__NN_POI_AIO_CLIENT = true

local PoiClientHandlers = AIO.AddHandlers("NN_POI_Client", {})
_G.NobleNextPoi = _G.NobleNextPoi or {}

function PoiClientHandlers.SetList(player, rows)
    if _G.NobleNextPoi.OnSetList then
        _G.NobleNextPoi.OnSetList(rows)
    end
end

function PoiClientHandlers.Notice(player, level, message)
    if _G.NobleNextPoi.OnNotice then
        _G.NobleNextPoi.OnNotice(level, message)
    end
end
