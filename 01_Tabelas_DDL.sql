CREATE TABLE projeto (
    id_projeto SERIAL PRIMARY KEY,
    titulo_projeto VARCHAR(255) NOT NULL,
    data_inicio DATE NOT NULL,
    data_termino DATE NOT NULL
);

CREATE TABLE financiador (
    id_financiador SERIAL PRIMARY KEY,
    cnpj_financiador CHAR(14) UNIQUE NOT NULL,
    nome_financiador VARCHAR(150) NOT NULL,
    tipo_financiador VARCHAR(50) NOT NULL,
    contato_financiador VARCHAR(100)
);

CREATE TABLE pesquisador (
    id_pesquisador SERIAL PRIMARY KEY,
    cpf_pesquisador CHAR(11) UNIQUE NOT NULL,
    titulacao VARCHAR(50) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    telefone VARCHAR(20),
    primeiro_nome VARCHAR(50) NOT NULL,
    sobrenome VARCHAR(50) NOT NULL
);

CREATE TABLE bolsa (
    id_bolsa SERIAL PRIMARY KEY,
    id_projeto INTEGER NOT NULL,
    valor_bolsa DECIMAL(10,2) NOT NULL,
    categoria_bolsa VARCHAR(50) NOT NULL,
    numero_processo VARCHAR(100) UNIQUE,
    
    CONSTRAINT fk_bolsa_projeto 
        FOREIGN KEY (id_projeto) 
        REFERENCES projeto (id_projeto) 
        ON DELETE CASCADE
);

CREATE TABLE contrato (
    id_contrato SERIAL PRIMARY KEY,
    id_pesquisador INTEGER NOT NULL,
    id_projeto INTEGER NOT NULL,
    id_bolsa INTEGER UNIQUE,
    data_assinatura DATE NOT NULL,
    data_vencimento DATE NOT NULL,
    tipo_vinculo VARCHAR(50) NOT NULL,

    CONSTRAINT fk_contrato_pesquisador 
        FOREIGN KEY (id_pesquisador) 
        REFERENCES pesquisador (id_pesquisador)
        ON DELETE RESTRICT,

    CONSTRAINT fk_contrato_projeto 
        FOREIGN KEY (id_projeto) 
        REFERENCES projeto (id_projeto) 
        ON DELETE CASCADE,

    CONSTRAINT fk_contrato_bolsa 
        FOREIGN KEY (id_bolsa) 
        REFERENCES bolsa (id_bolsa) 
        ON DELETE SET NULL
);

CREATE TABLE publicacao (
    id_publicacao SERIAL PRIMARY KEY,
    id_projeto INTEGER NOT NULL,
    doi VARCHAR(255) UNIQUE NOT NULL,
    titulo_publicacao VARCHAR(255) NOT NULL,
    data_publicacao DATE NOT NULL,
    
    CONSTRAINT fk_publicacao_projeto 
        FOREIGN KEY (id_projeto) 
        REFERENCES projeto (id_projeto) 
        ON DELETE CASCADE
);

CREATE TABLE relatorio (
    id_projeto INTEGER NOT NULL,
    sequencial_relatorio INTEGER NOT NULL,
    data_submissao DATE NOT NULL,
    texto_conteudo TEXT NOT NULL,
    PRIMARY KEY (id_projeto, sequencial_relatorio),
    
    CONSTRAINT fk_relatorio_projeto 
        FOREIGN KEY (id_projeto) 
        REFERENCES projeto (id_projeto) 
        ON DELETE CASCADE
);

CREATE TABLE financia (
    id_financiador INTEGER NOT NULL,
    id_projeto INTEGER NOT NULL,
    valor_aportado DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_financiador, id_projeto),

    CONSTRAINT fk_financia_financiador
        FOREIGN KEY (id_financiador)
        REFERENCES financiador (id_financiador) 
        ON DELETE RESTRICT,
   
    CONSTRAINT fk_financia_projeto 
        FOREIGN KEY (id_projeto) 
        REFERENCES projeto (id_projeto) 
        ON DELETE CASCADE
);