#!/usr/bin/env bash
# validate.sh — valida el proyecto desde la terminal (Git Bash en Windows, o Linux).
# Uso:   GODOT="/ruta/Godot_v4.7.2-stable_win64_console.exe" tools/validate.sh [proyecto]
# Pasos: import -> project (scripts, escenas, recursos y shaders) -> smoke (escena
#        principal) -> gut (si existe).
# Falla si un paso sale con código != 0 o si su salida contiene ERROR/WARNING:
# Godot suele salir con 0 aunque haya errores de script o de shader.
set -uo pipefail

PROJECT_DIR="${1:-$(dirname "$0")/..}"
STEP_TIMEOUT="${STEP_TIMEOUT:-300}"   # segundos máximos por paso
SMOKE_FRAMES="${SMOKE_FRAMES:-600}"   # frames del smoke test
CHECK_SCRIPT="res://tools/ci/check_project.gd"

# Líneas que hacen fallar un paso (se buscan tras quitar colores ANSI y \r).
STRICT_PATTERN='ERROR|WARNING|Parse Error'
# En GUT un test puede provocar ERROR/WARNING a propósito (assert_push_error),
# así que ahí manda el código de salida de GUT más estos patrones. GUT sale con 0
# si un test no compila (lo ignora), si falta la caché de clases o si no corre nada.
# Los errores fuera del cuerpo de un test y los push_warning los convierte en
# fallo el hook tests/hooks/post_run.gd.
GUT_PATTERN='SCRIPT ERROR|Parse Error|GUT ERROR|GUT WARNING|leaked at exit|still in use at exit'
GUT_SUCCESS='All tests passed'
# Ruido benigno conocido (regex). En Godot 4.7.2 --headless no se ha observado
# ninguno; añade aquí solo líneas exactas y justificadas.
BENIGN_PATTERN=''

if [[ -z "${GODOT:-}" ]]; then
  echo "ERROR: define la variable GODOT con la ruta al ejecutable *_console.exe de Godot." >&2
  exit 2
fi
if [[ ! -x "$GODOT" ]]; then
  echo "ERROR: GODOT='$GODOT' no existe o no es ejecutable." >&2
  exit 2
fi
if [[ ! -f "$PROJECT_DIR/project.godot" ]]; then
  echo "ERROR: no hay project.godot en '$PROJECT_DIR'." >&2
  exit 2
fi
# Ruta absoluta en formato Windows (C:/...) si estamos en Git Bash.
PROJECT_DIR="$(cd "$PROJECT_DIR" && (pwd -W 2>/dev/null || pwd))"
LOG_DIR="${LOG_DIR:-$(mktemp -d)}"   # logs completos de cada paso
mkdir -p "$LOG_DIR"
FAILED=()

# run_step <nombre> <patrón de fallo> <args de Godot...>
run_step() {
  local name="$1" pattern="$2"
  shift 2
  local log="$LOG_DIR/$name.log" code hits
  printf '==> %-8s ' "$name"
  # stdin cerrado: si el depurador local (-d) se parase, no se queda esperando.
  timeout -k 10 "$STEP_TIMEOUT" "$GODOT" --headless --path "$PROJECT_DIR" "$@" \
    < /dev/null 2>&1 | sed -E 's/\x1b\[[0-9;]*[A-Za-z]//g' | tr -d '\r' > "$log"
  code=${PIPESTATUS[0]}
  hits="$(grep -E "$pattern" "$log" | { [[ -n "$BENIGN_PATTERN" ]] && grep -Ev "$BENIGN_PATTERN" || cat; })"
  if (( code == 0 )) && [[ -z "$hits" ]]; then
    echo "OK"
    return 0
  fi
  echo "FAIL (exit $code)"
  (( code == 124 )) && echo "    timeout: más de ${STEP_TIMEOUT}s"
  # Muestra cada línea problemática con la siguiente (suele ser "at: archivo:línea").
  [[ -n "$hits" ]] && grep -E -A1 "$pattern" "$log" | grep -v '^--$' | head -n 40 | sed 's/^/    /'
  FAILED+=("$name")
  return 1
}

run_step import "$STRICT_PATTERN" --import
# Un asset que no se importa deja su .import con valid=false y Godot no lo
# reintenta mientras el archivo no cambie: sin esto, la segunda pasada saldría OK.
invalid_imports="$(grep -rl --include='*.import' --exclude-dir=.godot --exclude-dir=addons '^valid=false' "$PROJECT_DIR")"
if [[ -n "$invalid_imports" ]]; then
  echo "    import inválido (valid=false):"
  sed 's/^/      /' <<< "$invalid_imports"
  [[ " ${FAILED[*]} " == *" import "* ]] || FAILED+=(import)
fi
if [[ -f "$PROJECT_DIR/${CHECK_SCRIPT#res://}" ]]; then
  # -d activa el depurador local: es lo único que imprime los warnings de GDScript.
  run_step project "$STRICT_PATTERN" -s "$CHECK_SCRIPT" -d --ignore-error-breaks
else
  echo "==> project  FAIL (falta $CHECK_SCRIPT)"
  FAILED+=(project)
fi
run_step smoke "$STRICT_PATTERN" --quit-after "$SMOKE_FRAMES" -d --ignore-error-breaks
if [[ -d "$PROJECT_DIR/addons/gut" ]]; then
  if [[ ! -f "$PROJECT_DIR/.gutconfig.json" ]]; then
    echo "==> gut      FAIL (addons/gut existe pero falta .gutconfig.json)"
    FAILED+=(gut)
  elif run_step gut "$GUT_PATTERN" -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json \
      && ! grep -q "$GUT_SUCCESS" "$LOG_DIR/gut.log"; then
    echo "    GUT no ha mostrado «$GUT_SUCCESS»: ¿no se ha ejecutado ningún test?"
    FAILED+=(gut)
  fi
else
  echo "==> gut      SKIP (no hay addons/gut)"
fi

if (( ${#FAILED[@]} > 0 )); then
  echo "VALIDACIÓN FALLIDA: ${FAILED[*]}  (logs en $LOG_DIR)"
  exit 1
fi
echo "VALIDACIÓN OK  (logs en $LOG_DIR)"
