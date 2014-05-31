-----------------------------------------
--                                     --
--  EsoheadMerge based off of code     --
--  from Esohead by Zam Network        --
--                                     --
-----------------------------------------

EHM = {}

-----------------------------------------
--           Core Functions            --
-----------------------------------------

function EHM.Initialize()
    EHM.savedVars = {}
    EHM.debugDefault = 0
    EHM.dataDefault = {
        data = {}
    }
    EHM.minDefault = 0.000025 -- 0.005^2
    EHM.minReticleover = 0.000049 -- 0.007^2
end

function EHM.InitSavedVariables()
    EHM.savedVars = {
        ["internal"]     = ZO_SavedVars:NewAccountWide("EsoheadMerge_SavedVariables", 1, "internal", { debug = EHM.debugDefault, language = "" }),
        ["skyshard"]     = ZO_SavedVars:NewAccountWide("EsoheadMerge_SavedVariables", 2, "skyshard", EHM.dataDefault),
        ["book"]         = ZO_SavedVars:NewAccountWide("EsoheadMerge_SavedVariables", 2, "book", EHM.dataDefault),
        ["harvest"]      = ZO_SavedVars:NewAccountWide("EsoheadMerge_SavedVariables", 4, "harvest", EHM.dataDefault),
        ["provisioning"] = ZO_SavedVars:NewAccountWide("EsoheadMerge_SavedVariables", 4, "provisioning", EHM.dataDefault),
        ["chest"]        = ZO_SavedVars:NewAccountWide("EsoheadMerge_SavedVariables", 2, "chest", EHM.dataDefault),
        ["fish"]         = ZO_SavedVars:NewAccountWide("EsoheadMerge_SavedVariables", 2, "fish", EHM.dataDefault),
        ["npc"]          = ZO_SavedVars:NewAccountWide("EsoheadMerge_SavedVariables", 2, "npc", EHM.dataDefault),
        ["vendor"]       = ZO_SavedVars:NewAccountWide("EsoheadMerge_SavedVariables", 2, "vendor", EHM.dataDefault),
        ["quest"]        = ZO_SavedVars:NewAccountWide("EsoheadMerge_SavedVariables", 2, "quest", EHM.dataDefault),
    }

    if EHM.savedVars["internal"].debug == 1 then
        EHM.Debug("EsoheadMerge addon initialized. Debugging is enabled.")
    else
        EHM.Debug("EsoheadMerge addon initialized. Debugging is disabled.")
    end
end

