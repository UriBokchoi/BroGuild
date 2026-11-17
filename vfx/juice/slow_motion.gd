class_name SlowMotion
extends Node
## Cámara lenta en el jackpot de la tragaperras (GDD §7): al salir un jackpot
## ([signal EventBus.slot_resolved]), el juego va a [member time_scale] durante [member duration]
## segundos reales. Solo reacciona a la señal: el gameplay no sabe que existe.

## Velocidad del juego durante la cámara lenta.
@export_range(0.05, 1.0, 0.05) var time_scale: float = 0.3
## Segundos reales que dura.
@export_range(0.0, 5.0, 0.05, "suffix:s") var duration: float = 0.9

var _active: bool = false


func _ready() -> void:
	EventBus.slot_resolved.connect(_on_slot_resolved)


func _exit_tree() -> void:
	if _active:
		Engine.time_scale = 1.0


func is_active() -> bool:
	return _active


func _on_slot_resolved(_text_key: StringName, _value: float, jackpot: bool) -> void:
	if not jackpot or _active:
		return
	_active = true
	Engine.time_scale = time_scale
	# En segundos reales, aunque el juego vaya lento (o esté en pausa).
	get_tree().create_timer(duration, true, false, true).timeout.connect(_end)


func _end() -> void:
	_active = false
	Engine.time_scale = 1.0
