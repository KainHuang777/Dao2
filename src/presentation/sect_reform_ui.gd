class_name SectReformUi
extends RefCounted
## Presentation copy and native controls; no inventory writes or random draws.
const TRADEOFFS := {
 "taixu_sect": "修煉等待較短、自然靈力較多；材料及容量仍須備齊。",
 "tianjian_sect": "指定礦採集與金石加工較快；缺料、航運或秒數取整可能使收益為零。",
 "piaomiao_sect": "指定草採集與六丹草費節省；不增加丹效，仍有服丹衰減。",
 "wanfo_sect": "增加當世壽元；不回復已用時間，不縮短突破準備。",
 "zixiao_sect": "祖島靈力與七類材料庫容增加；不增加產量或地方庫容。",
}
const EFFECTS := [
 "修煉進度每階 +2%；不加服丹直接進度。",
 "祖島自然靈力每階 +3%；不加手動採集及一次性獎勵。",
 "玄礦下石／玄銅、寒銀精鐵／秘銀／寒鐵採集每階 +4%。",
 "銅精、中石（含批量）、上石、符咒、陣芯速率每階 +3%；新批次秒數向上取整。10秒配方啟用3階仍10秒，5階9秒；20秒對應19／18秒。不改航速。",
 "丹霞低草／百草、古藥千草採集每階 +4%。",
 "育靈／育草／聚財／納氣／延壽丹低草、渡劫丹百草每階 -2%；其他成本不折。",
 "當世壽元上限每階 +2年；不減少已用壽元。",
 "壽元比例每階 +2%；與原比例同層相加。",
 "祖島靈力容量每階 +4%；不是靈氣。",
 "祖島靈木、下石、玄銅、靈材、銅精、丹液、陣芯容量每階 +4%。",
]
const ERRORS := {
 "TECHNIQUE_SECT_REQUIRED": "需當世加入對應宗門", "TECHNIQUE_ERA_LOCKED": "當世境界不足",
 "TECHNIQUE_PREREQUISITE": "需同宗A法3階；升B4階需A5階", "TECHNIQUE_MAX_LEVEL": "已圓滿",
 "INSUFFICIENT_CONTRIBUTION": "貢獻不足", "INSUFFICIENT_STONE": "祖島下石不足",
 "LIFESPAN_EXHAUSTED": "壽元已盡", "SECT_LINEAGE_LIVES_REQUIRED": "有效世數不足",
 "INSUFFICIENT_DAO_HEART": "道心不足", "TALENT_MAX_LEVEL": "已圓滿",
}
static func text(parent: Node, value: String) -> Label:
 var node := Label.new()
 node.text = value
 node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 node.add_theme_font_size_override("font_size", 16)
 node.add_theme_color_override("font_color", UiMaterial.INK)
 parent.add_child(node)
 return node

static func progress(parent: Node, state: GameState) -> void:
 if state == null or not state.sect.has("lineage"): return
 var view := SectLineage.view(state)
 text(parent, "有效世：本世新委託已領 %d／3 · 本世最高第%d境\n需同宗、最高築基、領足3件新委託，再依原資格輪迴才結算；歷史委託不補計。" % [view.life_claimed, view.life_peak_era])
 if state.sect.has("guardian"):
  text(parent, "守護信物 %d／120 · 12枚指定兌換。合格新委託領取+1，重複資格再+2；滿額溢出不補償。發現只給永久資格，不自動結契。兌換與結契請至修行→靈獸。" % state.sect.guardian.guardian_tokens)

