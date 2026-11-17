class_name LevelUpController
extends Node
## Al subir de nivel el jugador ([code]EventBus.player_leveled_up[/code]), le ofrece la elección
## ([LevelUpPanel]) y aplica la opción elegida a sus armas o runas. Si sube varios niveles de golpe,
## una elección tras otra. Si no queda nada que ofrecer, no pregunta.

@export var data: LevelUpData
@export var player: Player
@export var panel: LevelUpPanel

## Azar de las opciones. Si no se asigna antes de entrar en el árbol, el flujo de apuestas de
## [code]Rng[/code] (la ruleta del Hito 4 irá encima).
var rng: RandomNumberGenerator

var _catalog: Array[ItemData] = []
var _pending: int = 0


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.GAMBLE)
	_catalog.assign(ResourceDir.load_all(data.weapons_dir, WeaponData))
	_catalog.append_array(ResourceDir.load_all(data.runes_dir, RuneData))
	EventBus.player_leveled_up.connect(_on_leveled_up)
	panel.chosen.connect(_on_chosen)


## Elecciones que quedan por hacer.
func pending() -> int:
	return _pending


## Aplica [param option] al jugador: añade el objeto o lo sube de nivel.
func apply(option: LevelUpOption) -> void:
	if option.item is WeaponData:
		var weapon_data := option.item as WeaponData
		if option.is_new():
			player.weapons.add(weapon_data)
		else:
			player.weapons.get_weapon(weapon_data).set_level(option.level)
	elif option.item is RuneData:
		player.runes.set_level(option.item as RuneData, option.level)


func _on_leveled_up(_level: int) -> void:
	_pending += 1
	if not panel.is_open():
		_offer()


func _on_chosen(option: LevelUpOption) -> void:
	apply(option)
	_pending -= 1
	if _pending > 0:
		# Diferido: la carta pulsada está emitiendo su señal y la siguiente elección la reemplaza.
		_offer.call_deferred()
	else:
		panel.close()


func _offer() -> void:
	var options := LevelUpOffer.build(_catalog, _owned_levels(), data, rng)
	if options.is_empty():
		_pending = 0
		panel.close()
		return
	panel.open(options, player.experience.get_level())


func _owned_levels() -> Dictionary[StringName, int]:
	var levels: Dictionary[StringName, int] = {}
	for weapon: Weapon in player.weapons.get_weapons():
		levels[weapon.data.id] = weapon.level
	for rune: RuneData in player.runes.get_runes():
		levels[rune.id] = player.runes.get_level(rune)
	return levels
