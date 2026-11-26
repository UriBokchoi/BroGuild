class_name QuestData
extends Resource
## Una misión: lo que hay que hacer en una partida para desbloquear algo (armas o personajes).
## Se mira al acabar cada partida con lo que apuntó el récord (is_met_by); hasta cumplirla, lo que da
## no sale (el arma, al subir de nivel; el personaje, sin poder elegirse). Los valores viven en
## data/meta/quests.tres.

## Identificador estable (el perfil guarda las cumplidas por él).
@export var id: StringName = &""
## Clave de traducción de lo que hay que hacer.
@export var description_key: StringName = &""
## Lo que desbloquea: [WeaponData] o [CharacterData] (el primero es el que se ve en «Misiones»).
@export var rewards: Array[Resource] = []

@export_group("condition")
## Con este personaje (vacío: cualquiera).
@export var character: CharacterData
## Con esta arma a [member item_level] o más (vacío: ninguna).
@export var item: WeaponData
@export_range(0, 100, 1) var item_level: int = 0
## Llegando a este nivel del jugador (0: el que sea).
@export_range(0, 1000, 1) var player_level: int = 0
## Derrotando al menos a estos enemigos en la partida (0: los que sean).
@export_range(0, 100000, 1, "or_greater") var kills: int = 0
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
	if record.kills < kills:
		return false
	return record.won or not needs_win


## ¿Desbloquea [param content]? (El mismo recurso o uno del mismo tipo con su id.)
func unlocks(content: Resource) -> bool:
	if content == null:
		return false
	for reward: Resource in rewards:
		if reward == content:
			return true
		var same_kind: bool = reward != null and reward.get_script() == content.get_script()
		if same_kind and reward.get(&"id") == content.get(&"id"):
			return true
	return false


## Los nombres de lo que desbloquea, traducidos y juntos («Brujo y Mal de ojo»).
func reward_names() -> String:
	var names := PackedStringArray()
	for reward: Resource in rewards:
		if reward:
			names.append(tr(reward.get(&"name_key") as StringName))
	return (" %s " % tr(&"QUESTS_AND")).join(names)
