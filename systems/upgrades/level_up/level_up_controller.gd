class_name LevelUpController
extends Node
## Al subir de nivel el jugador ([code]EventBus.player_leveled_up[/code]), le ofrece la elección
## ([LevelUpPanel]) y aplica la opción elegida a sus armas o runas. También cuando se pide una mejora
## gratis ([code]EventBus.upgrade_choice_requested[/code], la tragaperras), con su propio título. Si
## llegan varias de golpe, una elección tras otra, por orden. Si no queda nada que ofrecer, o el
## jugador ha muerto, no pregunta. «Volver a tirar» cobra oro al jugador (cada vez más en la
## partida, [method LevelUpData.reroll_cost_at]) y ofrece otras cartas para la misma elección.
## El doble o nada: con la probabilidad de los datos y la Suerte del jugador
## ([method LevelUpData.double_chance_with]), la mejora apostada sube a la rareza siguiente (se vuelve
## a tirar con su fuerza); si no, esa subida no da nada.

@export var data: LevelUpData
@export var player: Player
@export var panel: LevelUpPanel
## Título de las elecciones gratis (clave de traducción).
@export var free_choice_title_key: StringName = &""

## Azar de las opciones. Si no se asigna antes de entrar en el árbol, el flujo de apuestas de
## [code]Rng[/code].
var rng: RandomNumberGenerator

var _catalog: Array[ItemData] = []
## Elecciones por hacer, por orden: [code]true[/code] si es gratis (no de subir de nivel).
var _queue: Array[bool] = []
## Veces que ha vuelto a tirar en la partida (sube el coste).
var _rerolls: int = 0


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.GAMBLE)
	_catalog.assign(ResourceDir.load_all(data.weapons_dir, WeaponData))
	_catalog.append_array(ResourceDir.load_all(data.runes_dir, RuneData))
	EventBus.player_leveled_up.connect(_on_leveled_up)
	EventBus.upgrade_choice_requested.connect(_on_choice_requested)
	panel.chosen.connect(_on_chosen)
	panel.reroll_requested.connect(_on_reroll_requested)
	panel.double_requested.connect(_on_double_requested)
	_warm_up_panel.call_deferred()


## Elecciones que quedan por hacer.
func pending() -> int:
	return _queue.size()


## Probabilidad de ganar ahora un doble o nada (con la Suerte del jugador).
func double_chance() -> float:
	return data.double_chance_with(player.stats.get_value(&"luck"))


## Lo que cuesta ahora volver a tirar.
func reroll_cost() -> int:
	return data.reroll_cost_at(_rerolls)


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
	# Sin opción: un doble o nada perdido; esta subida no da nada.
	if option:
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
	var cost := reroll_cost()
	var affordable := player.wallet.get_gold() >= cost
	panel.open(options, player.experience.get_level(), title, cost, affordable, double_chance())


func _on_reroll_requested() -> void:
	if _queue.is_empty() or not player.wallet.spend(reroll_cost()):
		return
	_rerolls += 1
	_offer()


func _on_double_requested(option: LevelUpOption) -> void:
	var next := data.next_rarity(option.rarity())
	var won := next != null and rng.randf() < double_chance()
	var result: LevelUpOption = null
	if won:
		result = LevelUpOption.create_upgrade(option.item, option.level, option.item.roll_upgrade(next, rng))
	panel.resolve_double(result)


## Prepara el panel al cargar con una carta de ejemplo (una mejora mítica y un objeto nuevo), para que
## la primera subida de nivel no dé un tirón. Con su propio azar: no toca el de las apuestas.
func _warm_up_panel() -> void:
	if _catalog.is_empty() or data.rarities == null or data.rarities.entries.is_empty():
		return
	var sample_rng := RandomNumberGenerator.new()
	var strongest := data.rarities.entries[-1] as Rarity
	var first := _catalog[0]
	var sample: Array[LevelUpOption] = [
		LevelUpOption.create_upgrade(first, 2, first.roll_upgrade(strongest, sample_rng)),
		LevelUpOption.create(_catalog[-1], 1),
	]
	panel.warm_up(sample)


func _owned_levels() -> Dictionary[StringName, int]:
	var levels: Dictionary[StringName, int] = {}
	for weapon: Weapon in player.weapons.get_weapons():
		levels[weapon.data.id] = weapon.level
	for rune: RuneData in player.runes.get_runes():
		levels[rune.id] = player.runes.get_level(rune)
	return levels
