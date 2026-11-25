class_name StreakMeter
extends Label
## La racha en el HUD mientras dura: «Racha ×3 · 18 s». Da un salto al subir de nivel.

var _multiplier: float = 0.0


func _enter_tree() -> void:
	if not EventBus.streak_changed.is_connected(_on_streak_changed):
		EventBus.streak_changed.connect(_on_streak_changed)


func _ready() -> void:
	visible = false


func _on_streak_changed(multiplier: float, seconds_left: float) -> void:
	visible = multiplier > 0.0
	if not visible:
		_multiplier = 0.0
		return
	text = tr(&"HUD_STREAK") % [StatFormat.number(multiplier), ceili(seconds_left)]
	if _multiplier > 0.0 and multiplier > _multiplier:
		UiMotion.pop(self)
	_multiplier = multiplier
