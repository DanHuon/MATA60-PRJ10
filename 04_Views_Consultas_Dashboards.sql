-- ====================================================================================
-- Dashboards 1 e 2: Views Materializadas e Consultas em Tempo Real
-- ====================================================================================

-- ------------------------------------------------------------------------------------
-- MATERIALIZED VIEWS (Consultas de Alto Custo Computacional)
-- ------------------------------------------------------------------------------------

-- Materialized View 1 de 2
-- ARTEFATO 1: Dashboard 1 (Estratégico) - Agregações anuais pesadas e pivoteamento
CREATE MATERIALIZED VIEW mv_estrategica_aportes_anuais AS
SELECT 
    ano_inicio,
    COUNT(id_projeto) AS total_projetos_ano,
    SUM(CASE WHEN LOWER(tipo) = 'público' THEN valor ELSE 0 END) AS total_publico,
    SUM(CASE WHEN LOWER(tipo) = 'privado' THEN valor ELSE 0 END) AS total_privado
FROM (
    SELECT 
        pr.id_projeto,
        EXTRACT(YEAR FROM pr.data_inicio) AS ano_inicio,
        LOWER(f.tipo_financiador) AS tipo,
        fi.valor_aportado AS valor
    FROM projeto pr
    JOIN financia fi ON fi.id_projeto = pr.id_projeto
    JOIN financiador f ON f.id_financiador = fi.id_financiador
) sub_dados
GROUP BY ano_inicio
ORDER BY ano_inicio DESC;

-- Materialized View 2 de 2
-- ARTEFATO 2: Dashboard 2 (Operacional) - Uso intensivo de Window Functions
CREATE MATERIALIZED VIEW mv_operacional_equidade_incentivos AS
SELECT 
    pr.titulo_projeto,
    p.primeiro_nome,
    b.valor_bolsa,
    COUNT(c.id_contrato) OVER (PARTITION BY pr.id_projeto) AS total_contratos_projeto,
    DENSE_RANK() OVER (
        PARTITION BY pr.id_projeto 
        ORDER BY COALESCE(b.valor_bolsa, 0) DESC
    ) AS posicao_no_projeto
FROM contrato c
JOIN projeto pr ON pr.id_projeto = c.id_projeto
JOIN pesquisador p ON p.id_pesquisador = c.id_pesquisador
LEFT JOIN bolsa b ON b.id_bolsa = c.id_bolsa;


-- ------------------------------------------------------------------------------------
-- PASSO 2: CONSULTAS EM TEMPO REAL (8 Gráficos Restantes)
-- ------------------------------------------------------------------------------------

-- Consultas de dashboard em tempo real: 8 restantes; total = 2 MVs + 8 SELECTs = 10 dashboards
-- [DASHBOARD 2] Q.1.12
SELECT 
    pr.id_projeto,
    pr.titulo_projeto,
    COUNT(c.id_contrato) AS total_contratos,
    ROUND(AVG(c.data_vencimento - c.data_assinatura), 1) AS media_dias_contrato
FROM projeto pr
JOIN contrato c ON c.id_projeto = pr.id_projeto
JOIN pesquisador p ON p.id_pesquisador = c.id_pesquisador
GROUP BY pr.id_projeto, pr.titulo_projeto
ORDER BY media_dias_contrato DESC;

-- [DASHBOARD 2] Q.1.13
SELECT 
    f.nome_financiador,
    f.tipo_financiador,
    COUNT(b.id_bolsa) AS total_bolsas_pagas,
    SUM(b.valor_bolsa) AS investimento_total_bolsas
FROM financiador f
JOIN financia fi ON fi.id_financiador = f.id_financiador
JOIN bolsa b     ON b.id_projeto = fi.id_projeto
GROUP BY f.id_financiador, f.nome_financiador, f.tipo_financiador
ORDER BY investimento_total_bolsas DESC;

-- [DASHBOARD 2] Q.1.14
SELECT 
    p.titulacao,
    COUNT(DISTINCT p.id_pesquisador) AS total_pesquisadores,
    COUNT(c.id_contrato) AS total_contratos_assinados
FROM pesquisador p
JOIN contrato c ON c.id_pesquisador = p.id_pesquisador
JOIN projeto pr ON pr.id_projeto = c.id_projeto
GROUP BY p.titulacao
ORDER BY total_pesquisadores DESC;

-- [DASHBOARD 2] Q.1.15
SELECT 
    pr.id_projeto,
    pr.titulo_projeto,
    COUNT(DISTINCT pu.id_publicacao) AS total_publicacoes,
    COUNT(DISTINCT c.id_pesquisador) AS pesquisadores_envolvidos
