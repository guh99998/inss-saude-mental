-- 5. O que mudou com a pandemia e com o burnout?

-- 5.1 Antes (2019), durante (2020–2021) e depois (2022) da pandemia.
--     Média mensal, porque os períodos têm durações diferentes.
SELECT
    CASE
        WHEN ano = 2019 THEN '1. Antes (2019)'
        WHEN ano IN (2020, 2021) THEN '2. Durante (2020–2021)'
        ELSE '3. Depois (2022)'
    END AS periodo,
    count(DISTINCT competencia_concessao) AS meses,
    round(count(*) FILTER (WHERE grupo_transtorno IS NOT NULL)::numeric / count(DISTINCT competencia_concessao)) AS media_mensal_saude_mental,
    round(count(*)::numeric / count(DISTINCT competencia_concessao)) AS media_mensal_auxilios_doenca,
    round(100.0 * count(*) FILTER (WHERE grupo_transtorno IS NOT NULL) / count(*), 2) AS percentual_saude_mental
FROM vw_auxilio_doenca
WHERE ano BETWEEN 2019 AND 2022
GROUP BY periodo
ORDER BY periodo;


-- 5.2 Burnout e estresse (Z73, Z73.0 e Z73.3) mês a mês em todo o período (dez/2018 a mai/2023)
SELECT
    competencia_concessao,
    count(*) FILTER (WHERE grupo_transtorno = 'Burnout e estresse (Z73)') AS burnout_estresse,
    count(*) FILTER (WHERE cid = 'Z73.0')                                  AS esgotamento_z73_0
FROM vw_auxilio_doenca
GROUP BY competencia_concessao
ORDER BY competencia_concessao;
