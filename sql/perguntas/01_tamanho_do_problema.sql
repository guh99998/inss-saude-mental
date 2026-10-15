-- 1. Tamanho do problema (2019 a 2022, únicos anos completos)
-- 1.1 Afastamentos por transtornos mentais por ano
-- 1.2 Percentual sobre todos os auxílios-doença
-- 1.3 Variação do percentual em relação ao ano anterior, em pontos percentuais (p.p.)

WITH por_ano AS (
    SELECT
        ano,
        count(*) FILTER (WHERE grupo_transtorno IS NOT NULL) AS saude_mental,
        count(*)                                             AS total_auxilios_doenca
    FROM vw_auxilio_doenca
    WHERE ano BETWEEN 2019 AND 2022
    GROUP BY ano
)
SELECT
    ano,
    saude_mental,
    total_auxilios_doenca,
    round(100.0 * saude_mental / total_auxilios_doenca, 2) AS percentual,
    round(
        100.0 * saude_mental / total_auxilios_doenca
        - lag(100.0 * saude_mental / total_auxilios_doenca) OVER (ORDER BY ano),
        2
    ) AS variacao_pp
FROM por_ano
ORDER BY ano;
