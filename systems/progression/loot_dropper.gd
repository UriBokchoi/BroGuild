class_name LootDropper
extends Node
## Lo que sueltan los enemigos al morir (escucha [code]EventBus.enemy_died[/code]): una gema con su
## experiencia ([member EnemyStats.xp_reward]) y una moneda con su oro
## ([member EnemyStats.gold_reward]), que vuela sola hacia el jugador. Cofres y probabilidades de
## botín llegarán aquí.

## Dónde caen los recogibles.
@export var field: PickupField
## Recogible de la experiencia.
@export var xp_gem: PickupData
## Recogible del oro.
@export var gold_coin: PickupData


func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)


func _on_enemy_died(enemy: Enemy) -> void:
	_drop(xp_gem, enemy, enemy.xp_reward())
	_drop(gold_coin, enemy, enemy.gold_reward())


func _drop(pickup_data: PickupData, enemy: Enemy, amount: float) -> void:
	if pickup_data and amount > 0.0:
		field.drop(pickup_data, enemy.global_position, amount)
