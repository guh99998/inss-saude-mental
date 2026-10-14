import xml.etree.ElementTree as ET
from pathlib import Path
import pandas as pd

diretorio = Path(
    r"C:\Users\gusta\Downloads\inss-saude-mental\data"
)

for arquivo in diretorio.rglob("*.xml"):
    try:
        root = ET.parse(arquivo).getroot()

        registro = {}

        for variavel in root.findall(".//variavel"):
            nome = variavel.get("nome")
            valor = (variavel.text or "").strip()

            if nome:
                registro[nome] = valor

        df = pd.DataFrame([registro])

        # Mesmo diretório e mesmo nome, alterando apenas a extensão
        arquivo_csv = arquivo.with_suffix(".csv")

        df.to_csv(
            arquivo_csv,
            index=False,
            encoding="utf-8-sig"
        )

    except ET.ParseError as erro:
        print(f"Erro ao ler {arquivo}: {erro}")

print("Conversão concluída!")
