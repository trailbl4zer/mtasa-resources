addEvent('onClientPlayerKillMessage', true)
addEventHandler('onClientPlayerKillMessage', root, function(victim, killer, weapon, bodypart, pR, pG, pB, kR, kG, kB)
    if wasEventCancelled() then
        return
    end
    -- Pass arguments in the order outputKillMessage expects: victim, pR, pG, pB, killer, kR, kG, kB, weapon, bodypart
    outputKillMessage(victim, pR, pG, pB, killer, kR, kG, kB, weapon, bodypart)
end)

function outputKillMessage(player, pR, pG, pB, killer, kR, kG, kB, weapon, bodypart)
    pR = tonumber(pR) or 255
    pG = tonumber(pG) or 255
    pB = tonumber(pB) or 255

    kR = tonumber(kR) or 255
    kG = tonumber(kG) or 255
    kB = tonumber(kB) or 255

    -- DEBUG: Check the received victim element
    outputChatBox("DEBUG: outputKillMessage received victim type: " .. type(player))
    if player then
        outputChatBox("DEBUG: outputKillMessage received victim element type: " .. getElementType(player))
        outputChatBox("DEBUG: outputKillMessage isElement(victim): " .. tostring(isElement(player)))
    end
    -- Allow non-player elements for testing, just ensure it's a valid element
    if (not player) or (not isElement(player)) then
        outputDebugString("outputKillMessage - Invalid 'wasted' player specified", 0, 0, 0, 100)
        return false
    end

    local killerName

    if isElement(killer) then
        if (getElementType(killer) ~= 'player') then
            outputDebugString("outputKillMessage - Invalid 'killer' player specified", 0, 0, 0, 100)
            return false
        end
        killerName = getPlayerName(killer)

    elseif (type(killer) == 'string') then
        killerName = killer

    end

    local message = {
        icon = getMessageIcon(weapon, killer), -- Get weapon/vehicle icon
        victim = {
            text = (getElementType(player) == 'player') and removeHex(getPlayerName(player)) or "Ped", -- Handle non-player victim name
            color = {pR, pG, pB},
        }
    }

    -- Add headshot icon if applicable
    if bodypart == 9 then
        local headshotTexture = getTexture('icons/headshot.png')
        if headshotTexture and isElement(headshotTexture) then -- Check if it's a valid element
            message.headshotIcon = {
                texture = headshotTexture,
                width = dxGetMaterialSize(headshotTexture)
            }
        end
    end

    if (type(killerName) == 'string') then
        message.killer = {
            text = removeHex(killerName),
            color = {kR, kG, kB},
        }
    end

    return outputMessage(message)
end

local possibleKiller

function setPossibleKiller(player)
    if possibleKiller and isTimer(possibleKiller.timer) then
        killTimer(possibleKiller.timer)
    end

    possibleKiller = {
        player = player,
        timer = setTimer(function()
            possibleKiller = nil
        end, 7000, 1)
    }
end

local validExplosionTypes = {
    [2] = true, -- rocket
    [10] = true, -- tank grenade
}

addEventHandler('onClientExplosion', root, function(x, y, z, explosionType)
    if (not validExplosionTypes[explosionType]) then
        return
    end

    if (getElementType(source) ~= 'player') then
        return
    end

    if (not getPedOccupiedVehicle(source)) then
        return
    end

    local myVehicle = getPedOccupiedVehicle(localPlayer)

    if (not myVehicle) then
        return
    end

    if (getDistanceBetweenPoints3D(x, y, z, getElementPosition(myVehicle)) > 10) then
        return
    end

    setPossibleKiller(source)
end)

local vehicleWeapons = {
    [425] = 38, -- hunter
    [464] = 31, -- rc baron
    [476] = 31, -- rustler
}

addEventHandler('onClientVehicleDamage', root, function(attacker, weapon)
    if (not weapon) then
        return
    end

    local myVehicle = getPedOccupiedVehicle(localPlayer)

    if (source ~= myVehicle) then
        return
    end

    if (not attacker) or (getElementType(attacker) ~= 'vehicle') then
        return
    end

    local player = getVehicleOccupant(attacker)

    if (not player) then
        return
    end

    if (vehicleWeapons[getElementModel(attacker)] ~= weapon) then
        return
    end

    setPossibleKiller(player)
end)

addEventHandler('onClientPlayerWasted', localPlayer, function()
    if (not possibleKiller) then
        local myVehicle = getPedOccupiedVehicle(localPlayer)

        if myVehicle and isVehicleBlown(myVehicle) then
            triggerServerEvent('outputKillFromClient', localPlayer, localPlayer, myVehicle)
        end

        return
    end

    if (not isElement(possibleKiller.player)) then
        return
    end

    local vehicle = getPedOccupiedVehicle(possibleKiller.player)

    if isElement(vehicle) then
        triggerServerEvent('outputKillFromClient', localPlayer, possibleKiller.player, vehicle)
    end

    if isTimer(possibleKiller.timer) then
        killTimer(possibleKiller.timer)
    end

    possibleKiller = nil
end)
