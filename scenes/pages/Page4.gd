extends Control

# -----------------------------
# 配置常量
# -----------------------------
# 按鈕字體的最小字級與最大字級（自動縮放時的邊界）
const MODE_BUTTON_FONT_MIN_SIZE := 14
const MODE_BUTTON_FONT_MAX_SIZE := 34
# 文字在按鈕內左右預留的額外空間（像素）
const MODE_BUTTON_TEXT_PADDING_X := 24.0
const OPTION_BUTTON_MIN_HEIGHT := 128
 # 選項按鈕預設字級（動態產生時套用）
const OPTION_BUTTON_FONT_SIZE := 32
const DRAWER_TITLE_FONT_SIZE := 128
const DRAWER_SUBTITLE_FONT_SIZE := 64

# 預載入要套用的字體資源（對應 scenes/pages/Page4.tscn 中的 ExtResource id 3_8kico）
const OPTION_FONT := preload("res://asset/font/Cubic_11.ttf")

# 各種升級模式的靜態資料：包含標題、子標題與選項文字
const UPGRADE_MODES := {
	"restart": {
		"title": "重新出發",
		"subtitle": "重新開始時，先把開局節奏調順。",
		"items": [
			"開局金幣 +10",
			"基礎回復 +1",
			"初始冷卻 -5%",
		],
	},
	"milestone": {
		"title": "里程碑",
		"subtitle": "達成目標後解鎖永久型加成。",
		"items": [
			"關卡完成獎勵 +15%",
			"特殊事件解鎖 +1",
			"里程碑點數加倍",
		],
	},
	"tool": {
		"title": "工具",
		"subtitle": "強化手上的工具，提升操作效率。",
		"items": [
			"工具效率 +12%",
			"工具冷卻 -8%",
			"工具耐久 +1",
		],
	},
	"level": {
		"title": "等級",
		"subtitle": "提高等級上限，逐步開放更多能力。",
		"items": [
			"等級上限 +1",
			"升級需求 -10%",
			"升級獎勵 +1",
		],
	},
}


# 快取場景中常用節點的參考，避免在運行時反覆查找
@onready var _menu_overlay: PanelContainer = $PageContent/MenuOverlay
@onready var _drawer_title: Label = $PageContent/MenuOverlay/MenuContent/HeaderBar/DrawerTitle
@onready var _drawer_subtitle: Label = $PageContent/MenuOverlay/MenuContent/DrawerSubtitle
@onready var _option_list: VBoxContainer = $PageContent/MenuOverlay/MenuContent/OptionList
@onready var _menu_background: Panel = $PageContent/MenuOverlay/MenuContent/MenuBackground

# 四個頂部模式按鈕的節點集合，方便透過字串找到對應按鈕
@onready var _mode_buttons := {
	"restart": $RestartButton,
	"milestone": $MilestoneButton,
	"tool": $ToolButton,
	"level": $LevelButton,
}

# 儲存菜單動畫的 Tween 物件與初始位置
var _menu_tween: Tween
var _menu_base_offset_top: float  # 菜單隱藏時的位置（初始值，通常在屏幕下方）
var _menu_shown_offset_top: float  # 菜單顯示時的目標位置
# 儲存各按鈕的原始文字，以便隱藏/顯示時使用
var _button_original_texts: Dictionary = {}


func _ready() -> void:
	# 初始化：記錄菜單的隱藏位置（初始位置）與計算顯示位置
	_menu_base_offset_top = _menu_overlay.offset_top  # 1920（屏幕下方）
	_menu_shown_offset_top = 0.0  # 菜單顯示時應該在頂部（相對於 PageContent）

	# 預設隱藏菜單
	_menu_overlay.visible = false
	
	# 為四個模式按鈕設定透明背景樣式
	_setup_mode_buttons_style()
	
	# 儲存各按鈕的原始文字
	for mode in _mode_buttons.keys():
		var button: Button = _mode_buttons[mode] as Button
		if button != null:
			_button_original_texts[mode] = button.text
	
	# 信號連接已在場景編輯器中設定，無需在此重複連接


func _setup_mode_buttons_style() -> void:
	# 建立透明樣式 (StyleBoxEmpty)
	var transparent_style: StyleBoxEmpty = StyleBoxEmpty.new()
	
	# 為四個按鈕套用透明樣式
	for mode in _mode_buttons.keys():
		var button: Button = _mode_buttons[mode] as Button
		if button != null:
			button.add_theme_stylebox_override("normal", transparent_style)
			button.add_theme_stylebox_override("pressed", transparent_style)
			button.add_theme_stylebox_override("hover", transparent_style)
			button.add_theme_stylebox_override("focus", transparent_style)


