-- ====================================================================================
-- ARTEFATO 1: Procedure de Promoção
-- ====================================================================================
-- Stored Procedure 1 de 2 - Tela 1
-- Contagem exigida: 1 SELECT, 2 INSERTs, 2 UPDATEs
CREATE OR REPLACE PROCEDURE sp_promover_voluntario(
    p_id_pesquisador INTEGER,
    p_id_projeto INTEGER,
    p_valor_bolsa DECIMAL,
    p_categoria_bolsa VARCHAR,
    p_numero_processo VARCHAR,
    p_nova_titulacao VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_contrato_antigo INTEGER;
    v_nova_bolsa INTEGER;
BEGIN
    -- 1º SELECT
    SELECT id_contrato INTO v_contrato_antigo
    FROM contrato 
    WHERE id_pesquisador = p_id_pesquisador 
      AND id_projeto = p_id_projeto
      AND id_bolsa IS NULL 
      AND data_vencimento >= CURRENT_DATE
    LIMIT 1;

    IF v_contrato_antigo IS NULL THEN
        RAISE EXCEPTION 'Nenhum contrato de voluntário ativo encontrado para este pesquisador no projeto.';
    END IF;

    -- 1º UPDATE
    UPDATE contrato 
    SET data_vencimento = CURRENT_DATE, 
        tipo_vinculo = 'Encerrado - Promovido'
    WHERE id_contrato = v_contrato_antigo;

    -- 2º UPDATE
    UPDATE pesquisador 
    SET titulacao = p_nova_titulacao 
    WHERE id_pesquisador = p_id_pesquisador;

    -- 1º INSERT
    INSERT INTO bolsa (id_projeto, valor_bolsa, categoria_bolsa, numero_processo)
    VALUES (p_id_projeto, p_valor_bolsa, p_categoria_bolsa, p_numero_processo)
    RETURNING id_bolsa INTO v_nova_bolsa;

    -- 2º INSERT
    INSERT INTO contrato (id_pesquisador, id_projeto, id_bolsa, data_assinatura, data_vencimento, tipo_vinculo)
    VALUES (p_id_pesquisador, p_id_projeto, v_nova_bolsa, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 year', 'Bolsista');
    
    -- Atualização do Cache Analítico
    REFRESH MATERIALIZED VIEW mv_estrategica_aportes_anuais;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro na operação: %', SQLERRM;
END;
$$;


-- ====================================================================================
-- ARTEFATO 2: Procedure de Encerramento
-- ====================================================================================
-- Stored Procedure 2 de 2 - Tela 2
-- Contagem exigida: 2 SELECTs, 1 INSERT, 2 UPDATEs, 1 DELETE
CREATE OR REPLACE PROCEDURE sp_encerramento_emergencial(
    p_id_projeto INTEGER,
    p_motivo VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_contratos INTEGER;
    v_novo_sequencial INTEGER;
BEGIN
    -- 1º SELECT
    SELECT COUNT(*) INTO v_total_contratos
    FROM contrato 
    WHERE id_projeto = p_id_projeto AND data_vencimento > CURRENT_DATE;

    -- 2º SELECT
    SELECT COALESCE(MAX(sequencial_relatorio), 0) + 1 INTO v_novo_sequencial
    FROM relatorio
    WHERE id_projeto = p_id_projeto;

    -- 1º DELETE
    DELETE FROM relatorio 
    WHERE id_projeto = p_id_projeto AND LENGTH(texto_conteudo) < 10;

    -- 1º UPDATE
    UPDATE projeto 
    SET data_termino = CURRENT_DATE, 
        titulo_projeto = titulo_projeto || ' (ENCERRADO)'
    WHERE id_projeto = p_id_projeto;

    -- 2º UPDATE
    UPDATE contrato 
    SET data_vencimento = CURRENT_DATE, 
        tipo_vinculo = 'Cancelado'
    WHERE id_projeto = p_id_projeto AND data_vencimento > CURRENT_DATE;

    -- 1º INSERT
    INSERT INTO relatorio (id_projeto, sequencial_relatorio, data_submissao, texto_conteudo)
    VALUES (
        p_id_projeto, 
        v_novo_sequencial, 
        CURRENT_DATE, 
        'Encerramento emergencial. Motivo: ' || p_motivo || '. Contratos afetados: ' || v_total_contratos
    );

    -- Atualização do Cache Analítico
    REFRESH MATERIALIZED VIEW mv_operacional_equidade_incentivos;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro na operação: %', SQLERRM;
END;
$$;


-- ====================================================================================
-- ARTEFATO 3: Scripts de Chamada (Transações)
-- ====================================================================================

-- Transação 1 de 2 - Execução ACID da Tela 1
-- Execução da Tela 1
BEGIN;
CALL sp_promover_voluntario(1, 10, 1500.00, 'Mestrado', 'PROC-001', 'Mestre');
COMMIT;

-- Transação 2 de 2 - Execução ACID da Tela 2
-- Execução da Tela 2
BEGIN;
CALL sp_encerramento_emergencial(5, 'Corte de fomento estatal');
COMMIT;
