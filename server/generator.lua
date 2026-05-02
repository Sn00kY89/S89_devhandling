-- ============================================================
--  server/generator.lua
--  Logica di calcolo: simulated speed, display labels, XML build
-- ============================================================

local FIELD_ORDER = {
    'handlingName',
    'fMass', 'fInitialDragCoeff', 'fDownforceModifier', 'fPopUpLightRotation', 'fPercentSubmerged',
    'vecCentreOfMassOffset', 'vecInertiaMultiplier',
    'fDriveBiasFront', 'nInitialDriveGears', 'fInitialDriveForce', 'fDriveInertia',
    'fClutchChangeRateScaleUpShift', 'fClutchChangeRateScaleDownShift', 'fInitialDriveMaxFlatVel',
    'fBrakeForce', 'fBrakeBiasFront', 'fHandBrakeForce',
    'fSteeringLock',
    'fTractionCurveMax', 'fTractionCurveMin', 'fTractionCurveLateral',
    'fTractionSpringDeltaMax', 'fLowSpeedTractionLossMult', 'fCamberStiffnesss',
    'fTractionBiasFront', 'fTractionLossMult',
    'fSuspensionForce', 'fSuspensionCompDamp', 'fSuspensionReboundDamp',
    'fSuspensionUpperLimit', 'fSuspensionLowerLimit', 'fSuspensionRaise', 'fSuspensionBiasFront',
    'fAntiRollBarForce', 'fAntiRollBarBiasFront',
    'fRollCentreHeightFront', 'fRollCentreHeightRear',
    'fCollisionDamageMult', 'fWeaponDamageMult', 'fDeformationDamageMult', 'fEngineDamageMult',
    'fPetrolTankVolume', 'fOilVolume',
    'fSeatOffsetDistX', 'fSeatOffsetDistY', 'fSeatOffsetDistZ',
    'nMonetaryValue',
    'strModelFlags', 'strHandlingFlags', 'strDamageFlags',
    'AIHandling'
}

-- ============================================================
-- FORMULA: velocità simulata (drag vs engine power limit)
-- ============================================================
local function CalcSimulatedSpeed(driveForce, dragCoeff, maxFlatVel)
    local power      = driveForce  or 0.25
    local drag       = dragCoeff   or 8.0
    local flatVel    = maxFlatVel  or 150.0

    local engineCapKmh  = (flatVel * 3.6) * 0.8
    local dragLimitKmh  = math.sqrt(power / drag) * 350.0
    local finalLimit    = math.min(engineCapKmh, dragLimitKmh)
    local isDragLimited = dragLimitKmh < engineCapKmh

    return math.floor(finalLimit), isDragLimited
end

-- ============================================================
-- FORMULA: pre-calcola le display labels per ogni parametro
-- ============================================================
function GenerateDisplayData(values)
    local display = {}
    local valuesCfg = Config and Config.Values or {}

    for k, v in pairs(values) do
        local cfg     = valuesCfg[k]
        local numVal  = tonumber(v) or 0
        local isInt   = cfg and cfg.type == 'int'
        local isStr   = cfg and cfg.type == 'string'
        local isVec   = cfg and cfg.type == 'vector'

        if k == 'fInitialDriveMaxFlatVel' then
            local speed, isDrag = CalcSimulatedSpeed(
                tonumber(values['fInitialDriveForce']),
                tonumber(values['fInitialDragCoeff']),
                numVal
            )
            display[k] = {
                value        = tostring(speed),
                unit         = 'KM/H SIM.',
                isDragLimited = isDrag,
                raw          = string.format('%.1f', numVal)
            }
        elseif k == 'fInitialDriveForce' then
            display[k] = { value = string.format('%.2f', numVal * 3.33), unit = 'G-FORCE' }
        elseif k == 'fMass' then
            display[k] = { value = string.format('%.0f', numVal), unit = 'KG' }
        elseif k == 'fBrakeForce' then
            display[k] = { value = string.format('%.2f', numVal), unit = 'DECEL' }
        elseif isStr or isVec then
            display[k] = { value = tostring(v) }
        elseif isInt then
            display[k] = { value = string.format('%d', math.floor(numVal)) }
        else
            display[k] = { value = string.format('%.3f', numVal) }
        end
    end

    return display
end

-- ============================================================
-- FORMULA: genera il blocco XML handling.meta completo
-- ============================================================
function GenerateHandlingXML(vehicleName, aiHandling, values, config)
    local lines = {}
    table.insert(lines, '<?xml version="1.0" encoding="UTF-8"?>')
    table.insert(lines, '')
    table.insert(lines, '<CHandlingDataMgr>')
    table.insert(lines, '  <HandlingData>')
    table.insert(lines, '    <Item type="CHandlingData">')

    for _, field in ipairs(FIELD_ORDER) do
        if field == 'handlingName' then
            table.insert(lines, string.format('      <handlingName>%s</handlingName>', vehicleName))
        elseif field == 'AIHandling' then
            table.insert(lines, string.format('      <AIHandling>%s</AIHandling>', aiHandling))
        else
            local cfg = config[field]
            local val = values[field]
            if cfg and val ~= nil then
                if cfg.type == 'vector' then
                    local parts = {}
                    for part in tostring(val):gmatch('%S+') do
                        table.insert(parts, part)
                    end
                    local x = string.format('%.6f', tonumber(parts[1] or 0))
                    local y = string.format('%.6f', tonumber(parts[2] or 0))
                    local z = string.format('%.6f', tonumber(parts[3] or 0))
                    table.insert(lines, string.format('      <%s x="%s" y="%s" z="%s" />', field, x, y, z))
                elseif cfg.type == 'string' then
                    table.insert(lines, string.format('      <%s>%s</%s>', field, tostring(val), field))
                elseif cfg.type == 'int' then
                    table.insert(lines, string.format('      <%s value="%d" />', field, math.floor(tonumber(val) or 0)))
                else
                    table.insert(lines, string.format('      <%s value="%.6f" />', field, tonumber(val) or 0.0))
                end
            end
        end
    end

    table.insert(lines, '      <SubHandlingData>')
    table.insert(lines, '        <Item type="CCarHandlingData">')
    table.insert(lines, '          <fBackEndPopUpCarImpulseMult value="0.100000" />')
    table.insert(lines, '          <fBackEndPopUpBuildingImpulseMult value="0.030000" />')
    table.insert(lines, '          <fBackEndPopUpMaxDeltaSpeed value="0.600000" />')
    table.insert(lines, '        </Item>')
    table.insert(lines, '        <Item type="NULL" />')
    table.insert(lines, '        <Item type="NULL" />')
    table.insert(lines, '      </SubHandlingData>')
    table.insert(lines, '    </Item>')
    table.insert(lines, '  </HandlingData>')
    table.insert(lines, '</CHandlingDataMgr>')

    return table.concat(lines, '\n')
end
