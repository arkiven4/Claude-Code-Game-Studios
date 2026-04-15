# combat_end_overlay.gd
class_name CombatEndOverlay
extends CanvasLayer

## Shown after combat ends (victory or defeat).
## Displays result message, stats, and a restart button.

signal restart_requested

@onready var _result_label: Label = $CenterContainer/Panel/VBoxContainer/ResultLabel
@onready var _stats_label: Label = $CenterContainer/Panel/VBoxContainer/StatsLabel
@onready var _restart_button: Button = $CenterContainer/Panel/VBoxContainer/RestartButton
@onready var _panel: Panel = $CenterContainer/Panel

var _combat_end_stats: Dictionary = {}

func _ready() -> void:
	hide()
	if _restart_button:
		_restart_button.pressed.connect(_on_restart_pressed)

func show_victory(stats: Dictionary = {}) -> void:
	_combat_end_stats = stats
	if _result_label:
		_result_label.text = "⚔ VICTORY ⚔"
		_result_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	if _restart_button:
		_restart_button.text = "Continue"
	_show_with_stats()

func show_defeat(stats: Dictionary = {}) -> void:
	_combat_end_stats = stats
	if _result_label:
		_result_label.text = "☠ DEFEATED ☠"
		_result_label.add_theme_color_override("font_color", Color(0.8, 0.15, 0.15))
	if _restart_button:
		_restart_button.text = "Try Again"
	_show_with_stats()

func _show_with_stats() -> void:
	if _stats_label:
		var lines: Array[String] = []

		var time: float = _combat_end_stats.get("time_seconds", 0.0)
		var mins: int = int(time) / 60
		var secs: int = int(time) % 60
		lines.append("Time: %d:%02d" % [mins, secs])

		var damage_dealt: float = _combat_end_stats.get("damage_dealt", 0.0)
		lines.append("Damage Dealt: %.0f" % damage_dealt)

		var damage_received: float = _combat_end_stats.get("damage_received", 0.0)
		lines.append("Damage Received: %.0f" % damage_received)

		var kills: int = _combat_end_stats.get("kills", 0)
		lines.append("Enemies Defeated: %d" % kills)

		var switches: int = _combat_end_stats.get("switches", 0)
		if switches > 0:
			lines.append("Character Switches: %d" % switches)

		_stats_label.text = "\n".join(lines)

	show()

	# Animate panel in
	if _panel:
		_panel.modulate.a = 0.0
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(_panel, "modulate:a", 1.0, 0.3)

func _on_restart_pressed() -> void:
	restart_requested.emit()
