class_name FeatureUnlocks
extends RefCounted
## 負責決定各功能頁面狀態的純讀取工具
## 統一封裝開放條件，避免各 UI 散落硬編碼

enum State { HIDDEN, PREVIEW, AVAILABLE }

## route 對應 feature_navigation 註冊的頁面 ID
static func check(route: String, view: Dictionary) -> Dictionary:
	var state := State.HIDDEN
	var reason := ""
	var era := int(view.get("era_id", 1))
	var reinc := int(view.get("reincarnation_count", 0))
	
	match route:
		"buildings", "alchemy", "achievements":
			state = State.AVAILABLE
		"outposts", "manufacturing", "transport":
			state = State.AVAILABLE if era >= 2 else State.HIDDEN
			reason = "築基期開放" if era < 2 else ""
		"skills":
			var library: Variant = view.get("buildings", {}).get("library", {})
			var lib := int(library.get("level", 0)) if library is Dictionary else int(library)
			if era >= 2 and lib > 0:
				state = State.AVAILABLE
			elif era >= 2:
				state = State.PREVIEW
				reason = "需建造藏經閣"
			elif era == 1:
				state = State.PREVIEW
				reason = "築基期開放"
		"sect":
			if era >= 2 or reinc >= 1:
				state = State.AVAILABLE
			elif era == 1:
				state = State.PREVIEW
				reason = "築基期開放"
		"beasts":
			if era >= 3:
				state = State.AVAILABLE
			elif era == 2:
				state = State.PREVIEW
				reason = "結丹期開放"
		"decisions":
			if era >= 2:
				state = State.AVAILABLE
			else:
				state = State.PREVIEW
				reason = "築基期開放"
		"fortune":
			if era >= 2:
				state = State.AVAILABLE
			else:
				state = State.PREVIEW
				reason = "築基期開放"
		"reincarnation":
			if reinc >= 1 or era >= 6 or String(view.get("reincarnation_preview", {}).get("reason", "")) == "lifespan_exhausted":
				state = State.AVAILABLE
			else:
				state = State.HIDDEN
		"realms":
			if era >= 4:
				state = State.AVAILABLE
			elif era == 3:
				state = State.PREVIEW
				reason = "元嬰期開放"
		_:
			state = State.HIDDEN
			reason = "未知功能"
			
	return {"state": state, "reason": reason}

## Shared actionable reminders for the navigation dock and HUD status strip.
static func notification_flags(view: Dictionary, sect: Dictionary = {}) -> Dictionary:
	var expedition: Variant = sect.get("active_expedition")
	return {
		"reincarnation": check("reincarnation", view).state == State.AVAILABLE and bool(view.get("reincarnation_preview", {}).get("eligible", false)),
		"achievements": check("achievements", view).state == State.AVAILABLE and int(view.get("achievements", {}).get("unclaimed_count", 0)) > 0,
		"beasts": check("beasts", view).state == State.AVAILABLE and bool(view.get("beast", {}).get("can_feed", false)),
		"fortune": check("fortune", view).state == State.AVAILABLE and bool(view.get("fortune", {}).get("has_pending", false)),
		"sect": check("sect", view).state == State.AVAILABLE and bool(sect.get("unlocked", false)) and expedition is Dictionary and int(expedition.get("duration", 0)) > 0 and int(expedition.get("elapsed", 0)) >= int(expedition.duration),
	}
