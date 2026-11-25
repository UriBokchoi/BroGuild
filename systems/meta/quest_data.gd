class_name QuestData
extends Resource
## Una misión: lo que hay que hacer en una partida para desbloquear algo (un arma o un personaje).
## Se mira al acabar cada partida con lo que apuntó el récord (is_met_by); hasta cumplirla, lo que da
## no sale (el arma, al subir de nivel; el personaje, sin poder elegirse). Los valores viven en
## data/meta/quests.tres.

## Identificador estable (el perfil guarda las cumplidas por él).
@export var id: StringName = &""
## Clave de traducción de lo que hay que hacer.
@export var description_key: StringName = &""
## Lo que desbloquea: un [WeaponData] o un [CharacterData].
@export var reward: Resource

@export_group("condition")
## Con este personaje (vacío: cualquiera).
@export var character: CharacterData
## Con esta arma a [member item_level] o más (vacío: ninguna).
@export var item: WeaponData
@export_range(0, 100, 1) var item_level: int = 0
## Llegando a este nivel del jugador (0: el que sea).
@export_range(0, 1000, 1) var player_level: int = 0
## Ganando la partida.
@export var needs_win: bool = false


## ¿La partida de [param record] la cumple?
func is_met_by(record: RunRecord) -> bool:
	if character and record.character_id != character.id:
		return false
	if item and record.weapons.get(String(item.id), 0) < item_level:
		return false
	if record.player_level < player_level:
		return false
	return record.won or not needs_win


## ¿Desbloquea [param content]? (El mismo recurso o uno del mismo tipo con su id.)
func unlocks(content: Resource) -> bool:
	if reward == null or content == null:
		return false
	if reward == content:
		return true
	return reward.get_script() == content.get_script() and reward.get(&"id") == content.get(&"id")
