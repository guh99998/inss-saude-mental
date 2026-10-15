-- Auxílios-doença (espécies 31 e 91) concedidos pelo INSS entre dez/2018 e mai/2023.
-- Carregado a partir de data/processado/auxilio_doenca_2018_2023.csv, gerado por scripts/process_data.py.
-- As colunas seguem a mesma ordem do CSV.

CREATE TABLE IF NOT EXISTS auxilio_doenca (
    id                              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    competencia_concessao           DATE         NOT NULL,  -- sempre o dia 1 do mês
    especie_beneficio               TEXT         NOT NULL,
    cid                             VARCHAR(5),              -- ex.: F32, F32.1; nulo para Zerados, Em Branco e {ñ class}
    descricao_cid                   TEXT,
    tipo_despacho                   TEXT         NOT NULL,
    data_nascimento                 DATE,
    sexo                            TEXT         NOT NULL,
    tipo_clientela                  TEXT,                    -- não existe em mai–dez/2019
    codigo_municipio_inss           CHAR(5),                 -- código do INSS, não do IBGE
    uf_residencia                   CHAR(2),
    nome_municipio                  TEXT,
    vinculo_dependente              TEXT         NOT NULL,
    forma_filiacao                  TEXT         NOT NULL,
    uf                              TEXT         NOT NULL,   -- nome da UF por extenso, diferente de uf_residencia
    quantidade_salarios_minimos_rmi NUMERIC(6, 3) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_auxilio_doenca_competencia ON auxilio_doenca (competencia_concessao);
CREATE INDEX IF NOT EXISTS idx_auxilio_doenca_cid ON auxilio_doenca (cid text_pattern_ops);  -- acelera cid LIKE 'F%'
