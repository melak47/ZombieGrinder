 // -----------------------------------------------------------------------------
// 	Copyright (C) 2013-2014 TwinDrills, All Rights Reserved
// -----------------------------------------------------------------------------
using game.weapons.projectile_weapon;
using game.weapons.ammo.weapon_ammo_explosive;
using game.weapons.ammo.weapon_ammo_freeze;
using game.weapons.ammo.weapon_ammo_incendiary;

[
	Name("Weapon Shotgun"), 
	Description("Boomstick Time!") 
]
public class Weapon_Shotgun : Projectile_Weapon
{		
	Weapon_Shotgun()
	{
		Name = Locale.Get("#item_shotgun_name");

		Walk_Animation 	= "avatar_body_shotgun";
		Fire_Animation	= "avatar_body_shotgun_fire";

		Direction_Layers = { 
			1, 	// S
			1, 	// SE
			1, 	// E
			0, 	// NE
			0, 	// N
			0, 	// NW
			1, 	// W
			1 	// SW
		};

		Muzzle_Position = {
			Vec2(28, 63),		// S
			Vec2(40, 58),		// SE
			Vec2(47, 48),		// E
			Vec2(46, 37),		// NE
			Vec2(28, 40),		// N
			Vec2(16, 37),		// NW
			Vec2(17, 48),		// W
			Vec2(22, 58)		// SW
		};  
		
		Accepted_Ammo_Types = { 
			typeof(Weapon_Ammo_Explosive),
			typeof(Weapon_Ammo_Freeze),
			typeof(Weapon_Ammo_Incendiary)
		};  

		Slot					= Weapon_Slot.Shotgun;
		SubType					= Weapon_SubType.Small_Arms;
		Speed_Multiplier		= 1.0;

		Screenshake_Duration	= 0.5;
		Screenshake_Intensity	= 2;
		
		Clip_Size				= 8;
		Reserve_Size			= 48;
		Initial_Ammo			= 48;
		Reload_Duration			= 2.5;
		Has_Unlimited_Ammo	 	= false;
		Fire_Interval			= 0.450;			
		Fire_Ammo_Usage			= 1;
		Is_Rechargable			= false;
		Use_Individual_Reload	= true;

		Hear_Radius				= 128.0f;
		
		HUD_Icon				= "game_hud_weaponicon_shotgun";
		HUD_Ammo_Icon			= "game_hud_ammoicon_shotgun";
		
		Fire_Sound				= "sfx_objects_weapons_shotgun_fire";
		//Reload_Sound			= "sfx_objects_weapons_shotgun_reload";
		Reload_Individual_Sound	= "sfx_objects_weapons_shotgun_reload";
		Reload_Finish_Sound		= "sfx_objects_pickups_shotgun_pickup";
		Dry_Fire_Sound			= "sfx_objects_weapons_shotgun_dry_fire";
		
		AI_Priority				= 1.0f;

		Item_Type 				= Item_Archetype.Find_By_Type(typeof(Item_Shotgun));

		// Projectile specific settings.
		Muzzle_Effect			= "shotgun_fire";
		Is_Automatic			= false;
        
		Pickup_Sprite	= "actor_pickups_shotgun_0";
		Pickup_Name		= Locale.Get("#item_shotgun_name");
		Pickup_Sound	= "sfx_objects_pickups_shotgun_pickup";
	}
}
