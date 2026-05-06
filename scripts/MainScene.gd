extends Control

const START_MENU := "res://scenes/ui/StartMenu.tscn"
const FOCUS_SCENE := "res://scenes/game/FocusScene.tscn"

## 索引 0～4 對應按鈕 1～5；第 3 頁為主選單場景。
const PAGE_SCENES: PackedStringArray = [
	"res://scenes/pages/Page1.tscn",
	"res://scenes/pages/Page2.tscn",
	START_MENU,
	"res://scenes/pages/Page4.tscn",
	"res://scenes/pages/Page5.tscn",
]

const HOME_PAGE_INDEX := 2

@onready var _content: Control = $MainVBox/ContentContainer
@onready var _bottom_nav: HBoxContainer = $MainVBox/BottomNav

var _nav_button_group: ButtonGroup
var _nav_buttons: Array[Button] = []
var _current_page_index: int = HOME_PAGE_INDEX
var _focus_mode: bool = false


func _ready() -> void:
	add_to_group("main_scene")
	_nav_button_group = ButtonGroup.new()
	_nav_button_group.allow_unpress = false
	for i in PAGE_SCENES.size():
		var btn := _bottom_nav.get_node_or_null("NavButton%d" % (i + 1)) as Button
		if btn == null:
			push_error("MainScene: missing NavButton%d" % (i + 1))
			continue
		btn.toggle_mode = true
		btn.button_group = _nav_button_group
		btn.pressed.connect(_on_nav_pressed.bind(i))
		_nav_buttons.append(btn)
	_go_to_page(HOME_PAGE_INDEX)


func go_to_start_menu() -> void:
	_focus_mode = false
	_bottom_nav.visible = true
	_go_to_page(HOME_PAGE_INDEX)


func go_to_focus() -> void:
	_focus_mode = true
	_bottom_nav.visible = false
	_switch_content_to(FOCUS_SCENE)


func _on_nav_pressed(page_index: int) -> void:
	if _focus_mode:
		return
	_go_to_page(page_index)


func _go_to_page(page_index: int) -> void:
	if page_index < 0 or page_index >= PAGE_SCENES.size():
		return
	_current_page_index = page_index
	if page_index < _nav_buttons.size():
		_nav_buttons[page_index].button_pressed = true
	_switch_content_to(PAGE_SCENES[page_index])


func _switch_content_to(path: String) -> void:
	for c in _content.get_children():
		c.queue_free()
	var ps: PackedScene = load(path) as PackedScene
	if ps == null:
		push_error("MainScene: failed to load %s" % path)
		return
	_content.add_child(ps.instantiate())