static func render(panel: Control) -> void:
 var state: GameState = panel._cached_state
 if state == null or not SectReformSave.active(state): return
 var parent: Node = panel._tab_content_container
 var identity := SectIdentity.view(state.sect)
 text(parent, TRADEOFFS.get(identity.sect_id, "請先確認本世宗門身分。"))
 progress(parent, state)
 text(parent, "宗門專法 · 永久持有，僅當世同宗啟用。A：築基1–3／元嬰4–5；B：金丹1–3／化神4–5，並需A3／A5。")
 var grid: GridContainer = panel._new_grid()
 var methods := SectSpecialization.view(state)
 var index := 0
 for id in methods:
  var item: Dictionary = methods[id]
  var card := PanelContainer.new()
  card.set_meta("content_id", id)
  card.add_theme_stylebox_override("panel", UiMaterial.hud_paper())
  grid.add_child(card)
  var box := VBoxContainer.new()
  card.add_child(box)
  text(box, "%s · %s · 已學%d／5 · 啟用%d" % [SectIdentity.NAMES[item.sect_id], item.name, item.learned_level, item.active_level])
  text(box, EFFECTS[index])
  index += 1
  var level: int = item.learned_level
  var is_a: bool = item.group == "A"
  var cost := {} if level >= 5 else {"contribution": (SectSpecialization.A_CONTRIBUTION if is_a else SectSpecialization.B_CONTRIBUTION)[level], "stone_low": (SectSpecialization.A_STONE if is_a else SectSpecialization.B_STONE)[level]}
  var button := Button.new()
  button.custom_minimum_size.y = 44
  button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
  button.text = "參悟 · %d貢獻＋%d下石" % [cost.contribution, cost.stone_low] if not cost.is_empty() else "已圓滿"
  box.add_child(button)
  button.pressed.connect(func(): panel.learn_technique_requested.emit(id))
  panel._dynamic.append(func():
   var req := SectSpecialization.requirements(panel._cached_state, id)
   button.disabled = not req.ok
   button.tooltip_text = ERRORS.get(req.get("error", ""), "支付貢獻及祖島下品靈石；跨世保留。")
  )
  var reason := text(box, "")
  panel._dynamic.append(func(): reason.text = ERRORS.get(SectSpecialization.requirements(panel._cached_state, id).get("error", ""), "可參悟"))
 text(parent, "累世傳承 · 首次有效世後揭露；資格與成就領獎順序無關，稱號無數值獎勵。")
 var lineage := SectLineage.view(state)
 for id in lineage.talents:
  var item: Dictionary = lineage.talents[id]
  var sect_id: String = String(id).trim_suffix("_lineage") + "_sect"
  text(parent, "%s · %s · 有效世%d · 已學%d／3" % [SectIdentity.NAMES[sect_id], item.name, item.completed_lives, item.learned_level])
  if not item.revealed: continue
  text(parent, SectLineage.definition(id).description + "\n門檻1／3／5有效世；道心費5／10／20。啟用 +%d%% · %s" % [int(round(item.active_bonus * 100)), item.dormant_reason])
  var button := Button.new()
  button.custom_minimum_size.y = 44
  button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
  parent.add_child(button)
  button.pressed.connect(func(): panel.reform_action_requested.emit("lineage", id))
  panel._dynamic.append(func():
   var req := SectLineage.can_learn(panel._cached_state, id)
   button.disabled = not req.can_learn
   button.text = "參悟傳承 · %d道心" % item.next_cost if req.can_learn else ERRORS.get(req.get("reason", ""), "尚不可學")
  )
 text(parent, "八項共通功法 · 保留原投入與作用範圍")

static func beast_name(id: String) -> String:
 return String(GuardianBeasts.SPECIES[id][0]) if GuardianBeasts.SPECIES.has(id) else String(BeastSystem.BEAST_CONFIGS.get(id, {}).get("name", id))

static func task_reward(parent: Node, task: Dictionary, state: GameState) -> void:
 var reward: Dictionary = task.get("guardian_reward", {})
 if reward.is_empty():
  text(parent, "歷史委託：不補信物／發現／有效世計數。")
  return
 var id: String = reward.get("permit_id", "")
 var info := "領取信物 +%d" % int(reward.get("token_base", 0))
 if not id.is_empty():
  var ledger: Dictionary = state.sect.get("guardian", {})
  var owned: bool = ledger.get("permits", {}).has(id) or ledger.get("legacy_permits", {}).has(id)
  info += " · 發現%s：%s" % [beast_name(id), "已持資格，領取時轉+2信物" if owned else "領取永久資格"]
 text(parent, info + " · 獎勵已凍結，不自動結契。")

static func result_text(result: Dictionary) -> String:
 for event in result.get("events", []):
  if event.get("kind") == "guardian_reward_claimed":
   return "已領取並保存：信物+%d，溢出%d%s。" % [event.tokens_gained, event.tokens_overflow, " · " + beast_name(event.permit_id) + ("重複資格" if event.duplicate_permit else "永久資格") if not String(event.permit_id).is_empty() else ""]
 return "操作已完成並保存。"
