-- ==========================================
-- Plano 2
-- ==========================================

-- Índices compostos para otimizar consultas que filtram ou ordenam por múltiplas colunas simultaneamente
CREATE INDEX idx_comp_contrato_pesq_proj ON contrato(id_pesquisador, id_projeto);

CREATE INDEX idx_comp_bolsa_proj_valor ON bolsa(id_projeto, valor_bolsa);

CREATE INDEX idx_comp_pub_proj_data ON publicacao(id_projeto, data_publicacao);

CREATE INDEX idx_comp_financia_proj_valor ON financia(id_projeto, valor_aportado);