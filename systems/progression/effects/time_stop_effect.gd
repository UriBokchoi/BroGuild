class_name TimeStopEffect
extends PickupEffect
## Parar el tiempo (power-up): los enemigos y sus disparos se quedan quietos los segundos que vale
## el recogible ([method EnemySwarm.freeze_for]); se les puede seguir golpeando. El filtro azul lo
## pone [TimeStopFilter] al enterarse ([signal EventBus.time_stop_changed]).

## Enemigos que se paran.
@export var swarm: EnemySwarm


func apply(amount: float) -> void:
	swarm.freeze_for(amount)
