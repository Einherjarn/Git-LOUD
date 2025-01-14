-----------------------------------------------------------------------------
--  File     :  /projectiles/uheavygauss04/uheavygauss04_script.lua
--  Author(s):
--  Summary  :  SC2 UEF Heavy Gauss: UHeavyGauss04
--  Copyright � 2009 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------
UHeavyGauss04 = Class(import('/lua/sim/defaultprojectiles.lua').MultiPolyTrailProjectile)  {

	FxImpactTrajectoryAligned = true,
	FxTrails={
		'/effects/emitters/weapons/uef/heavygauss04/projectile/w_u_hvg04_p_01_glow_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/projectile/w_u_hvg04_p_04_wisps_emit.bp',
	},
	FxImpactProp = {
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_01_flatflash_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_02_glow_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_03_firecloud_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_04_firesmoke_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_05_firelines_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_06_smokegrit_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_09_sparks_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_10_debris_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_11_shockwave_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_12_blueshock_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_13_dirtlines_emit.bp',
	},
	FxImpactShield = {
		'/effects/emitters/weapons/uef/shield/impact/small/w_u_s_i_s_01_shrapnel_emit.bp',
		'/effects/emitters/weapons/uef/shield/impact/small/w_u_s_i_s_02_smoke_emit.bp',
		'/effects/emitters/weapons/uef/shield/impact/small/w_u_s_i_s_03_sparks_emit.bp',
		'/effects/emitters/weapons/uef/shield/impact/small/w_u_s_i_s_04_fire_emit.bp',
		'/effects/emitters/weapons/uef/shield/impact/small/w_u_s_i_s_05_firelines_emit.bp',
	},
	FxImpactLand = {
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_01_flatflash_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_02_glow_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_03_firecloud_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_04_firesmoke_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_05_firelines_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_06_smokegrit_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_09_sparks_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_10_debris_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_11_shockwave_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_12_blueshock_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_13_dirtlines_emit.bp',
	},
	FxImpactUnit = {
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_01_flatflash_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_02_glow_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_03_firecloud_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_04_firesmoke_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_05_firelines_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_06_smokegrit_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_09_sparks_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_10_debris_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_11_shockwave_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_12_blueshock_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/impact/unit/w_u_hvg04_i_u_13_dirtlines_emit.bp',
	},
	FxImpactWater = {
		'/effects/emitters/weapons/generic/water01/medium01/impact/w_g_wat01_m_i_01_flatflash_emit.bp',
		'/effects/emitters/weapons/generic/water01/medium01/impact/w_g_wat01_m_i_02_flatripple_emit.bp',
		'/effects/emitters/weapons/generic/water01/medium01/impact/w_g_wat01_m_i_03_shockwave_emit.bp',
		'/effects/emitters/weapons/generic/water01/medium01/impact/w_g_wat01_m_i_04_splash_emit.bp',
		'/effects/emitters/weapons/generic/water01/medium01/impact/w_g_wat01_m_i_05_firecore_emit.bp',
		'/effects/emitters/weapons/generic/water01/medium01/impact/w_g_wat01_m_i_06_waterspray_emit.bp',
		'/effects/emitters/weapons/generic/water01/medium01/impact/w_g_wat01_m_i_07_mist_emit.bp',
		'/effects/emitters/weapons/generic/water01/medium01/impact/w_g_wat01_m_i_08_leftover_emit.bp',
	},
	PolyTrails = {
		'/effects/emitters/weapons/uef/heavygauss04/projectile/w_u_hvg04_p_02_polytrail_emit.bp',
		'/effects/emitters/weapons/uef/heavygauss04/projectile/w_u_hvg04_p_03_polytrail_emit.bp',
	},
	PolyTrailOffset = {0,0},

    FxPropHitScale = 0.6,
    FxShieldHitScale = 0.6,
    FxLandHitScale = 0.6,
    FxUnitHitScale = 0.6,
    FxWaterHitScale = 0.6, 
}
TypeClass = UHeavyGauss04
