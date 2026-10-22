#!/usr/bin/env bash
# Собирает PDF-версии резюме (RU и EN) из index.html через WeasyPrint.
# index.html не меняется: стили для PDF подключаются только на время сборки.
#
# Запуск:  ./make-pdf.sh
# Нужно:   weasyprint (brew install weasyprint)

set -euo pipefail

cd "$(dirname "$0")"

if ! command -v weasyprint >/dev/null 2>&1; then
  echo "weasyprint не найден. Установи: brew install weasyprint" >&2
  exit 1
fi

NAME="Tigran_Ayrapetyan_Systems_Analyst"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Общие правки для PDF: без переключателя языка, имя в одну строку,
# заголовки не отрываются от своего текста на границе страниц.
COMMON='
.lang-switch { display: none !important; }
.header-row > div { flex: 1; }
h1 { white-space: nowrap; }
h2, .skill-name, .job-head, .job-meta { break-after: avoid; }
.skill-group, li { break-inside: avoid; }
'

# JS при сборке не выполняется, поэтому язык переключаем через CSS.
printf '%s\n' "$COMMON" > "$TMP/ru.css"
printf '%s\n%s\n' "$COMMON" \
  '#content-ru { display: none !important; } #content-en { display: block !important; }' \
  > "$TMP/en.css"

for lang in RU EN; do
  css="$TMP/$(echo "$lang" | tr 'A-Z' 'a-z').css"
  out="${NAME}_${lang}.pdf"
  # Предупреждение про prefers-color-scheme безвредно — скрываем его.
  weasyprint -s "$css" index.html "$out" 2>&1 | grep -v 'prefers-color-scheme' || true
  echo "Готово: $out"
done
