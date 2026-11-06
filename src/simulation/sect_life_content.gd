class_name SectLifeContent
extends RefCounted
## Immutable content revision 1. Save IDs resolve here; prose is never stored.
const TITLES := ["缺頁經卷", "雲盤失準", "一息之差", "藏書重編", "雲鐘之前", "問道留白"]
const OPENINGS := [
	"藏經樓的窗紙透著晨光，沈照微將一卷散開的舊經移到桌邊。經卷末頁有水痕，幾個字已難辨清；旁邊另有數卷尚未編次。她沒有急著請你補缺，只說初入山門，不必一日讀盡所有典籍。若此刻有暇，可以一起校一行字，也可以先替後來的人整理卷次。",
	"唐溪禾抱著觀雲盤在廊下等候，盤中的刻度與晨鐘相差了一線。她已反覆調過三次，卻不願把差異當作偶然。遠處雲層漸低，鐘聲還未傳來，她問你是否也看見那道變化。重測需要耐心，請人覆核則得說明自己的推論；她想先聽一聽你的看法，再決定如何留下記錄。",
	"論道散後，陸景行仍留在石案旁，將兩份推演並排。他算得很快，結論卻只差一息，誰也沒有足夠證據斷言另一人錯了。他坦言自己習慣先守住已知條件，也願意聽一個能驗的反例。山風翻起竹簡的一角，你可以請他逐步講解，亦可提出另一種邊界，讓這場討論繼續。",
	"藏經樓要為新入門的弟子重編書目。沈照微留出一張空紙，說舊卷的去處大致已清楚，真正難的是替後來的人留下查證的方法。她把筆推到你面前，沒有要求你沿用她的習慣。這一頁既可補足出處，也可記下收藏者的心意；無論選哪一種，都能讓零散的卷冊多一條可循的線索。",
	"雲影已掠過山門，晨鐘卻仍靜著。唐溪禾攤開這些日子留下的記錄，發現同樣的偏差再次出現。她這回沒有急著調整觀雲盤，而是先問你該如何把觀察交給值守同門。廊外一切平安，尚無需要搶救的危難；此刻要做的，只是決定何時提醒旁人，或陪她把尚未明白的部分看得更清楚。",
	"陸景行送來一本留有空白的筆記，說早先那一息之差，至今還沒有唯一答案。他不再急著把每道推演收束成一句定論，倒想知道哪些條件值得繼續問下去。下次大比將有同境修士互相印證，但名次不能替代論證。你可與他再驗一遍邊界，也可互換筆記，把各自仍有疑問的地方留給對方。"
]
const LABELS := [["逐字校勘", "先理卷次"], ["陪她重測", "請師兄覆核"], ["守成請教", "提出反例"], ["補注缺句", "請照微題後記"], ["依實測示警", "留下觀測陪她守候"], ["列出守成邊界", "與景行互換筆記"]]
const RESPONSES := [
	["照微把校定的字夾回原卷，另記下仍存疑的出處。她說今日補出的未必是最後答案，至少下一位讀者已能接著查下去。", "照微循著你排好的卷次找出另一本殘冊，笑說尋書終於不必憑記憶。她在書目留了你的記號，邀你日後再來補全。"],
	["溪禾將兩次刻度並排，終於圈出重複出現的偏差。她沒有立刻改盤，只請你替這一輪觀測署名，等下一次雲起再驗。", "景行讀完記錄後指出一處可重測的條件，溪禾逐項記下。三人約好保留原始刻度，往後若有分歧，先回到共同的證據。"],
	["景行將推演放慢，連自己省去的一步也重新寫明。他說能把條件問清楚，比搶先得到結論更難，這次的疑點先共同記著。", "你的反例讓景行停筆片刻。他沒有急著反駁，反而添上兩條待驗條件，說下回若能重現，這一頁就該由你來續寫。"],
	["你們把出處與查證路徑逐一補齊，未定之處仍留空白。照微將新書目放在入口，讓後來的人能自行找到下一條線索。", "照微起初只寫了幾個字，漸漸記起收藏這些殘卷的理由。後記沒有教人如何取勝，只留下曾有人耐心讀過它們的痕跡。"],
	["值守同門收到有依據的提醒，將巡望時間稍作調整。溪禾把示警前後的刻度都存下，這回她終於不必獨自猜測雲意。", "你們在廊下守到鐘響，替每次細微變化加上記號。溪禾說雖未得到漂亮的結論，願意一起等候的人，已使這頁記錄不同。"],
	["景行把驗算中仍成立的條件與失效處分列兩頁，末尾留了一行空白。他說往後若有新證據，誰先看見，便由誰來續上。", "你們交換筆記，約定不替對方填平所有疑問。大比可以比較當日得失，這本尚未寫完的冊子，則記著各自願意追問的事。"]
]

static func read(id: String, flags: Dictionary) -> Dictionary:
	var sect := SectLife.template_sect(id)
	if sect.is_empty(): return {}
	if sect != "taixu_sect":
		var story: Dictionary = SectLifeCatalog.SECTS[sect].stories[id].duplicate(true)
		if story.has("callback_key"):
			var previous: String = flags.get(story.callback_key, "decline")
			story.text = story.callbacks.get(previous, story.callbacks.decline) + story.text
			story.A = story.a_labels.get(previous, story.a_labels.decline)
		return story
	var i := SectLife.CHAPTERS.find(id)
	if i < 0:
		var d := SectLife.DAILY.find(id)
		return {"title": ["補錄書目", "校雲", "互評筆記"][d], "text": ["照微留了幾卷待編的書目，邀你續上之前的工作。", "溪禾帶來新一輪刻度，想同你再校一次觀雲盤。", "景行翻開筆記，請你看看近日多出的一條疑問。"][d], "A": "一同整理", "B": "留下交談", "decline": "今日先別過", "responses": {"A": "你們補完一段記錄，約好下回再續。", "B": "你們暫放下手邊工作，談起這些日子修行所見。", "decline": "同門收好記錄，說日後得閒再聚。"}}
	var labels: Array = LABELS[i].duplicate()
	var memory := ""
	if i >= 3:
		var previous: String = SectLife.FLAG_KEYS[i - 3]
		var choice: String = flags.get(previous, "decline")
		if choice == "decline": memory = "上回未及一同整理，今日仍可重新談起。"
		elif i == 3:
			memory = "你上回補出的那一句，我已夾在卷中。" if choice == "collate" else "你上回排好的卷次，已省下不少找書功夫。"
			if choice == "order": labels[0] = "列出索引"
		elif i == 4:
			memory = "這裡留著我們直接重測的原始刻度。" if choice == "measure" else "上回共同覆核的條件，今天也逐項核過。"
			if choice == "review": labels[0] = "合議後示警"
		else:
			memory = "上次請教的推演，我又補出了幾個邊界。" if choice == "steady" else "你提出的反例，這次可一同驗算。"
			if choice == "counter": labels[0] = "驗算反例"
	return {"title": TITLES[i], "text": memory + OPENINGS[i], "A": labels[0], "B": labels[1], "decline": "今日先別過", "responses": {"A": RESPONSES[i][0], "B": RESPONSES[i][1], "decline": "你說今日尚有別事，同門便收好案上的記錄，沒有追問。未完的話留待往後再談，也不妨礙下一回相見。"}}
