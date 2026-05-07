extends Control

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

@onready var _drawer: PanelContainer = $PageContent/DrawerHost/UpgradeDrawer
@onready var _drawer_title: Label = $PageContent/DrawerHost/UpgradeDrawer/DrawerContent/DrawerTitle
@onready var _drawer_subtitle: Label = $PageContent/DrawerHost/UpgradeDrawer/DrawerContent/DrawerSubtitle
@onready var _option_list: VBoxContainer = $PageContent/DrawerHost/UpgradeDrawer/DrawerContent/OptionList
@onready var _mode_buttons := {
	"restart": $PageContent/ModeBar/RestartButton,
	"milestone": $PageContent/ModeBar/MilestoneButton,
	"tool": $PageContent/ModeBar/ToolButton,
	"level": $PageContent/ModeBar/LevelButton,
}

var _drawer_base_offset_top: float
var _drawer_tween: Tween


func _ready() -> void:
	_drawer_base_offset_top = _drawer.offset_top
	for mode in _mode_buttons.keys():
		var button := _mode_buttons[mode] as Button
		if button != null:
			button.pressed.connect(_on_mode_button_pressed.bind(mode))
	_show_mode("restart", false)


func _on_mode_button_pressed(mode: String) -> void:
	_show_mode(mode, true)


func _show_mode(mode: String, animate: bool) -> void:
	if not UPGRADE_MODES.has(mode):
		return
	var data: Dictionary = UPGRADE_MODES[mode]
	_drawer_title.text = data["title"]
	_drawer_subtitle.text = data["subtitle"]
	_refresh_option_list(data["items"])
	if animate:
		_play_drawer_animation()
	else:
		_drawer.offset_top = _drawer_base_offset_top
		_drawer.modulate.a = 1.0


func _refresh_option_list(items: Array) -> void:
	for child in _option_list.get_children():
		child.queue_free()

	for item in items:
		var option_button := Button.new()
		option_button.text = str(item)
		option_button.custom_minimum_size = Vector2(0, 44)
		option_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		option_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_option_list.add_child(option_button)


func _play_drawer_animation() -> void:
	if _drawer_tween != null and _drawer_tween.is_valid():
		_drawer_tween.kill()

	_drawer.offset_top = _drawer_base_offset_top - 36.0
	_drawer.modulate.a = 0.0
	_drawer_tween = create_tween()
	_drawer_tween.set_trans(Tween.TRANS_QUAD)
	_drawer_tween.set_ease(Tween.EASE_OUT)
	_drawer_tween.parallel().tween_property(_drawer, "offset_top", _drawer_base_offset_top, 0.18)
	_drawer_tween.parallel().tween_property(_drawer, "modulate:a", 1.0, 0.18)