@abstract
class_name PickupEffect
extends Node
## Lo que hace un recogible especial al recogerlo (imán, comida, bomba…): escucha
## [code]EventBus.pickup_collected[/code] y, si la recompensa es su [member reward], aplica su
## efecto con lo que vale el recogible. Añadir un recogible especial es crear su [PickupData] con
## una recompensa nueva y un efecto (un script que herede de este) en [RunSystems].

## Recompensa de los recogibles que activan este efecto.
@export var reward: StringName = &""


func _enter_tree() -> void:
	if not EventBus.pickup_collected.is_connected(_on_pickup_collected):
		EventBus.pickup_collected.connect(_on_pickup_collected)


## Aplica el efecto de un recogible que vale [param amount].
@abstract func apply(amount: float) -> void


func _on_pickup_collected(kind: StringName, amount: float) -> void:
	if kind == reward:
		apply(amount)
