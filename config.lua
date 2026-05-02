Config = {}

Config.Locale = 'it' -- en, it, es, fr, de, pt

Config.isAllowed = function(source) --server side. most frameworks already have this.
    -- if you know what you are doing, edit server/server.lua to change the permission.
    if IsPlayerAceAllowed(source, 'admin') or IsPlayerAceAllowed(source, 'command') then
        return true
    end
    return false
end

Config.Precision = 10000.0

Config.MenuToggle = {
    method = 'keybind', -- 'command' or 'keybind'
    command = 'handlingeditor', -- The command name (used for both chat and keybind)
    key = 'F11', -- Default key if method is 'keybind'
    description = 'Open Handling Editor' -- Description shown in FiveM keybind settings
}


Config.Values = {
    -- Physical
    fMass = {
        name = "Vehicle Mass",
        type = "float", 
        change = 100.0,
        min = 100.0,
        max = 5000.0,
        description = "Vehicle weight in kilograms. Affects collision physics."
    },
    fInitialDragCoeff = {
        name = "Drag Coefficient",
        type = "float",
        change = 1,
        min = 10.0,
        max = 120.0,
        description = "Aerodynamic drag coefficient. Higher values increase air resistance."
    },
    fPopUpLightRotation = {
        name = "Pop-up Light Rotation",
        type = "float",
        change = 1.0,
        min = 0.0,
        max = 90.0,
        description = "Angle of pop-up headlights when deployed"
    },
    fPercentSubmerged = {
        name = "Submersion Percentage",
        type = "float",
        change = 5.0,
        min = 0.0,
        max = 100.0,
        description = "Percentage of vehicle that must be submerged before sinking. Default is 85%."
    },
    vecCentreOfMassOffset = {
        name = "Centre of Mass Offset",
        type = "vector",
        change = 0.1,
        min = -2.0,
        max = 2.0,
        description = "Center of mass offset from vehicle origin",
        components = {
            x = {name = "X Offset", description = "Left/Right offset"},
            y = {name = "Y Offset", description = "Front/Back offset"},
            z = {name = "Z Offset", description = "Up/Down offset"}
        }
    },
    vecInertiaMultiplier = {
        name = "Inertia Multiplier",
        type = "vector", 
        change = 0.1,
        min = 0.0,
        max = 3.0,
        description = "Inertia multiplier for each axis",
        components = {
            x = {name = "X Multiplier", description = "Roll inertia"},
            y = {name = "Y Multiplier", description = "Pitch inertia"},
            z = {name = "Z Multiplier", description = "Yaw inertia"}
        }
    },
    fSeatOffsetDistX = {
        name = "Seat X Offset",
        type = "float",
        change = 0.1,
        min = -2.0,
        max = 2.0,
        description = "Driver seat left/right offset"
    },
    fSeatOffsetDistY = {
        name = "Seat Y Offset", 
        type = "float",
        change = 0.1,
        min = -2.0,
        max = 2.0,
        description = "Driver seat front/back offset"
    },
    fSeatOffsetDistZ = {
        name = "Seat Z Offset",
        type = "float",
        change = 0.1,
        min = -2.0,
        max = 2.0,
        description = "Driver seat up/down offset"
    },

    -- Transmission
    fDriveBiasFront = {
        name = "Drive Type",
        type = "float",
        change = 0.05,
        min = 0.0,
        max = 1.0,
        description = "Drive type: 0.0 = RWD, 1.0 = FWD, 0.5 = balanced 4WD"
    },
    nInitialDriveGears = {
        name = "Number of Gears",
        type = "int",
        change = 1,
        min = 1,
        max = 8,
        description = "Number of forward gears in the transmission"
    },
    fInitialDriveForce = {
        name = "Engine Power",
        type = "float",
        change = 0.1,
        min = 0.01,
        max = 2.0,
        description = "Engine power multiplier. Higher values increase acceleration."
    },
    fDriveInertia = {
        name = "Engine Rev Speed",
        type = "float",
        change = 1,
        min = 0.01,
        max = 2.0,
        description = "Engine rev speed. Higher values make engine reach redline faster."
    },
    fClutchChangeRateScaleUpShift = {
        name = "Upshift Speed",
        type = "float",
        change = 0.5,
        min = 0.1,
        max = 10.0,
        description = "Upshift speed multiplier. Higher values = faster shifts."
    },
    fClutchChangeRateScaleDownShift = {
        name = "Downshift Speed",
        type = "float",
        change = 0.5,
        min = 0.1,
        max = 10.0,
        description = "Downshift speed multiplier. Higher values = faster shifts."
    },
    fInitialDriveMaxFlatVel = {
        name = "Top Speed",
        type = "float",
        change = 5.0,
        min = 0.0,
        max = 500.0,
        description = "Top speed at redline in highest gear (multiply by 0.82 for MPH)"
    },
    
    -- Brakes
    fBrakeForce = {
        name = "Brake Power",
        type = "float",
        change = 0.2,
        min = 0.01,
        max = 2.0,
        description = "Brake power multiplier. Higher values increase braking force."
    },
    fBrakeBiasFront = {
        name = "Brake Balance",
        type = "float",
        change = 0.1,
        min = 0.0,
        max = 1.0,
        description = "Brake distribution: 0.0 = rear only, 1.0 = front only, 0.5 = balanced"
    },
    fHandBrakeForce = {
        name = "Handbrake Power",
        type = "float",
        change = 0.2,
        min = 0.0,
        max = 5.0,
        description = "Handbrake power multiplier. Higher values increase handbrake strength."
    },

    -- Steering
    fSteeringLock = {
        name = "Steering Angle",
        type = "float",
        change = 5.0,
        min = 10.0,
        max = 70.0,
        description = "Maximum steering angle. Higher values increase turn radius."
    },

    -- Traction
    fTractionCurveMax = {
        name = "Cornering Grip",
        type = "float",
        change = 0.1,
        min = 0.1,
        max = 4.0,
        description = "Maximum cornering grip multiplier"
    },
    fTractionCurveMin = {
        name = "Acceleration Grip",
        type = "float",
        change = 0.1,
        min = 0.1,
        max = 4.0,
        description = "Minimum acceleration/braking grip multiplier"
    },
    fTractionCurveLateral = {
        name = "Lateral Grip",
        type = "float",
        change = 1.0,
        min = 0.0,
        max = 4.0,
        description = "Lateral grip curve shape"
    },
    fTractionSpringDeltaMax = {
        name = "Traction Height Loss",
        type = "float",
        change = 0.01,
        min = 0.0,
        max = 0.3,
        description = "Height at which vehicle loses traction"
    },
    fLowSpeedTractionLossMult = {
        name = "Burnout Effect",
        type = "float",
        change = 0.1,
        min = 0.0,
        max = 2.0,
        description = "Low speed traction loss. Higher values increase burnout effect."
    },
    fCamberStiffnesss = {
        name = "Drift Control",
        type = "float",
        change = 0.01,
        min = -1.0,
        max = 1.0,
        description = "Drift grip modifier. Positive values maintain drift angle, negative values cause oversteer."
    },
    fTractionBiasFront = {
        name = "Traction Balance",
        type = "float",
        change = 0.01,
        min = 0.01,
        max = 0.99,
        description = "Traction distribution: 0.01 = rear bias, 0.99 = front bias, 0.5 = balanced"
    },
    fTractionLossMult = {
        name = "Surface Grip Loss",
        type = "float",
        change = 1.0,
        min = 0.0,
        max = 2.0,
        description = "Surface traction loss multiplier. Higher values reduce grip on all surfaces."
    },

    -- Suspension
    fSuspensionForce = {
        name = "Suspension Force",
        type = "float",
        change = 0.1,
        min = 0.0,
        max = 5.0,
        description = "Suspension spring force"
    },
    fSuspensionCompDamp = {
        name = "Compression Damping",
        type = "float",
        change = 0.1,
        min = 0.0,
        max = 5.0,
        description = "Suspension compression damping"
    },
    fSuspensionReboundDamp = {
        name = "Rebound Damping",
        type = "float",
        change = 0.1,
        min = 0.0,
        max = 5.0,
        description = "Suspension rebound damping"
    },
    fSuspensionUpperLimit = {
        name = "Upper Limit",
        type = "float",
        change = 0.01,
        min = 0.0,
        max = 0.5,
        description = "Suspension upper movement limit"
    },
    fSuspensionLowerLimit = {
        name = "Lower Limit",
        type = "float",
        change = 0.01,
        min = -0.5,
        max = 0.0,
        description = "Suspension lower movement limit"
    },
    fSuspensionRaise = {
        name = "Ride Height",
        type = "float",
        change = 0.01,
        min = -0.2,
        max = 0.2,
        description = "Vehicle ride height adjustment"
    },
    fSuspensionBiasFront = {
        name = "Suspension Balance",
        type = "float",
        change = 0.01,
        min = 0.0,
        max = 1.0,
        description = "Suspension force distribution"
    },
    fAntiRollBarForce = {
        name = "Anti-Roll Force",
        type = "float",
        change = 0.1,
        min = 0.0,
        max = 2.0,
        description = "Anti-roll bar force"
    },
    fAntiRollBarBiasFront = {
        name = "Anti-Roll Balance",
        type = "float",
        change = 0.01,
        min = 0.0,
        max = 1.0,
        description = "Anti-roll bar force distribution"
    },
    fRollCentreHeightFront = {
        name = "Front Roll Height",
        type = "float",
        change = 0.01,
        min = 0.0,
        max = 1.0,
        description = "Front roll center height"
    },
    fRollCentreHeightRear = {
        name = "Rear Roll Height",
        type = "float",
        change = 0.01,
        min = 0.0,
        max = 1.0,
        description = "Rear roll center height"
    },

    -- Damage
    fCollisionDamageMult = {
        name = "Collision Damage",
        type = "float",
        change = 1.0,
        min = 0.0,
        max = 2.0,
        description = "Collision damage multiplier"
    },
    fWeaponDamageMult = {
        name = "Weapon Damage",
        type = "float",
        change = 1.0,
        min = 0.0,
        max = 2.0,
        description = "Weapon damage multiplier"
    },
    fDeformationDamageMult = {
        name = "Visual Damage",
        type = "float",
        change = 1.0,
        min = 0.0,
        max = 2.0,
        description = "Visual damage deformation multiplier"
    },
    fEngineDamageMult = {
        name = "Engine Damage",
        type = "float",
        change = 1.0,
        min = 0.0,
        max = 2.0,
        description = "Engine damage multiplier"
    },

    -- Misc
    fPetrolTankVolume = {
        name = "Fuel Capacity",
        type = "float",
        change = 1.0,
        min = 0.0,
        max = 100.0,
        description = "Fuel tank capacity"
    },
    fOilVolume = {
        name = "Oil Capacity",
        type = "float",
        change = 1.0,
        min = 0.0,
        max = 10.0,
        description = "Engine oil capacity"
    },
    nMonetaryValue = {
        name = "Vehicle Value", 
        type = "int",
        change = 1.0,
        min = 0,
        max = 1000000,
        description = "Vehicle monetary value"
    },
    strModelFlags = {
        name = "Model Flags",
        type = "string",
        description = "Vehicle model flags"
    },
    strHandlingFlags = {
        name = "Handling Flags", 
        type = "string",
        description = "Vehicle handling flags"
    },
    strDamageFlags = {
        name = "Damage Flags",
        type = "string", 
        description = "Vehicle damage flags"
    }
}
