-- ==========================================
-- Plano 1
-- ==========================================

-- Índices para otimização de JOINs (Foreign Keys)
CREATE INDEX idx_contrato_pesquisador ON contrato(id_pesquisador);
CREATE INDEX idx_contrato_projeto ON contrato(id_projeto);
CREATE INDEX idx_bolsa_projeto ON bolsa(id_projeto);
CREATE INDEX idx_publicacao_projeto ON publicacao(id_projeto);
CREATE INDEX idx_financia_projeto ON financia(id_projeto);

-- Índices Funcionais para otimizar filtros com LOWER() usados nas suas queries (Ex: Q.1.7, Q.2.7, Q.2.9)
CREATE INDEX idx_financiador_tipo ON financiador(LOWER(tipo_financiador));
CREATE INDEX idx_bolsa_categoria ON bolsa(LOWER(categoria_bolsa));

-- Índices para otimizar filtros de datas ativos (Ex: Q.1.2 e Q.1.8)
CREATE INDEX idx_contrato_vencimento ON contrato(data_vencimento);