addEvent("onPlayerKillMessage")

function createKillMessage(_, killer, weapon, bodypart, stealth)
    local usedVehicle, killerType
    weapon = weapon or 255

    -- In very rare cases killer isn't nil or false but isn't an element.
    if killer and (not isElement(killer)) then
        killer = nil
    end

    if killer then
        killerType = getElementType(killer)

        -- Sometimes the killer is returned as the driver instead of vehicle, like when driving a Rhino but we need the vehicle ID
        if (killerType == 'player') then
            local veh = getPedOccupiedVehicle(killer)
            if veh and (getPedWeapon(killer) == 0) then
                usedVehicle = veh
            end

        -- Change the killer into the vehicle controller
        elseif (killerType == 'vehicle') then
            usedVehicle = killer
            local controller = getVehicleController(killer)
            if controller then
                killer = controller
                killerType = getElementType(killer)
            end

        end
    end

    -- If killed by rocket and was on foot player turn it into their current weapon
    if (weapon == 19) and ((killerType == 'player') and (not isPedInVehicle(killer))) then
        weapon = getPedWeapon(killer) or 51
    end

    if killer and (killerType == 'player') then
        -- Suicide?
        if (source == killer) then
            if triggerEvent("onPlayerKillMessage", source, false, weapon, bodypart) then
                eventTriggered(source, false, weapon, bodypart, usedVehicle)
            end
        else
            if triggerEvent("onPlayerKillMessage", source, killer, weapon, bodypart) then
                eventTriggered(source, killer, weapon, bodypart, usedVehicle)
            end
        end
    else
        -- Avoid showing deaths caused by explosions, cuz they are client-side
        if (weapon ~= 63) then
            if triggerEvent("onPlayerKillMessage", source, false, weapon, bodypart) then
                eventTriggered(source, false, weapon, bodypart, usedVehicle)
            end
        end
    end
end
addEventHandler('onPlayerWasted', root, createKillMessage)

addEvent('outputKillFromClient', true)
addEventHandler('outputKillFromClient', root, function(killer, veh)
    if (source ~= client) then
        return
    end

    if (not isElement(killer)) then
        return
    end

    if (killer == source) then
        if triggerEvent("onPlayerKillMessage", source, false, veh and 63 or 999) then
            eventTriggered(source, false, veh and 63 or 999)
        end
    else
        if triggerEvent("onPlayerKillMessage", client, killer, 19) then
            eventTriggered(client, killer, 19, nil, veh)
        end
    end
end)

function eventTriggered(player, killer, weapon, bodypart, vehicle)
    outputConsoleMessage(player, killer, vehicle, weapon)

    if isElement(vehicle) and (getElementType(vehicle) == 'vehicle') then
        weapon = getElementModel(vehicle)
    end

    local pR, pG, pB = getPlayerColor(player)
    local kR, kG, kB = getPlayerColor(killer)

    outputKillMessage(player, pR, pG, pB, killer, kR, kG, kB, weapon, bodypart)

    return true
end

function outputKillMessage(player, pR, pG, pB, killer, kR, kG, kB, weapon, bodypart)
    if (not isElement(player)) or (getElementType(player) ~= 'player') then
        outputDebugString("outputKillMessage - Invalid 'wasted' player specified", 0, 0, 0, 100)
        return false
    end

    return triggerClientEvent(root, 'onClientPlayerKillMessage', player, killer, weapon, bodypart, pR, pG, pB, kR, kG, kB)
end

function outputMessage(message, visibleTo, r, g, b, font)
    if (type(message) ~= "string") and (type(message) ~= "table") then
        outputDebugString("outputMessage - Bad 'message' argument", 0, 112, 112, 112)
        return false
    end
    if (not isElement(visibleTo)) and (type(visibleTo) ~= "table") then
        outputDebugString("outputMessage - Bad 'visibleTo' argument", 0, 112, 112, 112)
        return false
    end
    return triggerClientEvent(visibleTo, "doOutputMessage", resourceRoot, message, r, g, b, font)
end

function outputConsoleMessage(player, killer, vehicle, weapon)
    if (get('outputConsole') ~= 'true') then
        return false
    end

    local extra = ''

    if isElement(vehicle) and (getElementType(vehicle) == 'vehicle') then
        extra = (' (%s)'):format(getVehicleName(vehicle))
    end

    local msg
    if killer then
        local victimName = (isElement(player) and getElementType(player) == 'player') and getPlayerName(player) or "Ped"
        local killerName = (isElement(killer) and getElementType(killer) == 'player') and getPlayerName(killer) or "Unknown" -- Killer should usually be a player

        if (player == killer) then
            msg = ('* %s killed himself.'):format(victimName)
        else
            msg = ('* %s killed %s.'):format(killerName, victimName)
        end
        local weaponName = getWeaponNameFromID(weapon)
        if weaponName then
            msg = msg .. (' (%s)'):format(weaponName)
        else
            msg = msg .. extra
        end
    else
        local victimName = (isElement(player) and getElementType(player) == 'player') and getPlayerName(player) or "Ped"
        msg = ('* %s died.%s'):format(victimName, extra)
    end

    if msg then
        outputConsole(msg)
    end

    return true
end

function getPlayerColor(player)
    local r, g, b = 255, 255, 255 -- Default to white

    if isElement(player) and getElementType(player) == 'player' then
        local team = getPlayerTeam(player)
        if team then
            local teamR, teamG, teamB = getTeamColor(team)
            -- Use team color only if getTeamColor succeeded
            if teamR then
                 r, g, b = teamR, teamG, teamB
            end
        else
            local tagR, tagG, tagB = getPlayerNametagColor(player)
            -- Use nametag color only if getPlayerNametagColor succeeded
            if tagR then
                r, g, b = tagR, tagG, tagB
            end
        end
    end
    return r, g, b
end

-- Temporary command for testing headshots
addCommandHandler("testheadshot", function(thePlayer)
    if not thePlayer then return end

    -- Spawn a ped near the player
    local x, y, z = getElementPosition(thePlayer)
    local ped = createPed(0, x + 2, y, z) -- Model 0 (CJ), 2 units in front

    if not ped then
        outputChatBox("Failed to create test ped.", thePlayer, 255, 0, 0)
        return
    end

    -- Simulate the headshot kill event by triggering the client event directly
    local weaponID = 34 -- Sniper Rifle
    local bodypartID = 9 -- Head
    local pR, pG, pB = 255, 255, 255 -- Ped victim color (white)
    local kR, kG, kB = getPlayerColor(thePlayer) -- Killer color

    -- Trigger the client event FOR the player who ran the command
    -- Arguments for onClientPlayerKillMessage: victim, killer, weapon, bodypart, pR, pG, pB, kR, kG, kB
    -- Note: 'source' on the client handler will be the 'thePlayer' element we trigger this on.
    if triggerClientEvent(thePlayer, "onClientPlayerKillMessage", thePlayer, ped, thePlayer, weaponID, bodypartID, pR, pG, pB, kR, kG, kB) then
        outputChatBox("Simulated client headshot kill message sent.", thePlayer, 0, 255, 0)
    else
        outputChatBox("Failed to trigger simulated client kill message.", thePlayer, 255, 0, 0)
    end

    -- Clean up the ped after a short delay
    setTimer(destroyElement, 5000, 1, ped)
end)
