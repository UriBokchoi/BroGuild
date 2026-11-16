class_name DamageReporter
extends Node3D
## Avisa por [code]EventBus.enemy_damaged[/code] de cada golpe que recibe la vida de un enemigo, con
## la posición de este nodo: colócalo encima de su cabeza, donde saldrán los números de daño. Así
## todos los enemigos (y el muñeco de práctica) cuentan como enemigos para los efectos.

@export var health: HealthComponent


func _ready() -> void:
	health.damaged.connect(_on_damaged)


func _on_damaged(amount: float, info: DamageInfo) -> void:
	EventBus.enemy_damaged.emit(global_position, amount, info)
