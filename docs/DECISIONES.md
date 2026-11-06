# Decisiones

Registro de decisiones de arquitectura y de proyecto: fecha, decisión y por qué.
Las nuevas van al final. Si una decisión se revierte, se añade otra que lo diga; las antiguas no se borran.

## 2026-11-06 · Nombre definitivo «Bro Guild» y temática medieval con humor
- **Decisión:** el juego se llama **Bro Guild** (`config/name` en `project.godot`). La temática pasa de casino-neón a **medieval con humor moderno**, sin realismo. Las apuestas siguen siendo el corazón del juego, pero sin casino; las **tragaperras repartidas por el mapa se quedan**. El repo de GitHub (`DuskTower`) y la carpeta local (`dusk-tower`) conservan el nombre anterior.
- **Por qué:** decisión del diseñador. El GDD aún usa nombres de casino (fichas, La Banca, crupier, mesa…); se adaptarán en una sesión de diseño aparte y están listados como pendientes en `GDD.md` §11.

## 2026-11-06 · Identificadores de código según la mecánica, no la temática
- **Decisión:** en código, señales y datos se nombra la mecánica (`currency`, `gamble`, `streak`, `pot`, `boss`…), nunca el disfraz temático (`chips`, `la_banca`…). Los nombres visibles para el jugador viven en las traducciones (`data/i18n/`).
- **Por qué:** la temática ya ha cambiado una vez. Así un cambio de nombres o de ambientación solo toca textos y assets, no código ni `.tres`.

## 2026-11-06 · Carpeta de datos de usuario fija: `bro_guild`
- **Decisión:** `application/config/use_custom_user_dir=true` y `custom_user_dir_name="bro_guild"`. En Windows, `user://` queda en `%APPDATA%/bro_guild`.
- **Por qué:** por defecto Godot deriva la carpeta de `config/name`; si el título cambiara, guardados, ajustes y remapeos quedarían huérfanos.

## 2026-11-06 · Arranque del repositorio
- **Decisión:** `main` parte del commit inicial que GitHub creó con el `README.md`. Todo lo demás entra por PR desde ramas `feat/…`, `fix/…`, `refactor/…` o `docs/…`. Los commits de este repo usan el email noreply de GitHub (`git config user.email` local).
- **Por qué:** cumple la regla «nunca commits directos a `main`» sin excepciones y no expone el email personal en un repo público.
