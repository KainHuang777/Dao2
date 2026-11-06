extends PanelContainer
## MAID-UI-2 presentation: reads the maid View, sends commands, owns no state or rewards.
signal portrait_requested(texture: Texture2D, owner: String)
signal memory_requested(texture: Texture2D, title: String, lines: Array)
signal chapter_requested(title: String, script: Dictionary)
signal action_requested(kind: String, payload: Dictionary)
const PORTRAIT := "res://assets/characters/qingheng/portrait.png"
const MEETING := "res://assets/characters/qingheng/first-meeting.png"
const OPENING := "冒昧叨擾。這一路只顧護著書，倒忘了替自己避雨……可容我借一角簷下，理好這幾頁？"
const REPLIES := ["那便叨擾了。等雨停，我再慢慢說給你聽。", "一路所見，還有幾件我不願忘的小事。你若有興趣，我們可慢慢翻。"]
const ART := {
	"qingheng": {"portrait": PORTRAIT, "meeting": MEETING},
	"nuomeizi": {"portrait": "res://assets/characters/nuomeizi/portrait-r2.png", "meeting": "res://assets/characters/nuomeizi/first-meeting-r2.png"},
	"danxia": {"portrait": "res://assets/characters/danxia/portrait-r2.png", "meeting": "res://assets/characters/danxia/first-meeting-r2.png"},
}
const STORIES := {
	"qingheng": {
		"role_note": "青藍書卷 · 洞府侍女",
		"quote": "「書可慢慢讀，\n眼前的風雨，先一起避過吧。」",
		"bio": "溫柔而有主見，習慣先理清眼前的事。她珍惜書頁，也記得與人許下的小小約定。",
		"tags": ["書卷", "細心", "溫柔有主見"],
		"closing": "一冊書，一枝筆。\n此後簷下燈明，便多了一個可以說話的人。",
		"seal": "書香",
		"scene": "雨過書未濕",
		"opening": OPENING,
		"replies": REPLIES,
		"choices": ["先進來避雨吧。", "書裡記著甚麼？"],
	},
	"nuomeizi": {
		"role_note": "墨紅劍影 · 洞府劍侍",
		"quote": "「劍要握穩，\n話也要說得明白。」",
		"bio": "爽朗而好勝，出劍時比誰都專注。她護人從不繞彎，笑起來卻像春日初晴。",
		"tags": ["劍術", "爽朗", "護短"],
		"closing": "一柄劍，一身短披。\n自雲海試劍之後，院裡便多了一陣清亮的劍鳴。",
		"seal": "劍心",
		"scene": "雲海試劍",
		"opening": "這片雲海最適合試劍。你若站穩了，我便把這一式慢些使給你看——先說好，輸了可不許賴。",
		"replies": ["那便請你慢些使，我看仔細。", "劍勢未收，雲海先起了風。你這一式，記住了。"],
		"choices": ["先請你露一手。", "這劍，是怎麼練成的？"],
	},
	"danxia": {
		"role_note": "藕紫丹心 · 洞府丹師",
		"quote": "「火候不到，\n急也無用。」",
		"bio": "沉穩從容，看火候也看人心。她話不多，卻總在該開口時說中要緊處。",
		"tags": ["丹道", "沉穩", "外冷內熱"],
		"closing": "一爐丹，一盞茶。\n丹房夜話之後，燈下便多了一道不疾不徐的身影。",
		"seal": "丹心",
		"scene": "丹房夜話",
		"opening": "丹爐的火不能急，人的話也不必急。坐罷——這爐丹還要一炷香，正好聽你說說來意。",
		"replies": ["那我便等這一爐丹，也等你的下文。", "火候到了，話也到了。今晚這一爐，算我陪你守的。"],
		"choices": ["這爐丹，煉的是甚麼？", "夜還長，慢慢說。"],
	},
}
const BOND_CG := {
	"qingheng": {
		"path": "res://assets/characters/qingheng/bond-lamplight-r1.png",
		"title": "前世燈火",
		"lines": ["燈火照著舊時的書案。她說，前世也曾這樣等一個人回來。", "這一世，她記得的不只是書頁，還有一盞不肯熄的燈。"],
	},
	"nuomeizi": {
		"path": "res://assets/characters/nuomeizi/bond-sword-rain-r1.png",
		"title": "劍鳴舊世",
		"lines": ["劍鳴穿過雨幕。她說，這一式在很久以前也曾在同一場雨裡響過。", "舊世未竟的劍，如今在她手中終於有了收勢。"],
	},
	"danxia": {
		"path": "res://assets/characters/danxia/bond-night-vigil-r1.png",
		"title": "丹心照夜",
		"lines": ["丹爐的火照著長夜。她說，前世也是這樣守著一爐未成的丹。", "這一夜，火候終於到了，人也終於等到。"],
	},
}
const BOND_SCRIPT := {
	"qingheng": {
		"qingheng_1": {
			"title": "一盞燈",
			"lines": [
				"她把燈芯挑亮一寸，屋裡的影子便退到牆角。",
				"「這盞燈是替晚歸的人留的。」她說，「你不必每次都趕在夜裡回來。」",
			],
			"choices": ["我會早些回來。", "留著燈也好，山路上看得見。"],
			"branches": [
				["她怔了怔，低頭笑了：「那我便少添些油，燈芯也剪短些。」"],
				["「嗯。」她把燈挪到窗邊，「這樣，從山道上抬頭就看得見了。」"],
			],
			"closing": "燈火不明不滅，恰好照見兩人的影子落在同一處。",
		},
		"qingheng_2": {
			"title": "宗門來信",
			"lines": [
				"宗門的來信壓在書案一角，封泥未拆。",
				"「信裡未必都是好事。」她把裁紙刀推到你手邊，「但總該有人陪你一起看。」",
			],
			"choices": ["那就一起拆。", "先擱著吧，今晚不談宗門。"],
			"branches": [
				["她點了點頭，指尖按住封泥：「拆壞了也不打緊，我再替你抄一份。」"],
				["她把信推進抽屜，動作很輕：「也好。茶還熱著，先喝茶。」"],
			],
			"closing": "燈下無言，信未拆，茶卻續了兩回。",
		},
		"qingheng_3": {
			"title": "前世燈火",
			"lines": [
				"燈火忽然晃了一下，像是有人從很遠的地方吹了口氣。",
				"「我夢見過這盞燈。」她盯著火苗，「夢裡我也這樣等過一個人。」",
			],
			"choices": ["那個人，等到了嗎？", "這一世，燈不會滅。"],
			"branches": [
				["她沉默了很久，才輕聲說：「記不清了。只記得燈一直亮著。」"],
				["她抬眼看你，眼裡映著火光：「你說的話，我記下了。」"],
			],
			"closing": "前世與今生的燈在同一張桌上亮著，誰也沒有先去吹熄它。",
		},
		"qingheng_4": {
			"title": "燈影同行",
			"lines": [
				"夜讀散了，她把燈台推到書案正中，火苗座椅般穩穩照著兩盞茶。",
				"「能同坐到深夜的燈影不多。」她合上書，「我想讓你算一個。」",
			],
			"choices": ["那就一直同坐。", "哪天燈滅了呢？"],
			"branches": [
				["她笑意淺淺：「那我便一直守著燈芯，讓這盞燈亮成習慣。」"],
				["「滅了我再點。」她把火剪放到你手邊，「往後，你也可以替我掌燈。」"],
			],
			"closing": "燈影與人影一路同行，書頁翻到何處，身邊都有一盞茶。",
		},
	},
	"nuomeizi": {
		"nuomeizi_1": {
			"title": "第一道劍痕",
			"lines": [
				"院中的木樁上多了一道新痕，深淺正好，一看就是反覆練過的。",
				"「第一道劍痕要留得直。」她把劍收回鞘裡，「歪了，之後每一劍都會跟著歪。」",
			],
			"choices": ["那這一道，夠直嗎？", "再試一次，我幫你看。"],
			"branches": [
				["她挑眉看了半晌，忽然笑出聲：「還行。至少沒丟我的臉。」"],
				["「好。」她把劍遞到你手裡，「站穩了，手別抖——我可不等人。」"],
			],
			"closing": "劍痕留在木上，劍鳴卻像是留在了兩個人的耳朵裡。",
		},
		"nuomeizi_2": {
			"title": "功法相印",
			"lines": [
				"她把兩卷功法並排攤開，墨色一新一舊，字跡卻隱隱相合。",
				"「同一路數。」她指尖敲了敲紙面，「你說，是巧合，還是本來就該遇上？」",
			],
			"choices": ["不是巧合。", "該不該遇上，得看往後。"],
			"branches": [
				["她愣了一下，隨即別過臉：「……說得這麼乾脆，倒讓我不知道怎麼接。」"],
				["「說得好。」她收起功法，「那往後，我就多看著你一點。」"],
			],
			"closing": "兩卷功法收在一處，邊角壓在同一枚鎮紙下。",
		},
		"nuomeizi_3": {
			"title": "劍鳴舊世",
			"lines": [
				"劍鳴穿過雨幕，聲音在舊世的某處也曾這樣響過。",
				"「這一式，我好像練過很多遍。」她收勢站定，「只是那時候，身邊沒有人看。」",
			],
			"choices": ["那我以後都在。", "這一次，劍勢收得漂亮。"],
			"branches": [
				["她握劍的手緊了緊，半晌才說：「記住你自己說的話。」"],
				["「當然。」她甩了甩劍上的雨水，嘴角壓不住，「我練了很久。」"],
			],
			"closing": "雨停時，劍尖最後一滴水落下，正落在兩人之間。",
		},
		"nuomeizi_4": {
			"title": "以劍為盟",
			"lines": [
				"她把佩劍橫在石桌中央，劍身映出並排站著的兩道影子。",
				"「劍前無虛誓。」她盯著劍身，「這一條道上的路，我要照劍誓算你一份。」",
			],
			"choices": ["這道誓，我接。", "比比看誰先走到下一城。"],
			"branches": [
				["「爽快。」她收劍入鞘，「那從今日起，你的道上有我這一劍開路。」"],
				["她眼睛一亮，轉身便走：「也行！輸的人替對方磨一個月的劍。」"],
			],
			"closing": "劍誓落定，雲海之上，兩條路從此並作一條。",
		},
	},
	"danxia": {
		"danxia_1": {
			"title": "爐火初溫",
			"lines": [
				"丹爐的火剛穩下來，藥香一層一層漫出來。",
				"「頭一爐不必求成。」她遞來一柄蒲扇，「先把火看住，比什麼都要緊。」",
			],
			"choices": ["我來看著火。", "若煉壞了呢？"],
			"branches": [
				["她側過身讓出爐前的位置：「記住這個火色，往後你便能自己判斷。」"],
				["「壞了就再起一爐。」她語氣平淡，「火候這回事，急不來，也省不得。」"],
			],
			"closing": "爐火溫著，兩個人的影子在丹房牆上輕輕晃動。",
		},
		"danxia_2": {
			"title": "靈獸銜丹",
			"lines": [
				"小靈獸銜著一枚丹藥，蹲在門檻上不肯進來。",
				"「它挑得很。」她放下藥碾，「肯銜來的，多半是成了的。」",
			],
			"choices": ["那這一枚，算成了？", "它倒是比你還先知道。"],
			"branches": [
				["她接過丹藥，就著光看了看：「成色尚可。賞它一粒糖豆罷。」"],
				["她難得彎了彎嘴角：「它鼻子靈。你若肯學，也能這麼靈。」"],
			],
			"closing": "靈獸把丹藥吐在掌心，尾巴一掃，藥香又濃了一分。",
		},
		"danxia_3": {
			"title": "丹心照夜",
			"lines": [
				"夜已深，丹爐的火卻比白日更穩。",
				"「這一爐，我守了很久。」她沒有回頭，「久到有時候會想，前世是不是也這樣守著。」",
			],
			"choices": ["那前世，有人陪你守嗎？", "這一夜，我陪你守。"],
			"branches": [
				["她搖了搖頭，聲音很輕：「記不得了。只記得火不能斷。」"],
				["她終於回頭看你，目光在火光裡軟了一瞬：「……嗯。那你坐近些。」"],
			],
			"closing": "爐火照著長夜，也照著兩個不肯先走的人。",
		},
		"danxia_4": {
			"title": "同守一爐",
			"lines": [
				"最後一爐九轉的丹，她破例在爐前多擺了一把蒲扇與一張矮凳。",
				"「丹爐的火不借人。」她卻把凳子往你身邊挪了挪，「但守夜的位置，可以多一個。」",
			],
			"choices": ["那我守下半夜。", "丹成之夜，記下時辰。"],
			"branches": [
				["「好。」她把丹方往你面前推了推，「換火便喚我，我就在簾子那邊。」"],
				["她提筆在丹方末頁記下今日火候：「往後翻到這一頁，都算同守。」"],
			],
			"closing": "爐火亮了一整夜，簾內簾外，成了同道守候的兩人。",
		},
	},
}
const MODES := ["person", "meeting", "work", "bond"]
const MAID_ORDER := ["qingheng", "nuomeizi", "danxia"]
const MAID_NAMES := {"qingheng": "青蘅", "nuomeizi": "糯美子", "danxia": "丹霞"}
const MAID_ROLES := {"qingheng": "侍女", "nuomeizi": "劍侍", "danxia": "丹師"}
const DUTY_KINDS := {"qingheng": "steward_stock", "nuomeizi": "oversee_build", "danxia": "restock_pills"}
const TARGET_DUTIES := ["steward_stock", "restock_pills"]
const DUTY_FIELDS := {"qingheng": "recipe_id", "nuomeizi": "building_id", "danxia": "pill_id"}
const OPTION_FIELDS := {"qingheng": "recipes", "nuomeizi": "buildings", "danxia": "pills"}
const DUTY_PLAIN := {"qingheng": "定量備料", "nuomeizi": "定量監造", "danxia": "定量煉丹"}
const REASONS := {
	"CHAPTER_CLAIMED": "已領取",
	"CHAPTER_LOCKED": "需先領前一章",
	"CHAPTER_REQUIREMENT": "尚未達成條件",
	"CHAPTER_UNKNOWN": "尚未開放",
	"MAID_REQUIREMENT": "條件尚未足",
	"ALCHEMY_LOCKED": "丹道未開",
	"ALREADY_RECRUITED": "已在洞府",
	"UNKNOWN_MAID": "尚未可招募",
	"DUTY_BUSY": "產線暫時忙碌",
	"DUTY_NONE": "尚未指派",
}
const RECRUIT_TEXTS := {
	"qingheng": {"MAID_REQUIREMENT": "先建成茅屋，青蘅便會進府。"},
	"nuomeizi": {"MAID_REQUIREMENT": "青蘅羈絆達相知、境界築基後，糯美子方可入府。"},
	"danxia": {"MAID_REQUIREMENT": "青蘅羈絆達相知、境界築基後，丹霞方可入府。", "ALCHEMY_LOCKED": "丹道尚未解鎖，丹霞無法開爐。"},
}
const GREETINGS := {
	"qingheng": [
		"書還在讀，茶先替您備好了。",
		"您來了，案上的燈我留到現在。",
		"這次的帳目我核過了，您放心。",
		"路還長，我把燈芯又留長了一寸。",
	],
	"nuomeizi": [
		"喚我？練劍的空檔都留給你。",
		"站住別動——哎，是你。",
		"今天手感好，你說去哪我就去哪。",
		"你走路的聲音我聽得出來，一起走。",
	],
	"danxia": [
		"……坐。火要一炷香，誰的話都可以等。",
		"新茶在壺裡，趁火還穩著。",
		"今天的丹色很好，值得多看一眼。",
		"夜長，爐穩，你來了正好。",
	],
}
const DUTY_GREETINGS := {
	"qingheng": [
		"庫房在核，您先忙別的。",
		"帳目在走，成品快到目標了。",
		"產線順著呢，今晚只須翻帳。",
		"有我看著這本帳，您去歇著。",
	],
	"nuomeizi": [
		"工程在盯，練劍回頭再說。",
		"監工交給我，進度不會偏。",
		"工地我看了三遍，你儘管去。",
		"工在進，劍在鞘，路我倆同看。",
	],
	"danxia": [
		"爐交我看，缺料我會說。",
		"丹爐排程在走，火候不必盯。",
		"成色上手便知，你不用陪夜。",
		"兩盞守夜，爐火從沒這般安穩。",
	],
}
const REUNION_LINES := {
	"qingheng": "久別重逢。燈未滅，書也未收，就等你回來一敘。",
	"nuomeizi": "回來啦！劍都快替你磨好了。舊路再走一輪？",
	"danxia": "……火還溫著。回來得正好，陪我守完這一爐。",
}
const VOICE_LINES := {
	"recruit_maid": {
		"qingheng": "已入府。案上那盞燈，替您亮著。",
		"nuomeizi": "入府了！劍在鞘，您說走哪。",
		"danxia": "入府了。爐在溫著，不急。",
	},
	"assign_maid_duty": {
		"qingheng": "職掌已指派，帳目我來按時核。",
		"nuomeizi": "監工我領了，進度不會偏離。",
		"danxia": "煉丹交付我，火候看我的。",
	},
	"clear_maid_duty": {
		"qingheng": "帳先擱下，您想慢慢安排也好。",
		"nuomeizi": "劍收回鞘，事由你做主。",
		"danxia": "爐封停了，料都留著。",
	},
	"set_maid_duty_paused": {
		"qingheng": "節奏放緩了，隨時可以續。",
		"nuomeizi": "劍令暫止或再啟，一聲令下。",
		"danxia": "爐火守著不熄，暫緩也無妨。",
	},
	"execute_maid_duty": {
		"qingheng": "這趟做完，帳上又添一筆。",
		"nuomeizi": "跑完一場，落點乾淨。",
		"danxia": "出爐了。成色你看過再說。",
	},
	"claim_maid_chapter": {
		"qingheng": "這一段，我也記在心上。",
		"nuomeizi": "又多一條我們共同的路。",
		"danxia": "篇章歸檔，火候不辜負人。",
	},
	"maid_reunion": {
		"qingheng": "回來就好，燈與帳都在。",
		"nuomeizi": "一天不見，劍都替你亮了。",
		"danxia": "重逢不必多話，茶替我說。",
	},
}
var mode := "person"
var selected_maid := "qingheng"
var selected_reply := -1
var column: VBoxContainer
var content: VBoxContainer
var _right_stage: Control
var section_body: HBoxContainer
var section_scroll: ScrollContainer
var _left_rail: VBoxContainer
var left_nav_host: VBoxContainer
var _nav_sep: HSeparator
var left_entry_host: VBoxContainer
var close_host: HBoxContainer
var _overlay_layer: Control
var section_tabs: VBoxContainer
var embedded := false
var person: HBoxContainer
var portrait_frame: PanelContainer
var portrait_button: Button
var portrait_image: TextureRect
var portrait_placeholder: Label
var name_column: BoxContainer
var role_label: Label
var name_label: Label
var seal: Label
var copy_scroll: ScrollContainer
var copy_box: VBoxContainer
var bookmark: PanelContainer
var bio_placeholder: Label
var bio_role_label: Label
var bio_quote_label: Label
var bio_text_label: Label
var bio_tags_label: Label
var bio_closing_label: Label
var greeting_label: Label
var meeting: BoxContainer
var meeting_image: TextureRect
var missing_meeting: Label
var dialogue: BoxContainer
var reading: VBoxContainer
var speaker: Label
var line_scroll: ScrollContainer
var line: Label
var choices: BoxContainer
var choice_buttons: Array = []
var replay: Button
var work: ScrollContainer
var work_box: VBoxContainer
var work_heading: Label
var work_fields: BoxContainer
var work_status: Label
var work_owner: Label
var duty_picker: OptionButton
var duty_target: SpinBox
var preset_row: BoxContainer
var preset_buttons: Array = []
var reserve_row: BoxContainer
var reserve_heading: Label
var reserve_entries: Array = []
var reserve_spins: Dictionary = {}
var _reserve_signature := ""
var duty_hint: Label
var action_row: BoxContainer
var assign_button: InscriptionAction
var pause_button: InscriptionAction
var execute_button: InscriptionAction
var clear_button: InscriptionAction
var bond: ScrollContainer
var bond_box: VBoxContainer
var bond_heading: Label
var bond_status: Label
var bond_next: Label
var chapter_box: VBoxContainer
var chapter_rows: Array = []
var reunion_box: BoxContainer
var reunion_label: Label
var reunion_button: InscriptionAction
var recruit_box: BoxContainer
var recruit_label: Label
var recruit_button: InscriptionAction
var feedback: Label
var bond_feedback: Label
var tabs: Dictionary = {}
var maid_row: BoxContainer
var maid_buttons: Dictionary = {}
var title: Label
var _maid_view: Dictionary = {}
var _duty_ids: Array[String] = []
var _duty_choice := ""
var _option_signature := ""
var _last_duty_target := -1
var _portrait_id := "qingheng"
var _meeting_id := ""
var _compact := false
var _bounds := Rect2()

