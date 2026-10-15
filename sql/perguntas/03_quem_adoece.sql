-- 3. Quem adoece? (2019 a 2022)

-- 3.1a Por sexo: quantos afastamentos por saúde mental e quanto eles pesam no total de auxílios-doença de cada sexo
SELECT
    sexo,
    count(*) FILTER (WHERE grupo_transtorno IS NOT NULL) AS saude_mental,
    count(*)                                             AS total_auxilios_doenca,
    round(100.0 * count(*) FILTER (WHERE grupo_transtorno IS NOT NULL) / count(*), 2) AS percentual
FROM vw_auxilio_doenca
WHERE ano BETWEEN 2019 AND 2022
GROUP BY sexo
ORDER BY sexo;


-- 3.1b Por sexo e grupo de transtorno: percentual de mulheres em cada grupo.
--      Ordenado da maior predominância feminina para a maior predominância masculina.
SELECT
    grupo_transtorno,
    count(*) FILTER (WHERE sexo = 'Feminino')  AS feminino,
    count(*) FILTER (WHERE sexo = 'Masculino') AS masculino,
    round(100.0 * count(*) FILTER (WHERE sexo = 'Feminino') / count(*), 1) AS percentual_feminino
FROM vw_auxilio_doenca
WHERE ano BETWEEN 2019 AND 2022
  AND grupo_transtorno IS NOT NULL
GROUP BY grupo_transtorno
ORDER BY percentual_feminino DESC;


-- 3.2 Por faixa etária e ano (idade na data da concessão):
--     participação de cada faixa nos afastamentos por saúde mental
--     e peso da saúde mental dentro dos auxílios-doença da faixa
SELECT
    ano,
    faixa_etaria,
    count(*) FILTER (WHERE grupo_transtorno IS NOT NULL) AS saude_mental,
    round(
        100.0 * count(*) FILTER (WHERE grupo_transtorno IS NOT NULL)
        / sum(count(*) FILTER (WHERE grupo_transtorno IS NOT NULL)) OVER (PARTITION BY ano),
        1
    ) AS percentual_da_saude_mental,
    round(100.0 * count(*) FILTER (WHERE grupo_transtorno IS NOT NULL) / count(*), 2) AS percentual_dos_auxilios_da_faixa
FROM vw_auxilio_doenca
WHERE ano BETWEEN 2019 AND 2022
  AND faixa_etaria NOT IN ('Idade inválida', 'Sem data de nascimento')
GROUP BY ano, faixa_etaria
ORDER BY ano, faixa_etaria;


-- 3.3 Por UF de residência: comparação justa pelo peso da saúde mental no total de auxílios-doença do estado
--     (registros sem município, cerca de 2,8%, ficam de fora)
SELECT
    uf_residencia,
    count(*) FILTER (WHERE grupo_transtorno IS NOT NULL) AS saude_mental,
    count(*)                                             AS total_auxilios_doenca,
    round(100.0 * count(*) FILTER (WHERE grupo_transtorno IS NOT NULL) / count(*), 2) AS percentual
FROM vw_auxilio_doenca
WHERE ano BETWEEN 2019 AND 2022
  AND uf_residencia IS NOT NULL
GROUP BY uf_residencia
ORDER BY percentual DESC;
