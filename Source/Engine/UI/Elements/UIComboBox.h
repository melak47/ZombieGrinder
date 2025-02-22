// ===================================================================
//	Copyright (C) 2013 Tim Leonard
// ===================================================================
#ifndef _ENGINE_UI_ELEMENTS_UICOMBOBOX_
#define _ENGINE_UI_ELEMENTS_UICOMBOBOX_

#include "Engine/UI/UIElement.h"
#include "Engine/UI/UIFrame.h"
#include "Engine/Renderer/Text/Font.h"
#include "Engine/Renderer/Text/FontRenderer.h"
#include "Engine/Renderer/Text/MarkupFontRenderer.h"

#include "Engine/Renderer/Atlases/Atlas.h"
#include "Engine/Renderer/Atlases/AtlasRenderer.h"

#include "Engine/Renderer/PrimitiveRenderer.h"

#include "Engine/Input/OutputBindings.h"

class AtlasHandle;
class UIManager;
struct AtlasFrame;

struct UIComboBoxItem
{
	MEMORY_ALLOCATOR(UIComboBoxItem, "UI");

public:
	std::string Text;
	void*		MetaData1;
	int			MetaData2;
	int			MetaData3;
	int			MetaData4;
};

class UIComboBox : public UIElement 
{
	MEMORY_ALLOCATOR(UIComboBox, "UI");

protected:	
	friend class UILayout;

	AtlasHandle*				m_atlas;
	AtlasRenderer				m_atlas_renderer;
		
	FontHandle*					m_font;
	FontRenderer				m_font_renderer;
	MarkupFontRenderer			m_markup_font_renderer;

	UIFrame						m_background_frame;
	UIFrame						m_background_active_frame;

	AtlasFrame*					m_active_arrow_frame;
	AtlasFrame*					m_inactive_arrow_frame;

	Rect2D						m_left_arrow_box;
	Rect2D						m_right_arrow_box;

	Color						m_frame_color;

	std::vector<UIComboBoxItem>	m_items;
	int							m_selected_item_index;

	float						m_highleft_left_arrow_timer;
	float						m_highleft_right_arrow_timer;

	bool						m_game_style;
	bool						m_use_markup;

	enum
	{
		ARROW_HIGHLIGHT_DURATION = 200
	};

public:
	UIComboBox();
	~UIComboBox();

	void Refresh();
	void Refresh_Boxes(UIManager* manager);
	void After_Refresh();
	bool Is_Focusable();

	void Add_Item(UIComboBoxItem item);
	void Add_Item(const char* item, void* meta = NULL);
	void Clear_Items();
	const UIComboBoxItem& Get_Selected_Item();
	int Get_Selected_Item_Index();
	void Set_Selected_Item_Index(int index);
	const std::vector<UIComboBoxItem>& Get_Items();

	void Select_Item_By_MetaData(void* data);
	
	bool Focus_Left(UIManager* manager);
	bool Focus_Right(UIManager* manager);

	void Tick(const FrameTime& time, UIManager* manager, UIScene* scene);
	void Draw(const FrameTime& time, UIManager* manager, UIScene* scene);

};

#endif

