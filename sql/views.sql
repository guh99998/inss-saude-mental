-- Visão de apoio às perguntas da análise: classifica cada auxílio-doença por grupo de transtorno,
-- idade na concessão e faixa etária. Mantém todos os auxílios-doença, porque eles formam o denominador.
-- Regras de CID documentadas em dados.md.

CREATE OR REPLACE VIEW vw_auxilio_doenca AS
SELECT
    a.*,
    extract(year FROM a.competencia_concessao)::int AS ano,
    a.especie_beneficio = 'Auxílio Doenca por Acidente do Trabalho' AS acidentario,

    CASE
        WHEN left(a.cid, 3) IN ('F32', 'F33')               THEN 'Depressão'
        WHEN left(a.cid, 3) IN ('F40', 'F41')               THEN 'Ansiedade'
        WHEN left(a.cid, 3) = 'F43'                         THEN 'Estresse e adaptação'
        WHEN left(a.cid, 3) = 'F31'                         THEN 'Transtorno bipolar'
        WHEN left(a.cid, 2) = 'F1'                          THEN 'Álcool e outras substâncias'
        WHEN left(a.cid, 2) = 'F2'                          THEN 'Esquizofrenia e psicóticos'
        WHEN a.cid IN ('Z73', 'Z73.0', 'Z73.3')             THEN 'Burnout e estresse (Z73)'
        WHEN left(a.cid, 1) = 'F'                           THEN 'Outros transtornos mentais'
    END AS grupo_transtorno,

    -- Idade na data da concessão, não a idade atual
    extract(year FROM age(a.competencia_concessao, a.data_nascimento))::int AS idade,

    CASE
        WHEN a.data_nascimento IS NULL                                                   THEN 'Sem data de nascimento'
        WHEN extract(year FROM age(a.competencia_concessao, a.data_nascimento)) < 14
          OR extract(year FROM age(a.competencia_concessao, a.data_nascimento)) > 100   THEN 'Idade inválida'
        WHEN extract(year FROM age(a.competencia_concessao, a.data_nascimento)) < 25    THEN '14 a 24'
        WHEN extract(year FROM age(a.competencia_concessao, a.data_nascimento)) < 35    THEN '25 a 34'
        WHEN extract(year FROM age(a.competencia_concessao, a.data_nascimento)) < 45    THEN '35 a 44'
        WHEN extract(year FROM age(a.competencia_concessao, a.data_nascimento)) < 55    THEN '45 a 54'
        ELSE                                                                                 '55 ou mais'
    END AS faixa_etaria
FROM auxilio_doenca a;
