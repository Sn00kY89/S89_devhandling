-- ============================================================
--  client/main.lua
--  Bridge NUI, handling natives, telemetria
--  (Rename-safe: tutti gli eventi usano GetCurrentResourceName())
-- ============================================================

local RESOURCE_NAME     = GetCurrentResourceName()
local EVT               = RESOURCE_NAME .. ':'
local LOG_PREFIX        = '[' .. RESOURCE_NAME .. '] '

local isMenuOpen        = false
local currentValues     = {}
local currentVehName    = ''
local currentAiHandling = 'AVERAGE'
local telemetryActive   = false

-- Mappa classe veicolo GTA -> valore AIHandling del handling.meta
local CLASS_TO_AI = {
    [0]  = 'AVERAGE',    [1]  = 'AVERAGE',    [2]  = 'AVERAGE',
    [3]  = 'AVERAGE',    [4]  = 'SPORTS_CAR', [5]  = 'SPORTS_CAR',
    [6]  = 'SPORTS_CAR', [7]  = 'SPORTS_CAR', [8]  = 'TRUCK',
    [9]  = 'AVERAGE',    [10] = 'AVERAGE',    [11] = 'AVERAGE',
    [12] = 'TRUCK',      [13] = 'AVERAGE',    [14] = 'TRUCK',
    [15] = 'AVERAGE',    [16] = 'AVERAGE',    [17] = 'TRUCK',
    [18] = 'TRUCK',      [19] = 'TRUCK',      [20] = 'TRUCK',
    [21] = 'AVERAGE'
}

local function readVehicleHandling(vehicle)
    local out = {}
    for k, v in pairs(Config.Values) do
        if v.type == 'float' then
            out[k] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', k)
        elseif v.type == 'int' then
            out[k] = GetVehicleHandlingInt(vehicle, 'CHandlingData', k)
        elseif v.type == 'vector' then
            local vec = GetVehicleHandlingVector(vehicle, 'CHandlingData', k)
            out[k] = string.format('%f %f %f', vec.x, vec.y, vec.z)
        elseif v.type == 'string' then
            local raw = GetVehicleHandlingInt(vehicle, 'CHandlingData', k)
            out[k] = string.format('%X', raw)
        end
    end
    return out
end

-- ============================================================
-- Registrazione comando / keybind
-- ============================================================
if Config and Config.MenuToggle then
    RegisterCommand(Config.MenuToggle.command, function()
        if telemetryActive or isMenuOpen then return end
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle    = GetVehiclePedIsIn(ped, false)
            local vehName    = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
            local aiHandling = CLASS_TO_AI[GetVehicleClass(vehicle)] or 'AVERAGE'
            local values     = readVehicleHandling(vehicle)
            TriggerServerEvent(EVT .. 'requestOpen', values, aiHandling, vehName)
        else
            print(LOG_PREFIX .. 'Devi essere in un veicolo per aprire l\'editor.')
        end
    end, false)

    if Config.MenuToggle.method == 'keybind' then
        RegisterKeyMapping(Config.MenuToggle.command, Config.MenuToggle.description, 'keyboard', Config.MenuToggle.key)
    end
end

-- ============================================================
-- Ricezione dati pre-calcolati dal server e apertura NUI
-- ============================================================
RegisterNetEvent(EVT .. 'openHandlingEditor', function(payload)
    if type(payload) ~= 'table' then return end
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then return end

    currentAiHandling = payload.aiHandling or 'AVERAGE'
    currentVehName    = payload.vehicleName or 'UNKNOWN'
    currentValues     = readVehicleHandling(vehicle)

    SetNuiFocus(true, true)
    isMenuOpen = true

    SendNUIMessage({
        type          = 'openHandlingEditor',
        vehicleName   = currentVehName,
        plate         = GetVehicleNumberPlateText(vehicle),
        data          = payload.config,
        values        = currentValues,
        displayData   = payload.displayData,
        aiHandling    = currentAiHandling,
        locales       = Locales or {},
        defaultLocale = Config.Locale or 'en'
    })
end)

-- ============================================================
-- Ricezione aggiornamenti display da server
-- ============================================================
RegisterNetEvent(EVT .. 'receiveDisplayUpdate', function(displayData)
    if isMenuOpen and type(displayData) == 'table' then
        SendNUIMessage({ type = 'updateDisplay', displayData = displayData })
    end
end)

-- ============================================================
-- Ricezione XML generato dal server → forward alla NUI
-- ============================================================
RegisterNetEvent(EVT .. 'receiveXML', function(xmlString)
    if isMenuOpen and type(xmlString) == 'string' then
        SendNUIMessage({ type = 'copyXML', xml = xmlString })
    end
end)

-- ============================================================
-- NUI Callbacks
-- ============================================================
RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    isMenuOpen = false
    cb('ok')
