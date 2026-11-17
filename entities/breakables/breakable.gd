class_name Breakable
extends Node3D
## Rompible del nivel (como los jarrones de Megabonk): se rompe al usarlo con «interactuar» (su
## [member interactable], con su aviso: «Romper la calavera»…). Avisa por
## [signal EventBus.breakable_broken] (el [LootDropper] suelta su botín) y desaparece con un pequeño
## estallido.

## Lo que suelta.
@export var data: BreakableData
## Lo que se usa con «interactuar» para romperlo.
@export var interactable: Interactable
## Modelo que estalla al romperse.
@export var visual: Node3D
## Duración del estallido.
@export_range(0.0, 1.0, 0.01, "suffix:s") var pop_time: float = 0.12
## Cuánto crece el modelo en el estallido antes de desaparecer.
@export_range(1.0, 3.0, 0.05) var pop_scale: float = 1.4

var _broken: bool = false


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)


## Lo rompe: avisa con su botín y desaparece. Una sola vez.
func break_open() -> void:
	if _broken:
		return
	_broken = true
	interactable.enabled = false
	EventBus.breakable_broken.emit(data, global_position)
	var pop := create_tween()
	pop.tween_property(visual, ^"scale", visual.scale * pop_scale, pop_time * 0.5)
	pop.tween_property(visual, ^"scale", Vector3.ZERO, pop_time * 0.5)
	pop.tween_callback(queue_free)


func is_broken() -> bool:
	return _broken


func _on_interacted(_by: Node3D) -> void:
	break_open()
