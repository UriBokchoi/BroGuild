class_name LevelUpController
extends Node
## Al subir de nivel el jugador ([code]EventBus.player_leveled_up[/code]), le ofrece la elección
## ([LevelUpPanel]) y aplica la opción elegida a sus armas o runas. También cuando se pide una mejora
## gratis ([code]EventBus.upgrade_choice_requested[/code], la tragaperras), con su propio título. Si
## llegan varias de golpe, una elección tras otra, por orden. Si no queda nada que ofrecer, o el
## jugador ha muerto, no pregunta.

@export var data: LevelUpData
@export var player: Player
@export var panel: LevelUpPanel
## Título de las elecciones gratis (clave de traducción).
@export var free_choice_title_key: StringName = &""

## Azar de las opciones. Si no se asigna antes de entrar en el árbol, el flujo de apuestas de
## [code]Rng[/code] (la ruleta del Hito 4 irá encima).
var rng: RandomNumberGenerator

var _catalog: Array[ItemData] = []
## Elecciones por hacer, por orden: [code]true[/code] si es gratis (no de subir de nivel).
var _queue: Array[bool] = []


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.GAMBLE)
	_catalog.assign(ResourceDir.load_all(data.weapons_dir, WeaponData))
	_catalog.append_array(ResourceDir.load_all(data.runes_dir, RuneData))
	EventBus.player_leveled_up.connect(_on_leveled_up)
	EventBus.upgrade_choice_requested.connect(_on_choice_requested)
	panel.chosen.connect(_on_chosen)


## Elecciones que quedan por hacer.
func pending() -> int:
	return _queue.size()


## Aplica [param option] al jugador: añade el objeto o lo sube de nivel.
func apply(option: LevelUpOption) -> void:
	if option.item is WeaponData:
		var weapon_data := option.item as WeaponData
		if option.is_new():
			player.weapons.add(weapon_data)
		else:
			player.weapons.get_weapon(weapon_data).add_upgrade(option.upgrade)
	elif option.item is RuneData:
		var rune := option.item as RuneData
		if option.is_new():
			player.runes.add(rune)
		else:
			player.runes.upgrade(rune, option.upgrade)


func _on_leveled_up(_level: int) -> void:
	_enqueue(false, 1)


func _on_choice_requested(count: int) -> void:
	_enqueue(true, count)


func _enqueue(free: bool, count: int) -> void:
	# Muerto, no elige: las gemas que aún volaban no le abren las cartas encima de los resultados.
	if player.health.is_dead():
		return
	for _choice: int in count:
		_queue.append(free)
	if not panel.is_open():
		_offer()


func _on_chosen(option: LevelUpOption) -> void:
	apply(option)
	_queue.pop_front()
	if not _queue.is_empty():
		# Diferido: la carta pulsada está emitiendo su señal y la siguiente elección la reemplaza.
		_offer.call_deferred()
	else:
		panel.close()


func _offer() -> void:
	var weapon_slots := data.clamp_weapon_slots(player.stats.get_int(&"weapon_slots"))
	var rune_slots := data.clamp_rune_slots(player.stats.get_int(&"rune_slots"))
	var luck := player.stats.get_value(&"luck")
	var options := LevelUpOffer.build(
		_catalog, _owned_levels(), data.choices, weapon_slots, rune_slots, data.rarities, rng, luck
	)
	if options.is_empty():
		_queue.clear()
		panel.close()
		return
	var free: bool = _queue.front()
	var title := free_choice_title_key if free else &""
	panel.open(options, player.experience.get_level(), title)


func _owned_levels() -> Dictionary[StringName, int]:
	var levels: Dictionary[StringName, int] = {}
	for weapon: Weapon in player.weapons.get_weapons():
		levels[weapon.data.id] = weapon.level
	for rune: RuneData in player.runes.get_runes():
		levels[rune.id] = player.runes.get_level(rune)
	return levels
