-- Helper function to calculate final coordinate (absolute or relative)
local function calculateCoordinate(currentValue, input)
    if not input or input == "" then
        return currentValue -- No input, use current value
    end

    -- Trim whitespace from input
    input = string.gsub(input, "^%s*(.-)%s*$", "%1")

    local firstChar = string.sub(input, 1, 1)
    if firstChar == '+' or firstChar == '-' then
        local numericPart = string.sub(input, 2)
        local num = tonumber(numericPart)
        if num then
            if firstChar == '+' then
                return currentValue + num
            else -- Must be '-'
                return currentValue - num
            end
        else
             -- Invalid relative input (e.g., "+abc"), fallback to current value
             outputChatBox("Invalid relative value: " .. input .. ". Using current value.", 255, 100, 100)
            return currentValue
        end
    else
        -- Try converting the whole input as an absolute value
        local absoluteNum = tonumber(input)
        if absoluteNum then
            return absoluteNum
        else
            -- Invalid absolute input (e.g., "abc"), fallback to current value
            outputChatBox("Invalid absolute value: " .. input .. ". Using current value.", 255, 100, 100)
            return currentValue
        end
    end
end

function setPosCommand(cmd, x, y, z, r)
	-- Handle setpos if used like: x, y, z, r or x,y,z,r
	local x, y, z, r = string.gsub(x or "", ",", " "), string.gsub(y or "", ",", " "), string.gsub(z or "", ",", " "), string.gsub(r or "", ",", " ")
	-- Extra handling for x,y,z,r
	if (x and y == "" and not tonumber(x)) then
		x, y, z, r = unpack(split(x, " "))
	end
	
	local px, py, pz = getElementPosition(localPlayer)

    local distanceToGround = getElementDistanceFromCentreOfMassToBaseOfModel(localPlayer)
    pz = pz - distanceToGround
    
	local pr = getPedRotation(localPlayer)
	
	--[[ If somebody doesn't provide all XYZ explain that we will use their current X Y or Z.
	local message = ""
	message = message .. (tonumber(x) and "" or "X ")
	message = message .. (tonumber(y) and "" or "Y ")
	message = message .. (tonumber(z) and "" or "Z ")
	if (message ~= "") then
		outputChatBox(message.."los argumentos no fueron provistos Usando tu corriente "..message.."valores en su lugar.", 255, 255, 0)
	end]]

	if  (getElementData( localPlayer, "Lugares:park:in") == true ) then
	    return 
	end
    
	-- Calculate final coordinates using the helper function
	local finalX = calculateCoordinate(px, x)
	local finalY = calculateCoordinate(py, y)
	local finalZ = calculateCoordinate(pz, z)
	local finalR = calculateCoordinate(pr, r)

	-- Set the player's position
	setPlayerPosition(finalX, finalY, finalZ)
	if (isPedInVehicle(localPlayer)) then
		local vehicle = getPedOccupiedVehicle(localPlayer)
		if (vehicle and isElement(vehicle) and getVehicleController(vehicle) == localPlayer) then
			setElementRotation(vehicle, 0, 0, finalR)
		end
	else
		setPedRotation(localPlayer, finalR)
	end
end