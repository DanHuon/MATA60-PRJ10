Q.1.1

Primeiro e último contrato de cada pesquisador 
Média 0,0204 
Desvio Padrão 0,00203

SELECT DISTINCT
    nome_completo,
    FIRST_VALUE(titulo_projeto)  OVER w AS primeiro_projeto,
    FIRST_VALUE(data_assinatura)  OVER w AS inicio_carreira,
    LAST_VALUE(titulo_projeto)   OVER w AS ultimo_projeto,
    LAST_VALUE(data_vencimento)  OVER w AS fim_ultimo_contrato
FROM (
    SELECT
        p.primeiro_nome || ' ' || p.sobrenome AS nome_completo, pr.titulo_projeto,
        c.data_assinatura, c.data_vencimento
    FROM contrato c
    JOIN pesquisador p  ON p.id_pesquisador = c.id_pesquisador
    JOIN projeto    pr  ON pr.id_projeto    = c.id_projeto
) AS base
WINDOW w AS (
    PARTITION BY nome_completo ORDER BY data_assinatura
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING




Q.1.2


Pesquisadores com Contratos ativos e suas bolsas (R3,R4) 
Média 0,00795
Desvio Padrão 0,00131

SELECT
    p.primeiro_nome || ' ' || p.sobrenome AS nome_completo,
    COUNT(c.id_contrato)          AS total_contratos,
    COUNT(c.id_bolsa)            AS contratos_com_bolsa,
    COALESCE(SUM(b.valor_bolsa), 0) AS valor_total_bolsas
FROM pesquisador p
JOIN contrato   c ON c.id_pesquisador = p.id_pesquisador
LEFT JOIN bolsa  b ON b.id_bolsa      = c.id_bolsa
WHERE c.data_vencimento >= CURRENT_DATE
GROUP BY
    p.id_pesquisador, p.cpf_pesquisador,
    p.primeiro_nome, p.sobrenome







Q.1.3

Financiadores com total de bolsas e publicação por projeto (R1,R2,R5)
Média 0,0087
Desvio Padrão 0,00152

SELECT
    f.nome_financiador,
    f.tipo_financiador,
    COUNT(DISTINCT fi.id_projeto) AS total_projetos,
    COUNT(DISTINCT b.id_bolsa)   AS total_bolsas,
    COUNT(DISTINCT pu.id_publicacao) AS total_publicacoes
FROM financiador f
JOIN financia fi         ON fi.id_financiador = f.id_financiador
LEFT JOIN bolsa b       ON b.id_projeto      = fi.id_projeto
LEFT JOIN publicacao pu ON pu.id_projeto     = fi.id_projeto
GROUP BY f.id_financiador, f.nome_financiador, f.tipo_financiador

Q.1.4
Média 0,0527
Desvio Padrão 0,00618

Ranking de pesquisadores pelo número de contratos (R4,R7)

SELECT
    nome_completo,
    total_contratos,
    RANK() OVER (ORDER BY total_contratos DESC) AS ranking
FROM (
    SELECT
        p.primeiro_nome || ' ' || p.sobrenome AS nome_completo,
        COUNT(c.id_contrato) AS total_contratos
    FROM pesquisador p
    JOIN contrato c ON c.id_pesquisador = p.id_pesquisador
    GROUP BY p.id_pesquisador, p.primeiro_nome, p.sobrenome
) AS sub
ORDER BY ranking;

 

















Q.1.5

Valor acumulado de bolsas por categoria (R2,R8)
Média 0,0091 
Desvio Padrão 0,00137

SELECT
    pr.titulo_projeto,
    b.categoria_bolsa,
    COUNT(b.id_bolsa)  AS qtd_bolsas,
    SUM(b.valor_bolsa) AS total_categoria,
    ROUND(
        SUM(b.valor_bolsa) * 100.0
        / SUM(SUM(b.valor_bolsa)) OVER (PARTITION BY b.id_projeto)
    , 2) AS pct_no_projeto
FROM bolsa b
JOIN projeto pr ON pr.id_projeto = b.id_projeto
GROUP BY
    b.id_projeto, pr.titulo_projeto,
    b.categoria_bolsa
ORDER BY pr.titulo_projeto, total_categoria DESC;




Q.1.6
Média 0,00875
Desvio Padrão 0,00125

Projetos com número de relatórios e pesquisadores vinculados (R3,R4,R6)

SELECT
    pr.id_projeto,
    pr.titulo_projeto,
    COUNT(DISTINCT r.sequencial_relatorio) AS total_relatorios,
    COUNT(DISTINCT c.id_pesquisador)       AS total_pesquisadores
FROM projeto pr
LEFT JOIN relatorio r ON r.id_projeto = pr.id_projeto
LEFT JOIN contrato c  ON c.id_projeto = pr.id_projeto
GROUP BY pr.id_projeto, pr.titulo_projeto
HAVING COUNT(DISTINCT r.sequencial_relatorio) > 0
ORDER BY total_relatorios DESC;














Q.1.7
Média 0,00455
Desvio Padrão 0,00105

Aporte financeiro público x privado (R1,R9)

SELECT
    pr.titulo_projeto,
    COALESCE(SUM(fi.valor_aportado)
        FILTER (WHERE LOWER(f.tipo_financiador) = 'público'), 0)  AS aporte_publico,
    COALESCE(SUM(fi.valor_aportado)
        FILTER (WHERE LOWER(f.tipo_financiador) = 'privado'), 0)  AS aporte_privado,
    SUM(fi.valor_aportado) AS aporte_total,
    COUNT(DISTINCT f.id_financiador)                              AS total_financiadores
FROM projeto pr
JOIN financia   fi ON fi.id_projeto    = pr.id_projeto
JOIN financiador f  ON f.id_financiador = fi.id_financiador
GROUP BY pr.id_projeto, pr.titulo_projeto
ORDER BY aporte_total DESC;

























Q.1.8
Média 0,00915
Desvio Padrão 0,00087

Publicações com Pesquisadores ativos no lançamento (R3,R4,R5)

SELECT
    pu.doi,
    pu.titulo_publicacao,
    pu.data_publicacao,
    pr.titulo_projeto,
    COUNT(c.id_pesquisador) AS coautores_ativos
FROM publicacao pu
JOIN projeto  pr ON pr.id_projeto    = pu.id_projeto
JOIN contrato c  ON c.id_projeto    = pu.id_projeto
    AND c.data_assinatura <= pu.data_publicacao
    AND c.data_vencimento  >= pu.data_publicacao
GROUP BY
    pu.id_publicacao, pu.doi,
    pu.titulo_publicacao, pu.data_publicacao,
    pr.titulo_projeto
ORDER BY pu.data_publicacao DESC;





Q.1.9
Média 0,0249
Desvio Padrão 0,00224
Histórico de contratos por pesquisador, com acúmulo de tempo de contrato e dias de trabalho (R3,R4,R7)

SELECT
    p.primeiro_nome || ' ' || p.sobrenome     AS nome_completo,
    pr.titulo_projeto,
    c.tipo_vinculo,
    c.data_assinatura,
    c.data_vencimento,
    (c.data_vencimento - c.data_assinatura)   AS duracao_dias,
    SUM(c.data_vencimento - c.data_assinatura)
        OVER (
            PARTITION BY c.id_pesquisador
            ORDER BY    c.data_assinatura
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                         AS dias_acumulados
FROM contrato c
JOIN pesquisador p  ON p.id_pesquisador = c.id_pesquisador
JOIN projeto    pr ON pr.id_projeto    = c.id_projeto
ORDER BY nome_completo, c.data_assinatura;



Q.1.10
Média 0,0032
Desvio Padrão 0,00095

Bolsas com pesquisadores vinculados e média do valor (R2,R3,R8)

SELECT
    b.categoria_bolsa,
    COUNT(c.id_contrato)    AS contratos_com_esta_categoria,
    ROUND(AVG(b.valor_bolsa), 2) AS media_categoria,
    ROUND(
        AVG(AVG(b.valor_bolsa)) OVER ()
    , 2)                       AS media_global_categorias,
    ROUND(
        AVG(b.valor_bolsa)
        - AVG(AVG(b.valor_bolsa)) OVER ()
    , 2)                       AS desvio_da_media_global
FROM bolsa b
JOIN contrato c ON c.id_bolsa = b.id_bolsa
JOIN projeto  p ON p.id_projeto = b.id_projeto
GROUP BY b.categoria_bolsa
ORDER BY media_categoria DESC;




Q.1.11
Média 0,0489
Desvio Padrão 0,00347

Painel de produtividade por projeto

SELECT
    pr.titulo_projeto,
    pr.data_inicio,
    pr.data_termino,
    COUNT(DISTINCT fi.id_financiador)       AS financiadores,
    COUNT(DISTINCT b.id_bolsa)              AS bolsas,
    COUNT(DISTINCT c.id_pesquisador)        AS pesquisadores,
    COUNT(DISTINCT pu.id_publicacao)        AS publicacoes,
    COUNT(DISTINCT r.sequencial_relatorio)  AS relatorios
FROM projeto pr
LEFT JOIN financia   fi  ON fi.id_projeto    = pr.id_projeto
LEFT JOIN bolsa      b   ON b.id_projeto     = pr.id_projeto
LEFT JOIN contrato   c   ON c.id_projeto     = pr.id_projeto
LEFT JOIN publicacao pu  ON pu.id_projeto    = pr.id_projeto
LEFT JOIN relatorio  r   ON r.id_projeto     = pr.id_projeto
GROUP BY
    pr.id_projeto, pr.titulo_projeto,
    pr.data_inicio, pr.data_termino
ORDER BY publicacoes DESC, relatorios DESC;






Q.2.1

Média 0,00695
Desvio Padrão 0,00131


Pesquisadores acima de sua média de contratos(R4,R7)

SELECT
    p.primeiro_nome || ' ' || p.sobrenome AS nome_completo,
    COUNT(c.id_contrato) AS total_contratos
FROM pesquisador p
JOIN contrato c  ON c.id_pesquisador = p.id_pesquisador
JOIN projeto  pr ON pr.id_projeto   = c.id_projeto
GROUP BY p.id_pesquisador, p.primeiro_nome, p.sobrenome
HAVING COUNT(c.id_contrato) > (
    SELECT AVG(cnt) FROM (
        SELECT COUNT(id_contrato) AS cnt
        FROM contrato
        GROUP BY id_pesquisador
    ) AS sub
)



Q.2.2

Média 0,00715
Desvio Padrão 0,00113

Pesquisadores em múltiplos projetos(R4,R7)

SELECT
    p.primeiro_nome || ' ' || p.sobrenome AS nome_completo,
    COUNT(DISTINCT c.id_projeto) AS projetos_distintos
FROM pesquisador p
JOIN contrato c ON c.id_pesquisador = p.id_pesquisador
WHERE p.id_pesquisador IN (
    SELECT id_pesquisador FROM contrato
    GROUP BY id_pesquisador
    HAVING COUNT(DISTINCT id_projeto) > 1
)
GROUP BY p.id_pesquisador, p.primeiro_nome, p.sobrenome






Q.2.3

Média 
Desvio Padrão

Bolsistas Jamais associados a um contrato (R2,R3)

SELECT
    pr.titulo_projeto,
    b.categoria_bolsa,
    b.valor_bolsa,
    b.numero_processo,
    (
        SELECT COUNT(*) FROM bolsa b2
        WHERE b2.id_projeto = pr.id_projeto
    ) AS total_bolsas_projeto
FROM bolsa b
JOIN projeto pr ON pr.id_projeto = b.id_projeto
WHERE b.id_bolsa NOT IN (
    SELECT id_bolsa FROM contrato
    WHERE id_bolsa IS NOT NULL
)
ORDER BY pr.titulo_projeto, b.categoria_bolsa;






Q.2.4
Média 
Desvio Padrão

Pesquisador que recebe a maior bolsa por projeto(R2,R3,R4)


SELECT titulo_projeto, nome_completo, titulacao, tipo_vinculo, valor_bolsa
FROM (
    SELECT
        pr.titulo_projeto,
        p.primeiro_nome || ' ' || p.sobrenome AS nome_completo,
        p.titulacao, c.tipo_vinculo, b.valor_bolsa,
        ROW_NUMBER() OVER (
            PARTITION BY pr.id_projeto
            ORDER BY b.valor_bolsa DESC
        ) AS rn
    FROM contrato c
    JOIN pesquisador p  ON p.id_pesquisador = c.id_pesquisador
    JOIN projeto    pr  ON pr.id_projeto    = c.id_projeto
    JOIN bolsa       b  ON b.id_bolsa       = c.id_bolsa
) AS ranked
WHERE rn = 1
ORDER BY titulo_projeto;





Q.2.5
Média 
Desvio Padrão

Financiadores financiando projetos sem relatório(1,6,9)

SELECT
    f.nome_financiador, f.tipo_financiador,
    COUNT(DISTINCT fi.id_projeto) AS projetos_sem_relatorio,
    SUM(fi.valor_aportado)        AS total_aportado
FROM financiador f
JOIN financia fi ON fi.id_financiador = f.id_financiador
JOIN projeto  pr ON pr.id_projeto     = fi.id_projeto
WHERE NOT EXISTS (
    SELECT 1 FROM relatorio r
    WHERE r.id_projeto = fi.id_projeto
)
GROUP BY f.id_financiador, f.nome_financiador, f.tipo_financiador
ORDER BY total_aportado DESC;


Q.2.6
Média 
Desvio Padrão

Pesquisadores sem bolsa ou projeto

SELECT
    p.primeiro_nome || ' ' || p.sobrenome AS nome_completo,
    p.titulacao,
    COUNT(c.id_contrato)         AS total_contratos,
    COUNT(DISTINCT c.id_projeto) AS projetos_distintos
FROM pesquisador p
JOIN contrato c  ON c.id_pesquisador = p.id_pesquisador
JOIN projeto  pr ON pr.id_projeto   = c.id_projeto
WHERE NOT EXISTS (
    SELECT 1 FROM contrato c2
    WHERE c2.id_pesquisador = p.id_pesquisador
      AND c2.id_bolsa IS NOT NULL
)
GROUP BY p.id_pesquisador, p.primeiro_nome, p.sobrenome, p.titulacao
ORDER BY total_contratos DESC;

Q.2.7
Média 
Desvio Padrão

Projetos financiados só por capital privado(1,9)

SELECT
    pr.titulo_projeto,
    COUNT(DISTINCT fi.id_financiador) AS total_financiadores,
    SUM(fi.valor_aportado) AS total_aportado
FROM projeto pr
JOIN financia    fi ON fi.id_projeto    = pr.id_projeto
JOIN financiador f  ON f.id_financiador = fi.id_financiador
WHERE pr.id_projeto IN (
    SELECT fi2.id_projeto
    FROM financia fi2
    JOIN financiador f2 ON f2.id_financiador = fi2.id_financiador
    GROUP BY fi2.id_projeto
    HAVING COUNT(*) FILTER (WHERE LOWER(f2.tipo_financiador) = 'público') = 0
)
GROUP BY pr.id_projeto, pr.titulo_projeto
ORDER BY total_aportado DESC;






Q.2.8

Média 
Desvio Padrão

Pesquisadores com projetos com múltiplos financiadores(1,3,4)

SELECT
    p.primeiro_nome || ' ' || p.sobrenome AS nome_completo,
    p.titulacao,
    COUNT(DISTINCT c.id_projeto) AS projetos_multi_financiados,
    COUNT(c.id_contrato)          AS total_contratos
FROM pesquisador p
JOIN contrato c ON c.id_pesquisador = p.id_pesquisador
WHERE c.id_projeto IN (
    SELECT id_projeto FROM financia
    GROUP BY id_projeto
    HAVING COUNT(DISTINCT id_financiador) > 1
)
GROUP BY p.id_pesquisador, p.primeiro_nome, p.sobrenome, p.titulacao
ORDER BY projetos_multi_financiados DESC;



Q.2.9

Média 
Desvio Padrão

Concentração de bolsas de doutorado por projeto


SELECT
    pr.titulo_projeto,
    total_bolsas, bolsas_doutorado,
    ROUND(100.0 * bolsas_doutorado / NULLIF(total_bolsas, 0), 2) AS pct_doutorado
FROM projeto pr
JOIN (
    SELECT
        id_projeto,
        COUNT(*) AS total_bolsas,
        COUNT(*) FILTER (WHERE LOWER(categoria_bolsa) = 'doutorado') AS bolsas_doutorado
    FROM bolsa GROUP BY id_projeto
) AS resumo ON resumo.id_projeto = pr.id_projeto
JOIN financia fi ON fi.id_projeto = pr.id_projeto
WHERE bolsas_doutorado > 0
GROUP BY pr.id_projeto, pr.titulo_projeto, total_bolsas, bolsas_doutorado
ORDER BY pct_doutorado DESC;

Q.2.10

Média 
Desvio Padrão

Quantidade de publicações por milhão investido

SELECT
    f.nome_financiador, f.tipo_financiador,
    total_aportado, total_publicacoes,
    ROUND(total_publicacoes::NUMERIC / NULLIF(total_aportado, 0) * 1000000, 4)
        AS publicacoes_por_milhao_reais
FROM financiador f
JOIN (
    SELECT
        fi.id_financiador,
        SUM(fi.valor_aportado) AS total_aportado,
        COUNT(DISTINCT pu.id_publicacao) AS total_publicacoes
    FROM financia fi
    JOIN projeto    pr ON pr.id_projeto  = fi.id_projeto
    LEFT JOIN publicacao pu ON pu.id_projeto = fi.id_projeto
    GROUP BY fi.id_financiador
) AS desempenho ON desempenho.id_financiador = f.id_financiador
