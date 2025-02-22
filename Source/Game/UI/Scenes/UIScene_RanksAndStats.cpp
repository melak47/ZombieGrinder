// ===================================================================
//	Copyright (C) 2013 Tim Leonard
// ===================================================================
#include "Game/UI/Scenes/UIScene_RanksAndStats.h"
#include "Engine/UI/Transitions/UISlideInTransition.h"
#include "Engine/UI/Transitions/UISlideInTopLevelTransition.h"
#include "Engine/UI/Layouts/UILayoutFactory.h"
#include "Engine/Platform/Platform.h"
#include "Engine/Display/GfxDisplay.h"
#include "Engine/Input/Input.h"
#include "Engine/UI/UIManager.h"
#include "Engine/UI/Elements/UIPanel.h"
#include "Engine/UI/Elements/UIProgressBar.h"
#include "Engine/UI/Elements/UILabel.h"
#include "Engine/UI/Elements/UISlider.h"
#include "Engine/UI/Elements/UICheckBox.h"
#include "Engine/UI/Elements/UIListView.h"
#include "Engine/UI/Elements/UIComboBox.h"
#include "Engine/Renderer/RenderPipeline.h"
#include "Engine/Resources/ResourceFactory.h"

#include "Engine/Audio/AudioRenderer.h"

#include "Engine/Localise/Locale.h"

#include "Game/UI/Scenes/UIScene_Game.h"

#include "Game/Online/RankingsManager.h"

#include "Game/Online/StatisticsManager.h"
#include "Engine/Online/OnlineAchievements.h"

#include "Game/Runner/Game.h"
#include "Engine/Engine/EngineOptions.h"
#include "Game/Runner/GameOptions.h"

#include "LibGeoIP/GeoIP.h"

//#define OPT_LEADERBOARD_CYCLE

bool RanksAndStats_Statistic_Category_Sort(Statistic* a, Statistic* b)
{
	return strcmp(b->category.c_str(), a->category.c_str()) < 0;
}

UIScene_RanksAndStats::UIScene_RanksAndStats()
	: m_current_board(NULL)
	, m_delegate_registered(false)
{
	Set_Layout("ranks_and_stats");

	m_get_item_delegate = new Delegate<UIScene_RanksAndStats, UIListViewGetItemData>(this, &UIScene_RanksAndStats::On_Get_Item_Data);

	UIListView* listview = Find_Element<UIListView*>("entry_listview");
	listview->Clear_Columns();
	listview->Add_Column("", 0.1f, false, true);
	listview->Add_Column(S("#menu_leaderboards_rank_column"), 0.15f, false);
	listview->Add_Column(S("#menu_leaderboards_name_column"), 0.45f, true, true);
	listview->Add_Column(S("#menu_leaderboards_score_column"), 0.30f, true);

	std::vector<Leaderboard*> boards = RankingsManager::Get()->Get_Leaderboards();
	UIComboBox* sourcebox = Find_Element<UIComboBox*>("source_box");

	sourcebox->Add_Item(S("#menu_statistics_local"), NULL);
	sourcebox->Add_Item(S("#menu_statistics_global"), NULL);

	for (std::vector<Leaderboard*>::iterator iter = boards.begin(); iter != boards.end(); iter++)
	{
		Leaderboard* board = *iter;
		if (!board->is_internal && board->name.find("< not set >") == std::string::npos)
		{
			sourcebox->Add_Item(board->name.c_str(), board);
		}
	}

	Refresh_Board();
}

const char* UIScene_RanksAndStats::Get_Name()
{
	return "UIScene_RanksAndStats";
}

bool UIScene_RanksAndStats::Should_Render_Lower_Scenes()
{
	return false;
}

bool UIScene_RanksAndStats::Should_Display_Cursor()
{
	return true;
}

bool UIScene_RanksAndStats::Is_Focusable()
{
	return true;
}

