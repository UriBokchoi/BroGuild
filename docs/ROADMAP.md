# ROADMAP

- La tarea actual es la **primera casilla sin marcar**. Claude la marca `[x]` al terminarla.
- Cada hito acaba con algo jugable. **Hecho** = validación sin errores + lo he probado y me convence.
- Si una tarea es grande, se parte aquí en subtareas antes de empezarla.

## Hito 0 — Cimientos
- [ ] Proyecto Godot 4.7 (Forward+) con `.gitignore` y `.gitattributes`; git y GitHub funcionando (push y PR)
- [ ] Comandos de Godot verificados y anotados en `CLAUDE.md`
- [ ] Estructura de carpetas de `CLAUDE.md`
- [ ] Autoloads tipados: `EventBus`, `RunState`, `Rng` (con semilla)
- [ ] InputMap con todas las acciones del GDD y capas de física con nombre
- [ ] GUT instalado con un test de ejemplo que pase
- [ ] Escena de pruebas en gris: suelo, rampas, bordes, paredes y plataformas
- [ ] `docs/DECISIONES.md` con las primeras decisiones

## Hito 1 — Movimiento (si no se siente bien, no se avanza)
- [ ] Jugador (`CharacterBody3D`) y cámara en tercera persona con ratón
- [ ] Máquina de estados + `data/player/movement.tres`
- [ ] Correr, saltar, coyote time, jump buffer y control aéreo
- [ ] Stamina por cargas + HUD mínimo
- [ ] Dash (suelo y aire) y doble salto
- [ ] Slide con pendientes y slide-jump
- [ ] Dash-jump con ventana y aviso visual
- [ ] Caída rápida, salto en pared y mantle
- [ ] Sensación de velocidad: FOV dinámico, estela de dash, líneas de velocidad
- [ ] Panel de depuración (velocidad, estado, stamina)

## Hito 2 — Combate y hordas
- [ ] `StatBlock` + `StatModifier` (con tests)
- [ ] Componentes `HealthComponent`, `HitboxComponent`, `HurtboxComponent`
- [ ] Primera arma automática basada en `WeaponData`
- [ ] Dos enemigos (enjambre y tirador) con `EnemyData` y steering simple
- [ ] Pooling de enemigos, proyectiles y pickups
- [ ] Director de oleadas con la curva en datos
- [ ] XP, niveles, fichas, muerte y reinicio rápido

## Hito 3 — Apuestas v1
- [ ] `WeightedTable`, rarezas en datos y Suerte (tests con semilla)
- [ ] Ruleta de nivel con 3 cartas que giran y reroll de coste creciente
- [ ] Doble o nada sobre la carta elegida
- [ ] Cofres con coste creciente y revelado de rareza
- [ ] 15 mejoras iniciales en `.tres` (3 con sinergia de movimiento)

## Hito 4 — Juice y look neón
- [ ] Entorno: fondo oscuro, rejilla emisiva, glow y tonemapping
- [ ] Materiales emisivos por tipo de enemigo y rareza
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
