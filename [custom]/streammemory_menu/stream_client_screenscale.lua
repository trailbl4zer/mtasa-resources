function selectorMenu(memorySizeBytes,memorySizeMiB)
    guiCreateTab("Client", guiCreateTabPanel(0, 0, 1, 1, false, nil))
end

local selectorWindow = nil -- Variable to hold the window element

addCommandHandler("streamsize", function()
    -- Check if the window already exists and is valid
    if isElement(selectorWindow) then
        -- Window exists, destroy it and hide cursor
        destroyElement(selectorWindow)
        selectorWindow = nil
        showCursor(false)
    else
        -- Window doesn't exist, create it
        local screenWidth, screenHeight = guiGetScreenSize()

        -- Calculate dimensions for a 16:9 window covering 1/48 of the screen area
        local targetArea = (screenWidth * screenHeight) / 48
        local aspectRatio = 21 / 9 -- Changed to 21:9 aspect ratio
        
        -- Derived formula for height based on area and aspect ratio
        local windowHeight = math.sqrt(targetArea / aspectRatio)
        -- Calculate width based on height and aspect ratio
        local windowWidth = windowHeight * aspectRatio

        local windowX = (screenWidth - windowWidth) / 2
        local windowY = (screenHeight - windowHeight) / 2

        -- Create the window and store it
        -- Create the window with the new multi-line title
        selectorWindow = guiCreateWindow(windowX, windowY, windowWidth, windowHeight, "Stream Memory Size - Selector Menu", false)
        guiWindowSetSizable(selectorWindow, false)
        guiFocus(selectorWindow) -- Set focus to the window (Removed duplicate)

        -- Calculate dynamic font size (adjust 0.03 factor if needed)
        local dynamicFontSize = math.max(1, math.floor(windowHeight * 0.03))
        local fontName = "default-bold-" .. dynamicFontSize -- Assumes default-bold-X fonts exist

        -- Label for Current Memory Size
        local currentSizeBytes = engineStreamingGetMemorySize() -- Get current size in bytes
        local currentSizeMiB = math.floor(currentSizeBytes / (1024 * 1024)) -- Convert bytes to MiB for display

        local currentSizeLabelText = "Current maximum stream memory size: " .. currentSizeMiB .. " MiB " -- Show current maximum memory size in MiB
        -- Position label relative to window size (adjust as needed)
        local currentSizeLabel = guiCreateLabel(0.05, 0.2, 0.9, 0.1, currentSizeLabelText, true, selectorWindow)
        guiSetFont(currentSizeLabel, fontName)
        guiLabelSetHorizontalAlign(currentSizeLabel, "center", false)

        -- Label for ComboBox
        local comboLabelText = "Select maximum stream memory size:"
        -- Position label relative to window size (adjust as needed)
        local comboLabel = guiCreateLabel(0.05, 0.375, 0.9, 0.1, comboLabelText, true, selectorWindow)
        guiSetFont(comboLabel, fontName)
        guiLabelSetHorizontalAlign(comboLabel, "center", false)
        
        -- ComboBox for selection
        -- Position ComboBox relative to window size (adjust as needed)
        local memoryComboBox = guiCreateComboBox(0.3, 0.45, 0.4, 0.4, "", true, selectorWindow) -- Centered X=0.3, Y = 0.31 (calculated center)
        guiComboBoxAddItem(memoryComboBox, "512 MiB")
        guiComboBoxAddItem(memoryComboBox, "1024 MiB")
        guiComboBoxAddItem(memoryComboBox, "2048 MiB")
        guiComboBoxAddItem(memoryComboBox, "3072 MiB")
        guiComboBoxAddItem(memoryComboBox, "4095 MiB")

        -- Set initial ComboBox selection based on current setting
        local currentBytesForCombo = engineStreamingGetMemorySize()
        local currentMiBForCombo = math.floor(currentBytesForCombo / (1024 * 1024))
        for i = 0, guiComboBoxGetItemCount(memoryComboBox) - 1 do
            local itemText = guiComboBoxGetItemText(memoryComboBox, i)
            local itemMiB = tonumber(string.match(itemText or "", "%d+"))
            if itemMiB and itemMiB == currentMiBForCombo then
                guiComboBoxSetSelected(memoryComboBox, i)
                setElementData(memoryComboBox, "selectedMiB", itemMiB) -- Store initial value
                break
            end
        end

        -- Event handler for ComboBox selection (stores selection, doesn't apply)
        addEventHandler("onClientGUIComboBoxAccepted", memoryComboBox, function()
            local selectedIndex = guiComboBoxGetSelected(memoryComboBox)
            if selectedIndex ~= -1 then -- Check if something is selected
                local selectedText = guiComboBoxGetItemText(memoryComboBox, selectedIndex)
                -- Extract the number from the text (e.g., "512 MiB" -> 512)
                -- Extract the number (representing MiB) from the text
                local selectedMiB = tonumber(string.match(selectedText, "%d+"))
                if selectedMiB then
                    -- Store the selected MiB value, but don't apply yet
                    setElementData(memoryComboBox, "selectedMiB", selectedMiB)
                    -- outputChatBox("ComboBox selection stored: " .. selectedMiB .. " MiB", 255, 165, 0) -- Optional debug
                end
            end
        end, false)

        -- Apply Button (Positioned below ComboBox)
        -- Apply Button (Positioned right of ComboBox)
        local applyButton = guiCreateButton(0.45, 0.55, 0.1, 0.08, "Apply", true, selectorWindow) -- Centered X=(1-0.1)/2=0.45, Y=0.60 (below combo)

        -- Event handler for Apply Button
        addEventHandler("onClientGUIClick", applyButton, function()
            local miBToApply = getElementData(memoryComboBox, "selectedMiB")
            
            if miBToApply then
                 -- Convert selected MiB value to bytes for the engine function
                local bytesToSend = miBToApply * 1024 * 1024

                -- Debug: Show MiB selected and Bytes being sent
                outputChatBox("Applying Setting - Selected: " .. miBToApply .. " MiB. Sending Bytes: " .. bytesToSend, 255, 255, 0)
                
                -- Set the memory size (function expects Bytes)
                engineStreamingSetMemorySize(bytesToSend)
                
                -- Debug: Check what the engine reports immediately after setting (in Bytes)
                local actualBytes = engineStreamingGetMemorySize()
                local actualMiB = math.floor(actualBytes / (1024 * 1024))
                outputChatBox("Engine reports Bytes: " .. actualBytes .. " (approx " .. actualMiB .. " MiB)", 255, 255, 0)

                -- Feedback: Confirm the request was processed using the intended MiB value
                outputChatBox("Stream memory size set request finished for: " .. miBToApply .. " MiB", 0, 255, 0)

                -- Close the window after applying
                if isElement(selectorWindow) then
                    destroyElement(selectorWindow)
                    selectorWindow = nil
                    showCursor(false)
                end
            else
                outputChatBox("No setting selected in ComboBox.", 255, 0, 0) -- Error feedback
            end
        end, false)

        -- Close Button (Positioned at the bottom)
        local closeButton = guiCreateButton(0.25, 0.775, 0.5, 0.08, "Close", true, selectorWindow) -- Centered X=(1-0.5)/2=0.25, Y=0.90 (bottom)

        -- Event handler for Close Button
        addEventHandler("onClientGUIClick", closeButton, function()
            if isElement(selectorWindow) then
                destroyElement(selectorWindow)
                selectorWindow = nil
                showCursor(false)
            end
        end, false)

        -- Show the cursor
        showCursor(true)

        -- Call the function to populate the window (if needed - likely remove this if elements are added here)
        -- selectorMenu(0,0) -- Commented out as we are adding elements directly here now
    end
end)
