class_name SfxSynth
extends RefCounted
## Sintetiza un [SfxRecipe] en muestras de 16 bits (mono) y en un [AudioStreamWAV]. Lógica pura y
## sin azar externo: la misma receta da siempre el mismo sonido.

## Muestras por segundo.
const MIX_RATE := 44100


## El sonido de [param recipe] listo para sonar o guardar ([method AudioStreamWAV.save_to_wav]).
static func render_stream(recipe: SfxRecipe) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = render(recipe)
	return stream


## Las muestras de [param recipe]: 16 bits con signo, little-endian, mono, a [constant MIX_RATE].
static func render(recipe: SfxRecipe) -> PackedByteArray:
	var count := maxi(roundi(recipe.duration() * MIX_RATE), 1)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = recipe.noise_seed
	var phase := 0.0
	var noise_value := 0.0
	var filtered := 0.0
	var smoothing := 1.0 - exp(-TAU * recipe.low_pass / MIX_RATE) if recipe.low_pass > 0.0 else 1.0
	var total := recipe.duration()
	# Una fase por parcial; su volumen total, para que sumar parciales no suba el volumen.
	var partial_phases := PackedFloat64Array()
	partial_phases.resize(recipe.partials.size())
	var partial_volume := 0.0
	for partial: Vector2 in recipe.partials:
		partial_volume += partial.y
	for index: int in count:
		var time := float(index) / MIX_RATE
		var frequency := _frequency(recipe, time, total)
		var previous_phase := phase
		phase = fmod(phase + frequency / MIX_RATE, 1.0)
		# El ruido cambia de valor cada medio ciclo, así sigue el tono (como en sfxr).
		if phase < previous_phase or (previous_phase < 0.5 and phase >= 0.5):
			noise_value = rng.randf_range(-1.0, 1.0)
		var value := _wave(recipe, phase, noise_value)
		if partial_volume > 0.0:
			value = 0.0
			for partial_index: int in recipe.partials.size():
				var partial := recipe.partials[partial_index]
				partial_phases[partial_index] = fmod(partial_phases[partial_index] + frequency * partial.x / MIX_RATE, 1.0)
				value += partial.y * _wave(recipe, partial_phases[partial_index], noise_value)
			value /= partial_volume
		value = lerpf(value, noise_value, recipe.noise)
		filtered += smoothing * (value - filtered)
		var sample := clampf(filtered * _envelope(recipe, time) * recipe.volume, -1.0, 1.0)
		bytes.encode_s16(index * 2, roundi(sample * 32767.0))
	return bytes


static func _frequency(recipe: SfxRecipe, time: float, total: float) -> float:
	var progress := time / total if total > 0.0 else 0.0
	var frequency := recipe.start_frequency * pow(recipe.end_frequency / recipe.start_frequency, progress)
	for step: Vector2 in recipe.arpeggio:
		if time >= step.x:
			frequency *= step.y
	if recipe.vibrato_depth > 0.0:
		frequency *= 1.0 + recipe.vibrato_depth * sin(TAU * recipe.vibrato_speed * time)
	return frequency


static func _wave(recipe: SfxRecipe, phase: float, noise_value: float) -> float:
	match recipe.wave:
		SfxRecipe.Wave.SQUARE:
			return 1.0 if phase < recipe.duty else -1.0
		SfxRecipe.Wave.SAW:
			return 2.0 * phase - 1.0
		SfxRecipe.Wave.SINE:
			return sin(TAU * phase)
		SfxRecipe.Wave.TRIANGLE:
			return 1.0 - 4.0 * absf(phase - 0.5)
		_:
			return noise_value


static func _envelope(recipe: SfxRecipe, time: float) -> float:
	if time < recipe.attack:
		return time / recipe.attack
	time -= recipe.attack
	if time < recipe.sustain:
		return 1.0 + recipe.punch * (1.0 - time / recipe.sustain)
	time -= recipe.sustain
	if time < recipe.decay:
		return pow(1.0 - time / recipe.decay, recipe.decay_curve)
	return 0.0