void UIScene_RanksAndStats::Refresh_Board()
{
	UIListView* listview = Find_Element<UIListView*>("entry_listview");
	listview->Set_Faked_Item_Count(refresh_range);
	listview->Set_Selected_Item_Index(0);

	UIComboBox* sourcebox = Find_Element<UIComboBox*>("source_box");
	//UICheckBox* filter = Find_Element<UICheckBox*>("filter_button");

	listview->Clear_Items();

	m_current_board = reinterpret_cast<Leaderboard*>(sourcebox->Get_Selected_Item().MetaData1);
	if (m_current_board != NULL)
	{
		listview->Get_Columns()[0].Text = "";
		listview->Get_Columns()[1].Text = S("#menu_leaderboards_rank_column");
		listview->Get_Columns()[2].Text = S("#menu_leaderboards_name_column");
		listview->Get_Columns()[3].Text = S("#menu_leaderboards_score_column");

		//m_friends_only = filter->Get_Checked();
		m_initial_seek = false;

		//DBG_LOG("Changed to board '%s' (%s)", m_current_board->name.c_str(), m_friends_only == true ? "Friends Only" : "Global");
		DBG_LOG("Changed to board '%s'.", m_current_board->name.c_str());

		RankingsManager* manager = RankingsManager::Get();
		manager->Clear_Board(m_current_board);
		manager->Get_Own_Entry(m_current_board);
	}
	else
	{
		listview->Set_Faked_Item_Count(-1);

		listview->Get_Columns()[0].Text = S("#menu_statistics_name_column");
		listview->Get_Columns()[1].Text = "";
		listview->Get_Columns()[2].Text = "";
		listview->Get_Columns()[3].Text = S("#menu_statistics_value_column");

		// Work out stat lists.
		StatisticsManager* stat_manager = StatisticsManager::Get();

		std::vector<Statistic*> stats = stat_manager->Get_Stats();
		std::sort(stats.begin(), stats.end(), RanksAndStats_Statistic_Category_Sort);

		std::string last_category = "";
		std::vector<std::string> values;

		bool display_global = (sourcebox->Get_Selected_Item_Index() == 1);

		for (std::vector<Statistic*>::iterator iter = stats.begin(); iter != stats.end(); iter++)
		{
			Statistic* current_stat = *iter;
			if (current_stat->display == true && (current_stat->aggregated == display_global))
			{
				if (last_category != current_stat->category)
				{
					// Add category values.
					values.clear();
					values.push_back(StringHelper::Format("[c=0,200,200,255]%s[/c]", S(current_stat->category)));
					values.push_back("");
					values.push_back("");
					values.push_back("");

					if (last_category != "")
					{
						listview->Add_Item("", NULL);
					}
					listview->Add_Item(values, NULL);

					last_category = current_stat->category;
				}

				// Add item values.
				values.clear();
				values.push_back(StringHelper::Format("    %s", S(current_stat->name)));
				values.push_back("");
				values.push_back("");

				if (display_global == true)
				{
					values.push_back(StringHelper::Format_Number(current_stat->aggregated_value));
				}
				else
				{
					values.push_back(StringHelper::Format_Number(current_stat->value));
				}

				listview->Add_Item(values, current_stat);
			}
		}
	}


	if (m_current_board != NULL)
	{
		if (!m_delegate_registered)
		{
			listview->On_Get_Item_Data += m_get_item_delegate;
			m_delegate_registered = true;
		}
	}
	else
	{
		if (m_delegate_registered)
		{
			listview->On_Get_Item_Data -= m_get_item_delegate;
			m_delegate_registered = false;
		}
	}
}

void UIScene_RanksAndStats::Enter(UIManager* manager)
{
}

void UIScene_RanksAndStats::Exit(UIManager* manager)
{
}

void UIScene_RanksAndStats::On_Get_Item_Data(UIListViewGetItemData* data)
{
	LeaderboardEntry* own_entry = RankingsManager::Get()->Get_Own_Entry(m_current_board);
	LeaderboardEntry* entry = RankingsManager::Get()->Get_Board_Entry(m_current_board, data->index + 1);
	data->item->Values.resize(4);

	if (m_current_board->total_entries == 0)
	{
		data->item->Values.at(0) = "";
		data->item->Values.at(1) = "";
		data->item->Values.at(2) = S("#menu_leaderboards_no_entries_text");
		data->item->Values.at(3) = "";
	}
	else if (entry->status == LeaderboardEntryStatus::Loaded)
	{
		const char* flag_id = GeoIP_code_by_id(entry->country);
		if (flag_id != NULL)
			data->item->Values.at(0) = StringHelper::Lowercase(StringHelper::Format("[img=flag_%s,0.6,0.6,0,1.5]", flag_id).c_str());
		else
			data->item->Values.at(0) = "";

		data->item->Values.at(1) = StringHelper::Format("%i", entry->rank);

		std::string name = MarkupFontRenderer::Escape(entry->name);

		if (entry->rank == own_entry->rank &&
			entry->name == own_entry->name)
		{
			data->item->Values.at(2) = StringHelper::Format("[c=0,200,200,255]%s[/c]", entry->name.c_str());
		}
		else
		{
			data->item->Values.at(2) = name;
		}

		data->item->Values.at(3) = StringHelper::Format_Number((float)entry->score);
	}
	else
	{
		data->item->Values.at(0) = "";
		data->item->Values.at(1) = "";
		data->item->Values.at(2) = S("#menu_leaderboards_loading_text");
		data->item->Values.at(3) = "";
	}
}

