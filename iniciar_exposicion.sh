#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${1:-8090}"

echo "Iniciando presentación ATLANIA en http://localhost:${PORT} ..."
python3 -m http.server "${PORT}" --directory "${DIR}" >/tmp/atlania_slides_server.log 2>&1 &
SERVER_PID=$!

sleep 1

if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "http://localhost:${PORT}/index.html" >/dev/null 2>&1 || true
elif command -v open >/dev/null 2>&1; then
  open "http://localhost:${PORT}/index.html" >/dev/null 2>&1 || true
fi

echo "Servidor corriendo (PID: ${SERVER_PID}). Presiona Ctrl+C para detenerlo."
wait "${SERVER_PID}"