class BookmarkPaper extends StyleBox:
	var bg_color := Color("ebe8d9")
	var border_color := Color("657f79")
	func _init() -> void:
		content_margin_left = 24
		content_margin_right = 24
		content_margin_top = 18
		content_margin_bottom = 32
	func _draw(canvas_item: RID, rect: Rect2) -> void:
		var points := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.get_center().x, rect.end.y - 16), Vector2(rect.position.x, rect.end.y)])
		RenderingServer.canvas_item_add_polygon(canvas_item, points, PackedColorArray([bg_color]))
		RenderingServer.canvas_item_add_line(canvas_item, rect.position, Vector2(rect.end.x, rect.position.y), border_color, 3, true)

func _ready() -> void:
	theme = UiTypography.create_theme()
	add_theme_stylebox_override("panel", UiMaterial.hud_paper())
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	section_body = HBoxContainer.new()
	section_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	section_body.add_theme_constant_override("separation", 14)
	column.add_child(section_body)
	section_scroll = ScrollContainer.new()
	section_scroll.name = "CharacterLeftRail"
	section_scroll.custom_minimum_size.x = 168
	section_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	section_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	section_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	section_scroll.follow_focus = true
	section_body.add_child(section_scroll)
	_left_rail = VBoxContainer.new()
	_left_rail.name = "CharacterLeftRailBox"
	_left_rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_rail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_left_rail.add_theme_constant_override("separation", 8)
	section_scroll.add_child(_left_rail)
	left_nav_host = VBoxContainer.new()
	left_nav_host.name = "LeftNavHost"
	left_nav_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_nav_host.add_theme_constant_override("separation", 4)
	_left_rail.add_child(left_nav_host)
	_nav_sep = HSeparator.new()
	_nav_sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_left_rail.add_child(_nav_sep)
	title = _label("侍女 · 青蘅", 18)
	title.add_theme_font_override("font", UiTypography.emphasis_font())
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_rail.add_child(title)
	maid_row = BoxContainer.new()
	maid_row.vertical = true
	maid_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	maid_row.add_theme_constant_override("separation", 4)
	_left_rail.add_child(maid_row)
	for id in MAID_ORDER:
		var selector := GameTab.new()
		selector.secondary = true
		selector.text = String(MAID_NAMES.get(id, id))
		selector.focus_mode = Control.FOCUS_ALL
		selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		selector.custom_minimum_size.y = 44
		selector.pressed.connect(select_maid.bind(id))
		maid_row.add_child(selector)
		maid_buttons[id] = selector
	var sub_sep := HSeparator.new()
	sub_sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_left_rail.add_child(sub_sep)
	section_tabs = VBoxContainer.new()
	section_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_tabs.add_theme_constant_override("separation", 6)
	_left_rail.add_child(section_tabs)
	for entry in [["person", "人物", "人物介紹"], ["meeting", "初遇", "初遇重溫"], ["work", "職掌", "職掌"], ["bond", "羈絆", "羈絆"]]:
		var button := ArrowBookmarkTab.new()
		button.text = entry[1]
		button.tooltip_text = entry[2]
		button.accessibility_name = entry[2]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(show_mode.bind(entry[0]))
		section_tabs.add_child(button)
		tabs[entry[0]] = button
	var rail_spacer := Control.new()
	rail_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_left_rail.add_child(rail_spacer)
	left_entry_host = VBoxContainer.new()
	left_entry_host.name = "LeftEntryHost"
	left_entry_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_entry_host.add_theme_constant_override("separation", 6)
	_left_rail.add_child(left_entry_host)
	var split_sep := VSeparator.new()
	split_sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	section_body.add_child(split_sep)
	content = VBoxContainer.new()
	content.name = "CharacterRightStage"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	section_body.add_child(content)
	_right_stage = content
	_overlay_layer = Control.new()
	_overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay_layer)
	close_host = HBoxContainer.new()
	close_host.name = "CloseHost"
	close_host.alignment = BoxContainer.ALIGNMENT_END
	close_host.z_index = 20
	_overlay_layer.add_child(close_host)
	person = HBoxContainer.new()
	person.size_flags_vertical = Control.SIZE_EXPAND_FILL
	person.add_theme_constant_override("separation", 24)
	content.add_child(person)
	portrait_frame = PanelContainer.new()
	portrait_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_frame.size_flags_stretch_ratio = 1.3
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("e4e9df")
	frame.border_color = Color("9ca99b")
	frame.set_border_width_all(1)
	frame.set_content_margin_all(12)
	portrait_frame.add_theme_stylebox_override("panel", frame)
	person.add_child(portrait_frame)
	var stage := HBoxContainer.new()
	portrait_frame.add_child(stage)
	name_column = BoxContainer.new()
	name_column.vertical = true
	name_column.custom_minimum_size.x = 72
	name_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stage.add_child(name_column)
	role_label = _label("侍\n女", 24, true)
	name_label = _label("青\n蘅", 60, true)
	seal = _label("書香", 18, true)
	seal.add_theme_color_override("font_color", Color("914d42"))
	for label in [role_label, name_label, seal]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_column.add_child(label)
	portrait_button = Button.new()
	portrait_button.name = "FullPortrait"
	portrait_button.tooltip_text = "查看完整立繪"
	portrait_button.accessibility_name = "查看青蘅完整立繪"
	portrait_button.custom_minimum_size = Vector2(44, 44)
	portrait_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed"]:
		portrait_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	stage.add_child(portrait_button)
	portrait_image = _image(PORTRAIT)
	portrait_button.add_child(portrait_image)
	portrait_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_button.pressed.connect(open_art)
	portrait_placeholder = _label("立繪待 Codex 補完", 18)
	portrait_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait_placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_child(portrait_placeholder)
	copy_scroll = _scroll()
	copy_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	person.add_child(copy_scroll)
	copy_box = VBoxContainer.new()
	copy_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy_box.add_theme_constant_override("separation", 18)
	copy_scroll.add_child(copy_box)
	bookmark = PanelContainer.new()
	bookmark.add_theme_stylebox_override("panel", BookmarkPaper.new())
	copy_box.add_child(bookmark)
	greeting_label = _label("", 18)
	copy_box.add_child(greeting_label)
	var bio := VBoxContainer.new()
	bio.add_theme_constant_override("separation", 14)
	bookmark.add_child(bio)
	bio.add_child(_label("人物小傳", 20, true))
	bio_role_label = _label("青藍書卷 · 洞府侍女", 18)
	bio.add_child(bio_role_label)
	bio_quote_label = _label("「書可慢慢讀，\n眼前的風雨，先一起避過吧。」", 22)
	bio.add_child(bio_quote_label)
	bio_text_label = _label("溫柔而有主見，習慣先理清眼前的事。她珍惜書頁，也記得與人許下的小小約定。", 18)
	bio.add_child(bio_text_label)
	bio_tags_label = _label("書卷　·　細心　·　溫柔有主見", 18)
	bio.add_child(bio_tags_label)
	bio_closing_label = _label("一冊書，一枝筆。\n此後簷下燈明，便多了一個可以說話的人。", 18)
	copy_box.add_child(bio_closing_label)
	bio_placeholder = _label("人物小傳待 Codex 補完。", 18)
	copy_box.add_child(bio_placeholder)
	meeting = BoxContainer.new()
	meeting.vertical = true
	meeting.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meeting.add_theme_constant_override("separation", 14)
	content.add_child(meeting)
	meeting_image = _image("")
	meeting_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meeting_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meeting.add_child(meeting_image)
	missing_meeting = _label("初遇 CG 待 Codex 補完", 18)
	missing_meeting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	missing_meeting.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	missing_meeting.size_flags_vertical = Control.SIZE_EXPAND_FILL
	missing_meeting.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meeting.add_child(missing_meeting)
	dialogue = BoxContainer.new()
	dialogue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meeting.add_child(dialogue)
	reading = VBoxContainer.new()
	reading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reading.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue.add_child(reading)
	speaker = _label("青蘅 · 雨過書未濕", 20)
	reading.add_child(speaker)
	line_scroll = _scroll()
	line_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reading.add_child(line_scroll)
	line = _label(OPENING, 18)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_scroll.add_child(line)
	var responses := VBoxContainer.new()
	dialogue.add_child(responses)
	choices = BoxContainer.new()
	choices.vertical = true
	responses.add_child(choices)
	var choice_labels := _choice_labels()
	for index in REPLIES.size():
		var choice := InscriptionAction.new()
		choice.text = String(choice_labels[index]) if index < choice_labels.size() else ""
		choice.add_theme_font_size_override("font_size", 18)
		choice.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		choice.pressed.connect(reply.bind(index))
		choices.add_child(choice)
		choice_buttons.append(choice)
	replay = InscriptionAction.new()
	replay.text = "重新相遇"
	replay.add_theme_font_size_override("font_size", 18)
	replay.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	replay.pressed.connect(restart_meeting)
	responses.add_child(replay)
	work = _page("work")
	work_box = VBoxContainer.new()
	work_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	work_box.add_theme_constant_override("separation", 10)
	work.add_child(work_box)
	work_heading = _head("職掌")
	work_box.add_child(work_heading)
	work_status = _label("尚未取得仙侍狀態。", 18)
	work_status.add_theme_font_override("font", UiTypography.emphasis_font())
	work_box.add_child(work_status)
	work_owner = _label("目前沒有生效中的職掌。", 18)
	work_box.add_child(work_owner)
	work_fields = BoxContainer.new()
	work_fields.add_theme_constant_override("separation", 8)
	work_box.add_child(work_fields)
	duty_picker = OptionButton.new()
	duty_picker.custom_minimum_size = Vector2(220, 44)
	duty_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	duty_picker.item_selected.connect(_on_option_selected)
	duty_picker.add_theme_font_override("font", UiTypography.body_font())
	duty_picker.add_theme_font_size_override("font_size", 16)
	duty_picker.get_popup().add_theme_font_override("font", UiTypography.body_font())
	duty_picker.get_popup().add_theme_font_size_override("font_size", 16)
	duty_picker.get_popup().add_theme_constant_override("v_separation", 28)
	work_fields.add_child(duty_picker)
	duty_target = SpinBox.new()
	duty_target.min_value = 1
	duty_target.max_value = 999
	duty_target.step = 1
	duty_target.value = 1
	duty_target.prefix = "目標 "
	duty_target.suffix = " 個"
	duty_target.custom_minimum_size.y = 44
	duty_target.value_changed.connect(func(_value: float): _refresh_preview())
	work_fields.add_child(duty_target)
	preset_row = BoxContainer.new()
	preset_row.add_theme_constant_override("separation", 8)
	work_box.add_child(preset_row)
	for preset in MaidRules.duty_presets("steward_stock"):
		var preset_button := _action(preset_row, "%s %d" % [String(preset.get("name", "")), int(preset.get("target", 1))], _apply_preset.bind(preset))
		preset_button.add_theme_font_size_override("font_size", 16)
		preset_button.tooltip_text = "目標 %d・各材料保留 %d%%" % [int(preset.get("target", 1)), int(roundf(float(preset.get("reserve_ratio", 0.0)) * 100.0))]
		preset_buttons.append(preset_button)
	reserve_row = BoxContainer.new()
	reserve_row.add_theme_constant_override("separation", 8)
	work_box.add_child(reserve_row)
	reserve_heading = _label("保留量", 18)
	reserve_row.add_child(reserve_heading)
	duty_hint = _label("尚無可用目標", 18)
	work_box.add_child(duty_hint)
	action_row = BoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	work_box.add_child(action_row)
	assign_button = _action(action_row, "指派", _assign)
	pause_button = _action(action_row, "暫停", _toggle_pause)
	execute_button = _action(action_row, "立即執行", _execute)
	clear_button = _action(action_row, "清除", _clear)
	feedback = _label("", 18)
	feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	work_box.add_child(feedback)
	bond = _page("bond")
	bond_box = VBoxContainer.new()
	bond_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bond_box.add_theme_constant_override("separation", 10)
	bond.add_child(bond_box)
	bond_heading = _head("羈絆")
	bond_box.add_child(bond_heading)
	bond_status = _label("初識　0 點", 18)
	bond_status.add_theme_font_override("font", UiTypography.emphasis_font())
	bond_box.add_child(bond_status)
	bond_next = _label("尚無下一階段。", 18)
	bond_box.add_child(bond_next)
	chapter_box = VBoxContainer.new()
	chapter_box.add_theme_constant_override("separation", 6)
	bond_box.add_child(chapter_box)
	for index in 4:
		var row := BoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var info := _label("", 18)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var claim := _action(row, "領取", _claim.bind(index))
		var replay := _action(row, "重溫", _replay_chapter.bind(index))
		replay.tooltip_text = "重溫此章羈絆對話"
		replay.visible = false
		var memory := _action(row, "回憶", _memory.bind(index))
		memory.tooltip_text = "重溫此章羈絆 CG"
		memory.visible = false
		chapter_box.add_child(row)
		chapter_rows.append({"row": row, "info": info, "claim": claim, "replay": replay, "memory": memory, "id": ""})
	reunion_box = BoxContainer.new()
	reunion_box.add_theme_constant_override("separation", 8)
	bond_box.add_child(reunion_box)
	reunion_label = _label(_reunion_text(), 18)
	reunion_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reunion_box.add_child(reunion_label)
	reunion_button = _action(reunion_box, "重逢", _reunion)
	recruit_box = BoxContainer.new()
	recruit_box.add_theme_constant_override("separation", 8)
	bond_box.add_child(recruit_box)
	recruit_label = _label("尚未招募。", 18)
	recruit_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recruit_box.add_child(recruit_label)
	recruit_button = _action(recruit_box, "招募", _recruit)
	bond_feedback = _label("", 18)
	bond_feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bond_box.add_child(bond_feedback)
	minimum_size_changed.connect(func(): _fit_bounds.call_deferred())
	_sync_view()
	show_mode("person")

