// -----------------------------------------------------------------------------
// 	Copyright (C) 2013-2014 TwinDrills, All Rights Reserved
// -----------------------------------------------------------------------------
using runtime.math;
using runtime.log;
using game.skills.skill_archetype;

public class Skill_Turret_Ammo_1 : Skill_Archetype
{
	Skill_Turret_Ammo_1()
	{
		Name 				= "#skill_turret_ammo_1_name";
		Description 		= "#skill_turret_ammo_1_description";
		Icon_Frame 			= "skill_turret_ammo_1";
		Cost 				= 1;
		Is_Passive		 	= true;
		Are_Children_Mutex 	= false;
		Parent_Name 		= "Skill_Heavy";
        Unlock_Criteria_Threshold = 0;
	}
	
	override void On_Recieve(Profile profile, Skill skill)
	{
		profile.Stat_Multipliers[Profile_Stat.Turret_Ammo] = 1.50;
	}
}
