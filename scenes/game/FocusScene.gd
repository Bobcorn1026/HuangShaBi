extends Control

## 專注計時；時長與報酬由 Global（地圖頁選擇）決定，預設 25 分鐘 / 10 金幣。

@onready var _timer_label: Label = $VBoxContainer/TimerLabel
@onready var _progress: ProgressBar = $VBoxContainer/ProgressBar
@onready var _character_root: Node2D = $CharacterAnim
@onready var _character_sprite: AnimatedSprite2D = $CharacterAnim/AnimatedSprite2D


var _session_seconds: float = 25.0 * 60.0
var _earned_gold: int = 10
var _remaining: float = 25.0 * 60.0


func _ready() -> void:
	_session_seconds = Global.next_focus_seconds
	_earned_gold = Global.next_focus_gold
	Global.reset_default_focus_session()
	_remaining = _session_seconds
	_progress.max_value = _session_seconds
	_progress.value = 0.0
	_update_ui()
	_character_root.visible = true
	_character_sprite.stop()
	_character_sprite.play("new_animation")


func _process(delta: float) -> void:
	if _remaining <= 0.0:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		_remaining = 0.0
		_finish_session()
	_update_ui()


func _finish_session() -> void:
	set_process(false)
	Global.complete_focus_session(_earned_gold, _session_seconds)
	var main := get_tree().get_first_node_in_group("main_scene")
	if main and main.has_method("go_to_start_menu"):
		main.go_to_start_menu()


func _update_ui() -> void:
	var total_sec := int(ceil(_remaining))
	var m := int(total_sec / 60.0)
	var s := total_sec % 60
	_timer_label.text = "%02d:%02d" % [m, s]
	_progress.value = _session_seconds - _remaining
