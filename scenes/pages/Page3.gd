extends Control

const MAP_SIZE := Vector2(3000, 3000)
## 進入頁面時，視窗的哪個角對齊地圖的同一角（例如 BOTTOM_RIGHT = 一進來看到地圖右下區域）。
enum MapInitialAnchor { CENTER, TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT }
const MAP_INITIAL_ANCHOR := MapInitialAnchor.BOTTOM_RIGHT
const BASE_FOCUS_MINUTES := 25.0
const BASE_GOLD := 10

const REGION_NAMES: PackedStringArray = [
	"黑暗火山",
	"熱帶森林",
	"寒冰深谷",
	"沙漠",
]

const DURATION_MINUTES: Array = [15.0, 25.0, 45.0]

@onready var _map_viewport: Control = $VBox/MapViewport
@onready var _map_root: Control = $VBox/MapViewport/MapRoot
@onready var _map_bg: ColorRect = $VBox/MapViewport/MapRoot/MapBackground
@onready var _region_buttons: Array[Button] = [
	$VBox/MapViewport/MapRoot/Region0,
	$VBox/MapViewport/MapRoot/Region1,
	$VBox/MapViewport/MapRoot/Region2,
	$VBox/MapViewport/MapRoot/Region3,
]
@onready var _duration_modal: Control = $DurationModal
@onready var _duration_title: Label = $DurationModal/CenterContainer/Panel/Margin/VBox/TitleLabel
@onready var _duration_buttons: GridContainer = $DurationModal/CenterContainer/Panel/Margin/VBox/DurationGrid
@onready var _btn_cancel: Button = $DurationModal/CenterContainer/Panel/Margin/VBox/CancelButton

var _panning: bool = false
var _selected_region: int = -1


func _ready() -> void:
	_map_root.custom_minimum_size = MAP_SIZE
	_map_root.size = MAP_SIZE
	_map_bg.gui_input.connect(_on_map_bg_gui_input)
	for i in _region_buttons.size():
		var rid := i
		_region_buttons[i].pressed.connect(_on_region_pressed.bind(rid))
		_region_buttons[i].text = REGION_NAMES[i]
	for m in DURATION_MINUTES:
		var btn := Button.new()
		btn.text = "%d 分鐘" % int(m)
		btn.custom_minimum_size = Vector2(200, 48)
		btn.pressed.connect(_on_duration_chosen.bind(float(m)))
		_duration_buttons.add_child(btn)
	_btn_cancel.pressed.connect(_close_duration_modal)
	_duration_modal.visible = false
	_map_viewport.resized.connect(_on_map_viewport_resized)
	call_deferred("_apply_initial_map_position")


func _on_map_viewport_resized() -> void:
	_clamp_map()


func _on_map_bg_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_panning = mb.pressed
	elif event is InputEventMouseMotion and _panning:
		var mm := event as InputEventMouseMotion
		_map_root.position += mm.relative
		_clamp_map()


func _apply_initial_map_position() -> void:
	var vs := _map_viewport.size
	match MAP_INITIAL_ANCHOR:
		MapInitialAnchor.TOP_LEFT:
			_map_root.position = Vector2.ZERO
		MapInitialAnchor.TOP_RIGHT:
			_map_root.position = Vector2(vs.x - MAP_SIZE.x, 0.0)
		MapInitialAnchor.BOTTOM_LEFT:
			_map_root.position = Vector2(0.0, vs.y - MAP_SIZE.y)
		MapInitialAnchor.BOTTOM_RIGHT:
			_map_root.position = vs - MAP_SIZE
		MapInitialAnchor.CENTER:
			_map_root.position = (vs - MAP_SIZE) * 0.5
	_clamp_map()


func _clamp_map() -> void:
	var vs := _map_viewport.size
	var p := _map_root.position
	p.x = clampf(p.x, vs.x - MAP_SIZE.x, 0.0)
	p.y = clampf(p.y, vs.y - MAP_SIZE.y, 0.0)
	_map_root.position = p


func _on_region_pressed(region_index: int) -> void:
	_selected_region = region_index
	_duration_title.text = "選擇掛機時長 — %s" % REGION_NAMES[region_index]
	_duration_modal.visible = true


func _on_duration_chosen(minutes: float) -> void:
	Global.next_focus_region_name = REGION_NAMES[_selected_region]
	Global.next_focus_seconds = minutes * 60.0
	Global.next_focus_gold = _gold_for_minutes(minutes)
	_duration_modal.visible = false
	var main := get_tree().get_first_node_in_group("main_scene")
	if main and main.has_method("go_to_focus"):
		main.go_to_focus()


func _gold_for_minutes(minutes: float) -> int:
	return maxi(1, int(round(BASE_GOLD * minutes / BASE_FOCUS_MINUTES)))


func _close_duration_modal() -> void:
	_duration_modal.visible = false
	_selected_region = -1
