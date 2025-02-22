// -----------------------------------------------------------------------------
// 	Copyright (C) 2013-2014 TwinDrills, All Rights Reserved
// -----------------------------------------------------------------------------
using runtime.math;
using runtime.log;
using game.skills.skill_archetype;

public class Skill_Heal_3 : Skill_Archetype
{
	Skill_Heal_3()
	{
		Name 				= "#skill_heal_3_name";
		Description 		= "#skill_heal_3_description";
		Icon_Frame 			= "skill_heal_3";
		Cost 				= 3;
        Energy_Type         = Skill_Energy_Type.Enemy_Kills;
        Energy_Required     = 500;
		Is_Passive		 	= false;
		Are_Children_Mutex 	= false;
		Parent_Name 		= "Skill_Heal_2";
		Is_Team_Based		= false;
		Duration			= 3.0f;
		Player_Effect		= "heal_3s_player";
        Unlock_Criteria_Threshold = 17;
	}

	public override void Apply(NetUser user)
	{
		user.Skill_Stat_Multipliers[Profile_Stat.Health_Regen] = 1.0f / 3.0f;
	}
}
