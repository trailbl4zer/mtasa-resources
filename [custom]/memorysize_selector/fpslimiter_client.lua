-- fpslimiter_client.lua

local fpsLimitWindow = nil -- Variable to hold the window element

local fpsInput = 74 -- Default FPS limit (74 FPS)

addCommandHandler("fpslimit", function()
    -- Check if the window already exists and is valid
    if isElement(fpsLimitWindow) then
        -- Window exists, destroy it and hide cursor
        destroyElement(fpsLimitWindow)
        fpsLimitWindow = nil
        showCursor(false)
    else
        -- Window doesn't exist, create it
        local screenWidth, screenHeight = guiGetScreenSize()

        -- Define fixed window dimensions (adjust as needed)
        local windowWidth = 300
        local windowHeight = 180 -- Adjusted height for fewer elements

        local windowX = (screenWidth - windowWidth) / 2
        local windowY = (screenHeight - windowHeight) / 2

        -- Create the window and store it
        fpsLimitWindow = guiCreateWindow(windowX, windowY, windowWidth, windowHeight, "FPS Limiter - Settings", false)
        guiWindowSetSizable(fpsLimitWindow, false)

        -- Use a fixed font size
        local fontName = "default-bold-1" -- Using size 1, adjust if needed

        -- Label for Current FPS Limit
        local currentFPS = getFPSLimit()
        local currentFPSLabelText = "Current FPS limit: " .. currentFPS
        local currentFPSLabel = guiCreateLabel(15, 25, 270, 20, currentFPSLabelText, false, fpsLimitWindow)
        guiSetFont(currentFPSLabel, fontName)
        guiLabelSetHorizontalAlign(currentFPSLabel, "center", false)

        -- Label for Input Field
        local inputLabelText = "Enter desired FPS limit (25-32767):"
        local inputLabel = guiCreateLabel(15, 50, 270, 20, inputLabelText, false, fpsLimitWindow)
        guiSetFont(inputLabel, fontName)
        guiLabelSetHorizontalAlign(inputLabel, "center", false)

        -- Input Field (Edit Box)
        local fpsInput = guiCreateEdit(90, 75, 120, 25, tostring(currentFPS), false, fpsLimitWindow) -- Centered, pre-filled with current FPS

        -- Apply Button
        local applyButton = guiCreateButton(50, 110, 80, 25, "Apply", false, fpsLimitWindow)

        -- Close Button
        local closeButton = guiCreateButton(170, 110, 80, 25, "Close", false, fpsLimitWindow)

        -- Event handler for Apply Button
        addEventHandler("onClientGUIClick", applyButton, function()
            local inputText = guiGetText(fpsInput)
            local newFPS = tonumber(inputText)

            if newFPS and newFPS >= 25 and newFPS <= 32767 then -- Basic validation (MTA default range)
                setFPSLimit(newFPS)
                outputChatBox("FPS limit set to: " .. newFPS, 0, 255, 0)

                -- Close the window after applying
                if isElement(fpsLimitWindow) then
                    destroyElement(fpsLimitWindow)
                    fpsLimitWindow = nil
                    showCursor(false)
                end
            elseif newFPS and (newFPS < 25 or newFPS > 32767) then
                 outputChatBox("Invalid FPS value. Please enter a number between 25 and 32767 (Use 0 for unlimited FPS).", 255, 0, 0)
            else
                outputChatBox("Invalid input. Please enter a number.", 255, 0, 0)
            end
        end, false)

        -- Event handler for Close Button
        addEventHandler("onClientGUIClick", closeButton, function()
            if isElement(fpsLimitWindow) then
                destroyElement(fpsLimitWindow)
                fpsLimitWindow = nil
                showCursor(false)
            end
        end, false)

        -- Show the cursor
        showCursor(true)
    end
end)


addEventHandler("onClientResourceStart", resourceRoot, function()
    -- Check if the FPS limit window is open and close it if necessary
    if isElement(fpsLimitWindow) then
        destroyElement(fpsLimitWindow)
        fpsLimitWindow = nil
        showCursor(false)
    end

    -- Set the default FPS limit on resource start
    setFPSLimit(fpsInput) -- Set the default FPS limit (74 FPS)
end)