end)

RegisterNUICallback('respawnVehicle', function(_, cb)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
        SetVehicleModKit(vehicle, 0)
        ModifyVehicleTopSpeed(vehicle, 1.0)
    end
    cb('ok')
end)

RegisterNUICallback('saveLimit', function(data, cb)
    if type(data) == 'table' and type(data.param) == 'string' then
        TriggerServerEvent(EVT .. 'saveLimit', data.param, data.min, data.max)
    end
    cb('ok')
end)

RegisterNUICallback('exportXML', function(data, cb)
    TriggerServerEvent(EVT .. 'generateXML', currentVehName, currentAiHandling, currentValues)
    cb('ok')
end)

RegisterNUICallback('updateHandling', function(data, cb)
    if type(data) ~= 'table' then cb('ok') return end
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if vehicle ~= 0 then
        local key   = data.key
        local value = data.value
        local vCfg  = type(key) == 'string' and Config.Values[key] or nil

        if vCfg then
            if vCfg.type == 'float' then
                local numVal = tonumber(value)
                if numVal then
                    SetVehicleHandlingFloat(vehicle, 'CHandlingData', key, numVal + 0.0)
                    currentValues[key] = numVal
                end
            elseif vCfg.type == 'int' then
                local numVal = tonumber(value)
                if numVal then
                    numVal = math.floor(numVal)
                    SetVehicleHandlingInt(vehicle, 'CHandlingData', key, numVal)
                    currentValues[key] = numVal
                end
            elseif vCfg.type == 'string' then
                local intVal = type(value) == 'string' and tonumber(value, 16) or nil
                if intVal then
                    SetVehicleHandlingInt(vehicle, 'CHandlingData', key, intVal)
                    currentValues[key] = value
                end
            end

            -- Refresh specifico per il numero di marce: forza ricarico delle ratios
            if key == 'nInitialDriveGears' then
                local gears = math.floor(tonumber(value) or 1)
                SetVehicleHighGear(vehicle, gears)
                local curMaxVel = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel')
                SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel', curMaxVel + 0.1)
                local vehRef = vehicle
                CreateThread(function()
                    Wait(50)
                    if DoesEntityExist(vehRef) then
                        SetVehicleHandlingFloat(vehRef, 'CHandlingData', 'fInitialDriveMaxFlatVel', curMaxVel)
                        SetVehicleModKit(vehRef, 0)
                        ModifyVehicleTopSpeed(vehRef, 1.0)
                    end
                end)
            elseif key == 'fInitialDriveForce' then
                SetVehicleModKit(vehicle, 0)
            end

            ModifyVehicleTopSpeed(vehicle, 1.0)

            -- Per i parametri che influenzano la velocità simulata o hanno unit specifiche: richiedi recalc al server
            if key == 'fInitialDriveForce' or key == 'fInitialDragCoeff' or key == 'fInitialDriveMaxFlatVel' or key == 'fMass' or key == 'fBrakeForce' then
                TriggerServerEvent(EVT .. 'recalcDisplay', key, currentValues)
            end
        end
    end
    cb('ok')
end)

-- Aggiornamento limiti broadcast da server
RegisterNetEvent(EVT .. 'updateLimit', function(paramName, minVal, maxVal)
    if isMenuOpen and type(paramName) == 'string' and Config.Values[paramName] then
        SendNUIMessage({
            type  = 'updateLimit',
            param = paramName,
            min   = minVal,
            max   = maxVal
        })
    end
end)