# 隱藏所有頂部按鈕的文字
func _hide_mode_buttons_text() -> void:
	for mode in _mode_buttons.keys():
		var button: Button = _mode_buttons[mode] as Button
		if button != null:
			button.disabled = true  # 禁用按鈕以避免在文字隱藏時誤點擊
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE


# 恢復所有頂部按鈕的原始文字
func _show_mode_buttons_text() -> void:
	for mode in _mode_buttons.keys():
		var button: Button = _mode_buttons[mode] as Button
		if button != null and _button_original_texts.has(mode):
			button.text = _button_original_texts[mode]
			button.disabled = false  # 啟用按鈕
			button.mouse_filter = Control.MOUSE_FILTER_PASS


func _on_mode_button_pressed(mode: String) -> void:
	# 使用動畫切換到指定的模式
	_show_mode(mode, true)


func _show_mode(mode: String, animate: bool) -> void:
	# 根據模式名稱載入對應的資料並更新菜單內容
	if not UPGRADE_MODES.has(mode):
		return
	var data: Dictionary = UPGRADE_MODES[mode]
	_drawer_title.text = data["title"]
	_drawer_subtitle.text = data["subtitle"]
	# 重新建立選項清單（動態產生按鈕）
	_refresh_option_list(data["items"])
	if animate:
		_play_menu_animation_show()
	else:
		# 直接顯示菜單，不播放動畫
		_hide_mode_buttons_text()
		_menu_overlay.visible = true
		_menu_overlay.offset_top = _menu_shown_offset_top


func _refresh_option_list(items: Array) -> void:
	# 清空舊的選項並以新的資料建立按鈕
	for child in _option_list.get_children():
		child.queue_free()

	for item in items:
		var option_button := Button.new()
		# 套用指定的字體資源（3_8kico）到此按鈕
		option_button.add_theme_font_override("font", OPTION_FONT)
		option_button.text = str(item)
		# 設定選項按鈕的最小高度，避免過小難以點擊
		#option_button.custom_minimum_size = Vector2(0, OPTION_BUTTON_MIN_HEIGHT)
		# 設定選項按鈕字級，讓抽屜內文字更大易讀
		option_button.add_theme_font_size_override("font_size", OPTION_BUTTON_FONT_SIZE)
		option_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		option_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_option_list.add_child(option_button)


func _play_menu_animation_show() -> void:
	# 若已有進行中的 tween，先終止再建立新的動畫
	if _menu_tween != null and _menu_tween.is_valid():
		_menu_tween.kill()

	# 隱藏頂部按鈕的文字
	_hide_mode_buttons_text()
	
	# 顯示菜單並從下方向上彈出
	_menu_overlay.visible = true
	_menu_overlay.offset_top = _menu_base_offset_top  # 從隱藏位置開始
	_menu_overlay.modulate.a = 0.0
	_menu_tween = create_tween()
	_menu_tween.set_trans(Tween.TRANS_QUAD)
	_menu_tween.set_ease(Tween.EASE_OUT)
	_menu_tween.parallel().tween_property(_menu_overlay, "offset_top", _menu_shown_offset_top, 0.3)
	_menu_tween.parallel().tween_property(_menu_overlay, "modulate:a", 1.0, 0.3)
	await _menu_tween.finished


func _play_menu_animation_hide() -> void:
	# 若已有進行中的 tween，先終止再建立新的動畫
	if _menu_tween != null and _menu_tween.is_valid():
		_menu_tween.kill()

	# 菜單從上向下滑出並隱藏，回到屏幕下方
	_menu_tween = create_tween()
	_menu_tween.set_trans(Tween.TRANS_QUAD)
	_menu_tween.set_ease(Tween.EASE_IN)
	_menu_tween.parallel().tween_property(_menu_overlay, "offset_top", _menu_base_offset_top, 0.3)
	_menu_tween.parallel().tween_property(_menu_overlay, "modulate:a", 0.0, 0.3)
	await _menu_tween.finished
	_menu_overlay.visible = false
	
	# 菜單隱藏後，恢復頂部按鈕的文字
	_show_mode_buttons_text()


func _on_close_menu() -> void:
	# 關閉菜單
	_play_menu_animation_hide()
