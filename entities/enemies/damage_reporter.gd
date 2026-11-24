class_name DamageReporter
extends Node3D
## Avisa de cada golpe que recibe un enemigo, con su posición (va encima de la cabeza, donde salen
## los números de daño) y de a quién se golpeó, para los efectos de los objetos. Así cualquier
## enemigo, y el muñeco de práctica, cuenta para todo eso.

@export var health: HealthComponent


func _ready() -> void:
	health.damaged.connect(_on_damaged)


func _on_damaged(amount: float, info: DamageInfo) -> void:
	EventBus.enemy_damaged.emit(global_position, amount, info)
	EventBus.enemy_hit.emit(get_parent() as Node3D, health, info, amount)
