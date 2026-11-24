class_name PactData
extends Resource
## Un pacto del Gremio: un premio a cambio de una maldición, los dos para el resto de la partida. Los
## dos son modificadores de las stats del jugador. Los valores viven en data/pacts/.

## Claves de traducción de su nombre y de su frase.
@export var name_key: StringName = &""
@export var flavor_key: StringName = &""
## Lo que gana el jugador.
@export var rewards: Array[StatModifier] = []
## Lo que pierde: la maldición.
@export var curses: Array[StatModifier] = []


## El premio y la maldición juntos, en ese orden.
func modifiers() -> Array[StatModifier]:
	var all: Array[StatModifier] = rewards.duplicate()
	all.append_array(curses)
	return all
