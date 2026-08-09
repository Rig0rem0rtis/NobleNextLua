--[[ GM/MasterPanel/NNMasterClient — AIO client (no NN_BOOTSTRAP_ACTIVE gate before AddAddon) ]]

local AIO = AIO or require("AIO")
if AIO.AddAddon() then
    return
end

if _G.__NN_MASTER_AIO_CLIENT then
    return
end
_G.__NN_MASTER_AIO_CLIENT = true

local AddonNDMHandlers = AIO.AddHandlers("AIOAddonMasterPanel", {})

_G.NobleNextMaster = _G.NobleNextMaster or {}

function AddonNDMHandlers.ElunaGetTalkingHead(player, line, UnitName, creator)
    if _G.NobleNextMaster.OnTalkingHead then
        _G.NobleNextMaster.OnTalkingHead(line, UnitName, creator)
    end
end
