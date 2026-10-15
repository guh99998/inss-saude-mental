import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv

DIRETORIO_BASE = Path(__file__).resolve().parent.parent
ARQUIVO_CSV = DIRETORIO_BASE / "data" / "processado" / "auxilio_doenca_2018_2023.csv"

load_dotenv(DIRETORIO_BASE / ".env")

COLUNAS = (
    "competencia_concessao, especie_beneficio, cid, descricao_cid, tipo_despacho, data_nascimento, "
    "sexo, tipo_clientela, codigo_municipio_inss, uf_residencia, nome_municipio, vinculo_dependente, "
    "forma_filiacao, uf, quantidade_salarios_minimos_rmi"
)

with psycopg.connect(
    host="localhost",
    port=os.environ["POSTGRES_PORT"],
    dbname=os.environ["POSTGRES_DB"],
    user=os.environ["POSTGRES_USER"],
    password=os.environ["POSTGRES_PASSWORD"],
) as conexao, conexao.cursor() as cursor:
    # Recarrega do zero a cada execução
    cursor.execute("TRUNCATE auxilio_doenca RESTART IDENTITY")

    with ARQUIVO_CSV.open("rb") as arquivo, cursor.copy(
        f"COPY auxilio_doenca ({COLUNAS}) FROM STDIN WITH (FORMAT csv, HEADER true)"
    ) as copy:
        while bloco := arquivo.read(1024 * 1024):
            copy.write(bloco)

    # Atualiza as estatísticas para o planejador usar os índices desde a primeira consulta
    cursor.execute("ANALYZE auxilio_doenca")

    cursor.execute("SELECT count(*) FROM auxilio_doenca")
    print("Registros carregados:", cursor.fetchone()[0])