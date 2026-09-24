-- lua_scripts/distance_tracker_aura.lua
-- Серверный скрипт Eluna для DistanceTracker.
-- Накладывает ауру истощения при 0 шагов движения,
-- снимает — при использовании способности «Движение» (или новом ходу).

local EXHAUSTION_AURA_ID = 383027

-- Куда отправлять служебные сообщения игроку.
local function Notify(player, text)
    player:SendBroadcastMessage("|cff00ccff[DistanceTracker]|r " .. text)
end

-- Обработчик события чата.
-- Возвращаем false, чтобы служебное сообщение не улетало в общий чат.
local function OnPlayerChat(event, player, msg, msgType, lang)
    if msg == ".dtaura" then
        if not player:HasAura(EXHAUSTION_AURA_ID) then
            player:AddAura(EXHAUSTION_AURA_ID, player)
            Notify(player, "Истощение наложено (0 шагов движения).")
        end
        return false
    end

    if msg == ".dtunaura" then
        if player:HasAura(EXHAUSTION_AURA_ID) then
            player:RemoveAura(EXHAUSTION_AURA_ID)
            Notify(player, "Истощение снято (движение возобновлено).")
        end
        return false
    end
end

RegisterPlayerEvent(18, OnPlayerChat) -- 18 = PLAYER_EVENT_ON_CHAT

print("|cff88aaff[DistanceTracker]|r Серверный скрипт ауры загружен.")