FROM projeto pr
JOIN publicacao pu ON pu.id_projeto = pr.id_projeto
LEFT JOIN contrato c ON c.id_projeto = pr.id_projeto
GROUP BY pr.id_projeto, pr.titulo_projeto
ORDER BY total_publicacoes DESC;

-- [DASHBOARD 2] Q.2.21
SELECT 
    p.id_pesquisador,
    p.primeiro_nome,
    p.titulacao,
    COUNT(c.id_contrato) AS total_contratos_pesquisador
FROM pesquisador p
JOIN contrato c ON c.id_pesquisador = p.id_pesquisador
JOIN projeto pr ON pr.id_projeto = c.id_projeto
GROUP BY p.id_pesquisador, p.primeiro_nome, p.titulacao
HAVING COUNT(c.id_contrato) > (
    SELECT AVG(sub_contagem)
    FROM (
        SELECT p_sub.titulacao, COUNT(c_sub.id_contrato) AS sub_contagem
        FROM pesquisador p_sub
        JOIN contrato c_sub ON c_sub.id_pesquisador = p_sub.id_pesquisador
        GROUP BY p_sub.id_pesquisador, p_sub.titulacao
    ) sub
    WHERE sub.titulacao = p.titulacao
    GROUP BY sub.titulacao
);

-- [DASHBOARD 1] Q.2.22
SELECT 
    f.id_financiador,
    f.nome_financiador,
    COUNT(fi.id_projeto) AS total_projetos_financiados
FROM financiador f
JOIN financia fi ON fi.id_financiador = f.id_financiador
WHERE NOT EXISTS (
    SELECT 1 
    FROM financia fi2 
    WHERE fi2.id_financiador = f.id_financiador
      AND NOT EXISTS (
          SELECT 1 
          FROM publicacao pu 
          WHERE pu.id_projeto = fi2.id_projeto
      )
)
GROUP BY 
    f.id_financiador, 
    f.nome_financiador;

-- [DASHBOARD 1] Q.2.25
SELECT 
    pr.id_projeto,
    pr.titulo_projeto,
    COUNT(c.id_contrato) AS quantidade_bolsistas,
    (SELECT SUM(b.valor_bolsa) FROM contrato cx JOIN bolsa b ON cx.id_bolsa = b.id_bolsa WHERE cx.id_projeto = pr.id_projeto) AS custo_bolsas
FROM projeto pr
JOIN contrato c ON c.id_projeto = pr.id_projeto
GROUP BY pr.id_projeto, pr.titulo_projeto
HAVING 
    (SELECT SUM(b.valor_bolsa) FROM contrato cx JOIN bolsa b ON cx.id_bolsa = b.id_bolsa WHERE cx.id_projeto = pr.id_projeto) > 
    (SELECT SUM(fi.valor_aportado) * 0.6 FROM financia fi WHERE fi.id_projeto = pr.id_projeto);

-- [DASHBOARD 1] Q.2.26
SELECT 
    id_pesquisador,
    primeiro_nome,
    titulo_projeto,
    fim_contrato_anterior,
    inicio_contrato_atual,
    (inicio_contrato_atual - fim_contrato_anterior) AS dias_de_intervalo
FROM (
    SELECT 
        p.id_pesquisador,
        p.primeiro_nome,
        pr.titulo_projeto,
        c.data_assinatura AS inicio_contrato_atual,
        LAG(c.data_vencimento) OVER (
            PARTITION BY p.id_pesquisador 
            ORDER BY c.data_assinatura
        ) AS fim_contrato_anterior
    FROM contrato c
    JOIN pesquisador p ON p.id_pesquisador = c.id_pesquisador
    JOIN projeto pr    ON pr.id_projeto = c.id_projeto
) sub_historico
WHERE fim_contrato_anterior IS NOT NULL
  AND (inicio_contrato_atual - fim_contrato_anterior) BETWEEN 0 AND 30
ORDER BY dias_de_intervalo ASC;


-- ------------------------------------------------------------------------------------
-- PASSO 3: MANUTENÇÃO (Comandos de Refresh)
-- ------------------------------------------------------------------------------------

-- A ideia da execução dos comandos abaixo é serem programados em rotinas de cron jobs (Execução periódica automática pelo sistema operacional)

-- Atualização do Cache Analítico
REFRESH MATERIALIZED VIEW mv_estrategica_aportes_anuais;
REFRESH MATERIALIZED VIEW mv_operacional_equidade_incentivos;
