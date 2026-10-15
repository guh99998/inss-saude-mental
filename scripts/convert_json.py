import json
from pathlib import Path
import pandas as pd

diretorio = Path(
    r"C:\Users\gusta\Downloads\inss-saude-mental\data"
)

for arquivo in diretorio.rglob("*.json"):
    try:
        with arquivo.open("r", encoding="utf-8") as f:
            dados = json.load(f)

        registros = [
            item["node"]
            for item in dados["nodes"]
        ]

        df = pd.DataFrame(registros)

        arquivo_csv = arquivo.with_name(
            f"{arquivo.stem}_json_convertido.csv"
        )

        if arquivo_csv.exists():
            print(f"Já existe, ignorando: {arquivo_csv.name}")
            continue

        df.to_csv(
            arquivo_csv,
            index=False,
            encoding="utf-8-sig"
        )

        print(f"Convertido: {arquivo.name} -> {arquivo_csv.name}")

    except (json.JSONDecodeError, KeyError, TypeError) as erro:
        print(f"Erro ao processar {arquivo.name}: {erro}")

print("Conversão concluída!")