func _label(value: String, font_size: int, decorative: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", UiMaterial.INK)
	if decorative: label.add_theme_font_override("font", UiTypography.character_title_font())
	if decorative: label.autowrap_mode = TextServer.AUTOWRAP_OFF
	return label

func _head(value: String) -> Label:
	var label := _label(value, 20)
	label.add_theme_font_override("font", UiTypography.emphasis_font())
	return label

func _page(key: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = key
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	return scroll

func _action(parent: BoxContainer, value: String, handler: Callable) -> InscriptionAction:
	var button := InscriptionAction.new()
	button.text = value
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(handler)
	parent.add_child(button)
	return button

func _scroll() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return scroll

func _image(path: String) -> TextureRect:
	var image := TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not path.is_empty(): image.texture = load(path)
	return image

func show_mode(value: String) -> void:
	if value not in MODES: return
	if mode != value: _clear_feedback()
	mode = value
	if mode == "meeting" and _has_art(): _load_meeting()
	_sync()

func select_maid(value: String) -> void:
	if value not in MAID_ORDER or value == selected_maid: return
	selected_maid = value
	_duty_choice = ""
	_option_signature = ""
	_last_duty_target = -1
	_clear_reserve_rows()
	selected_reply = -1
	_clear_feedback()
	if line != null: line.text = _opening()
	_sync_view()

func refresh(view: Dictionary) -> void:
	_maid_view = _as_dict(view.get("maid", {}))
	if column == null: return
	_sync_view()

func show_result(text: String) -> void:
	if feedback == null: return
	feedback.text = text
	feedback.tooltip_text = text
	bond_feedback.text = text
	bond_feedback.tooltip_text = text
	_sync()

func _clear_feedback() -> void:
	if feedback == null: return
	feedback.text = ""
	feedback.tooltip_text = ""
	bond_feedback.text = ""
	bond_feedback.tooltip_text = ""

func open_art() -> void:
	if not _has_art() or portrait_image.texture == null: return
	portrait_requested.emit(portrait_image.texture, _maid_name(_maid_entry()))

func back() -> bool:
	if mode == "person": return false
	show_mode("person")
	tabs.person.grab_focus()
	return true

func reply(index: int) -> void:
	var replies := _replies()
	if index < 0 or index >= replies.size(): return
	selected_reply = index
	line.text = String(replies[index])
	line_scroll.scroll_vertical = 0
	_sync()
	replay.grab_focus()

func restart_meeting() -> void:
	selected_reply = -1
	line.text = _opening()
	line_scroll.scroll_vertical = 0
	_sync()
	choices.get_child(0).grab_focus()

func play_first_meeting(maid_id: String) -> void:
	if maid_id not in MAID_ORDER: return
	if maid_id != selected_maid: select_maid(maid_id)
	selected_reply = -1
	line.text = _opening()
	line_scroll.scroll_vertical = 0
	show_mode("meeting")
	if choices.get_child_count() > 0: choices.get_child(0).grab_focus()

func _as_dict(raw: Variant) -> Dictionary:
	if raw is Dictionary:
		return raw
	return {}

func _as_array(raw: Variant) -> Array:
	if raw is Array:
		return raw
	return []

func _maid_entry() -> Dictionary:
	var maids := _as_dict(_maid_view.get("maids", {}))
	return _as_dict(maids.get(selected_maid, {}))

func _maid_name(entry: Dictionary) -> String:
	var value := String(entry.get("name", ""))
	if not value.is_empty(): return value
	return String(MAID_NAMES.get(selected_maid, selected_maid))

func _maid_role(entry: Dictionary) -> String:
	var value := String(entry.get("role", ""))
	if value.is_empty(): return String(MAID_ROLES.get(selected_maid, "侍女"))
	if value.length() > 2: return value.right(2)
	return value

func _story() -> Dictionary:
	return _as_dict(STORIES.get(selected_maid, STORIES.get("qingheng", {})))

func _art() -> Dictionary:
	return _as_dict(ART.get(selected_maid, {}))

func _art_path(key: String) -> String:
	return String(_art().get(key, ""))

func _choice_labels() -> Array:
	return _as_array(_story().get("choices", []))

func _replies() -> Array:
	return _as_array(_story().get("replies", REPLIES))

func _opening() -> String:
	return String(_story().get("opening", OPENING))

func _has_art() -> bool:
	var entry := _maid_entry()
	if entry.is_empty(): return ART.has(selected_maid)
	return bool(entry.get("art_ready", ART.has(selected_maid)))

func _load_portrait() -> void:
	if _portrait_id == selected_maid: return
	_portrait_id = selected_maid
	var path := _art_path("portrait")
	portrait_image.texture = load(path) if not path.is_empty() else null

func _load_meeting() -> void:
	_meeting_id = selected_maid
	var path := _art_path("meeting")
	meeting_image.texture = load(path) if not path.is_empty() else null

func _sync_story(entry: Dictionary) -> void:
	var story := _story()
	bio_role_label.text = String(story.get("role_note", ""))
	bio_quote_label.text = String(story.get("quote", ""))
	bio_text_label.text = String(story.get("bio", ""))
	var tags := PackedStringArray()
	for tag in _as_array(story.get("tags", [])):
		tags.append(String(tag))
	bio_tags_label.text = "　·　".join(tags)
	bio_closing_label.text = String(story.get("closing", ""))
	seal.text = String(story.get("seal", ""))
	_sync_greeting(entry)
	var scene := String(story.get("scene", ""))
	speaker.text = ("%s · %s" % [_maid_name(entry), scene]) if not scene.is_empty() else _maid_name(entry)

func _sync_choices() -> void:
	var labels := _choice_labels()
	for index in choice_buttons.size():
		var button: InscriptionAction = choice_buttons[index]
		button.text = String(labels[index]) if index < labels.size() else ""

func _duty() -> Dictionary:
	var duty := _as_dict(_maid_entry().get("duty", {}))
	if duty.is_empty(): return {}
	if String(duty.get("kind", "")) != String(DUTY_KINDS.get(selected_maid, "")): return {}
	return duty

func _active_duty_ids() -> Array:
	var ids := _as_array(_maid_view.get("active_duties", []))
	if not ids.is_empty(): return ids
	var single := String(_maid_view.get("active_duty", ""))
	return [single] if not single.is_empty() else []

func _vertical(value: String) -> String:
	var chars := PackedStringArray()
	for index in value.length():
		chars.append(value[index])
	return "\n".join(chars)

func _reason_text(code: String) -> String:
	var texts := _as_dict(RECRUIT_TEXTS.get(selected_maid, {}))
	if not code.is_empty() and texts.has(code):
		return String(texts[code])
	if code.is_empty(): return "條件尚未足"
	return String(REASONS.get(code, code))

func _sync_view() -> void:
	if column == null: return
	var entry := _maid_entry()
	var display_name := _maid_name(entry)
	role_label.text = _vertical(_maid_role(entry))
	name_label.text = _vertical(display_name)
	_load_portrait()
	if mode == "meeting" or not _meeting_id.is_empty(): _load_meeting()
	_sync_story(entry)
	_sync_choices()
	portrait_button.tooltip_text = "查看完整立繪" if _has_art() else "立繪尚未完成"
	portrait_button.accessibility_name = ("查看%s完整立繪" % display_name) if _has_art() else ("%s立繪尚未完成" % display_name)
	_sync_work(entry)
	_sync_bond(entry)
	_sync()

func _sync_work(entry: Dictionary) -> void:
	var display_name := _maid_name(entry)
	var duty := _duty()
	var recruited := bool(entry.get("recruited", false))
	var plain := String(DUTY_PLAIN.get(selected_maid, "職掌"))
	if duty.is_empty():
		var tail := "・尚未招募"
		if recruited: tail = "・已執行 %d 次" % int(entry.get("duty_actions", 0))
		work_status.text = "%s（%s）・尚未指派%s" % [display_name, plain, tail]
	else:
		var status := String(duty.get("status_text", ""))
		if status.is_empty():
			var code := String(duty.get("status", "RUNNING"))
			status = code
			if code == "RUNNING": status = "運作中"
			elif code == "TARGET_REACHED": status = "已達目標"
		var count := "・累計 %d 次" % int(entry.get("duty_actions", 0))
		var cooldown := int(duty.get("cooldown", 0))
		if cooldown > 0: count += "・倒數 %d 秒" % cooldown
		work_status.text = "%s（%s）・%s%s" % [display_name, plain, status, count]
	var active := _active_duty_ids()
	if active.is_empty():
		work_owner.text = "目前沒有生效中的職掌。"
	else:
		var names := PackedStringArray()
		for maid_id in active:
			var label := String(MAID_NAMES.get(maid_id, maid_id))
			if String(maid_id) == selected_maid: label += "（就是眼前這位）"
			names.append(label)
		work_owner.text = "生效中：%s" % "、".join(names)
	_fill_options(entry, duty)
	duty_target.visible = String(DUTY_KINDS.get(selected_maid, "")) in TARGET_DUTIES
	_sync_reserve_rows(duty)
	_update_shortage_hint(duty)
	_update_actions_state(recruited, duty)

func _options(entry: Dictionary) -> Array:
	var options := _as_dict(entry.get("options", {}))
	return _as_array(options.get(String(OPTION_FIELDS.get(selected_maid, "")), []))

func _fill_options(entry: Dictionary, duty: Dictionary) -> void:
	var options := _options(entry)
	var signature := ""
	for option in options:
		var id := String(_as_dict(option).get("id", ""))
		if not id.is_empty(): signature += id + "|"
	if signature != _option_signature:
		_option_signature = signature
		_duty_ids.clear()
		duty_picker.clear()
		for option in options:
			var item := _as_dict(option)
			var id := String(item.get("id", ""))
			if id.is_empty(): continue
			_duty_ids.append(id)
			duty_picker.add_item(String(item.get("name", id)))
	var preferred := String(duty.get(String(DUTY_FIELDS.get(selected_maid, "")), ""))
	if _duty_choice.is_empty() or not _duty_ids.has(_duty_choice):
		if _duty_ids.has(preferred):
			_duty_choice = preferred
		elif not _duty_ids.is_empty():
			_duty_choice = String(_duty_ids[0])
		else:
			_duty_choice = ""
	var index := _duty_ids.find(_duty_choice)
	if index >= 0:
		if duty_picker.selected != index: duty_picker.select(index)
		duty_picker.tooltip_text = duty_picker.get_item_text(index)
	var wanted := -1.0
	if not duty.is_empty() and duty.has("target"):
		wanted = clampf(float(duty.get("target", 1)), 1.0, 999.0)
		if wanted != float(_last_duty_target) and not duty_target.has_focus():
			duty_target.value = wanted
	_last_duty_target = int(wanted)
	duty_picker.visible = not _duty_ids.is_empty()

func _chosen_option() -> Dictionary:
	var chosen := _chosen_id()
	if chosen.is_empty(): return {}
	for option in _options(_maid_entry()):
		var item := _as_dict(option)
		if String(item.get("id", "")) == chosen: return item
	return {}

func _selected_input_rows() -> Array:
	var item := _chosen_option()
	if item.is_empty(): return []
	var kind := String(DUTY_KINDS.get(selected_maid, ""))
	if kind == "steward_stock": return _as_array(item.get("inputs", []))
	if kind == "restock_pills": return _as_array(item.get("cost", []))
	return []

func _input_signature(rows: Array) -> String:
	var signature := _chosen_id()
	for row in rows:
		signature += "|" + String(_as_dict(row).get("id", ""))
	return signature

func _clear_reserve_rows() -> void:
	for entry in reserve_entries:
		var spin: SpinBox = entry.get("spin")
		if spin != null and is_instance_valid(spin) and spin.get_parent() == reserve_row:
			reserve_row.remove_child(spin)
			spin.queue_free()
	reserve_entries.clear()
	reserve_spins.clear()
	_reserve_signature = ""

func _sync_reserve_rows(duty: Dictionary) -> void:
	var kind := String(DUTY_KINDS.get(selected_maid, ""))
	var presets := MaidRules.duty_presets(kind)
	preset_row.visible = kind in TARGET_DUTIES and not presets.is_empty()
	var rows := _selected_input_rows()
	if kind not in TARGET_DUTIES or rows.is_empty():
		_clear_reserve_rows()
		reserve_row.visible = false
		return
	if _input_signature(rows) != _reserve_signature:
		_rebuild_reserve_rows(rows, duty)
	else:
		for entry in reserve_entries:
			var entry_id := String(entry.get("id", ""))
			for row in rows:
				var item := _as_dict(row)
				if String(item.get("id", "")) == entry_id:
					entry["stock"] = float(item.get("stock", 0.0))
					break
	reserve_heading.visible = not reserve_entries.is_empty()
	reserve_row.visible = not reserve_entries.is_empty()

func _rebuild_reserve_rows(rows: Array, duty: Dictionary) -> void:
	_clear_reserve_rows()
	var chosen := _chosen_id()
	var field := String(DUTY_FIELDS.get(selected_maid, ""))
	var duty_item := String(duty.get(field, "")) if not duty.is_empty() else ""
	var seed := _as_dict(duty.get("reserve", {})) if duty_item == chosen else {}
	for row in rows:
		var item := _as_dict(row)
		var id := String(item.get("id", ""))
		if id.is_empty(): continue
		var display_name := String(item.get("name", id))
		var spin := SpinBox.new()
		spin.min_value = 0
		spin.max_value = 999999
		spin.step = 1
		spin.prefix = "%s 保留 " % display_name
		spin.custom_minimum_size = Vector2(150, 44)
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin.value = clampf(_to_number(seed.get(id, 0)), 0.0, 999999.0)
		spin.tooltip_text = "至少保留的%s數量；職掌不會動用這部分。" % display_name
		spin.value_changed.connect(func(_value: float): _refresh_preview())
		reserve_row.add_child(spin)
		reserve_entries.append({"id": id, "name": display_name, "stock": float(item.get("stock", 0.0)), "spin": spin})
		reserve_spins[id] = spin
	_reserve_signature = _input_signature(rows)

func _reserve_value(id: String) -> float:
	var spin: Variant = reserve_spins.get(id)
	if spin is SpinBox: return float((spin as SpinBox).value)
	return 0.0

func _apply_preset(preset: Dictionary) -> void:
	if duty_target.visible:
		duty_target.value = clampf(float(preset.get("target", 1)), 1.0, 999.0)
	var ratio := float(preset.get("reserve_ratio", 0.0))
	for entry in reserve_entries:
		var spin: SpinBox = entry.get("spin")
		if spin == null or not is_instance_valid(spin): continue
		var keep := int(floor(maxf(0.0, float(entry.get("stock", 0.0))) * ratio))
		spin.value = clampf(float(keep), 0.0, spin.max_value)
	_refresh_preview()

func _refresh_preview() -> void:
	_update_actions()
	_update_shortage_hint(_duty())

func _to_number(raw: Variant) -> float:
	if raw is int or raw is float:
		var direct := float(raw)
		return direct if is_finite(direct) else 0.0
	if raw is String:
		var parsed := AmountCompat.try_parse(raw)
		if bool(parsed.get("ok", false)) and parsed.get("value") is AmountCompat:
			return (parsed.get("value") as AmountCompat).to_float()
	return 0.0

func _fmt_number(value: float) -> String:
	return AmountCompat.from_number(value).to_display_string()

func _shortage_preview() -> String:
	if not duty_target.visible: return ""
	var item := _chosen_option()
	if item.is_empty(): return ""
	var kind := String(DUTY_KINDS.get(selected_maid, ""))
	var target := int(duty_target.value)
	var stock := float(item.get("stock", 0.0))
	var need := target - int(floor(stock))
	if need <= 0: return ""
	var batches := 0
	var rows: Array = []
	var per_key := ""
	if kind == "steward_stock":
		var output := maxf(1.0, float(item.get("output", 1.0)))
		batches = mini(MaidRules.MAX_UNITS_PER_ACTION, int(ceilf(float(need) / output)))
		rows = _as_array(item.get("inputs", []))
		per_key = "per_batch"
	elif kind == "restock_pills":
		batches = mini(MaidRules.MAX_UNITS_PER_ACTION, need)
		rows = _as_array(item.get("cost", []))
		per_key = "per_unit"
	if batches <= 0 or rows.is_empty(): return ""
	for row in rows:
		var input := _as_dict(row)
		var id := String(input.get("id", ""))
		var per := float(input.get(per_key, 0.0))
		if per <= 0.0: continue
		var required := per * float(batches)
		var reserve := _reserve_value(id)
		var owned := float(input.get("stock", 0.0))
		var available := maxf(0.0, owned - reserve)
		if available + 0.000001 >= required: continue
		var display_name := String(input.get("name", id))
		if reserve > 0.0:
			return "%s不足 %s（需 %s，現有 %s，保留 %s）" % [display_name, _fmt_number(required - available), _fmt_number(required), _fmt_number(owned), _fmt_number(reserve)]
		return "%s不足 %s（需 %s，現有 %s）" % [display_name, _fmt_number(required - available), _fmt_number(required), _fmt_number(owned)]
	return ""

func _update_shortage_hint(duty: Dictionary) -> void:
	var text := ""
	if _duty_ids.is_empty():
		text = "尚無可用目標"
	else:
		var field := String(DUTY_FIELDS.get(selected_maid, ""))
		var chosen := _chosen_id()
		var duty_text := String(duty.get("shortage_text", ""))
		if not duty_text.is_empty() and not chosen.is_empty() and String(duty.get(field, "")) == chosen:
			text = duty_text
		else:
			text = _shortage_preview()
	duty_hint.text = text
	duty_hint.visible = not text.is_empty()

func _update_actions_state(recruited: bool, duty: Dictionary) -> void:
	var has_options := not _duty_ids.is_empty()
	assign_button.disabled = not recruited or not has_options or _chosen_id().is_empty()
	var assign_note := "以所選目標指派%s。" % String(DUTY_PLAIN.get(selected_maid, "職掌"))
	if not recruited:
		assign_note = "尚未招募，無法指派職掌。"
	elif not has_options:
		assign_note = "尚無可用目標；需先有可指派的配方、建築或丹藥。"
	assign_button.tooltip_text = assign_note
	var paused := bool(duty.get("paused", false))
	pause_button.disabled = duty.is_empty()
	pause_button.text = "恢復" if paused else "暫停"
	pause_button.tooltip_text = "恢復此職掌的推進節奏。" if paused else "暫停此職掌，進行中的批次不回收。"
	execute_button.disabled = duty.is_empty()
	execute_button.tooltip_text = "立即執行一次有界動作，忽略冷卻。"
	clear_button.disabled = duty.is_empty()
	clear_button.tooltip_text = "清除工作設定，保留累計次數。"

func _update_actions() -> void:
	var entry := _maid_entry()
	_update_actions_state(bool(entry.get("recruited", false)), _duty())

func _chosen_id() -> String:
	var index := duty_picker.selected
	if index >= 0 and index < _duty_ids.size(): return String(_duty_ids[index])
	if _duty_ids.has(_duty_choice): return _duty_choice
	return ""

func _on_option_selected(index: int) -> void:
	if index < 0 or index >= _duty_ids.size(): return
	_duty_choice = String(_duty_ids[index])
	_sync_reserve_rows(_duty())
	_update_shortage_hint(_duty())
	_update_actions()

func _sync_bond(entry: Dictionary) -> void:
	var recruited := bool(entry.get("recruited", false))
	var bond_name := String(entry.get("bond_name", ""))
	if bond_name.is_empty(): bond_name = "初識"
	var points := int(entry.get("bond", 0))
	bond_status.text = "%s・%s　%d 點" % [_maid_name(entry), bond_name, points]
	var next_at := int(entry.get("next_bond_at", -1))
	if next_at >= 0:
		var next_name := String(entry.get("next_bond_name", ""))
		bond_next.text = "下一階段：%s（%d 點）" % [next_name if not next_name.is_empty() else "未名", next_at]
	else:
		bond_next.text = "已達最高羈絆。"
	var chapters := _as_array(entry.get("chapters", []))
	for index in chapter_rows.size():
		var row_data: Dictionary = chapter_rows[index]
		var row: BoxContainer = row_data["row"]
		var info: Label = row_data["info"]
		var claim: InscriptionAction = row_data["claim"]
		var replay: InscriptionAction = row_data["replay"]
		var memory: InscriptionAction = row_data["memory"]
		if index >= chapters.size():
			row.visible = false
			replay.visible = false
			memory.visible = false
			row_data["id"] = ""
			continue
		var chapter := _as_dict(chapters[index])
		var claimed := bool(chapter.get("claimed", false))
		var can_claim := bool(chapter.get("can_claim", false))
		var chapter_id := String(chapter.get("id", ""))
		row_data["id"] = chapter_id
		row.visible = recruited
		info.visible = recruited
		var state := _reason_text(String(chapter.get("reason", "")))
		if claimed: state = "已領取"
		elif can_claim: state = "可領取"
		info.text = "%s・+%d 點・%s" % [String(chapter.get("title", chapter_id)), int(chapter.get("bond", 0)), state]
		claim.visible = recruited and can_claim
		claim.disabled = not can_claim
		replay.visible = recruited and claimed
		replay.disabled = not replay.visible
		var final_chapter := index == chapters.size() - 1
		memory.visible = recruited and claimed and final_chapter
		memory.disabled = not memory.visible
	reunion_box.visible = recruited and bool(entry.get("reunion_pending", false))
	reunion_label.text = _reunion_text()
	recruit_box.visible = not recruited
	var recruit := _as_dict(entry.get("recruit", {}))
	var can := bool(recruit.get("can", false))
	var ready := "條件已足，可招募 %s。" % _maid_name(entry)
	recruit_label.text = ready if can else _reason_text(String(recruit.get("reason", "")))
	recruit_button.disabled = not can

func _sync() -> void:
	if column == null: return
	var art := _has_art()
	person.visible = mode == "person"
	maid_row.visible = true
	meeting.visible = mode == "meeting"
	work.visible = mode == "work"
	bond.visible = mode == "bond"
	if mode == "person":
		title.text = "%s · %s" % [_maid_role(_maid_entry()), _maid_name(_maid_entry())]
	elif mode == "meeting":
		var scene := String(_story().get("scene", ""))
		title.text = ("初遇 · %s" % scene) if art and not scene.is_empty() else "初遇 · 尚未補完"
	elif mode == "work":
		title.text = "職掌 · %s" % _maid_name(_maid_entry())
	else:
		title.text = "羈絆 · %s" % _maid_name(_maid_entry())
	for key in tabs:
		tabs[key].set_pressed_no_signal(key == mode)
		tabs[key]._update_style()
	var maids := _as_dict(_maid_view.get("maids", {}))
	for id in maid_buttons:
		var recruited := bool(_as_dict(maids.get(id, {})).get("recruited", false))
		maid_buttons[id].tooltip_text = "" if recruited else "尚未招募 · 可先閱覽人物與初遇"
		maid_buttons[id].set_pressed_no_signal(id == selected_maid)
		maid_buttons[id]._update_style()
	portrait_image.visible = art
	portrait_placeholder.visible = not art
	portrait_button.disabled = not art
	seal.visible = art and not _compact
	bookmark.visible = art
	bio_placeholder.visible = not art
	meeting_image.visible = art
	missing_meeting.visible = not art
	dialogue.visible = art
	choices.visible = art and selected_reply < 0
	replay.visible = art and selected_reply >= 0
	var active := _active_duty_ids()
	work_owner.visible = not _compact or not active.is_empty()
	feedback.visible = mode == "work" and not feedback.text.is_empty()
	bond_feedback.visible = mode == "bond" and not bond_feedback.text.is_empty()

func _assign() -> void:
	var option_id := _chosen_id()
	if option_id.is_empty(): return
	var reserve := {}
	for entry in reserve_entries:
		var spin: SpinBox = entry.get("spin")
		if spin == null or not is_instance_valid(spin): continue
		var keep := int(spin.value)
		if keep > 0: reserve[String(entry.get("id", ""))] = keep
	var duty := {}
	match selected_maid:
		"qingheng": duty = {"kind": "steward_stock", "recipe_id": option_id, "target": int(duty_target.value), "reserve": reserve}
		"nuomeizi": duty = {"kind": "oversee_build", "building_id": option_id}
		"danxia": duty = {"kind": "restock_pills", "pill_id": option_id, "target": int(duty_target.value), "reserve": reserve}
		_: return
	action_requested.emit("assign_maid_duty", {"maid_id": selected_maid, "duty": duty})

func _toggle_pause() -> void:
	var duty := _duty()
	if duty.is_empty(): return
	action_requested.emit("set_maid_duty_paused", {"maid_id": selected_maid, "paused": not bool(duty.get("paused", false))})

func _execute() -> void:
	if _duty().is_empty(): return
	action_requested.emit("execute_maid_duty", {"maid_id": selected_maid})

func _clear() -> void:
	if _duty().is_empty(): return
	action_requested.emit("clear_maid_duty", {"maid_id": selected_maid})

func _claim(index: int) -> void:
	if index < 0 or index >= chapter_rows.size(): return
	var row_data: Dictionary = chapter_rows[index]
	var chapter_id := String(row_data.get("id", ""))
	if chapter_id.is_empty(): return
	action_requested.emit("claim_maid_chapter", {"maid_id": selected_maid, "chapter_id": chapter_id})

func _replay_chapter(index: int) -> void:
	if index < 0 or index >= chapter_rows.size(): return
	var chapters := _as_array(_maid_entry().get("chapters", []))
	if index >= chapters.size(): return
	var chapter := _as_dict(chapters[index])
	if not bool(chapter.get("claimed", false)): return
	var script := chapter_script(selected_maid, String(chapter.get("id", "")))
	if script.is_empty(): return
	chapter_requested.emit("%s · %s" % [_maid_name(_maid_entry()), String(script.get("title", ""))], script)

func chapter_script(maid_id: String, chapter_id: String) -> Dictionary:
	var scripts := _as_dict(BOND_SCRIPT.get(maid_id, {}))
	return _as_dict(scripts.get(chapter_id, {})).duplicate(true)

static func voice_line(kind: String, maid_id: String) -> String:
	var lines: Variant = VOICE_LINES.get(kind, {})
	if not lines is Dictionary:
		return ""
	return String((lines as Dictionary).get(maid_id, ""))

func _reunion_text() -> String:
	return String(REUNION_LINES.get(selected_maid, ""))

func _greeting_tier(tier_name: String) -> int:
	match tier_name:
		"相知": return 1
		"信任": return 2
		"同道": return 3
	return 0

func _sync_greeting(entry: Dictionary) -> void:
	if greeting_label == null: return
	var tier := _greeting_tier(String(entry.get("bond_name", "")))
	var duty := _as_dict(entry.get("duty", {}))
	var table: Dictionary = DUTY_GREETINGS if not duty.is_empty() and not bool(duty.get("paused", false)) else GREETINGS
	var lines := _as_array(table.get(selected_maid, []))
	greeting_label.text = String(lines[tier]) if tier < lines.size() else ""
	greeting_label.visible = bool(entry.get("recruited", false)) and not greeting_label.text.is_empty()

func _memory(index: int) -> void:
	if index != chapter_rows.size() - 1: return
	var chapters := _as_array(_maid_entry().get("chapters", []))
	if index >= chapters.size(): return
	if not bool(_as_dict(chapters[index]).get("claimed", false)): return
	var def: Dictionary = BOND_CG.get(selected_maid, {})
	var path := String(def.get("path", ""))
	if path.is_empty() or not ResourceLoader.exists(path): return
	var texture := load(path) as Texture2D
	if texture == null: return
	memory_requested.emit(texture, "%s · %s" % [_maid_name(_maid_entry()), String(def.get("title", ""))], _as_array(def.get("lines", [])))

func _reunion() -> void:
	action_requested.emit("maid_reunion", {"maid_id": selected_maid})

func _recruit() -> void:
	var recruit := _as_dict(_maid_entry().get("recruit", {}))
	if not bool(recruit.get("can", false)): return
	action_requested.emit("recruit_maid", {"maid_id": selected_maid})

func set_embedded(value: bool) -> void:
	embedded = value
	if column != null: _apply_surface()

func _apply_surface() -> void:
	if embedded:
		add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		return
	var paper := UiMaterial.hud_paper()
	paper.content_margin_top = 4 if _compact else 10
	paper.content_margin_bottom = 4 if _compact else 10
	add_theme_stylebox_override("panel", paper)

func set_layout_bounds(bounds: Rect2) -> void:
	if not is_visible_in_tree() and position == bounds.position and size == bounds.size:
		return
	_bounds = bounds
	position = bounds.position
	size = bounds.size
	if column == null: return
	_compact = bounds.size.y < 400 or bounds.size.x < 960
	_apply_surface()
	if is_instance_valid(section_scroll):
		section_scroll.custom_minimum_size.x = 112.0 if bounds.size.x < 500.0 else (140.0 if _compact else 168.0)
	if is_instance_valid(section_body):
		section_body.add_theme_constant_override("separation", 8 if _compact else 14)
	if is_instance_valid(_left_rail):
		_left_rail.add_theme_constant_override("separation", 4 if _compact else 8)
	if is_instance_valid(_nav_sep):
		_nav_sep.visible = is_instance_valid(left_nav_host) and left_nav_host.get_child_count() > 0
	if is_instance_valid(close_host):
		close_host.position = Vector2(maxf(0.0, bounds.size.x - (12.0 if _compact else 18.0) - 44.0), 6.0 if _compact else 10.0)
		close_host.size = Vector2(44.0, 44.0)
	var frame: StyleBoxFlat = portrait_frame.get_theme_stylebox("panel").duplicate()
	frame.set_content_margin_all(4 if _compact else 12)
	portrait_frame.add_theme_stylebox_override("panel", frame)
	column.add_theme_constant_override("separation", 4 if _compact else 6)
	name_column.vertical = not _compact
	name_column.custom_minimum_size.x = 44 if _compact else 72
	person.add_theme_constant_override("separation", 12 if _compact else 24)
	portrait_frame.size_flags_stretch_ratio = 0.85 if _compact else 1.3
	role_label.visible = not _compact
	name_label.add_theme_font_size_override("font_size", 28 if _compact else 60)
	seal.visible = not _compact and _has_art()
	meeting.vertical = not _compact
	dialogue.vertical = _compact
	dialogue.add_theme_constant_override("separation", 4 if _compact else 18)
	speaker.visible = not _compact
	choices.vertical = not _compact
	meeting_image.size_flags_stretch_ratio = 0.8 if _compact else 1.0
	dialogue.size_flags_stretch_ratio = 1.2 if _compact else 1.0
	dialogue.size_flags_vertical = Control.SIZE_EXPAND_FILL if _compact else Control.SIZE_FILL
	line_scroll.custom_minimum_size.y = 0 if _compact else 64
	maid_row.add_theme_constant_override("separation", 2 if _compact else 4)
	_copy_scroll_layout()
	work_box.add_theme_constant_override("separation", 4 if _compact else 10)
	bond_box.add_theme_constant_override("separation", 4 if _compact else 10)
	action_row.vertical = _compact
	_apply_field_layout()
	for row_data in chapter_rows:
		var row: BoxContainer = row_data["row"]
		row.vertical = _compact
		row.add_theme_constant_override("separation", 2 if _compact else 8)
	reunion_box.vertical = _compact
	recruit_box.vertical = _compact
	reunion_box.add_theme_constant_override("separation", 2 if _compact else 8)
	recruit_box.add_theme_constant_override("separation", 2 if _compact else 8)
	_compact_labels()
	title.visible = not _compact
	_sync()
	_fit_bounds.call_deferred()

func _copy_scroll_layout() -> void:
	copy_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy_box.add_theme_constant_override("separation", 6 if _compact else 18)

func _apply_field_layout() -> void:
	duty_picker.custom_minimum_size = Vector2(140 if _compact else 220, 44)
	duty_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	duty_target.custom_minimum_size = Vector2(110 if _compact else 140, 44)
	work_fields.vertical = _compact
	work_fields.add_theme_constant_override("separation", 4 if _compact else 8)
	preset_row.vertical = _compact
	reserve_row.vertical = _compact
	preset_row.add_theme_constant_override("separation", 4 if _compact else 8)
	reserve_row.add_theme_constant_override("separation", 4 if _compact else 8)
	for button in preset_buttons:
		(button as Control).custom_minimum_size.y = 44
	for entry in reserve_entries:
		var spin: SpinBox = entry.get("spin")
		if spin != null and is_instance_valid(spin):
			spin.custom_minimum_size = Vector2(150, 44)
			spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _compact_labels() -> void:
	var heading_size := 18 if _compact else 20
	var body_size := 18
	work_status.add_theme_font_size_override("font_size", body_size)
	work_owner.add_theme_font_size_override("font_size", body_size)
	duty_hint.add_theme_font_size_override("font_size", body_size)
	greeting_label.add_theme_font_size_override("font_size", body_size)
	bond_status.add_theme_font_size_override("font_size", body_size)
	bond_next.add_theme_font_size_override("font_size", body_size)
	reunion_label.add_theme_font_size_override("font_size", body_size)
	recruit_label.add_theme_font_size_override("font_size", body_size)
	feedback.add_theme_font_size_override("font_size", body_size)
	bond_feedback.add_theme_font_size_override("font_size", body_size)
	work_heading.add_theme_font_size_override("font_size", heading_size)
	bond_heading.add_theme_font_size_override("font_size", heading_size)
	for row_data in chapter_rows:
		(row_data["info"] as Label).add_theme_font_size_override("font_size", body_size)

func _fit_bounds() -> void:
	if not _bounds.has_area(): return
	if size != _bounds.size: size = _bounds.size
