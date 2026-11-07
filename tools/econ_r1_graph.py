"""Build the ECON-R1-A dependency report from a Godot runtime extraction.

No source-content formulas are reimplemented here. Costs and earned cap witnesses
come from the engine report. This is analysis, not a second game simulator.
"""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def build(data):
    nodes, edges = {}, []

    def node(key, kind, **attrs):
        nodes.setdefault(key, {"id": key, "kind": kind, **attrs})
        nodes[key].update(attrs)
        return key

    def edge(source, target, relation, **attrs):
        assert source in nodes and target in nodes, (source, target)
        edges.append({"from": source, "to": target, "relation": relation, **attrs})

    def resource(r):
        return node("home:" + r, "resource", definition=data["resources"][r], scope="home", source_operator="OR")

    def threshold(r, amount):
        cap = node(f"cap:{r}:{float(amount):g}", "capacity_threshold", resource=r, amount=float(amount), scope="home", operator="OR")
        edge(node("basecap:" + r, "base_capacity", amount=data["resources"][r]["max"]), cap, "candidate_base_capacity")
        for b, d in data["buildings"].items():
            effects = d["effects"]
            if r + "_max" in effects or ("all_max" in effects and r in ["lingli", "money", "wood", "stone_low", "spirit_grass_low"]) or ("synthetic_max_mult" in effects and r in ["stone_mid", "stone_high", "liquid", "talisman", "star_metal", "void_crystal"]):
                edge(node("building:" + b, "building", definition=d), cap, "candidate_capacity_provider")
        if r == "lingli":
            edge(node("onboarding:hut_cap", "conditional_capacity", era=1, per_hut=150), cap, "candidate_capacity_provider")
        return cap

    def payment(r, amount, target):
        edge(resource(r), target, "pay", amount=float(amount), scope="home")
        edge(threshold(r, amount), target, "AND")

    for r in data["resources"]:
        resource(r)
    for e, d in data["eras"].items():
        node("era:" + e, "era", definition=d)
    for b, d in data["buildings"].items():
        node("building:" + b, "building", definition=d)
    for b, d in data["buildings"].items():
        for row in data["building_costs"][b]:
            level = int(row["from_level"]) + 1
            n = node(f"buy:{b}:{level}", "building_purchase", operator="AND", costs=row["costs"])
            edge("era:" + str(int(d["era"])), n, "first_purchase_era" if level == 1 else "definition_era")
            if level > 1:
                edge(f"buy:{b}:{level-1}", n, "AND")
            elif d["prereq"]:
                p = d["prereq"]
                edge(node(f"buy:{p['building']}:{int(p['level'])}", "building_purchase"), n, "AND")
            for r, amount in row["costs"].items():
                payment(r, amount, n)
            edge(n, "building:" + b, "reaches_level", level=level)
        for r, amount in d["effects"].items():
            if r in data["resources"] and float(amount) > 0:
                edge("building:" + b, resource(r), "production_alternative", effect=amount)
    for r, d in data["resources"].items():
        if float(d["rate"]) > 0:
            edge(node("passive:" + r, "base_production", rate=d["rate"]), resource(r), "source_alternative")
    for e, levels in data["cultivation"].items():
        for row in levels:
            level = int(row["level"])
            n = node(f"cultivate:{e}:{level}", "cultivation", operator="AND", training_seconds=row["training_seconds"])
            edge("era:" + e, n, "AND")
            if level > 1:
                edge(f"cultivate:{e}:{level-1}", n, "AND")
            for r, amount in row["costs"].items():
                payment(r, amount, n)
        if int(e) < 6:
            n = node("breakthrough:" + e, "breakthrough", operator="AND", stochastic=int(e) >= 3)
            edge(f"cultivate:{e}:9", n, "AND")
            for r, amount in data["eras"][e].get("upgrade_requirements", {}).get("capacity", {}).items():
                # Capacity is checked, not paid.
                cap = threshold(r, amount)
                edge(cap, n, "capacity_only")
            edge(n, "era:" + str(int(e)+1), "success")
    for island, d in data["islands"].items():
        n = node("island:" + island, "island", operator="AND", definition=d)
        edge("era:" + str(int(d["era"])), n, "AND")
        if island != "home":
            for r, amount in d.get("cost", {"wood": 20, "stone_low": 10}).items():
                payment(r, amount, n)
        for b, level in d.get("facility", {}).items():
            local_facility = node(f"facility:{island}:{b}", "local_facility", level=level, scope=island)
            edge(n, local_facility, "provides_fixed_facility")
        for r, rate in d["rates"].items():
            local = node(f"local:{island}:{r}", "local_resource", scope=island, rate=rate, capacity=d.get("local_cap", 150))
            edge(n, local, "production")
    for route, (source, destination, r) in data["routes"].items():
        n = node("route:" + route, "route", operator="AND", resource=r, source=source, destination=destination, retired=route in ["wood_ore", "ore_wood"])
        edge("island:" + source, n, "AND")
        edge("island:" + destination, n, "AND")
        edge(node(f"local:{source}:{r}", "local_resource", scope=source), n, "source_inventory")
        edge(n, resource(r) if destination == "home" else node(f"local:{destination}:{r}", "local_resource", scope=destination), "arrival_only")
    for island, building in data.get("dispatch", {}).items():
        for row in data["building_costs"][building]:
            edge("island:" + island, f"buy:{building}:{int(row['from_level'])+1}", "opened_island_required")
    for recipe, d in data["catalog"]["recipes"].items():
        n = node("recipe:" + recipe, "recipe", operator="AND", definition=d, duration=data["durations"][recipe], payment_scope="home", output_scope="home")
        edge("era:" + str(int(d["era"])), n, "AND")
        lane = "wood" if recipe == "spirit_timber" else "ore" if recipe == "bronze_essence" else "home"
        alternatives = node("execution:" + recipe, "execution_alternatives", operator="OR")
        edge(alternatives, n, "AND")
        for owner in (["home", "herb"] if recipe == "liquid" else [lane]):
            execution = node(f"execute:{recipe}:{owner}", "recipe_execution", operator="AND")
            edge("island:" + owner, execution, "opened_lane")
            idle = node("lane_idle:" + owner, "runtime_predicate", scope=owner, predicate="no_running_job")
            edge(idle, execution, "AND")
            for b, level in d["facility"].items():
                if owner == "home":
                    edge(f"buy:{b}:{int(level)}", execution, "home_facility_gate")
                else:
                    # Local fixed facility definitions are not purchased home buildings.
                    facility = node(f"facility:{owner}:{b}", "local_facility", level=data["islands"][owner]["facility"].get(b, 0))
                    assert data["islands"][owner]["facility"].get(b, 0) >= int(level)
                    edge(facility, execution, "local_facility_gate", required_level=int(level))
            edge(execution, alternatives, "OR")
        for r, amount in d["inputs"].items():
            payment(r, amount, n)
            edge(node("unlock:" + r, "resource_unlock"), n, "input_unlocked")
        product = d.get("product", recipe)
        unlock = node("unlock:" + product, "resource_unlock", definition_era=data["catalog"]["resources"][product]["era"], activation_existing_entry_sync=True)
        edge(unlock, n, "AND")
        output_space = node("output_space:" + recipe, "runtime_predicate", scope="home", resource=product, predicate="free_space_at_least", amount=float(d["output"]))
        edge(output_space, n, "AND")
        edge(n, resource(product), "output", amount=float(d["output"]))
    for skill, d in data["skills"].items():
        node("skill:" + skill, "optional_skill", definition=d, required_for_solo=False)

    # These restrictions are conditional to the onboarding era, not permanent.
    for before, after in zip(data["onboarding_milestones"], data["onboarding_milestones"][1:]):
        edge(f"buy:{before['building']}:{int(before['level'])}", f"buy:{after['building']}:1", "onboarding_only_era1")
    activation = node("activate:islands", "activation", operator="AND", existing_resource_unlocks="synchronized_to_current_era")
    edge("era:2", activation, "AND")
    for island in data["islands"]:
        if island != "home":
            edge(activation, "island:" + island, "AND")
    for recipe, d in data["catalog"]["recipes"].items():
        product = d.get("product", recipe)
        era = max(2, int(data["catalog"]["resources"][product]["era"]))
        gate = node("sync_unlock:" + product, "conditional_transition", operator="AND", required_era=era, triggers=["activation", "subsequent_era_transition"])
        edge(activation, gate, "economy_activation_or_already_active")
        edge("era:" + str(era), gate, "current_era_at_least")
        edge(gate, "unlock:" + product, "unlocks_existing_entry")

    witnesses = {}
    for strategy in data["strategies"] + data.get("purchase_probes", []):
        for t in strategy["trace"]:
            if t["kind"] != "upgrade_building":
                continue
            b = t["payload"]["building_id"]
            if int(t["before"]["buildings"].get(b, 0)) != 0:
                continue
            costs = data["building_costs"][b][0]["costs"]
            assert all(t["before"]["caps"][r] >= v for r, v in costs.items())
            witnesses.setdefault(b, []).append({"policy": strategy["policy"], "seconds": t["seconds"], "era": t["era"], "costs": costs, "caps_before": {r: t["before"]["caps"][r] for r in costs}})
    stops = [{k: s[k] for k in ["policy", "era", "level", "seconds", "stop_reason", "completed_era6"]} for s in data["strategies"]]
    policies_complete = {s["policy"] for s in data["strategies"]} == {"production_first", "capacity_first", "progression_first"}
    return {"task": "ECON-R1-A", "nodes": list(nodes.values()), "edges": edges, "first_purchase_witnesses": witnesses,
            "strategy_stops": stops,
            "coverage": {"first_purchase_proven": len(witnesses), "buildings_total": len(data["buildings"]), "baseline_policies_complete": policies_complete, "reachable_to_era": min(s["era"] for s in data["strategies"]), "downstream": "PROVEN" if policies_complete and all(s["completed_era6"] for s in data["strategies"]) else "NOT_PROVEN: see observation scope and strategy stop reasons", "stage_limit": data.get("stage_limit", 6)},
            "interpretation": "AND/OR hypergraph; capacity provider edges are candidates, never an affordability or reachability proof. Cycles across repeat investment are legal. Retired routes and non-home inventory are not new hub supply. Definitions are not earned state."}


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument("runtime", type=Path, nargs="+")
    parser.add_argument("--purchase-probe", type=Path)
    parser.add_argument("--output", type=Path, default=ROOT / "docs/economy/econ-r1-a")
    args = parser.parse_args()
    sources = [{"path": path.as_posix(), "sha256": hashlib.sha256(path.read_bytes()).hexdigest()} for path in args.runtime]
    data = json.loads(args.runtime[0].read_bytes())
    for path in args.runtime[1:]:
        part = json.loads(path.read_bytes())
        for key in data.keys() - {"strategies", "failures"}:
            assert data[key] == part[key], (path, "inconsistent definition or observation scope", key)
        data["strategies"].extend(part["strategies"])
        data["failures"].extend(part["failures"])
    if args.purchase_probe:
        part = json.loads(args.purchase_probe.read_bytes())
        for key in ["task", "engine", "content_version"]:
            assert data[key] == part[key], ("inconsistent purchase probe", key)
        assert not part["failures"]
        data["purchase_probes"] = part["purchase_probes"]
        data["dispatch"] = part["dispatch"]
        sources.append({"path": args.purchase_probe.as_posix(), "sha256": hashlib.sha256(args.purchase_probe.read_bytes()).hexdigest(), "kind": "optional_purchase_probe"})
    assert len({s["policy"] for s in data["strategies"]}) == len(data["strategies"]), "duplicate policy"
    raw = args.runtime[0].read_bytes() if len(args.runtime) == 1 and not args.purchase_probe else (json.dumps(data, ensure_ascii=False, indent=2)+"\n").encode("utf-8")
    assert not data["failures"]
    graph = build(data)
    provenance = {"git_head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
                  "runtime_sha256": hashlib.sha256(raw).hexdigest(), "runtime_sources": sources, "files": {}}
    for folder in ["content", "src/content", "src/simulation", "src/domain", "src/application", "src/persistence"]:
        for path in sorted((ROOT / folder).rglob("*")):
            if path.suffix in [".gd", ".json"]:
                provenance["files"][path.relative_to(ROOT).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    for relative in ["tests/econ_r1_baseline_runner.gd", "tests/econ_r1_optional_purchase_runner.gd", "tools/run_all_runners.ps1", "tools/econ_r1_graph.py"]:
        provenance["files"][relative] = hashlib.sha256((ROOT / relative).read_bytes()).hexdigest()
    graph["provenance"] = provenance
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / "runtime-baseline.json").write_bytes(raw)
    (args.output / "dependency-graph.json").write_text(json.dumps(graph, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    lines = ["# ECON-R1-A 現版基線與門檻圖", "", "此檔由 `tools/econ_r1_graph.py` 產生；結案、命令與未通過項統一記於 [development-status](../../development-status.md#econ-r1-a)。", "", f"Godot {data['engine']}；runtime SHA256 `{hashlib.sha256(raw).hexdigest()}`。", "", f"正式組裝：{len(data['resources'])} 資源、{len(data['buildings'])} 建築、6 境、24 技能、11 配方、7 島、15 航線（含退役／舊地方產物航線）。", "", "## 讀取方式", "", "`runtime-baseline.json` 保留引擎組裝的定義、無折扣逐階成本、修行扣料／工時、三策略命令與停點。`dependency-graph.json` 為 AND／OR 門檻圖，包含逐次購買、材料與容量雙條件、地方來源／實際到貨、配方設備與資源解鎖。容量來源邊只是候選，不代表已買得起；升境的 capacity 是資格而非扣料。", "", "範圍為 Era1–6 主線經濟；技能保留原定義作選修索引，宗門、天賦、靈獸、丹藥等可選加成不列為主線門票。現版沒有通用研究，第三策略使用修行優先；不冒稱已測先研究策略。", "", "## 空白新局三策略", "", "所有策略相同 seed=1、無宗門／技能／傳承、相同起手建設。Era1 每模擬秒最多一次合法 gather；Era2 後只等權威生產／運輸。這是高頻命令策略，不是真實滑鼠自然時間試玩。", "", "| 策略 | 起手後額外投資 | 入築基秒數 | 停點秒數 | 結果 |", "| --- | --- | ---: | ---: | --- |"]
    labels = {"production_first": ("產能優先", "居所／木／礦／草各加一階"), "capacity_first": ("容量優先", "靈力／錢／木／石／草倉各建一座"), "progression_first": ("修行優先", "僅主線所需庫容")}
    for s in data["strategies"]:
        label, investment = labels[s["policy"]]
        lines.append(f"| {label} | {investment} | {s['milestones'][0]['seconds']:g} | {s['seconds']:g} | Era{s['era']} Lv{s['level']}，{s['stop_reason']} |")
    lines += ["", "### 分境停點與等待", "", "每格為完成該境修行／升境後的累計模擬秒；最後一境以 Era6 Lv10 為目標。失敗格保留實際停止時間，空白表示未觀察。", "", "| 策略 | Era1 | Era2 | Era3 | Era4 | Era5 | Era6 |", "| --- | ---: | ---: | ---: | ---: | ---: | ---: |"]
    for s in data["strategies"]:
        stages = {int(row["stage"]): row for row in s["milestones"]}
        cells = [f"{stages[e]['seconds']:g}" + ("（停止）" if not stages[e]["completed"] else "") if e in stages else "—" for e in range(1, 7)]
        lines.append("| " + labels[s["policy"]][0] + " | " + " | ".join(cells) + " |")
    lines += ["", "| 策略 | 採集等待 | 供給等待 | 製作等待 | 修行等待 | 命令數 |", "| --- | ---: | ---: | ---: | ---: | ---: |"]
    for s in data["strategies"]:
        totals = {kind: sum(v for k, v in s["waits_seconds"].items() if k.startswith(kind+":")) for kind in ["gather", "supply", "craft", "training"]}
        lines.append("| " + labels[s["policy"]][0] + " | " + " | ".join(f"{totals[kind]:g}" for kind in totals) + f" | {s['commands']} |")
    lines += ["", "等待欄位是策略當下呼叫時間推進的原因分類；等待製作時修行和供給也持續累積，不能把此分類當作互斥的因果瓶頸或無選擇等待比例。三策略只比較起手分支，後段共用同一按需求投資控制器，不代表搜尋過所有最優策略。"]
    lines += ["", f"本報告 stage_limit={data.get('stage_limit', 6)}。預設回歸只驗至金丹入口；完整 Era1–6 觀察需明確設定 `DAO_ECON_A_FULL_BASELINE=1`。checkpoint 是觀察範圍終點，不代表後段阻擋或通過。不能外推未測範圍時長、主導策略、80–160h 新版節奏或首世完成率。等待按 gather／供給／製作／修行分類保留於 JSON；未實作的研究利用率、設備回本、多世收益不填造數值。", "", "## 首購容量證據", "", "成功購買前的真實 caps 與原價已逐項比對；不把未走到的建築說成可達。", "", "| 建築 | 首購原價 | 實際付款前容量（首份證據） | 證據 |", "| --- | --- | --- |"]
    for b in data["buildings"]:
        w = graph["first_purchase_witnesses"].get(b, [])
        lines.append(f"| {b} | {json.dumps(data['building_costs'][b][0]['costs'], ensure_ascii=False)} | {json.dumps(w[0]['caps_before']) if w else '未證明'} | {'PASS' if w else 'NOT_PROVEN'} |")
    if data.get("purchase_probes"):
        lines += ["", "藏經閣／經書樓另以空白新局的 `optional_purchases` 支線付款驗證；其投資與時間不混入上方三策略。支線的購買命令與付款前容量保留於 runtime JSON 的 purchase_probes。"]
    lines += ["", "起手茅屋需靈力20；舊版非 onboarding 首購仍需金錢30。兩種成本都保留於快照。茅屋每階靈力容量150只在 Era1 有效；後續容量需另建，不把起手紅利永久帶入築基。", "", "## 配方、能力與加工深度", "", "| 配方 | 定義Era | 工序 | 單批投入 → 產出 | 秒 |", "| --- | ---: | --- | --- | ---: |"]
    depths = {}
    recipes = data["catalog"]["recipes"]
    def depth(r, visiting=()):
        if r in depths:
            return depths[r]
        if r in visiting:
            raise ValueError("recipe cycle: " + r)
        choices = [d for k, d in recipes.items() if d.get("product", k) == r]
        depths[r] = min((1+max((depth(i, visiting+(r,)) for i in d["inputs"]), default=0) for d in choices), default=0)
        return depths[r]
    for r, d in recipes.items():
        product = d.get("product", r)
        lines.append(f"| {r} | {int(d['era'])} | {depth(product)} | {json.dumps(d['inputs'], ensure_ascii=False)} → {product}×{d['output']} | {data['durations'][r]} |")
    lines += ["", "工序按配方圖推導，與 rarity／tier／Era 分開；寒銀三金屬是直接採集。中石批量是相同物品替代配方，不增加工序。靈材／銅精在 wood／ore 產線，付款與新產物均在祖島；丹液另有 home／herb 產線替代，herb 需 Era3 開島。", "", "## 解鎖同步與證據邊界", "", "啟用時 migrate_processing 對缺少及既有資源槽一律按當前 Era 同步 unlocked，保留既有數量及 ever_obtained；後續成功升境繼續同步。這修復了先前空白築基首批 RESOURCE_LOCKED 的反例，未更動數值或配方門檻。", "", "runner 以實際賺得的築基快照驗證候選保存拒寫不改 live state、重試保留來源歸檔、重新載入、重複啟用拒絕與缺槽初始化。三策略的首批靈材／銅精及首次築基扣料升層均須通過，不能用手動開槽代替。", ""]
    if graph["coverage"]["downstream"] == "PROVEN":
        lines += [f"本報告三條既定策略均實際到達 Era6 Lv10；首購容量見證 {len(graph['first_purchase_witnesses'])}/{len(data['buildings'])}。PROVEN 僅涵蓋本次 seed／策略／無選修加成的主線範圍，不代表所有隨機種子、所有高階建築升級、最優解或新版平衡已驗。B 尚未開始。", ""]
    else:
        lines += ["後段首購與跨Era容量仍依 coverage 與逐策略停點判讀，不能以內容存在宣稱全主線可通；B 尚未開始。", ""]
    (args.output / "README.md").write_text("\n".join(lines), encoding="utf-8")
    print(json.dumps({"nodes": len(graph["nodes"]), "edges": len(graph["edges"]), "coverage": graph["coverage"], "output": str(args.output)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
