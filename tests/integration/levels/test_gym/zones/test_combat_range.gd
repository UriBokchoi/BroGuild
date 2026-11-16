extends GutTest
## Zona de combate del gimnasio: la vuelta lleva adonde diga quien la coloca, el recogedor de
## caídas devuelve a la llegada y los muñecos cuentan como enemigos.

const RangeScene := preload("res://levels/test_gym/zones/combat_range.tscn")

var _range: CombatRange
var _exit: Marker3D


func before_each() -> void:
	_exit = Marker3D.new()
	add_child_autofree(_exit)
	_range = RangeScene.instantiate() as CombatRange
	_range.exit_destination = _exit
	add_child_autofree(_range)


func test_exit_goes_where_the_level_says() -> void:
	assert_same(_range.exit_teleporter.destination, _exit)


func test_falling_returns_to_the_arrival() -> void:
	var catcher := _range.get_node(^"FallCatcher") as Teleporter
	assert_same(catcher.destination, _range.arrival)


func test_has_dummies_that_count_as_enemies() -> void:
	var dummies := _range.get_node(^"Dummies").get_children()
	assert_gt(dummies.size(), 0)
	for dummy: Node in dummies:
		var hurtbox := dummy.get_node(^"Hurtbox") as HurtboxComponent
		assert_eq(hurtbox.collision_layer, PhysicsLayers.mask(PhysicsLayers.ENEMY_HURTBOX))
