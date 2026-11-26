class_name ArchiveRecorder
extends Node
## Apunta en el Archivo ([code]Save.discover[/code]) lo que se descubre en la partida, escuchando el
## [code]EventBus[/code]: el personaje del jugador al empezar, las armas y runas al conseguirlas
## (también la inicial), los objetos pasivos y los enemigos al derrotarlos (un élite cuenta como su
## enemigo). Solo apunta lo que está en su [ContentCatalog].

## Lo que se puede descubrir.
@export var catalog: ContentCatalog
## Jugador de la partida (su personaje).
@export var player: Player
## Si apunta (sí el de las partidas de verdad, en [code]run_systems.tscn[/code]; los tests lo llevan
## a otro archivo: [code]tests/hooks/pre_run.gd[/code]).
@export var record: bool = false


func _enter_tree() -> void:
	# En _enter_tree para no perder el arma inicial, que llega en el _ready del jugador.
	_connect(EventBus.enemy_died, _on_enemy_died)
	_connect(EventBus.player_item_changed, _on_item_changed)
	_connect(EventBus.player_passive_changed, _on_passive_changed)


func _ready() -> void:
	# Diferido: el nivel le pone al jugador su personaje de serie en su _ready, después de este.
	_discover_character.call_deferred()


## Apunta [param entry] si está en el catálogo. Devuelve si era nuevo.
func discover(entry: Resource) -> bool:
	if not record or catalog == null or entry == null:
		return false
	var category := catalog.category_of(entry)
	if category == null:
		return false
	var id: StringName = entry.get(&"id")
	return Save.discover(category.id, id)


func _connect(event: Signal, handler: Callable) -> void:
	if not event.is_connected(handler):
		event.connect(handler)


func _discover_character() -> void:
	if is_instance_valid(player):
		discover(player.character)


func _on_enemy_died(enemy: Enemy) -> void:
	discover(enemy.data)


func _on_item_changed(item: ItemData, level: int, _max_level: int) -> void:
	if level > 0:
		discover(item)


func _on_passive_changed(item: PassiveItemData, count: int) -> void:
	if count > 0:
		discover(item)
