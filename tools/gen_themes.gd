extends SceneTree
## Genera ui/theme/main_theme.tres (tema global) y ui/debug/debug_theme.tres (panel de depuración).
## Paleta: pizarra oscura con acentos dorados (medieval + apuestas). Los temas se cambian aquí y se
## regeneran, no a mano:
## [code]"$G" --headless --path . -s res://tools/gen_themes.gd[/code]

const INK := Color("ece6d9")
const MUTED := Color("a59f92")
const GOLD := Color("e8b04a")
const GOLD_DARK := Color("9c7426")
const SLATE := Color("1b1f29")
const SLATE_LIGHT := Color("2b313e")
const SLATE_HOVER := Color("394152")
const MODIFIED := Color("7cc7ff")
const HEALTH := Color("c94a4a")
const EXPERIENCE := Color("4fb6ff")


func _initialize() -> void:
	var main_err := ResourceSaver.save(_main_theme(), "res://ui/theme/main_theme.tres")
	var debug_err := ResourceSaver.save(_debug_theme(), "res://ui/debug/debug_theme.tres")
	print("main=", main_err, " debug=", debug_err)
	quit(0 if main_err == OK and debug_err == OK else 1)


func _main_theme() -> Theme:
	var theme := Theme.new()
	var font := FontVariation.new()
	font.variation_embolden = 0.6
	theme.default_font = font
	theme.default_font_size = 22
	_add_labels(theme)
	_add_buttons(theme)
	_add_small_buttons(theme)
	_add_cards(theme)
	_add_panels(theme)
	_add_layouts(theme)
	_add_hud(theme)
	_add_scrollbar(theme)
	return theme


func _add_labels(theme: Theme) -> void:
	theme.set_color(&"font_color", &"Label", INK)
	theme.set_color(&"font_shadow_color", &"Label", Color(0.0, 0.0, 0.0, 0.5))
	theme.set_constant(&"shadow_offset_y", &"Label", 2)
	_label_variation(theme, &"TitleLabel", 72, GOLD)
	_label_variation(theme, &"HeaderLabel", 30, GOLD)
	_label_variation(theme, &"StatGroupLabel", 17, Color(GOLD, 0.85))
	_label_variation(theme, &"StatNameLabel", 20, INK)
	_label_variation(theme, &"StatValueLabel", 20, INK)
	_label_variation(theme, &"StatModifiedLabel", 20, MODIFIED)
	_label_variation(theme, &"StatBaseLabel", 15, MUTED)


func _add_buttons(theme: Theme) -> void:
	_button_boxes(theme, &"Button", Vector2(28, 12), 10)
	theme.set_font_size(&"font_size", &"Button", 26)
	theme.set_color(&"font_color", &"Button", INK)
	theme.set_color(&"font_hover_color", &"Button", GOLD)
	theme.set_color(&"font_focus_color", &"Button", GOLD)
	theme.set_color(&"font_pressed_color", &"Button", SLATE)
	theme.set_color(&"font_hover_pressed_color", &"Button", SLATE)
	theme.set_color(&"font_disabled_color", &"Button", Color(MUTED, 0.5))


## Botón compacto para filas y cabeceras (armería…); hereda los colores del botón normal.
func _add_small_buttons(theme: Theme) -> void:
	theme.set_type_variation(&"SmallButton", &"Button")
	_button_boxes(theme, &"SmallButton", Vector2(16, 6), 8)
	theme.set_font_size(&"font_size", &"SmallButton", 18)


## Cartas de la elección al subir de nivel: un botón grande con su contenido en columna.
func _add_cards(theme: Theme) -> void:
	theme.set_type_variation(&"CardButton", &"Button")
	_button_boxes(theme, &"CardButton", Vector2(20, 20), 14)
	_separation(theme, &"CardColumn", &"VBoxContainer", 8)
	_separation(theme, &"CardRow", &"HBoxContainer", 24)


func _add_panels(theme: Theme) -> void:
	var panel := _box(Color(0.09, 0.1, 0.13, 0.94), 16, Vector2(24, 24), Color(GOLD, 0.55), 2, 2)
	panel.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	panel.shadow_size = 16
	theme.set_stylebox(&"panel", &"PanelContainer", panel)
	_panel_variation(theme, &"StatRow", Color(1.0, 1.0, 1.0, 0.035))
	_panel_variation(theme, &"StatRowAlt", Color(1.0, 1.0, 1.0, 0.07))