-- Logs saved variables
function EHM.Log(type, nodes, ...)
    local data = {}
    local dataStr = ""
    local sv

    if EHM.savedVars[type] == nil or EHM.savedVars[type].data == nil then
        EHM.Debug("Attempted to log unknown type: " .. type)
        return
    else
        sv = EHM.savedVars[type].data
    end

    for i = 1, #nodes do
        local node = nodes[i];
        if string.find(node, '\"') then
            node = string.gsub(node, '\"', '\'')
        end

        if sv[node] == nil then
            sv[node] = {}
        end
        sv = sv[node]
    end

    for i = 1, select("#", ...) do
        local value = select(i, ...)
        data[i] = value
        dataStr = dataStr .. "[" .. tostring(value) .. "] "
    end

    if EHM.savedVars["internal"].debug == 1 then
        EHM.Debug("Logged [" .. type .. "] data: " .. dataStr)
    end

    if #sv == 0 then
        sv[1] = data
    else
        sv[#sv+1] = data
    end
end

-- Checks if we already have an entry for the object/npc within a certain x/y distance
function EHM.LogCheck(type, nodes, x, y, scale, name)
    local log = true
    local sv

    if x <= 0 or y <= 0 then
        return false
    end

    if EHM.savedVars[type] == nil or EHM.savedVars[type].data == nil then
        return true
    else
        sv = EHM.savedVars[type].data
    end

    local distance
    if scale == nil then
        distance = EHM.minDefault
    else
        distance = scale
    end

    for i = 1, #nodes do
        local node = nodes[i];
        if string.find(node, '\"') then
            node = string.gsub(node, '\"', '\'')
        end

        if sv[node] == nil then
            sv[node] = {}
        end
        sv = sv[node]
    end

    for i = 1, #sv do
        local item = sv[i]

        dx = item[1] - x
        dy = item[2] - y
        -- (x - center_x)2 + (y - center_y)2 = r2, where center is the player
        dist = math.pow(dx, 2) + math.pow(dy, 2)
        -- both ensure that the entire table isn't parsed
        if dx <= 0 and dy <= 0 then -- at player location
            if name == nil then -- npc, quest, vendor all but harvesting
                return false
            else -- harvesting only
                if item[4] == name then
                    return false
                end
            end
        elseif dist < distance then -- near player location
            if name == nil then -- npc, quest, vendor all but harvesting
                return false
            else -- harvesting only
                if item[4] == name then
                    return false
                end
            end
        end
    end

    return log
end

-- formats a number with commas on thousands
function EHM.NumberFormat(num)
    local formatted = num
    local k

    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then
            break
        end
    end

    return formatted
end

-----------------------------------------
--           Merge Nodes               --
-----------------------------------------
function EHM.importFromEsohead()
    if not EH then
        d("Please enable the Esohead addon to import data!")
        return
    end

    EHM.Debug("EsoheadMerge Starting Import")
    for category, data in pairs(EH.savedVars) do
        if category ~= "internal" and (category == "chest" or category == "fish") then
            for map, location in pairs(data.data) do
                -- EHM.Debug(category .. map)
                for v1, node in pairs(location) do
                    -- EHM.Debug(node[1] .. node[2])
                    if EHM.LogCheck(category, { map }, node[1], node[2], EHM.minReticleover, nil) then
                        EHM.Log(category, { map }, node[1], node[2])
                    end
                end
            end
        elseif category ~= "internal" and category == "skyshard" then
            for map, location in pairs(data.data) do
                -- EHM.Debug(category .. map)
                for v1, node in pairs(location) do
                    -- EHM.Debug(node[1] .. node[2])
                    if EHM.LogCheck(category, { map }, node[1], node[2], EHM.minReticleover, nil) then
                        EHM.Log(category, { map }, node[1], node[2])
                    end
                end
            end
        elseif category ~= "internal" and category == "provisioning" then
            for map, location in pairs(data.data) do
                -- EHM.Debug(category .. map)
                for itemId, nodes in pairs(location[5]) do
                    for v1, node in pairs(nodes) do
                        -- EHM.Debug("ItemID : " .. itemId .. " : " .. node[1] .. " : " .. node[2] .. " : " .. node[3] .. " : " .. node[4])
                        if EHM.LogCheck(category, {map, 5, itemId}, node[1], node[2], nil, nil) then
                            EHM.Log(category, {map, 5, itemId}, node[1], node[2], node[3], node[4])
                        end
                    end
                end
            end
        elseif category ~= "internal" and category == "harvest" then
            for map, location in pairs(data.data) do
                -- EHM.Debug(category .. map)
                for profession, nodes in pairs(location) do
                    for v1, node in pairs(nodes) do
                        if EHM.LogCheck(category, {map, profession}, node[1], node[2], nil, node[4]) then
                            EHM.Log(category, {map, profession}, node[1], node[2], node[3], node[4], node[5])
                        end
                    end
                end
            end
        elseif category ~= "internal" and category == "vendor" then
            for map, location in pairs(data.data) do
                -- EHM.Debug(category .. map)
                for vendor, vendors in pairs(location) do
                    for v1, inventory in pairs(vendors) do
                        -- EHM.Debug("Vendor : " .. vendor .." : X, Y : " .. inventory[1] .. " : " .. inventory[2])
                        if EHM.LogCheck(category, {map, vendor}, inventory[1], inventory[2], 0.1, nil) then
                            EHM.Log(category, {map, vendor}, inventory[1], inventory[2], inventory[3])
                        end
                    end
                end
            end
        elseif category ~= "internal" and category == "quest" then
            for map, location in pairs(data.data) do
                -- EHM.Debug(category .. map)
                for quest, quests in pairs(location) do
                    for v1, info in pairs(quests) do
                        -- EHM.Debug("Quest : " .. quest .." : X, Y : " .. info[1] .. " : " .. info[2])
                        if EHM.LogCheck(category, {map, quest}, info[1], info[2], EHM.minReticleover, nil) then
                            EHM.Log(category, { map, quest }, info[1], info[2], info[3], info[4], info[5])
                        end
                    end
                end
            end
        elseif category ~= "internal" and category == "npc" then
            for map, location in pairs(data.data) do
                -- EHM.Debug(category .. map)
                for npc, npcs in pairs(location) do
                    for v1, info in pairs(npcs) do
                        -- EHM.Debug("Npc : " .. npc .." : X, Y : " .. info[1] .. " : " .. info[2])
                        if EHM.LogCheck(category, { map, npc }, info[1], info[2], EHM.minReticleover, nil) then
                            EHM.Log(category, { map, npc }, info[1], info[2], info[3])
                        end
                    end
                end
            end
        elseif category ~= "internal" and category == "book" then
            for map, location in pairs(data.data) do
                -- EHM.Debug(category .. map)
                for book, books in pairs(location) do
                    for v1, info in pairs(books) do
                        -- EHM.Debug("Book Name : " .. book .." : X, Y : " .. info[1] .. " : " .. info[2])
                        if EHM.LogCheck(category, {map, book}, info[1], info[2], nil, nil) then
                            EHM.Log(category, {map, book}, info[1], info[2])
                        end
                    end
                end
            end
        end
    end
    EHM.Debug("Import Complete")
end

-----------------------------------------
--           Debug Logger              --
-----------------------------------------

local function EmitMessage(text)
    if(CHAT_SYSTEM)
    then
        if(text == "")
        then
            text = "[Empty String]"
        end

        CHAT_SYSTEM:AddMessage(text)
    end
end

local function EmitTable(t, indent, tableHistory)
    indent          = indent or "."
    tableHistory    = tableHistory or {}

    for k, v in pairs(t)
    do
        local vType = type(v)

        EmitMessage(indent.."("..vType.."): "..tostring(k).." = "..tostring(v))

        if(vType == "table")
        then
            if(tableHistory[v])
            then
                EmitMessage(indent.."Avoiding cycle on table...")
            else
                tableHistory[v] = true
                EmitTable(v, indent.."  ", tableHistory)
            end
        end
    end
end

function EHM.Debug(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if(type(value) == "table")
        then
            EmitTable(value)
        else
            EmitMessage(tostring (value))
        end
    end
end

-----------------------------------------
--           Slash Command             --
-----------------------------------------

EHM.validCategories = {
    "chest",
    "fish",
    "provisioning",
    "book",
    "vendor",
    "quest",
    "harvest",
    "npc",
    "skyshard",
}

function EHM.IsValidCategory(name)
    for k, v in pairs(EHM.validCategories) do
        if string.lower(v) == string.lower(name) then
            return true
        end
    end

    return false
end

SLASH_COMMANDS["/esomerge"] = function (cmd)
    local commands = {}
    local index = 1
    for i in string.gmatch(cmd, "%S+") do
        if (i ~= nil and i ~= "") then
            commands[index] = i
            index = index + 1
        end
    end

    if #commands == 0 then
        return EHM.Debug("Please enter a valid EsoheadMerge command")
    end

    if #commands == 2 and commands[1] == "debug" then
        if commands[2] == "on" then
            EHM.Debug("EsoheadMerge debugger toggled on")
            EHM.savedVars["internal"].debug = 1
        elseif commands[2] == "off" then
            EHM.Debug("EsoheadMerge debugger toggled off")
            EHM.savedVars["internal"].debug = 0
        end

    elseif commands[1] == "import" then

        EHM.importFromEsohead()

    elseif commands[1] == "reset" then
        if #commands ~= 2 then 
            for type,sv in pairs(EHM.savedVars) do
                if type ~= "internal" then
                    EHM.savedVars[type].data = {}
                end
            end
            EHM.Debug("EsoheadMerge saved data has been completely reset")
        else
            if commands[2] ~= "internal" then
                if EHM.IsValidCategory(commands[2]) then
                    EHM.savedVars[commands[2]].data = {}
                    EHM.Debug("EsoheadMerge saved data : " .. commands[2] .. " has been reset")
                else
                    return EHM.Debug("Please enter a valid EsoheadMerge category to reset")
                end
            end
        end

    elseif commands[1] == "datalog" then
        EHM.Debug("---")
        EHM.Debug("Complete list of gathered data:")
        EHM.Debug("---")

        local counter = {
            ["skyshard"] = 0,
            ["npc"] = 0,
            ["harvest"] = 0,
            ["provisioning"] = 0,
            ["chest"] = 0,
            ["fish"] = 0,
            ["book"] = 0,
            ["vendor"] = 0,
            ["quest"] = 0,
        }

        for type,sv in pairs(EHM.savedVars) do
            if type ~= "internal" and (type == "skyshard" or type == "chest" or type == "fish") then
                for zone, t1 in pairs(EHM.savedVars[type].data) do
                    counter[type] = counter[type] + #EHM.savedVars[type].data[zone]
                end
            elseif type ~= "internal" and type == "provisioning" then
                for zone, t1 in pairs(EHM.savedVars[type].data) do
                    for item, t2 in pairs(EHM.savedVars[type].data[zone]) do
                        for data, t3 in pairs(EHM.savedVars[type].data[zone][item]) do
                            counter[type] = counter[type] + #EHM.savedVars[type].data[zone][item][data]
                        end
                    end
                end
            elseif type ~= "internal" then
                for zone, t1 in pairs(EHM.savedVars[type].data) do
                    for data, t2 in pairs(EHM.savedVars[type].data[zone]) do
                        counter[type] = counter[type] + #EHM.savedVars[type].data[zone][data]
                    end
                end
            end
        end

        EHM.Debug("Skyshards: "        .. EHM.NumberFormat(counter["skyshard"]))
        EHM.Debug("Monster/NPCs: "     .. EHM.NumberFormat(counter["npc"]))
        EHM.Debug("Lore/Skill Books: " .. EHM.NumberFormat(counter["book"]))
        EHM.Debug("Harvest: "          .. EHM.NumberFormat(counter["harvest"]))
        EHM.Debug("Provisioning: "     .. EHM.NumberFormat(counter["provisioning"]))
        EHM.Debug("Treasure Chests: "  .. EHM.NumberFormat(counter["chest"]))
        EHM.Debug("Fishing Pools: "    .. EHM.NumberFormat(counter["fish"]))
        EHM.Debug("Quests: "           .. EHM.NumberFormat(counter["quest"]))
        EHM.Debug("Vendor Lists: "     .. EHM.NumberFormat(counter["vendor"]))

        EHM.Debug("---")
    end
end

SLASH_COMMANDS["/rl"] = function()
    ReloadUI("ingame")
end

SLASH_COMMANDS["/reload"] = function()
    ReloadUI("ingame")
end

-----------------------------------------
--        Addon Initialization         --
-----------------------------------------

function EHM.OnLoad(eventCode, addOnName)
    if addOnName ~= "EsoheadMerge" then
        return
    end

    EHM.language = (GetCVar("language.2") or "en")
    EHM.InitSavedVariables()
    EHM.savedVars["internal"]["language"] = EHM.language
end

EVENT_MANAGER:RegisterForEvent("EsoheadMerge", EVENT_ADD_ON_LOADED, function (eventCode, addOnName)
    if addOnName == "EsoheadMerge" then
        EHM.Initialize()
        EHM.OnLoad(eventCode, addOnName)
    end
end)
