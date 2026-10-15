-- 4. O trabalho adoece? (2019 a 2022)
-- Acidentário = espécie 91 (Auxílio Doenca por Acidente do Trabalho): o INSS reconheceu ligação com o trabalho.
-- Autônomos, facultativos e optantes não têm direito ao acidentário, por isso o percentual por filiação (4.2)
-- é mais justo que o geral.

-- 4.1 Percentual acidentário por ano: saúde mental comparada aos demais auxílios-doença
SELECT
    ano,
    count(*) FILTER (WHERE grupo_transtorno IS NOT NULL) AS saude_mental,
    round(
        100.0 * count(*) FILTER (WHERE grupo_transtorno IS NOT NULL AND acidentario)
        / count(*) FILTER (WHERE grupo_transtorno IS NOT NULL),
        2
    ) AS percentual_acidentario_saude_mental,
    round(
        100.0 * count(*) FILTER (WHERE grupo_transtorno IS NULL AND acidentario)
        / count(*) FILTER (WHERE grupo_transtorno IS NULL),
        2
    ) AS percentual_acidentario_demais
FROM vw_auxilio_doenca
WHERE ano BETWEEN 2019 AND 2022
GROUP BY ano
ORDER BY ano;


-- 4.2 A base não tem ramo de atividade (CNAE); a alternativa disponível é a forma de filiação
SELECT
    forma_filiacao,
    count(*) FILTER (WHERE grupo_transtorno IS NOT NULL)                 AS saude_mental,
    count(*) FILTER (WHERE grupo_transtorno IS NOT NULL AND acidentario) AS acidentario,
    round(
        100.0 * count(*) FILTER (WHERE grupo_transtorno IS NOT NULL AND acidentario)
        / nullif(count(*) FILTER (WHERE grupo_transtorno IS NOT NULL), 0),
        2
    ) AS percentual_acidentario
FROM vw_auxilio_doenca
WHERE ano BETWEEN 2019 AND 2022
GROUP BY forma_filiacao
HAVING count(*) FILTER (WHERE grupo_transtorno IS NOT NULL) > 0
ORDER BY saude_mental DESC;


-- 4.3 Grupos de transtorno mais reconhecidos como ligados ao trabalho, considerando só empregados
--     (a filiação com direito ao acidentário e com mais casos)
SELECT
    grupo_transtorno,
    count(*)                         AS afastamentos,
    count(*) FILTER (WHERE acidentario) AS acidentario,
    round(100.0 * count(*) FILTER (WHERE acidentario) / count(*), 2) AS percentual_acidentario
FROM vw_auxilio_doenca
WHERE ano BETWEEN 2019 AND 2022
  AND grupo_transtorno IS NOT NULL
  AND forma_filiacao = 'Empregado'
GROUP BY grupo_transtorno
ORDER BY percentual_acidentario DESC;
