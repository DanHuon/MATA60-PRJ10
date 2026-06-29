TRUNCATE TABLE financia, relatorio, publicacao, contrato, bolsa, pesquisador, financiador, projeto RESTART IDENTITY CASCADE;

WITH RECURSIVE seq_projetos(i) AS (
    SELECT 1
    UNION ALL
    SELECT i + 1 FROM seq_projetos WHERE i < 1000
)
INSERT INTO projeto (titulo_projeto, data_inicio, data_termino)
SELECT 
    'Pesquisa em Tema ' || CAST(i AS VARCHAR),
    CURRENT_DATE - CAST(FLOOR(RANDOM() * 1000 + 365) AS INTEGER) * INTERVAL '1 day',
    CURRENT_DATE + CAST(FLOOR(RANDOM() * 365) AS INTEGER) * INTERVAL '1 day'
FROM seq_projetos;

WITH RECURSIVE seq_financiadores(i) AS (
    SELECT 1
    UNION ALL
    SELECT i + 1 FROM seq_financiadores WHERE i < 50
)
INSERT INTO financiador (cnpj_financiador, nome_financiador, tipo_financiador, contato_financiador)
SELECT 
    LPAD(CAST(i AS VARCHAR), 14, '0'),
    'Fundo de Amparo ' || CAST(i AS VARCHAR),
    CASE WHEN RANDOM() < 0.5 THEN 'Público' ELSE 'Privado' END,
    '(71) 9' || LPAD(CAST(FLOOR(RANDOM() * 99999999) AS VARCHAR), 8, '0')
FROM seq_financiadores;

WITH RECURSIVE seq_pesq(i) AS (
    SELECT 1
    UNION ALL
    SELECT i + 1 FROM seq_pesq WHERE i < 5000
)
INSERT INTO pesquisador (cpf_pesquisador, titulacao, email, telefone, primeiro_nome, sobrenome)
SELECT 
    LPAD(CAST(i AS VARCHAR), 11, '0'),
    CASE MOD(i, 3) 
        WHEN 0 THEN 'Graduando' 
        WHEN 1 THEN 'Mestre' 
        ELSE 'Doutor' 
    END,
    'pesquisador_' || CAST(i AS VARCHAR) || '@ufba.br',
    '(71) 9' || LPAD(CAST(FLOOR(RANDOM() * 99999999) AS VARCHAR), 8, '0'),
    'Nome' || CAST(i AS VARCHAR),
    'Sobrenome' || CAST(i AS VARCHAR)
FROM seq_pesq;

WITH RECURSIVE seq_bolsas(i) AS (
    SELECT 1
    UNION ALL
    SELECT i + 1 FROM seq_bolsas WHERE i < 3000
)
INSERT INTO bolsa (id_projeto, valor_bolsa, categoria_bolsa, numero_processo)
SELECT 
    CAST(FLOOR(RANDOM() * 1000 + 1) AS INTEGER),
    CASE MOD(i, 3) 
        WHEN 0 THEN 700.00
        WHEN 1 THEN 2100.00
        ELSE 3100.00 
    END,
    CASE MOD(i, 3)
        WHEN 0 THEN 'IC'
        WHEN 1 THEN 'Mestrado'
        ELSE 'Doutorado'
    END,
    'PROC-' || LPAD(CAST(i AS VARCHAR), 8, '0')
FROM seq_bolsas;

WITH RECURSIVE seq_contratos(i) AS (
    SELECT 1
    UNION ALL
    SELECT i + 1 FROM seq_contratos WHERE i < 6000
)
INSERT INTO contrato (id_pesquisador, id_projeto, id_bolsa, data_assinatura, data_vencimento, tipo_vinculo)
SELECT 
    CAST(FLOOR(RANDOM() * 5000 + 1) AS INTEGER), -- id_pesquisador aleatório
    
    CASE 
        WHEN i <= 3000 THEN (SELECT id_projeto FROM bolsa WHERE id_bolsa = i)
        ELSE CAST(FLOOR(RANDOM() * 1000 + 1) AS INTEGER) 
    END,
    
    CASE WHEN i <= 3000 THEN i ELSE NULL END,
    
    CURRENT_DATE - CAST(FLOOR(RANDOM() * 500 + 180) AS INTEGER) * INTERVAL '1 day',
    CURRENT_DATE + CAST(FLOOR(RANDOM() * 500) AS INTEGER) * INTERVAL '1 day',
    
    CASE WHEN i <= 3000 THEN 'Bolsista' ELSE 'Voluntário' END
FROM seq_contratos;

INSERT INTO bolsa (id_projeto, valor_bolsa, categoria_bolsa, numero_processo)
SELECT 
    c.id_projeto,
    SUM(b.valor_bolsa),
    'Orçamento Consolidado',
    'TOTAL-' || LPAD(CAST(c.id_projeto AS VARCHAR), 8, '0')
FROM contrato c
JOIN bolsa b ON c.id_bolsa = b.id_bolsa
GROUP BY c.id_projeto;

INSERT INTO financia (id_financiador, id_projeto, valor_aportado)
SELECT 
    f.id_financiador, 
    p.id_projeto, 
    CAST(ROUND(CAST(RANDOM() * 490000 + 10000 AS NUMERIC), 2) AS DECIMAL(10,2))
FROM financiador f
CROSS JOIN projeto p
ORDER BY RANDOM()
FETCH FIRST 1500 ROWS ONLY;

WITH RECURSIVE seq_pub(i) AS (
    SELECT 1
    UNION ALL
    SELECT i + 1 FROM seq_pub WHERE i < 2000
)
INSERT INTO publicacao (id_projeto, doi, titulo_publicacao, data_publicacao)
SELECT 
    CAST(FLOOR(RANDOM() * 1000 + 1) AS INTEGER),
    '10.1000/ufba.' || LPAD(CAST(i AS VARCHAR), 6, '0'),
    'Análise de Dados Vol. ' || CAST(i AS VARCHAR),
    CURRENT_DATE - CAST(FLOOR(RANDOM() * 700) AS INTEGER) * INTERVAL '1 day'
FROM seq_pub;

WITH RECURSIVE seq_rel(seq) AS (
    SELECT 1
    UNION ALL
    SELECT seq + 1 FROM seq_rel WHERE seq < 3
)
INSERT INTO relatorio (id_projeto, sequencial_relatorio, data_submissao, texto_conteudo)
SELECT 
    p.id_projeto,
    s.seq,
    CURRENT_DATE - CAST(FLOOR(RANDOM() * 300) AS INTEGER) * INTERVAL '1 day',
    'Conteúdo gerado para o relatório ' || CAST(p.id_projeto AS VARCHAR) || '-' || CAST(s.seq AS VARCHAR)
FROM projeto p
CROSS JOIN seq_rel s
ORDER BY RANDOM()
FETCH FIRST 2000 ROWS ONLY;