void UIScene_RanksAndStats::Tick(const FrameTime& time, UIManager* manager, int scene_index)
{
	UIListView* listview = Find_Element<UIListView*>("entry_listview");

	RankingsManager* rankings = RankingsManager::Get();

#ifdef OPT_LEADERBOARD_CYCLE
	UIComboBox* sourcebox = Find_Element<UIComboBox*>("source_box");

	static int counter = 0;
	static float timer = 0.0f;
	timer += time.Get_Delta_Seconds();
	if (timer >= 2.0f)
	{
		timer = 0.0f;
		sourcebox->Set_Selected_Item_Index((counter++) % (int)sourcebox->Get_Items().size());
		Refresh_Board();
	}
#endif

	if (m_current_board)
	{
		// Make sure we have our own entry before we try to refresh 
		// other entries.
		LeaderboardEntry* own_entry = rankings->Get_Own_Entry(m_current_board);
		if (own_entry != NULL && own_entry->status == LeaderboardEntryStatus::Loaded)
		{
			// Seek to our entry in the leaderboard.
			if (!m_initial_seek)
			{
				// No rank.
				if (own_entry->rank <= 0)
				{
					// Get the first rankings.
					rankings->Refresh_Entries(m_current_board, 1, refresh_range * 2, false);
				}
				else
				{
					// Zoom scroll so our rank is at the top.				
					listview->Set_Faked_Item_Count(own_entry->rank + (refresh_range * 2));
					listview->Set_Selected_Item_Index(own_entry->rank - 1);
					listview->Scroll_To(own_entry->rank - 1);

					// Get all the entries around our current one.
					rankings->Refresh_Entries(m_current_board, own_entry->rank, refresh_range * 2, false);
				}

				m_initial_seek = true;
			}

			// Refresh the areas we are viewing.
			else
			{
				// Work out range. If we have found the end then set range to 0-max otherwise set it to 0-total_downloaded + refresh_range
				int total_entries = m_current_board->total_entries;
				if (total_entries < 0)
				{
					total_entries = m_current_board->highest_entry + refresh_range;
				}
				listview->Set_Faked_Item_Count(Max(1, total_entries)); // We always need 1 entry to show the "no entries" text.

																	   // If unloaded ranks are in view, get loading!
				int scroll_position = listview->Get_Scroll_Offset();
				if (total_entries > 0)
				{
					int start_offset = -1;
					int end_offset = -1;

					for (int i = scroll_position + 1; i < (scroll_position + refresh_range) + 1; i++)
					{
						if (total_entries >= 0)
						{
							if (i >= total_entries)
							{
								break;
							}
						}

						LeaderboardEntry* entry = rankings->Get_Board_Entry(m_current_board, i);
						if (entry->status == LeaderboardEntryStatus::Unloaded)
						{
							if (start_offset == -1)
							{
								start_offset = i;
								end_offset = i;

								// Load future ones as well.
								if (end_offset == (scroll_position + refresh_range))
								{
									end_offset += refresh_range;
								}
							}
							else
							{
								end_offset = i;
							}

						}
					}

					if (start_offset >= 0 && !listview->Is_Scrolling())
					{
						DBG_LOG("Refreshing rankings entries %i-%i", start_offset, end_offset);
						rankings->Refresh_Entries(m_current_board, start_offset, (end_offset - start_offset) + 1, false);
					}
				}
			}
		}
	}

	UIScene::Tick(time, manager, scene_index);
}

void UIScene_RanksAndStats::Draw(const FrameTime& time, UIManager* manager, int scene_index)
{
	UIScene::Draw(time, manager, scene_index);
}

void UIScene_RanksAndStats::Recieve_Event(UIManager* manager, UIEvent e)
{
	switch (e.Type)
	{
	case UIEventType::ComboBox_SelectedIndexChanged:
	{
		if (e.Source->Get_Name() == "source_box")
		{
			Refresh_Board();
		}
		break;
	}
	case UIEventType::CheckBox_Click:
	{
		if (e.Source->Get_Name() == "filter_button")
		{
			Refresh_Board();
		}
		break;
	}
	case UIEventType::Button_Click:
	{
		if (e.Source->Get_Name() == "back_button")
		{
			manager->Go(UIAction::Pop(new UISlideInTopLevelTransition()));
		}
		break;
	}
	}
}
