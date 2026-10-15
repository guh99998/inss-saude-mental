-- 2. Quais transtornos mais afastam? (2019 a 2022)

-- 2.1 Ranking dos grupos de transtorno por ano, com a participação de cada grupo na saúde mental
WITH por_grupo AS (
    SELECT ano, grupo_transtorno, count(*) AS afastamentos
    FROM vw_auxilio_doenca
    WHERE ano BETWEEN 2019 AND 2022
      AND grupo_transtorno IS NOT NULL
    GROUP BY ano, grupo_transtorno
)
SELECT
    ano,
    rank() OVER (PARTITION BY ano ORDER BY afastamentos DESC) AS posicao,
    grupo_transtorno,
    afastamentos,
    round(100.0 * afastamentos / sum(afastamentos) OVER (PARTITION BY ano), 1) AS percentual_saude_mental
FROM por_grupo
ORDER BY ano, posicao;


-- 2.2 Ansiedade ultrapassou depressão em algum momento? Comparação mês a mês em todo o período
SELECT
    competencia_concessao,
    count(*) FILTER (WHERE grupo_transtorno = 'Depressão') AS depressao,
    count(*) FILTER (WHERE grupo_transtorno = 'Ansiedade') AS ansiedade,
    count(*) FILTER (WHERE grupo_transtorno = 'Ansiedade')
        > count(*) FILTER (WHERE grupo_transtorno = 'Depressão') AS ansiedade_maior
FROM vw_auxilio_doenca
WHERE grupo_transtorno IN ('Depressão', 'Ansiedade')
GROUP BY competencia_concessao
ORDER BY competencia_concessao;


-- 2.3 Variação de cada grupo entre 2019 e 2022: em número de afastamentos (%)
--     e em participação dentro da saúde mental (p.p.). Ordenado da maior queda para o maior crescimento.
WITH por_grupo AS (
    SELECT
        grupo_transtorno,
        count(*) FILTER (WHERE ano = 2019) AS afastamentos_2019,
        count(*) FILTER (WHERE ano = 2022) AS afastamentos_2022
    FROM vw_auxilio_doenca
    WHERE ano IN (2019, 2022)
      AND grupo_transtorno IS NOT NULL
    GROUP BY grupo_transtorno
)
SELECT
    grupo_transtorno,
    afastamentos_2019,
    afastamentos_2022,
    round(100.0 * (afastamentos_2022 - afastamentos_2019) / afastamentos_2019, 1) AS variacao_percentual,
    round(
        100.0 * afastamentos_2022 / sum(afastamentos_2022) OVER ()
        - 100.0 * afastamentos_2019 / sum(afastamentos_2019) OVER (),
        2
    ) AS variacao_participacao_pp
FROM por_grupo
ORDER BY variacao_percentual;
