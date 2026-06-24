CREATE INDEX idx_part_contrato_ativo ON contrato(id_projeto) 
WHERE data_vencimento >= CURRENT_DATE;

CREATE INDEX idx_part_contrato_bolsista ON contrato(id_pesquisador) 
WHERE tipo_vinculo = 'Bolsista';

CREATE INDEX idx_part_financia_alto ON financia(id_projeto) 
WHERE valor_aportado > 100000.00;

CREATE INDEX idx_part_financiador_publico ON financiador(id_financiador) 
WHERE LOWER(tipo_financiador) = 'público';