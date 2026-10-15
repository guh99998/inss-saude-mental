"""
Trata os arquivos de benefícios concedidos do INSS (dez/2018 a mai/2023) e gera um único CSV
com os auxílios-doença (espécies 31 e 91), pronto para ser carregado no PostgreSQL.

Cada arquivo mensal é lido, tratado e acrescentado ao CSV de saída, um de cada vez,
para não manter todos os registros em memória.

Fontes (uma por competência):
- dez/2018 a abr/2021: CSV original, separado por ';'
- mai/2021 a mai/2023: CSV convertido do JSON (*_json_convertido.csv), separado por ','
"""
from pathlib import Path

import pandas as pd

DIRETORIO_BASE = Path(__file__).resolve().parent.parent
DIRETORIO_DADOS = DIRETORIO_BASE / "data"
ARQUIVO_SAIDA = DIRETORIO_DADOS / "processado" / "auxilio_doenca_2018_2023.csv"

ANOS = range(2018, 2024)

ESPECIES_AUXILIO_DOENCA = [
    "Auxílio Doenca Previdenciário",
    "Auxílio Doenca por Acidente do Trabalho",
]

MESES = {
    "janeiro": "01", "fevereiro": "02", "março": "03", "abril": "04", "maio": "05", "junho": "06",
    "julho": "07", "agosto": "08", "setembro": "09", "outubro": "10", "novembro": "11", "dezembro": "12",
}

# Valores sem código nas colunas de CID e município
CID_SEM_CODIGO = {"Zerados", "Em Branco", "{ñ class}"}
MUNICIPIO_SEM_CODIGO = {"00000-Zerada", "{ñ class}"}

# A partir de 05/2021 (fonte JSON) alguns valores vêm cortados; padroniza para o nome completo usado até 04/2021
VALORES_TRUNCADOS = {
    "Forma Filiação": {
        "Optante Pela Lei 6.": "Optante Pela Lei 6.184/74",
        "Equiparado a Autôno": "Equiparado a Autônomo",
    },
    "Clientela": {
        "{ñ class": "{ñ class}",
    },
}

COLUNAS_SAIDA = {
    "Competência concessão": "competencia_concessao",
    "Espécie": "especie_beneficio",
    "CID": "cid",
    "Descricao": "descricao_cid",
    "Despacho": "tipo_despacho",
    "Dt Nascimento": "data_nascimento",
    "Sexo.": "sexo",
    "Clientela": "tipo_clientela",
    "codigo_municipio_inss": "codigo_municipio_inss",
    "uf_residencia": "uf_residencia",
    "nome_municipio": "nome_municipio",
    "Vínculo dependentes": "vinculo_dependente",
    "Forma Filiação": "forma_filiacao",
    "UF": "uf",
    "Qt SM RMI": "quantidade_salarios_minimos_rmi",
}


def listar_arquivos():
    arquivos = []
    for ano in ANOS:
        arquivos += sorted((DIRETORIO_DADOS / str(ano)).glob("*.csv"))
    return arquivos


def ler_arquivo(arquivo):
    separador = "," if arquivo.name.endswith("_json_convertido.csv") else ";"
    df = pd.read_csv(arquivo, sep=separador, dtype=str, encoding="utf-8-sig")

    df.columns = df.columns.str.replace("﻿", "", regex=False).str.strip()
    # 02/2020 vem com o cabeçalho da competência corrompido na origem
    df = df.rename(columns={"mandar continuar, obrigado.": "Competência concessão", "CID.1": "CID_1"})

    # Até 04/2021 existem CID (só código) e CID_1 (código + nome); depois só CID com código + nome
    if "CID_1" in df.columns:
        df = df.drop(columns=["CID"]).rename(columns={"CID_1": "CID"})

    # Tipo de Cálculo só existe a partir de 05/2021 e não é usado; Clientela não existe em mai–dez/2019
    df = df.drop(columns=["Tipo de Cálculo"], errors="ignore")
    df = df.apply(lambda coluna: coluna.str.strip())
    if "Clientela" not in df.columns:
        df["Clientela"] = pd.Series(pd.NA, index=df.index, dtype="str")

    return df


def converter_competencia(competencia):
    # 2018 usa o formato AAAA-MM-DD, 01/2019 usa mês/AAAA (ex.: janeiro/2019) e os demais AAAAMM
    resultado = pd.to_datetime(competencia, format="%Y-%m-%d", errors="coerce")

    partes = competencia.str.lower().str.extract(r"^([a-zç]+)/(\d{4})$")
    mes_ano = partes[1] + partes[0].map(MESES)
    resultado = resultado.fillna(pd.to_datetime(mes_ano, format="%Y%m", errors="coerce"))

    aaaamm = competencia.str.replace(r"\.0+$", "", regex=True)
    resultado = resultado.fillna(pd.to_datetime(aaaamm, format="%Y%m", errors="coerce"))
    assert resultado.notna().all(), competencia[resultado.isna()].unique()
    return resultado


