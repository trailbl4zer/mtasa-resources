function selectorMenu(memorySizeBytes,memorySizeMiB)
    guiCreateTab("Client", guiCreateTabPanel(0, 0, 1, 1, false, nil))
end

local selectorWindow = nil -- Variable to hold the window element

addCommandHandler("cachesize", function()
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
        local windowHeight = 215 -- Match stream_client.lua

        local windowX = (screenWidth - windowWidth) / 2
        local windowY = (screenHeight - windowHeight) / 2

        -- Create the window and store it
        -- Create the window with the new multi-line title
        selectorWindow = guiCreateWindow(windowX, windowY, windowWidth, windowHeight, "Buffer Size - Selector Menu", false) -- Updated Title
        guiWindowSetSizable(selectorWindow, false)


        -- Use a fixed font size
        local fontName = "default-bold-1" -- Using size 1, adjust if needed

        -- Label for Current Memory Size
        local currentSizeBytes = engineStreamingGetBufferSize() -- Get current buffer size in bytes
        local currentSizeMiB = math.floor(currentSizeBytes / (1024 * 1024)) -- Convert bytes to MiB for display

        local currentSizeLabelText = "Current buffer size: " .. currentSizeMiB .. " MiB " -- Updated Label Text
        -- Position label relative to window size (adjust as needed)
        local currentSizeLabel = guiCreateLabel(15, 25, 270, 20, currentSizeLabelText, false, selectorWindow) -- Absolute
        guiSetFont(currentSizeLabel, fontName)
        guiLabelSetHorizontalAlign(currentSizeLabel, "center", false)

        -- Label for ComboBox
        local comboLabelText = "Select buffer size:" -- Updated Label Text
        -- Position label relative to window size (adjust as needed)
        local comboLabel = guiCreateLabel(15, 50, 270, 20, comboLabelText, false, selectorWindow) -- Match stream_client: Y=50
        guiSetFont(comboLabel, fontName)
        guiLabelSetHorizontalAlign(comboLabel, "center", false)
        
        -- ComboBox for selection
        -- Position ComboBox relative to window size (adjust as needed)
        local memoryComboBox = guiCreateComboBox(37, 70, 140, 103, "", false, selectorWindow) -- Match stream_client: Y=70, H=103
        -- Add new options
        guiComboBoxAddItem(memoryComboBox, "4 MiB")
        guiComboBoxAddItem(memoryComboBox, "128 MiB")
        guiComboBoxAddItem(memoryComboBox, "256 MiB")
        guiComboBoxAddItem(memoryComboBox, "512 MiB")
        guiComboBoxAddItem(memoryComboBox, "1000 MiB") -- Added option

        -- Set initial ComboBox selection based on current setting
        local currentBytesForCombo = engineStreamingGetBufferSize() -- Use Buffer Size function
        local selectedIndex = -1
        local selectedMiBValue = nil

        -- Special check for the default 5160960 bytes
        if currentBytesForCombo == 5160960 then
            for i = 0, guiComboBoxGetItemCount(memoryComboBox) - 1 do
                if guiComboBoxGetItemText(memoryComboBox, i) == "4 MiB" then
                    selectedIndex = i
                    selectedMiBValue = 4 -- Store the nominal MiB value for consistency
                    break
                end
            end
        end

        -- If not the special case, find the closest MiB match (or exact if possible)
        if selectedIndex == -1 then
            local smallestDifference = math.huge
            for i = 0, guiComboBoxGetItemCount(memoryComboBox) - 1 do
                local itemText = guiComboBoxGetItemText(memoryComboBox, i)
                local itemMiB = tonumber(string.match(itemText or "", "%d+"))
                if itemMiB then
                    local itemBytes = itemMiB * 1024 * 1024
                    local difference = math.abs(currentBytesForCombo - itemBytes)
                    if difference < smallestDifference then
                        smallestDifference = difference
                        selectedIndex = i
                        selectedMiBValue = itemMiB
                    end
                end
            end
        end

        -- Select the determined index and store its MiB value
        if selectedIndex ~= -1 then
            guiComboBoxSetSelected(memoryComboBox, selectedIndex)
            setElementData(memoryComboBox, "selectedMiB", selectedMiBValue)
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
        local applyButton = guiCreateButton(182, 69, 80, 25, "Apply", false, selectorWindow) -- Match stream_client: Y=69

        -- Event handler for Apply Button
        addEventHandler("onClientGUIClick", applyButton, function()
            -- Get the TEXT of the selected item to check for the special case
            local selectedIndex = guiComboBoxGetSelected(memoryComboBox)
            local selectedText = ""
            if selectedIndex ~= -1 then
                selectedText = guiComboBoxGetItemText(memoryComboBox, selectedIndex)
            end

            local bytesToSend = nil
            local feedbackMiB = ""

            -- Check for the special "4 MiB" case
            if selectedText == "4 MiB" then
                bytesToSend = 5160960 -- Use the specific byte value
                feedbackMiB = "4 MiB (5160960 Bytes)"
            else
                -- Otherwise, use the stored MiB value (fallback if text somehow doesn't match)
                local miBToApply = getElementData(memoryComboBox, "selectedMiB")
                if miBToApply then
                    bytesToSend = miBToApply * 1024 * 1024 -- Standard calculation
                    feedbackMiB = miBToApply .. " MiB"
                end
            end
            
            if bytesToSend then
                -- Debug: Show MiB selected and Bytes being sent
                -- Construct specific debug message for the 4 MiB case
                if selectedText == "4 MiB" then
                    outputChatBox("Applying Buffer Setting - Selected: 4 MiB. Using default value, sending Bytes: 5160960", 255, 255, 0)
                else
                    outputChatBox("Applying Buffer Setting - Selected: " .. feedbackMiB .. ". Sending Bytes: " .. bytesToSend, 255, 255, 0)
                end
                
                -- Set the buffer size (function expects Bytes)
                engineStreamingSetBufferSize(bytesToSend)
                
                -- Debug: Check what the engine reports immediately after setting (in Bytes)
                local actualBytes = engineStreamingGetBufferSize() -- Use Buffer Size function
                local actualMiB = math.floor(actualBytes / (1024 * 1024))
                outputChatBox("Engine reports Bytes: " .. actualBytes .. " (approx. " .. actualMiB .. " MiB)", 255, 255, 0)

                -- Feedback: Confirm the request was processed using the intended MiB value
                outputChatBox("Buffer size set request finished for: " .. feedbackMiB, 0, 255, 0)

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
