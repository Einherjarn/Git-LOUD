local TAirUnit = import('/lua/defaultunits.lua').AirUnit

local TWeapons = import('/lua/terranweapons.lua')

local TAAGinsuRapidPulseWeapon = TWeapons.TAAGinsuRapidPulseWeapon
local TIFCruiseMissileLauncher = TWeapons.TIFCruiseMissileLauncher

SEA0212 = Class(TAirUnit) {
    Weapons = {
        AutoCannon = Class(TAAGinsuRapidPulseWeapon) {},
        Missile = Class(TIFCruiseMissileLauncher) {},
    },
}

TypeClass = SEA0212
