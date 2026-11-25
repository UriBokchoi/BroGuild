class_name StageDebugSection
extends DebugSection
## Fases de un nivel con tiers: en cuál se está y un botón para pasar ya a la siguiente, sin vencer
## al jefe y aunque la partida acabara en esta. Para probar los tiers y la arena final. En un nivel
## sin tiers no sale.

var _stages: LevelStages
var _stage: Label


func setup(_player: Player) -> void:
	_stages = get_tree().get_first_node_in_group(LevelStages.GROUP) as LevelStages
	visible = _stages != null
	if _stages == null:
		return
	add_title("stages")
	_stage = add_value_row("stage")
	add_child(make_button("next stage", _stages.skip))


func refresh() -> void:
	if _stages:
		_stage.text = "%d / %d" % [_stages.get_index_playing() + 1, _stages.get_stage_count()]