## Espaciados de las pantallas de menú.
func _add_layouts(theme: Theme) -> void:
	theme.set_type_variation(&"ScreenMargin", &"MarginContainer")
	theme.set_constant(&"margin_left", &"ScreenMargin", 64)
	theme.set_constant(&"margin_right", &"ScreenMargin", 64)
	theme.set_constant(&"margin_top", &"ScreenMargin", 48)
	theme.set_constant(&"margin_bottom", &"ScreenMargin", 48)
	_separation(theme, &"MenuList", &"VBoxContainer", 14)
	_separation(theme, &"StatList", &"VBoxContainer", 4)
	_separation(theme, &"ArmoryBody", &"HBoxContainer", 28)
	_separation(theme, &"ArmoryRowLayout", &"VBoxContainer", 6)
	_separation(theme, &"ArmoryRowButtons", &"HBoxContainer", 8)


func _add_hud(theme: Theme) -> void:
	# Barras de stamina.
	theme.set_type_variation(&"ChargeBar", &"ProgressBar")
	theme.set_stylebox(&"background", &"ChargeBar", _box(Color(SLATE, 0.85), 5, Vector2(0, 0), Color(GOLD, 0.35), 2, 2))
	theme.set_stylebox(&"fill", &"ChargeBar", _box(GOLD, 5, Vector2(0, 0), Color.TRANSPARENT, 0, 0))
	_separation(theme, &"ChargeRow", &"HBoxContainer", 8)
	# Barra de vida y columna que la apila con la stamina.
	theme.set_type_variation(&"HealthBar", &"ProgressBar")
	theme.set_stylebox(&"background", &"HealthBar", _box(Color(SLATE, 0.85), 6, Vector2(0, 0), Color(GOLD, 0.35), 2, 2))
	theme.set_stylebox(&"fill", &"HealthBar", _box(HEALTH, 6, Vector2(0, 0), Color.TRANSPARENT, 0, 0))
	_separation(theme, &"HudColumn", &"VBoxContainer", 8)
	# Aviso de «interactuar»: la tecla en una tecla dibujada y el texto al lado.
	theme.set_type_variation(&"PromptPanel", &"PanelContainer")
	theme.set_stylebox(&"panel", &"PromptPanel", _box(Color(SLATE, 0.88), 10, Vector2(14, 8), Color(GOLD, 0.45), 2, 2))
	_separation(theme, &"PromptRow", &"HBoxContainer", 10)
	theme.set_type_variation(&"KeyCap", &"PanelContainer")
	theme.set_stylebox(&"panel", &"KeyCap", _box(SLATE_LIGHT, 6, Vector2(10, 1), GOLD, 2, 4))
	_label_variation(theme, &"KeyCapLabel", 20, GOLD)
	_label_variation(theme, &"PromptLabel", 20, INK)
	# Experiencia y nivel, arriba.
	theme.set_type_variation(&"XpBar", &"ProgressBar")
	theme.set_stylebox(&"background", &"XpBar", _box(Color(SLATE, 0.85), 6, Vector2(0, 0), Color(EXPERIENCE, 0.35), 2, 2))
	theme.set_stylebox(&"fill", &"XpBar", _box(EXPERIENCE, 6, Vector2(0, 0), Color.TRANSPARENT, 0, 0))
	_separation(theme, &"XpRow", &"HBoxContainer", 12)
	_label_variation(theme, &"LevelLabel", 22, EXPERIENCE)
	# Oro, debajo de la experiencia: una moneda dibujada y la cantidad.
	_separation(theme, &"HudTop", &"VBoxContainer", 6)
	_separation(theme, &"GoldRow", &"HBoxContainer", 8)
	theme.set_type_variation(&"CoinIcon", &"PanelContainer")
	theme.set_stylebox(&"panel", &"CoinIcon", _box(GOLD, 9, Vector2(0, 0), GOLD_DARK, 2, 3))
	_label_variation(theme, &"GoldLabel", 22, GOLD)
	# Reloj de la ronda, arriba en el centro; en rojo pasada la ronda.
	_label_variation(theme, &"ClockLabel", 28, INK)
	_label_variation(theme, &"ClockLabelOvertime", 28, HEALTH)


