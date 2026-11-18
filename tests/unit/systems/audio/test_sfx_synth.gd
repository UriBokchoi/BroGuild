extends GutTest
## SfxSynth: convierte una receta en muestras de 16 bits que duran lo que dice, siempre iguales,
## dentro del rango, que suenan y que acaban en silencio. Con parciales cambia el timbre sin subir
## el volumen, y con la caída curvada se apaga antes.


func test_lasts_what_the_recipe_says() -> void:
	var recipe := _recipe()
	var bytes := SfxSynth.render(recipe)
	assert_eq(bytes.size(), roundi(recipe.duration() * SfxSynth.MIX_RATE) * 2, "16 bits por muestra")


func test_the_same_recipe_always_sounds_the_same() -> void:
	var recipe := _recipe()
	recipe.noise = 0.5
	assert_eq(SfxSynth.render(recipe), SfxSynth.render(recipe))


func test_sounds_and_fades_to_silence() -> void:
	var bytes := SfxSynth.render(_recipe())
	var peak := 0
	for index: int in range(0, bytes.size(), 2):
		peak = maxi(peak, absi(bytes.decode_s16(index)))
	assert_gt(peak, 1000, "se oye")
	assert_lte(peak, 32767)
	assert_lt(absi(bytes.decode_s16(bytes.size() - 2)), 200, "acaba casi en silencio")


func test_the_stream_is_16_bit_mono() -> void:
	var stream := SfxSynth.render_stream(_recipe())
	assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS)
	assert_eq(stream.mix_rate, SfxSynth.MIX_RATE)
	assert_false(stream.stereo)


func _recipe() -> SfxRecipe:
	var recipe := SfxRecipe.new()
	recipe.wave = SfxRecipe.Wave.SQUARE
	recipe.start_frequency = 440.0
	recipe.end_frequency = 220.0
	recipe.sustain = 0.05
	recipe.decay = 0.1
	recipe.volume = 0.5
	return recipe


func test_partials_mix_without_getting_louder() -> void:
	var plain := _recipe()
	plain.wave = SfxRecipe.Wave.SINE
	var metallic := _recipe()
	metallic.wave = SfxRecipe.Wave.SINE
	metallic.partials = PackedVector2Array([Vector2(1.0, 1.0), Vector2(1.47, 0.7), Vector2(2.09, 0.5)])
	assert_false(SfxSynth.render(metallic) == SfxSynth.render(plain), "otro timbre")
	assert_lte(_peak(SfxSynth.render(metallic)), _peak(SfxSynth.render(plain)) + 1, "no más fuerte")


func test_a_steeper_decay_fades_sooner() -> void:
	var straight := _recipe()
	var steep := _recipe()
	steep.decay_curve = 3.0
	var middle := roundi((straight.attack + straight.sustain + straight.decay * 0.5) * SfxSynth.MIX_RATE)
	assert_lt(_peak_from(SfxSynth.render(steep), middle), _peak_from(SfxSynth.render(straight), middle))


func _peak(bytes: PackedByteArray) -> int:
	return _peak_from(bytes, 0)


## El pico desde la muestra [param first].
func _peak_from(bytes: PackedByteArray, first: int) -> int:
	var peak := 0
	for index: int in range(first * 2, bytes.size(), 2):
		peak = maxi(peak, absi(bytes.decode_s16(index)))
	return peak
