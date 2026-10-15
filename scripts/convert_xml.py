
import xml.etree.ElementTree as ET
from pathlib import Path
import pandas as pd

diretorio = Path(
    r"C:\Users\gusta\Downloads\inss-saude-mental\data"
)

for arquivo in diretorio.rglob("*.xml"):
    try:
        arquivo_csv = arquivo.with_name(
            f"{arquivo.stem}_xml_convertido.csv"
        )

        registros = []

        # Cada <node> representa um registro independente
        for _, node in ET.iterparse(arquivo, events=("end",)):
            if node.tag != "node":
                continue

            registro = {}

            for variavel in node.findall("./variavel"):
                nome = variavel.get("nome")
                valor = (variavel.text or "").strip()

                if nome:
                    registro[nome] = valor

            registros.append(registro)
            node.clear()

        df = pd.DataFrame(registros)

        df.to_csv(
            arquivo_csv,
            index=False,
            encoding="utf-8-sig"
        )

        print(
            f"Convertido: {arquivo.name} -> "
            f"{arquivo_csv.name} "
            f"({len(df):,} registros)"
        )

    except ET.ParseError as erro:
        print(f"Erro ao ler {arquivo.name}: {erro}")

print("Conversão concluída!")
