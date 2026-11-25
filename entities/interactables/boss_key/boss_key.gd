class_name BossKey
extends Node3D
## Llave del jefe (GDD §6; en el Brosque, una tarjeta de socio): repartida por el nivel, gira y flota
## bajo una columna de luz que se ve de lejos. Se coge con «interactuar»: avisa por
## [signal EventBus.boss_key_collected] (las cuenta el [BossEncounter]) y desaparece con un
## estallido. Con las suficientes, el portal invoca al jefe antes de tiempo.

@export var interactable: Interactable
## Modelo (con su columna de luz) que estalla al cogerla.
@export var visual: Node3D
## Duración del estallido.
@export_range(0.0, 1.0, 0.01, "suffix:s") var pop_time: float = 0.2
## Cuánto crece el modelo en el estallido antes de desaparecer.
@export_range(1.0, 3.0, 0.05) var pop_scale: float = 1.5

var _taken: bool = false


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)


## La coge: avisa y desaparece. Una sola vez.
func take() -> void:
	if _taken:
		return
	_taken = true
	interactable.enabled = false
	EventBus.boss_key_collected.emit()
	PopOut.play(self, visual, pop_scale, pop_time)


func is_taken() -> bool:
	return _taken


func _on_interacted(_by: Node3D) -> void:
	take()
