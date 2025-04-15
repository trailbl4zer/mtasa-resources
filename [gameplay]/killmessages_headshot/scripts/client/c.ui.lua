local messages = {}
local sW, sH = guiGetScreenSize()

function outputMessage(new)
    if (type(new) == 'string') then
        new = {
            victim = {
                text = new,
                color = {255, 255, 255},
            },
        }
    end

    new.initTick = getTickCount()

    if new.icon.path and fileExists(new.icon.path) then
        new.icon.texture = dxCreateTexture(new.icon.path)
    end

    table.insert(messages, new)

    local displayLines = tonumber(getSetting('displayLines')) or 5

    local quantity = #messages

    if (quantity == 1) then
        addEventHandler('onClientRender', root, renderMessages)

    elseif (quantity > displayLines) then
        table.remove(messages, 1)

    end

    return true
end
addEvent('doOutputMessage', true)
addEventHandler('doOutputMessage', resourceRoot, outputMessage)

function renderMessages()
    local now = getTickCount()

    local lineHeight = 20
    local font = 'default'

    local marginRight = tonumber(getSetting('drawMarginRight')) or 0.01
    local marginBottom = tonumber(getSetting('drawMarginBottom')) or 0.55
    local fadeTime = tonumber(getSetting('fadeTime')) or 1
    local duration = tonumber(getSetting('duration')) or 10

    fadeTime = fadeTime * 1000
    duration = duration * 1000

    local y = sH - (sH * marginBottom)

    local padding = 5 -- distance between texts and icon

    for k = #messages, 1, -1 do
        local v = messages[k]
        if v then
            local passed = now - v.initTick
            if (passed <= duration) then
                local alpha = 255

                if (passed <= fadeTime) then
                    alpha = 255 * passed / math.max(1, fadeTime)

                elseif (passed >= (duration - fadeTime)) then
                    alpha = 255 - 255 * ((now - duration + fadeTime) - v.initTick) / math.max(1, fadeTime)

                end

                local victim = v.victim
                local victimText = victim.text
                local victimColor = victim.color
                victimColor = tocolor(victimColor[1], victimColor[2], victimColor[3], alpha)

                local victimWidth = dxGetTextSize(victimText, 0, 1, 1, font, false, true)

                local x = sW - (sW * marginRight) - victimWidth

                dxDrawText(victimText, x + 2, y + 2, x + victimWidth, y + lineHeight, tocolor(0, 0, 0, alpha), 1, font, 'center', 'center')
                dxDrawText(victimText, x, y, x + victimWidth, y + lineHeight, victimColor, 1, font, 'center', 'center')

                local currentX = x -- Start position for icons (right edge of victim name)

                -- Draw Headshot Icon (if exists)
                local headshotIcon = v.headshotIcon
                if headshotIcon and headshotIcon.texture and isElement(headshotIcon.texture) then
                    local texture = headshotIcon.texture
                    local iconWidth = headshotIcon.width
                    currentX = currentX - padding - iconWidth -- Adjust X position
                    dxDrawImage(currentX, y, iconWidth, lineHeight, texture, 0, 0, 0, tocolor(255, 255, 255, alpha))
                end

                -- Draw Weapon/Vehicle Icon (if exists)
                local weaponIcon = v.icon
                if weaponIcon and weaponIcon.texture and isElement(weaponIcon.texture) then
                    local texture = weaponIcon.texture
                    local iconWidth = weaponIcon.width
                    currentX = currentX - padding - iconWidth -- Adjust X position
                    dxDrawImage(currentX, y, iconWidth, lineHeight, texture, 0, 0, 0, tocolor(255, 255, 255, alpha))
                end

                x = currentX -- Update x to the leftmost edge after drawing icons

                local killer = v.killer

                if killer then
                    local killerText = killer.text
                    local killerColor = killer.color
                    killerColor = tocolor(killerColor[1], killerColor[2], killerColor[3], alpha)

                    local killerWidth = dxGetTextSize(killerText, 0, 1, 1, font, false, true)

                    local killerX = x - padding - killerWidth -- Calculate killer name X based on final icon position

                    dxDrawText(killerText, killerX + 2, y + 2, killerX + killerWidth, y + lineHeight, tocolor(0, 0, 0, alpha), 1, font, 'center', 'center')
                    dxDrawText(killerText, killerX, y, killerX + killerWidth, y + lineHeight, killerColor, 1, font, 'center', 'center')
                end

                y = y - lineHeight - padding
            else
                -- Destroy textures
                if v.icon and v.icon.texture and isElement(v.icon.texture) then
                    destroyElement(v.icon.texture)
                end
                if v.headshotIcon and v.headshotIcon.texture and isElement(v.headshotIcon.texture) then
                    destroyElement(v.headshotIcon.texture)
                end

                table.remove(messages, k)

                if (#messages == 0) then
                    removeEventHandler('onClientRender', root, renderMessages)
                end

            end
        end
    end
end