def separar_cid(df):
    # Código CID-10 (ex.: F32, F32.1) ou CID-9 antigo de 3 dígitos (ex.: 020, E923), seguido da descrição
    partes_cid = df["CID"].str.extract(r"^([A-Z]\d{2}(?:\.\d)?|E?\d{3})\s+(.+)$")

    sem_codigo = set(df.loc[partes_cid[0].isna(), "CID"].dropna())
    assert sem_codigo <= CID_SEM_CODIGO, sem_codigo - CID_SEM_CODIGO

    df["CID"] = partes_cid[0]
    df["Descricao"] = partes_cid[1]
    return df


def separar_municipio(df):
    # Formato "21504-SP-São Paulo" (código do INSS, não do IBGE); "16224-rco do Piaui" vem sem UF na origem
    partes_municipio = df["Mun Resid"].str.extract(r"^(\d{5})-(?:([A-Z]{2})-)?(.+)$")
    partes_municipio = partes_municipio.where(partes_municipio[0] != "00000")

    sem_codigo = set(df.loc[partes_municipio[0].isna(), "Mun Resid"].dropna())
    assert sem_codigo <= MUNICIPIO_SEM_CODIGO, sem_codigo - MUNICIPIO_SEM_CODIGO

    # UF ausente é deduzida pelo prefixo do código, que corresponde a uma única UF
    prefixo_codigo = partes_municipio[0].str[:2]
    uf_por_prefixo = partes_municipio.dropna(subset=[1]).groupby(prefixo_codigo)[1].unique()
    assert uf_por_prefixo.str.len().eq(1).all()
    partes_municipio[1] = partes_municipio[1].fillna(prefixo_codigo.map(uf_por_prefixo.str[0]))
    assert partes_municipio.loc[partes_municipio[0].notna(), 1].notna().all()

    # Nome truncado na origem: 16224 fica entre os municípios do PI e é o único terminado em "rco do Piauí"
    nome_truncado = (partes_municipio[0] == "16224") & (partes_municipio[2] == "rco do Piaui")
    partes_municipio.loc[nome_truncado, 2] = "Pau D'Arco do Piauí"

    df["codigo_municipio_inss"] = partes_municipio[0]
    df["uf_residencia"] = partes_municipio[1]
    df["nome_municipio"] = partes_municipio[2]
    return df.drop(columns=["Mun Resid"])


def tratar_arquivo(df):
    df = df[df["Espécie"].isin(ESPECIES_AUXILIO_DOENCA)].copy()

    df["Competência concessão"] = converter_competencia(df["Competência concessão"])
    df = separar_cid(df)

    # Data de nascimento no formato dd/mm/aaaa; {ñ class}, vazio e a data impossível 00/01/1900 viram nulos
    nascimento = pd.to_datetime(df["Dt Nascimento"], format="%d/%m/%Y", errors="coerce")
    nascimento_invalido = set(df.loc[nascimento.isna(), "Dt Nascimento"].dropna())
    assert nascimento_invalido <= {"{ñ class}", "00/01/1900"}, nascimento_invalido
    df["Dt Nascimento"] = nascimento

    # Quantidade de salários mínimos com vírgula decimal (ex.: 1,000 e 4,326)
    df["Qt SM RMI"] = pd.to_numeric(df["Qt SM RMI"].str.replace(",", ".", regex=False), errors="coerce")
    assert df["Qt SM RMI"].notna().all()

    df = separar_municipio(df)

    for coluna, correcoes in VALORES_TRUNCADOS.items():
        df[coluna] = df[coluna].replace(correcoes)

    return df[list(COLUNAS_SAIDA)].rename(columns=COLUNAS_SAIDA)


def main():
    arquivos = listar_arquivos()
    assert len(arquivos) == 54, f"Esperados 54 arquivos mensais, encontrados {len(arquivos)}"

    ARQUIVO_SAIDA.parent.mkdir(parents=True, exist_ok=True)
    ARQUIVO_SAIDA.unlink(missing_ok=True)

    total_lidos = 0
    total_gravados = 0
    competencias_gravadas = set()

    for arquivo in arquivos:
        df = ler_arquivo(arquivo)
        lidos = len(df)
        df = tratar_arquivo(df)

        competencias = set(df["competencia_concessao"].dt.strftime("%Y-%m"))
        assert len(competencias) == 1, f"{arquivo.name} tem mais de uma competência: {competencias}"
        assert not competencias & competencias_gravadas, f"{arquivo.name} repete a competência {competencias}"
        competencias_gravadas |= competencias

        df.to_csv(
            ARQUIVO_SAIDA,
            mode="a",
            header=not ARQUIVO_SAIDA.exists(),
            index=False,
            encoding="utf-8",
            date_format="%Y-%m-%d",
        )

        total_lidos += lidos
        total_gravados += len(df)
        print(f"{arquivo.name}: {lidos:>9,} lidos | {len(df):>9,} auxílios-doença | {competencias.pop()}")

    print(f"\nTotal lido: {total_lidos:,}")
    print(f"Total gravado: {total_gravados:,}")
    print(f"Competências: {len(competencias_gravadas)}")
    print(f"Arquivo gerado: {ARQUIVO_SAIDA}")


if __name__ == "__main__":
    main()
