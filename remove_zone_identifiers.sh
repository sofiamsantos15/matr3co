#!/usr/bin/env bash
#
# remove_zone_identifiers.sh
# Remove recursivamente todos os arquivos nomeados *:Zone.Identifier
#
# Uso:
#   ./remove_zone_identifiers.sh [<diretório>]
# Se não passar diretório, usa o diretório corrente.

SEARCH_DIR="${1:-.}"

echo "🚀 Removendo arquivos '*:Zone.Identifier' em '$SEARCH_DIR'..."

# Encontra e apaga qualquer arquivo cujo nome termine em ':Zone.Identifier'
find "$SEARCH_DIR" -type f -name '*:Zone.Identifier' -print0 \
  | xargs -0 -r rm -f

echo "✅ Concluído. Todos os arquivos ':Zone.Identifier' foram removidos."