func _add_scrollbar(theme: Theme) -> void:
	theme.set_stylebox(&"scroll", &"VScrollBar", _box(Color(1.0, 1.0, 1.0, 0.05), 4, Vector2(4, 4), Color.TRANSPARENT, 0, 0))
	theme.set_stylebox(&"grabber", &"VScrollBar", _box(Color(GOLD, 0.55), 4, Vector2(4, 4), Color.TRANSPARENT, 0, 0))
	theme.set_stylebox(&"grabber_highlight", &"VScrollBar", _box(Color(GOLD, 0.8), 4, Vector2(4, 4), Color.TRANSPARENT, 0, 0))
	theme.set_stylebox(&"grabber_pressed", &"VScrollBar", _box(GOLD, 4, Vector2(4, 4), Color.TRANSPARENT, 0, 0))


func _debug_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 14
	theme.set_font_size(&"font_size", &"Label", 14)
	theme.set_font_size(&"font_size", &"Button", 14)
	theme.set_stylebox(&"normal", &"Button", _box(SLATE_LIGHT, 4, Vector2(6, 2), SLATE, 0, 0))
	theme.set_stylebox(&"hover", &"Button", _box(SLATE_HOVER, 4, Vector2(6, 2), GOLD, 1, 1))
	theme.set_stylebox(&"pressed", &"Button", _box(GOLD_DARK, 4, Vector2(6, 2), GOLD, 1, 1))
	theme.set_stylebox(&"hover_pressed", &"Button", _box(GOLD_DARK, 4, Vector2(6, 2), GOLD, 1, 1))
	theme.set_stylebox(&"panel", &"PanelContainer", _box(Color(0.05, 0.06, 0.08, 0.85), 8, Vector2(10, 10), Color.TRANSPARENT, 0, 0))
	return theme


## Fondos de un tipo de botón con márgenes [param margin] y esquinas [param radius].
func _button_boxes(theme: Theme, type: StringName, margin: Vector2, radius: int) -> void:
	theme.set_stylebox(&"normal", type, _box(SLATE_LIGHT, radius, margin, SLATE, 0, 3))
	theme.set_stylebox(&"hover", type, _box(SLATE_HOVER, radius, margin, GOLD, 2, 3))
	theme.set_stylebox(&"pressed", type, _box(GOLD, radius, margin, GOLD_DARK, 2, 3))
	theme.set_stylebox(&"hover_pressed", type, _box(GOLD, radius, margin, GOLD_DARK, 2, 3))
	theme.set_stylebox(&"disabled", type, _box(Color(SLATE_LIGHT, 0.45), radius, margin, SLATE, 0, 3))
	var focus := _box(Color.TRANSPARENT, radius, margin, GOLD, 2, 2)
	focus.draw_center = false
	theme.set_stylebox(&"focus", type, focus)


func _label_variation(theme: Theme, variation: StringName, size: int, color: Color) -> void:
	theme.set_type_variation(variation, &"Label")
	theme.set_font_size(&"font_size", variation, size)
	theme.set_color(&"font_color", variation, color)


func _panel_variation(theme: Theme, variation: StringName, color: Color) -> void:
	theme.set_type_variation(variation, &"PanelContainer")
	theme.set_stylebox(&"panel", variation, _box(color, 8, Vector2(14, 7), Color.TRANSPARENT, 0, 0))


func _separation(theme: Theme, variation: StringName, base: StringName, pixels: int) -> void:
	theme.set_type_variation(variation, base)
	theme.set_constant(&"separation", variation, pixels)


## Caja con fondo, esquinas redondeadas, márgenes (x: lados, y: arriba/abajo) y borde
## (`bottom` es el grosor del borde de abajo, para dar relieve a los botones).
func _box(color: Color, radius: int, margin: Vector2, border: Color, width: int, bottom: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.content_margin_left = margin.x
	box.content_margin_right = margin.x
	box.content_margin_top = margin.y
	box.content_margin_bottom = margin.y
	box.border_color = border
	box.border_width_left = width
	box.border_width_right = width
	box.border_width_top = width
	box.border_width_bottom = bottom
	return box
