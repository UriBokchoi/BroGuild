@abstract
class_name CharacterPassive
extends Node
## Habilidad pasiva de un personaje ([member CharacterData.passive]): un nodo que el [Player] añade
## al elegir el personaje ([method activate]) y quita al cambiarlo. Escucha lo que necesite y cambia
## stats con modificadores suyos, que se quitan solos al irse. Sus números van en [code]@export[/code]
## de su escena.

## Jugador que la tiene.
var player: Player


## La pone en marcha en [param owner_player] (ya en el árbol).
func activate(owner_player: Player) -> void:
	player = owner_player
	_activated()


func _exit_tree() -> void:
	if player and is_instance_valid(player.stats):
		player.stats.remove_modifiers_from(self)


## Recién activada: conecta lo que necesite y aplica su efecto inicial.
@abstract func _activated() -> void


## Cambia su modificador de [param stat] por uno nuevo de [param kind] y [param value] (0 = quitarlo).
func _set_bonus(stat: StringName, kind: StatModifier.Kind, value: float) -> void:
	player.stats.remove_modifiers_from(self)
	if not is_zero_approx(value):
		player.stats.add_modifier(StatModifier.create(stat, kind, value), self)
