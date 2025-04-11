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

        -- Define fixed window dimensions
        local windowWidth = 300
        local windowHeight = 215

        local windowX = (screenWidth - windowWidth) / 2
        local windowY = (screenHeight - windowHeight) / 2

        -- Create the window and store it
        -- Create the window with the new multi-line title
        selectorWindow = guiCreateWindow(windowX, windowY, windowWidth, windowHeight, "Stream Memory Size - Selector Menu", false)
        guiWindowSetSizable(selectorWindow, false)

        -- Use a fixed font size
        local fontName = "default-bold-1" -- Using size 1, adjust if needed

        -- Label for Current Memory Size
        local currentSizeBytes = engineStreamingGetMemorySize() -- Get current size in bytes
        local currentSizeMiB = math.floor(currentSizeBytes / (1024 * 1024)) -- Convert bytes to MiB for display

        local currentSizeLabelText = "Current maximum stream memory size: " .. currentSizeMiB .. " MiB " -- Show current maximum memory size in MiB
        -- Position label relative to window size (adjust as needed)
        local currentSizeLabel = guiCreateLabel(15, 25, 270, 20, currentSizeLabelText, false, selectorWindow) -- Absolute
        guiSetFont(currentSizeLabel, fontName)
        guiLabelSetHorizontalAlign(currentSizeLabel, "center", false)

        -- Label for ComboBox
        local comboLabelText = "Select maximum stream memory size:"
        -- Position label relative to window size (adjust as needed)
        local comboLabel = guiCreateLabel(15, 50, 270, 20, comboLabelText, false, selectorWindow) -- Centered X=15, Y=43
        guiSetFont(comboLabel, fontName)
        guiLabelSetHorizontalAlign(comboLabel, "center", false)
        
        -- ComboBox for selection
        -- Position ComboBox relative to window size (adjust as needed)
        local memoryComboBox = guiCreateComboBox(37, 70, 140, 103, "", false, selectorWindow) -- Pair Centered: X=37, Y=68
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
        local applyButton = guiCreateButton(182, 69, 80, 25, "Apply", false, selectorWindow) -- Pair Centered: X=182, Y=68, H=25

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
                outputChatBox("Engine reports Bytes: " .. actualBytes .. " (approx. " .. actualMiB .. " MiB)", 255, 255, 0)

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
        local closeButton = guiCreateButton(0, 180, 300, 25, "Close", false, selectorWindow) -- Absolute, Y adjusted

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
