CREATE OR REPLACE FUNCTION validar_projeto_bolsa_contrato()
RETURNS TRIGGER AS $$
DECLARE
    v_projeto_bolsa INTEGER;
BEGIN
    IF NEW.id_bolsa IS NOT NULL THEN
        
        SELECT id_projeto INTO v_projeto_bolsa
        FROM bolsa
        WHERE id_bolsa = NEW.id_bolsa;

        IF NEW.id_projeto <> v_projeto_bolsa THEN
            RAISE EXCEPTION 'Operação negada pela regra de negócio: O Contrato tenta vincular o Projeto %, mas a Bolsa % pertence de fato ao Projeto %.', 
                NEW.id_projeto, NEW.id_bolsa, v_projeto_bolsa;
        END IF;
        
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_valida_bolsa_contrato
BEFORE INSERT OR UPDATE ON contrato
FOR EACH ROW
EXECUTE FUNCTION validar_projeto_bolsa_contrato();