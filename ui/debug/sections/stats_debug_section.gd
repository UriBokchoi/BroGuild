class_name StatsDebugSection
extends DebugSection
## Todas las stats del jugador, con su valor y su base, y botones que les aplican
## modificadores en % como haría una mejora. «reset» quita los que ha puesto este panel.
## Una stat nueva aparece aquí sola.

## Porcentaje que suma o resta cada botón (0.1 = 10 %).
@export_range(0.01, 1.0, 0.01) var percent_step: float = 0.1

var _stats: StatsComponent
var _values: Dictionary[StringName, Label] = {}


func setup(player: Player) -> void:
	_stats = player.stats
	add_title("stats")
	var grid := GridContainer.new()
	grid.columns = 4
	var step_percent := roundi(percent_step * 100.0)
	for stat: StringName in _stats.get_stats():
		var name_label := make_label(stat)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(name_label)
		_values[stat] = make_label("")
		grid.add_child(_values[stat])
		grid.add_child(make_button("%+d%%" % -step_percent, nudge.bind(stat, -1)))
		grid.add_child(make_button("%+d%%" % step_percent, nudge.bind(stat, 1)))
	add_child(grid)
	add_child(make_button("reset", reset))


func refresh() -> void:
	for stat: StringName in _values:
		_values[stat].text = "%.2f (base %.2f)" % [_stats.get_value(stat), _stats.get_base(stat)]


## Aplica a [param stat] un modificador de ±[member percent_step], como haría una mejora.
func nudge(stat: StringName, direction: int) -> void:
	var modifier := StatModifier.create(stat, StatModifier.Kind.PERCENT, percent_step * direction)
	_stats.add_modifier(modifier, self)


## Quita todos los modificadores que ha puesto este panel.
func reset() -> void:
	_stats.remove_modifiers_from(self)
