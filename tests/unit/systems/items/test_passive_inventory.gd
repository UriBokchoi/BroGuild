extends GutTest
## PassiveInventory: cada copia de un objeto vuelve a sumar sus modificadores (se apilan), quitar
## una deja las demás, los objetos se guardan en el orden en que llegaron y cada cambio se avisa con
## las copias que quedan.

var _stats: StatsComponent
var _items: PassiveInventory
var _changes: Array = []


func before_each() -> void:
	_changes.clear()
	_stats = StatsComponent.new()
	var offense := OffenseData.new()
	offense.damage = 100.0
	_stats.sources.append(offense)
	var progression := ProgressionData.new()
	_stats.sources.append(progression)
	add_child_autofree(_stats)
	_items = PassiveInventory.new()
	_items.stats = _stats
	_items.item_changed.connect(func(item: PassiveItemData, count: int) -> void: _changes.append([item.id, count]))
	add_child_autofree(_items)


func test_copies_stack() -> void:
	var gloves := _item(&"gloves", &"damage", StatModifier.Kind.PERCENT, 0.1)
	_items.add(gloves)
	assert_almost_eq(_stats.get_value(&"damage"), 110.0, 0.001)
	_items.add(gloves)
	assert_almost_eq(_stats.get_value(&"damage"), 120.0, 0.001, "la segunda copia suma otra vez")
	assert_eq(_items.count(gloves), 2)
	assert_eq(_items.get_items().size(), 1, "un objeto, dos copias")
	assert_eq(_changes, [[&"gloves", 1], [&"gloves", 2]])


func test_removing_a_copy_keeps_the_rest() -> void:
	var socks := _item(&"socks", &"luck", StatModifier.Kind.FLAT, 10.0)
	_items.add(socks)
	_items.add(socks)
	_items.remove(socks)
	assert_almost_eq(_stats.get_value(&"luck"), 10.0, 0.001)
	assert_eq(_items.count(socks), 1)
	_items.remove(socks)
	assert_almost_eq(_stats.get_value(&"luck"), 0.0, 0.001)
	assert_eq(_items.get_items().size(), 0)
	var last: Array = _changes.back()
	assert_eq(last, [&"socks", 0])
	_items.remove(socks)
	assert_eq(_changes.size(), 4, "quitar lo que no lleva no avisa")


func test_keeps_the_order_they_arrived_in() -> void:
	var first := _item(&"first", &"luck", StatModifier.Kind.FLAT, 1.0)
	var second := _item(&"second", &"luck", StatModifier.Kind.FLAT, 1.0)
	_items.add(first)
	_items.add(second)
	_items.add(first)
	assert_eq(_items.get_items(), [first, second] as Array[PassiveItemData])
	assert_eq(_items.total(), 3)


func _item(id: StringName, stat: StringName, kind: StatModifier.Kind, value: float) -> PassiveItemData:
	var item := PassiveItemData.new()
	item.id = id
	item.stat_modifiers = [StatModifier.create(stat, kind, value)] as Array[StatModifier]
	return item