-- ============================================================
-- Telemetria (escrowed nel client, loop real-time)
-- ============================================================
RegisterNUICallback('startTelemetry', function(data, cb)
    if telemetryActive then
        cb('ok')
        return
    end

    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        SendNUIMessage({ type = 'closeTelemetry' })
        cb('ok')
        return
    end

    if type(data) ~= 'table' then data = {} end

    SetNuiFocus(false, false)
    isMenuOpen    = false
    telemetryActive = true

    local duration       = tonumber(data.duration) or 60
    if duration < 5 or duration > 600 then duration = 60 end
    local speedUnit      = data.unit == 'mph' and 'mph' or 'kmh'
    local partialTargets = (speedUnit == 'mph') and {t100=60,t150=100,t200=130} or {t100=100,t150=150,t200=200}
    local recordingTime  = duration * 1000

    -- ESC handler (per-frame): blocca il pause menu e ferma la telemetria
    CreateThread(function()
        while telemetryActive do
            Wait(0)
            DisableControlAction(0, 200, true) -- INPUT_FRONTEND_PAUSE
            DisableControlAction(0, 322, true) -- INPUT_FRONTEND_PAUSE_ALTERNATE
            if IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 322) then
                telemetryActive = false
            end
        end

        -- Input Sinking: previene apertura immediata del pause menu post-telemetria
        for _ = 1, 20 do
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 322, true)
            Wait(0)
        end
    end)

    CreateThread(function()
        local timerActive      = false
        local startTime        = 0
        local topSpeed         = 0
        local time100          = nil
        local time150          = nil
        local time200          = nil
        local timeQmile        = nil
        local timeHmile        = nil
        local hasStartedMoving = false
        local distanceTraveled = 0.0
        local lastCoords       = nil
        local stoppedSince     = nil

        while telemetryActive do
            Wait(50)

            if GetVehiclePedIsIn(ped, false) == 0 or not DoesEntityExist(vehicle) then
                telemetryActive = false
                break
            end

            local speedRaw = GetEntitySpeed(vehicle)
            local speed = 0
            if speedUnit == 'kmh' then
                speed = math.floor(speedRaw * 3.6)
            else
                speed = math.floor(speedRaw * 2.236936)
            end
            local gear        = GetVehicleCurrentGear(vehicle)
            local currentCoords = GetEntityCoords(vehicle)

            if speed > topSpeed then topSpeed = speed end

            if speed > 0 and not hasStartedMoving then
                hasStartedMoving = true
                timerActive      = true
                startTime        = GetGameTimer()
                lastCoords       = currentCoords
            elseif speed == 0 and hasStartedMoving then
                if stoppedSince == nil then
                    stoppedSince = GetGameTimer()
                elseif GetGameTimer() - stoppedSince >= 5000 then
                    telemetryActive = false
                    break
                end
            else
                stoppedSince = nil
            end

            local timeLeft = duration
            if timerActive then
                local elapsed   = GetGameTimer() - startTime
                local elapsedSec = elapsed / 1000.0
                timeLeft = math.ceil((recordingTime - elapsed) / 1000)

                if elapsed >= recordingTime then
                    telemetryActive = false
                    break
                end

                if lastCoords then
                    distanceTraveled = distanceTraveled + #(currentCoords - lastCoords)
                end
                lastCoords = currentCoords

                if speed >= partialTargets.t100 and time100 == nil then time100 = elapsedSec end
                if speed >= partialTargets.t150 and time150 == nil then time150 = elapsedSec end
                if speed >= partialTargets.t200 and time200 == nil then time200 = elapsedSec end
                if distanceTraveled >= 402.336 and timeQmile == nil then timeQmile = elapsedSec end
                if distanceTraveled >= 804.672 and timeHmile == nil then timeHmile = elapsedSec end
            end

            SendNUIMessage({
                type            = 'updateTelemetry',
                speed           = speed,
                gear            = gear,
                topSpeed        = topSpeed,
                timeLeft        = timeLeft > 0 and timeLeft or duration,
                hasStartedMoving = hasStartedMoving,
                time100         = time100,
                time150         = time150,
                time200         = time200,
                timeQmile       = timeQmile,
                timeHmile       = timeHmile,
                unit            = speedUnit
            })
        end

        SendNUIMessage({ type = 'closeTelemetry' })
    end)

    cb('ok')
end)

RegisterNUICallback('stopTelemetry', function(data, cb)
    telemetryActive = false
    local reopen = type(data) == 'table' and data.reopen or false
    if reopen then
        SetNuiFocus(true, true)
        isMenuOpen = true
    else
        SetNuiFocus(false, false)
        isMenuOpen = false
    end
    cb('ok')
end)

-- Request current vehicle stock mods
RegisterNUICallback('requestVehicleMods', function(data, cb)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then cb({stock = {}}) return end
    local stock = {
        engine = GetVehicleMod(veh, 11),
        brakes = GetVehicleMod(veh, 12),
        transmission = GetVehicleMod(veh, 13),
        suspension = GetVehicleMod(veh, 15),
        turbo = IsToggleModOn(veh, 18)
    }
    cb({stock = stock})
end)

-- Apply selected mods
RegisterNUICallback('setVehicleMods', function(data, cb)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then cb('error') return end
    if type(data) == 'table' and type(data.mods) == 'table' then
        SetVehicleModKit(veh, 0)
        local m = data.mods
        if tonumber(m.engine)       then SetVehicleMod(veh, 11, tonumber(m.engine),       false) end
        if tonumber(m.brakes)       then SetVehicleMod(veh, 12, tonumber(m.brakes),       false) end
        if tonumber(m.transmission) then SetVehicleMod(veh, 13, tonumber(m.transmission), false) end
        if tonumber(m.suspension)   then SetVehicleMod(veh, 15, tonumber(m.suspension),   false) end
        if m.turbo ~= nil           then ToggleVehicleMod(veh, 18, m.turbo and true or false) end
    end
    cb('ok')
end)
