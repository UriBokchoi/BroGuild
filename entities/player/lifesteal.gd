class_name Lifesteal
extends Node
## Robo de vida del jugador: cada golpe a un enemigo le cura un tanto por ciento del daño hecho (la
## stat lifesteal). Se entera por EventBus.enemy_hit.

@export var health: HealthComponent
@export var stats: StatsComponent


func _enter_tree() -> void:
	if not EventBus.enemy_hit.is_connected(_on_enemy_hit):
		EventBus.enemy_hit.connect(_on_enemy_hit)


func _on_enemy_hit(_target: Node3D, _health: HealthComponent, _info: DamageInfo, amount: float) -> void:
	var percent := stats.get_value(&"lifesteal")
	if percent > 0.0 and amount > 0.0:
		health.heal(amount * percent / 100.0)
