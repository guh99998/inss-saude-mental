#!/bin/bash

BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)

BASE_DADOS="$BASE_DIR/data/"

find "$BASE_DADOS" -mindepth 1 -type d | while read -r sub_dir; do
  echo "=== Arquivos em: $sub_dir ==="

  find "$sub_dir" -maxdepth 1 -type f | while read -r arquivo; do
    encoding=$(file -b --mime-encoding "$arquivo")

    if [[ "$encoding" == "iso-8859-1" ]]; then
      echo "Convertendo: $(basename "$arquivo") de ISO-8859-1 para UTF-8..."

      if iconv -f ISO-8859-1 -t UTF-8 "$arquivo" > "$arquivo.tmp"; then
        mv "$arquivo.tmp" "$arquivo"

        if [[ "$arquivo" == *.xml ]]; then
        sed -i 's/encoding="ISO-8859-1"/encoding="UTF-8"/gI' "$arquivo"
        fi

        echo "Sucesso!"
      else
        echo "ERRO ao converter $arquivo"
        rm -f "$arquivo.tmp"
      fi
    fi
  done

  echo ""
done
