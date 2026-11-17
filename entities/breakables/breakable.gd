class_name Breakable
extends Node3D
## Rompible del nivel (como los jarrones de Megabonk): al tocarlo el jugador, se rompe, avisa por
## [signal EventBus.breakable_broken] (el [LootDropper] suelta su botín) y desaparece con un
## pequeño estallido. Los ataques no lo rompen: premia moverse por el mapa. Solo lo detecta el
## jugador (máscara de su [member area]).

## Lo que suelta.
@export var data: BreakableData
## Zona que, al tocarla el jugador, lo rompe.
@export var area: Area3D
## Modelo que estalla al romperse.
@export var visual: Node3D
## Duración del estallido.
@export_range(0.0, 1.0, 0.01, "suffix:s") var pop_time: float = 0.12
## Cuánto crece el modelo en el estallido antes de desaparecer.
@export_range(1.0, 3.0, 0.05) var pop_scale: float = 1.4

var _broken: bool = false


func _ready() -> void:
	area.body_entered.connect(_on_body_entered)


## Lo rompe: avisa con su botín y desaparece. Una sola vez.
func break_open() -> void:
	if _broken:
		return
	_broken = true
	area.set_deferred(&"monitoring", false)
	EventBus.breakable_broken.emit(data, global_position)
	var pop := create_tween()
	pop.tween_property(visual, ^"scale", visual.scale * pop_scale, pop_time * 0.5)
	pop.tween_property(visual, ^"scale", Vector3.ZERO, pop_time * 0.5)
	pop.tween_callback(queue_free)


func is_broken() -> bool:
	return _broken


func _on_body_entered(_body: Node3D) -> void:
	break_open()
