-- ============================================================
--  server/server.lua
--  Permessi, persistenza limiti, dispatch eventi
--  (Rename-safe: tutti gli eventi usano GetCurrentResourceName())
-- ============================================================

local RESOURCE_NAME  = GetCurrentResourceName()
local EVT            = RESOURCE_NAME .. ':'
local CustomLimits   = {}
local LIMIT_HARD_MIN = -1e6
local LIMIT_HARD_MAX =  1e6

local function sanitizeXmlText(s)
    if type(s) ~= 'string' then return '' end
    s = s:gsub('[<>&"\'\r\n\t]', '')
    if #s > 64 then s = s:sub(1, 64) end
    return s
end

local function isValidValuesTable(t)
    if type(t) ~= 'table' then return false end
    local count = 0
    for k, _ in pairs(t) do
        if type(k) ~= 'string' or not Config.Values[k] then return false end
        count = count + 1
        if count > 128 then return false end
    end
    return true
end

CreateThread(function()
    local loadFile = LoadResourceFile(RESOURCE_NAME, "limits.json")
    if loadFile and #loadFile > 0 then
        local ok, decoded = pcall(json.decode, loadFile)
        CustomLimits = (ok and type(decoded) == 'table') and decoded or {}
    else
        SaveResourceFile(RESOURCE_NAME, "limits.json", json.encode({}), -1)
    end
end)

-- Apertura menu: raccoglie i valori e li passa al client con display+chart pre-calcolati
RegisterNetEvent(EVT .. 'requestOpen', function(vehicleValues, aiHandling, vehicleName)
    local src = source
    if not Config.isAllowed(src) then return end
    if not isValidValuesTable(vehicleValues) then return end

    -- Applica i limiti custom ai parametri prima di inviare al client
    local sendData = {}
    for k, v in pairs(Config.Values) do
        sendData[k] = {
            name        = v.name,
            type        = v.type,
            change      = v.change,
            min         = v.min,
            max         = v.max,
            description = v.description,
            components  = v.components
        }
        local cl = CustomLimits[k]
        if cl and tonumber(cl.min) and tonumber(cl.max) then
            sendData[k].min = cl.min
            sendData[k].max = cl.max
        end
    end

    -- Pre-calcola display labels e dati grafici
    local displayData = GenerateDisplayData(vehicleValues)

    TriggerClientEvent(EVT .. 'openHandlingEditor', src, {
        config      = sendData,
        displayData = displayData,
        aiHandling  = type(aiHandling) == 'string' and aiHandling or 'AVERAGE',
        vehicleName = type(vehicleName) == 'string' and vehicleName or 'UNKNOWN'
    })
end)

-- Ricalcola solo le display label dipendenti quando un valore cambia
RegisterNetEvent(EVT .. 'recalcDisplay', function(changedKey, currentValues)
    local src = source
    if not Config.isAllowed(src) then return end
    if type(changedKey) ~= 'string' or not Config.Values[changedKey] then return end
    if not isValidValuesTable(currentValues) then return end

    local displayData = GenerateDisplayData(currentValues)
    TriggerClientEvent(EVT .. 'receiveDisplayUpdate', src, displayData)
end)

-- Genera e restituisce l'XML al client (che lo forward alla NUI)
RegisterNetEvent(EVT .. 'generateXML', function(vehicleName, aiHandling, values)
    local src = source
    if not Config.isAllowed(src) then return end
    if not isValidValuesTable(values) then return end

    local cleanName = sanitizeXmlText(vehicleName)
    local cleanAi   = sanitizeXmlText(aiHandling)
    if cleanName == '' then cleanName = 'UNKNOWN' end
    if cleanAi   == '' then cleanAi   = 'AVERAGE' end

    local xml = GenerateHandlingXML(cleanName, cleanAi, values, Config.Values)
    TriggerClientEvent(EVT .. 'receiveXML', src, xml)
end)

-- Salva un limite custom per un parametro
RegisterNetEvent(EVT .. 'saveLimit', function(paramName, minVal, maxVal)
    local src = source
    if not Config.isAllowed(src) then return end
    if type(paramName) ~= 'string' or not Config.Values[paramName] then return end

    local minN = tonumber(minVal)
    local maxN = tonumber(maxVal)
    if not minN or not maxN then return end
    if minN >= maxN then return end
    if minN < LIMIT_HARD_MIN or maxN > LIMIT_HARD_MAX then return end

    CustomLimits[paramName] = { min = minN, max = maxN }

    SaveResourceFile(RESOURCE_NAME, "limits.json", json.encode(CustomLimits, {indent=true}), -1)
    TriggerClientEvent(EVT .. 'updateLimit', -1, paramName, minN, maxN)
end)
