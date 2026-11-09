# ROADMAP

- La tarea actual es la **primera casilla sin marcar**. Claude la marca `[x]` al terminarla.
- Cada hito acaba con algo jugable. **Hecho** = validación sin errores + lo he probado y me convence.
- Si una tarea es grande, se parte aquí en subtareas antes de empezarla.
- Los nombres que vienen del casino (fichas, La Banca, mesa…) están pendientes de adaptar a la temática medieval (GDD §11).

## Hito 0 — Cimientos
- [x] Proyecto Godot 4.7 (Forward+) con `.gitignore` y `.gitattributes`; git y GitHub funcionando (push y PR)
- [x] Comandos de Godot verificados y anotados en `CLAUDE.md`
- [x] Estructura de carpetas de `CLAUDE.md`
- [x] Autoloads tipados: `EventBus`, `RunState`, `Rng` (con semilla)
- [x] InputMap con todas las acciones del GDD y capas de física con nombre
- [x] GUT instalado con un test de ejemplo que pase
- [x] Escena de pruebas en gris: suelo, rampas, bordes, paredes y plataformas
- [x] `docs/DECISIONES.md` con las primeras decisiones

## Hito 1 — Movimiento (si no se siente bien, no se avanza)
- [x] `StatBlock` + `StatModifier` (con tests): los parámetros de movimiento se leen como stats, para que mejoras y personajes los modifiquen
- [x] Jugador (`CharacterBody3D`) y cámara en tercera persona con ratón (distancia que crece con el nivel, curva en datos; interpolación de física activada); Esc suelta el ratón (aún sin menú de pausa)
- [x] Máquina de estados + `data/player/movement.tres` (gana la primera acción; nada se cancela salvo con el dash)
- [x] Correr, saltar, coyote time, jump buffer y control aéreo
- [x] Panel de depuración con F3 (velocidad, estado, suelo/coyote y nivel de la cámara; cada sistema nuevo añade lo suyo), con las stats modificables como haría una mejora
- [x] Textos traducibles (CSV en `data/i18n/`, español e inglés) y `Theme` global, antes del primer HUD
- [x] Menú de pausa (Esc): continuar, opciones (aún sin función), reintentar y salir, con un panel fijo de todas las stats del jugador (con scroll)
- [x] Stamina por cargas + HUD mínimo
- [x] Dash (suelo y aire), picado (doble Shift en el aire sin dirección) y doble salto
- [x] Slide con pendientes y slide-jump
- [ ] Dash-jump con ventana y aviso visual
- [ ] Caída rápida, salto en pared y mantle
- [ ] Sensación de velocidad: FOV dinámico, estela de dash, líneas de velocidad

## Hito 2 — Combate y hordas
- [x] Stats de combate y progresión del personaje en datos (vida, regeneración, defensa, esquiva, robo de vida, daño, crítico, velocidad de ataque, proyectiles, área, duración, retroceso, experiencia, fichas, suerte, radio de recogida), visibles en la pausa y en F3
- [ ] Componentes `HealthComponent`, `HitboxComponent`, `HurtboxComponent` (usan las stats de supervivencia)
- [ ] Primera arma automática basada en `WeaponData`
- [ ] Dos enemigos (enjambre y tirador) con `EnemyData` y steering simple
- [ ] Pooling de enemigos, proyectiles y pickups
- [ ] Escena de estrés con 300 y 500 enemigos y fps medidos (se repite al cerrar cada hito)
- [ ] Director de oleadas con la curva en datos
- [ ] XP, niveles, fichas, muerte y reinicio rápido (la cámara ya se aleja con el nivel)

## Hito 3 — Apuestas v1
- [ ] GDD adaptado a la temática medieval (pendientes de §11)
- [ ] `WeightedTable`, rarezas en datos y Suerte (tests con semilla)
- [ ] Ruleta de nivel con 3 cartas que giran y reroll de coste creciente
- [ ] Doble o nada sobre la carta elegida
- [ ] Cofres con coste creciente y revelado de rareza
- [ ] 15 mejoras iniciales en `.tres` (3 con sinergia de movimiento)
- [ ] Pantalla de estadísticas (Tab)

## Hito 4 — Juice y look
- [ ] Entorno según la dirección visual del GDD (luz, glow y tonemapping)
- [ ] Materiales con color propio por tipo de enemigo y rareza
- [ ] Hit-stop, screen shake, flash y números de daño
- [ ] Partículas: muertes, fichas, cofres, impactos
- [ ] Sonidos con tono creciente y UI animada
- [ ] Rendimiento: 300+ enemigos a 60 fps

## Hito 5 — La mesa de juego
- [ ] Racha y bote (niveles, multiplicador, cobrar, perder al ser golpeado)
- [ ] Tragaperras en la arena
- [ ] Pactos de la Banca
- [ ] Élites con afijos que sueltan cofres
- [ ] Las 4 armas iniciales del GDD

## Hito 6 — Cierre de partida y meta
- [ ] Jefe "La Banca" al minuto 10
- [ ] ¿Cobrar o Doblar? y mesas siguientes
- [ ] Resumen de partida
- [ ] Guardado y desbloqueos (personajes, armas, ventajas)
- [ ] Menú principal y opciones (sensibilidad, volumen, remapeo)

## Backlog (sin orden)
- Raíles/ziplines y plataformas de salto
- Más armas, enemigos y personajes con movimiento propio
- Nuevas arenas; generación procedural
- Retos diarios con semilla compartida
- Soporte de mando
- Actualizar a Godot 4.8 cuando sea estable
