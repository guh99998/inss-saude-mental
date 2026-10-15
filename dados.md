## DADOS

| Fonte | Definição |
|-------|-----------|
| Fonte | [INSS - Benefícios concedidos](https://dadosabertos.inss.gov.br/gl/dataset/inss-beneficios-concedidos) |
| Período | dez/2018 a mai/2023 |
| Filtro de saúde mental | CID começando com **F**, mais **Z73**, **Z73.0** e **Z73.3** (burnout e estresse) |
| Filtro de espécie | **31** auxílio-doença previdenciário (comum) e **91** auxílio-doença acidentário (ligado ao trabalho) |
| Base de comparação | Todos os auxílios-doença (31 + 91), para calcular a **participação** da saúde mental no total |

---


## CIDs

| Grupo na análise | Códigos |
|------------------|---------|
| Depressão | F32, F33 |
| Ansiedade | F40, F41 |
| Estresse e adaptação (inclui pós-traumático) | F43 |
| Transtorno bipolar | F31 |
| Álcool e outras substâncias | F10 a F19 |
| Esquizofrenia e psicóticos | F20 a F29 |
| Burnout e estresse (fora do capítulo F) | Z73 (sem subcódigo), Z73.0 (esgotamento), Z73.3 (estresse) |
| Outros transtornos mentais | Demais códigos F |

Os demais subcódigos de Z73 (Z73.1, Z73.2, Z73.4, Z73.6, Z73.8 e Z73.9) ficam **fora** do filtro, porque tratam de outros problemas do modo de vida, como traços de personalidade, falta de lazer e limites impostos por invalidez.

Filtro em SQL:

```sql
WHERE cid LIKE 'F%' OR cid IN ('Z73', 'Z73.0', 'Z73.3')
```