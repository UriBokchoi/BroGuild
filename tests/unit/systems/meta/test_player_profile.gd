extends GutTest
## PlayerProfile: guarda y lee las bro-monedas; nunca quedan en negativo.


func test_round_trip() -> void:
	var profile := PlayerProfile.new()
	profile.add_bro_coins(7)
	var config := ConfigFile.new()
	profile.write_to(config)
	var loaded := PlayerProfile.new()
	loaded.read_from(config)
	assert_eq(loaded.bro_coins, 7)


func test_ignores_negative_amounts() -> void:
	var profile := PlayerProfile.new()
	profile.add_bro_coins(3)
	profile.add_bro_coins(-5)
	assert_eq(profile.bro_coins, 3)


func test_a_broken_file_reads_as_zero() -> void:
	var config := ConfigFile.new()
	config.set_value(PlayerProfile.SECTION, "bro_coins", -40)
	var loaded := PlayerProfile.new()
	loaded.read_from(config)
	assert_eq(loaded.bro_coins, 0)
