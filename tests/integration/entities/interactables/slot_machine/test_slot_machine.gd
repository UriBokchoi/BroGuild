extends GutTest
## Tragaperras: cobra su coste, avisa de lo que sale y, cuando paran los rodillos, da el premio como
## recompensa y lo anuncia; mientras gira no se puede volver a jugar; sin oro no gira; cada uso la
## encarece. Con datos de prueba de un solo símbolo (siempre jackpot de oro ×10) y rodillos rápidos.

const MachineScene := preload("res://entities/interactables/slot_machine/slot_machine.tscn")
const COIN_ICON := preload("res://assets/textures/icons/slots/coin.svg")

var _machine: SlotMachine
var _wallet: WalletComponent
var _rewards: Array[float] = []
var _texts: Array[StringName] = []


func before_each() -> void:
	_rewards.clear()
	_texts.clear()
	EventBus.pickup_collected.connect(_on_reward)
	EventBus.slot_resolved.connect(_on_resolved)
	var stats := StatsComponent.new()
	var progression := ProgressionData.new()
	progression.currency_gain = 100.0
	stats.sources.append(progression)
	add_child_autofree(stats)
	_wallet = WalletComponent.new()
	_wallet.stats = stats
	add_child_autofree(_wallet)
	_machine = MachineScene.instantiate() as SlotMachine
	_machine.data = _gold_only_data()
	add_child_autofree(_machine)


func after_each() -> void:
	EventBus.pickup_collected.disconnect(_on_reward)
	EventBus.slot_resolved.disconnect(_on_resolved)


func test_pays_spins_and_gives_the_prize_when_the_reels_stop() -> void:
	_wallet.add(100.0)
	watch_signals(EventBus)
	assert_true(_machine.play(_wallet))
	assert_eq(_wallet.get_gold(), 90.0, "cobra 10")
	assert_signal_emitted(EventBus, "slot_spun")
	assert_true(_machine.is_spinning())
	assert_false(_machine.play(_wallet), "girando no se vuelve a jugar")
	assert_eq(_rewards.size(), 0, "aún no hay premio")
	await wait_seconds(_machine.data.total_time() + 0.1)
	assert_false(_machine.is_spinning())
	assert_eq(_rewards, [100.0] as Array[float], "jackpot: 10 × lo que costó")
	assert_eq(_texts, [&"SLOT_JACKPOT_GOLD"] as Array[StringName])


func test_without_gold_it_does_not_spin() -> void:
	_wallet.add(5.0)
	assert_false(_machine.play(_wallet))
	assert_eq(_wallet.get_gold(), 5.0)
	assert_false(_machine.is_spinning())
	assert_eq(_texts, [&"SLOT_NOT_ENOUGH_GOLD"] as Array[StringName])


func test_each_use_makes_it_pricier() -> void:
	_wallet.add(1000.0)
	var first := _machine.get_cost()
	_machine.play(_wallet)
	assert_gt(_machine.get_cost(), first)


## Un solo símbolo (siempre tres iguales): el jackpot da 10 veces el coste en oro.
func _gold_only_data() -> SlotMachineData:
	var jackpot := SlotOutcome.new()
	jackpot.reward = &"gold"
	jackpot.amount = 10.0
	jackpot.scale_with_cost = true
	jackpot.text_key = &"SLOT_JACKPOT_GOLD"
	var coin := SlotSymbol.new()
	coin.weight = 1.0
	coin.icon = COIN_ICON
	coin.pair = jackpot
	coin.jackpot = jackpot
	var table := WeightedTable.new()
	table.entries = [coin] as Array[WeightedEntry]
	var data := SlotMachineData.new()
	data.symbols = table
	data.reels = 3
	data.base_cost = 10.0
	data.cost_growth = 1.5
	data.spin_time = 0.1
	data.reel_delay = 0.05
	return data


func _on_reward(kind: StringName, amount: float) -> void:
	if kind == &"gold":
		_rewards.append(amount)


func _on_resolved(text_key: StringName, _value: float, _jackpot: bool) -> void:
	_texts.append(text_key)
