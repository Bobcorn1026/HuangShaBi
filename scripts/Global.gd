extends Node

## 全域單例：金幣與專注時間。請在「專案 → 專案設定 → Autoload」確認已註冊為 Global。

signal focus_finished(earned_gold: int)

const SAVE_PATH := "user://pomodoro_save.cfg"

var gold: int = 0
## 累積專注秒數（可依需求在專注結束時累加）
var total_focus_time: float = 0.0

## 進入 FocusScene 前由地圖頁設定；讀取後由 FocusScene 重設為預設。
var next_focus_seconds: float = 25.0 * 60.0
var next_focus_gold: int = 10
var next_focus_region_name: String = ""


func _ready() -> void:
	_load_data()


func add_focus_time(seconds: float) -> void:
	total_focus_time += maxf(0.0, seconds)


func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "gold", gold)
	cfg.set_value("player", "total_focus_time", total_focus_time)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Global.save_data failed: %s" % err)


func _load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	gold = int(cfg.get_value("player", "gold", 0))
	total_focus_time = float(cfg.get_value("player", "total_focus_time", 0.0))


func reset_default_focus_session() -> void:
	next_focus_seconds = 25.0 * 60.0
	next_focus_gold = 10
	next_focus_region_name = ""


func complete_focus_session(earned_gold: int, session_seconds: float) -> void:
	gold += earned_gold
	add_focus_time(session_seconds)
	focus_finished.emit(earned_gold)
	save_data()
