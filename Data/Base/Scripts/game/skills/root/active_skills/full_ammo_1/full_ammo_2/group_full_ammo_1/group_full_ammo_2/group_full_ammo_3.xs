// -----------------------------------------------------------------------------
// 	Copyright (C) 2013-2014 TwinDrills, All Rights Reserved
// -----------------------------------------------------------------------------
using runtime.math;
using runtime.log;
using game.skills.skill_archetype;

public class Skill_Group_Full_Ammo_3 : Skill_Archetype
{
	Skill_Group_Full_Ammo_3()
	{
		Name 				= "#skill_group_full_ammo_3_name";
		Description 		= "#skill_group_full_ammo_3_description";
		Icon_Frame 			= "skill_group_full_ammo_3";
		Cost 				= 5;
        Energy_Type         = Skill_Energy_Type.Enemy_Kills;
        Energy_Required     = 1000;
		Is_Passive		 	= false;
		Are_Children_Mutex 	= false;
		Parent_Name 		= "Skill_Group_Full_Ammo_2";
		Is_Team_Based		= true;
		Duration			= 0.0f;
		Player_Effect		= "full_ammo_0s_player";
        Unlock_Criteria_Threshold = 41;
	}

	public override void Apply(NetUser user)
	{
		user.Skill_Stat_Multipliers[Profile_Stat.Ammo_Regen] = 999.0f;
	}
}
