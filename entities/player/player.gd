class_name Player
extends CharacterBody3D
## Jugador: monta el contexto de movimiento, avanza la máquina de estados y mueve el cuerpo.
## Lleva un personaje ([CharacterData]: su base de stats, su arma inicial, su pasiva y su aspecto).
## Avisa a la interfaz de su vida, su experiencia, su oro, sus armas y runas y su muerte (al morir se
## queda quieto y sus armas paran); al subir de nivel aleja la cámara. Las mecánicas van en sus
## estados y componentes, nunca aquí (CLAUDE.md, «Nunca»).

## Modelo que viste con el color y las piezas de su personaje.
@export var model: CharacterModel
@export var stats: StatsComponent
@export var stamina: StaminaComponent
@export var health: HealthComponent
@export var experience: ExperienceComponent
@export var wallet: WalletComponent
@export var weapons: WeaponInventory
@export var runes: RuneInventory
## Cámara que se aleja con el nivel.
@export var camera: CameraRig
@export var input: PlayerInput
@export var movement: StateMachine
## Sensor de paredes para el salto en pared.
@export var wall_sensor: WallSensor
## Sensor de bordes para el mantle.
@export var ledge_sensor: LedgeSensor
## Estado neutro en el suelo.
@export var ground_state: State
## Estado neutro en el aire.
@export var air_state: State
## Personaje con el que empieza si no se eligió otro ([code]RunState.character[/code]). Vacío:
## stats básicas, sin arma ni pasiva (el nivel decide).
@export var character: CharacterData

## Contexto compartido por los estados de movimiento. Fuera de los estados, solo para leer
## (el panel de depuración, por ejemplo).
var context: MovementContext
## Habilidad pasiva de su personaje (o [code]null[/code]).
var passive: CharacterPassive


func _enter_tree() -> void:
	# Antes de que sus stats se registren (son hijas: entran después), el personaje pasa a ser su
	# base: la vida, la stamina y el movimiento arrancan ya con sus diferencias.
	if RunState.character:
		character = RunState.character
	if character and not stats.base_sets.has(character):
		stats.base_sets.append(character)


func _ready() -> void:
	context = MovementContext.new()
	context.body = self
	context.move = stats.get_resolved(MovementData) as MovementData
	context.stamina = stamina
	context.wall_sensor = wall_sensor
	context.ledge_sensor = ledge_sensor
	context.ground = ground_state
	context.air = air_state
	input.action_pressed.connect(context.record_press)
	movement.start(context)
	health.health_changed.connect(EventBus.player_health_changed.emit)
	health.died.connect(_on_died)
	experience.xp_changed.connect(EventBus.player_xp_changed.emit)
	experience.leveled_up.connect(_on_leveled_up)
	wallet.gold_changed.connect(EventBus.player_gold_changed.emit)
	weapons.weapon_changed.connect(EventBus.player_item_changed.emit)
	runes.rune_changed.connect(EventBus.player_item_changed.emit)
	stats.stat_changed.connect(_on_stat_changed)
	# Vida, experiencia y armas iniciales avisaron en su _ready, antes de estas conexiones: se repite
	# para la interfaz.
	EventBus.player_health_changed.emit(health.get_current(), health.get_maximum())
	EventBus.player_xp_changed.emit(experience.get_xp(), experience.needed(), experience.get_level())
	EventBus.player_gold_changed.emit(wallet.get_gold())
	_announce_loadout()
	if character:
		_equip(character)


## Cambia de personaje en el momento: su base de stats, su aspecto, su arma inicial (quita la del
## anterior) y su pasiva, con la vida llena. La elección se guarda en [code]RunState[/code]: reintentar sigue con
## él.
func set_character(data: CharacterData) -> void:
	if data == null or data == character:
		return
	if character:
		stats.remove_modifiers_from(character)
		_unequip(character)
	character = data
	RunState.character = data
	stats.add_base_set(data)
	_equip(data)
	health.reset()


func _physics_process(delta: float) -> void:
	context.elapsed += delta
	context.wish_direction = input.move_direction()
	context.view_forward = input.view_forward()
	context.slide_held = input.is_held(InputActions.SLIDE)
	context.jump_held = input.is_held(InputActions.JUMP)
	# Cada tick, por si una mejora acaba de cambiar estas stats.
	movement.buffer_time = context.move.input_buffer_time
	movement.committed_end_buffer = context.move.action_end_buffer_time
	movement.physics_update(delta)
	move_and_slide()


## Lleva al jugador a [param feet] (la posición de sus pies) parado y sin el arrastre de la
## interpolación, como si apareciera ahí (teletransportes).
func teleport_to(feet: Vector3) -> void:
	global_position = feet
	velocity = Vector3.ZERO
	reset_physics_interpolation()


## Le da el aspecto, el arma inicial y la pasiva de [param data].
func _equip(data: CharacterData) -> void:
	model.dress(data)
	if data.starting_weapon:
		weapons.add(data.starting_weapon)
	if data.passive:
		passive = data.passive.instantiate() as CharacterPassive
		add_child(passive)
		passive.activate(self)


## Le quita el arma inicial y la pasiva de [param data].
func _unequip(data: CharacterData) -> void:
	if data.starting_weapon:
		weapons.remove(data.starting_weapon)
	if passive:
		stats.remove_modifiers_from(passive)
		# Se queda en el árbol, parada, hasta que se borre al acabar el frame.
		passive.process_mode = Node.PROCESS_MODE_DISABLED
		passive.queue_free()
		passive = null


## Avisa a la interfaz de sus ranuras abiertas y de las armas y runas que ya lleva.
func _announce_loadout() -> void:
	EventBus.player_slots_changed.emit(stats.get_int(&"weapon_slots"), stats.get_int(&"rune_slots"))
	for weapon: Weapon in weapons.get_weapons():
		EventBus.player_item_changed.emit(weapon.data, weapon.level)
	for rune: RuneData in runes.get_runes():
		EventBus.player_item_changed.emit(rune, runes.get_level(rune))


func _on_stat_changed(stat: StringName, _value: float, _previous: float) -> void:
	if stat == &"weapon_slots" or stat == &"rune_slots":
		EventBus.player_slots_changed.emit(stats.get_int(&"weapon_slots"), stats.get_int(&"rune_slots"))


func _on_leveled_up(level: int) -> void:
	camera.level = level
	EventBus.player_leveled_up.emit(level)


## Muerto, se queda quieto y sus armas paran; la pantalla de resultados se entera por el
## [code]EventBus[/code].
func _on_died() -> void:
	set_physics_process(false)
	velocity = Vector3.ZERO
	weapons.process_mode = Node.PROCESS_MODE_DISABLED
	EventBus.player_died.emit()
