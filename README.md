# Sistema de Gestão de Pesquisa - Documentação do Projeto

## 1. O Que Fizemos Até Agora
Ao longo do projeto, modelamos a arquitetura lógica e conceitual do banco de dados para o sistema de Gestão de Pesquisa. As principais evoluções incluem:
- **Modelagem de Entidades:** Estruturamos os domínios de Pesquisadores, Projetos, Financiadores e Produção Acadêmica.
- **Otimização de Chaves Primárias (PK):** Substituímos o uso de CPF, CNPJ e DOI como Chaves Primárias por IDs substitutos (ex: `ID_Pesquisador`, `ID_Financiador`). Isso previne travamentos operacionais (*locks*) em cascata (`ON UPDATE CASCADE`) caso ocorram erros de digitação e melhora a performance de `JOIN`s, substituindo grandes campos VARCHAR por inteiros mais leves.
- **Relacionamentos e Cardinalidades:** - Ajustamos a cardinalidade para refletir que se uma bolsa existe, ela automaticamente já remunera um contrato: `[Bolsa] (1,1) -> <Remunera> -> (0,1) [Contrato]`.
  - Consolidamos a relação N:N entre Financiador e Projeto transformando a relação *Fomenta* em uma tabela própria na fase DDL, incluindo o atributo essencial `valor_aportado`.
- **Regras de Negócio:** Definimos travas importantes para conformidade administrativa, como a exclusividade temporal de bolsas (um pesquisador não pode ter duas bolsas ativas simultâneas) e garantimos que Publicações não sejam tratadas como entidades fracas.

---

## 2. Como a Tabela Funciona (Estrutura e Relações)
O banco de dados foi projetado focando na integridade referencial entre o financiamento e a produção acadêmica. Eis como as entidades se comportam e se conectam:

* **Pesquisador:** A tabela principal que centraliza o cadastro de pessoas (incluindo pesquisadores e bolsistas). Possui seus dados (Nome, E-mail institucional, Titulação, etc.) e usa um `ID_Pesquisador` como PK. Relaciona-se na forma de 1:N com Bolsas e Contratos (um pesquisador pode ter múltiplas bolsas ao longo do tempo).
* **Projeto:** É o coração do sistema (`ID_Projeto`). Concentra as frentes de trabalho. Ele recebe financiamento (através da tabela *Fomenta*), possui diversas Bolsas e Contratos atrelados (1:N) e é a origem da Produção Acadêmica (1:N para Relatórios e Publicações).
* **Financiador:** Representa as instituições de fomento (`CNPJ`, `Nome`). Relaciona-se com múltiplos projetos por meio da tabela **Fomenta**.
* **Bolsa e Contrato:** Representam os vínculos financeiros. Uma `Bolsa` pertence a um `Pesquisador` específico e está diretamente ligada a um `Projeto` (usando as chaves estrangeiras `ID_Pesquisador` e `ID_Projeto`).
* **Publicação e Relatório (Produção Acadêmica):** Tabelas que rastreiam os resultados gerados por um projeto. Elas guardam a chave estrangeira do projeto de origem (`ID_Projeto`). No caso dos relatórios, a relação das assinaturas de pesquisadores forma uma tabela associativa N:N.

---

## 3. Como Conectar ao DBeaver (Passo a Passo)
O DBeaver atua como nossa principal ferramenta para visualizar e gerenciar as tabelas.

1.  **Abra o DBeaver.**
2.  No menu superior ou na aba lateral de navegação (*Database Navigator*), clique no ícone de **Nova Conexão** (ícone de tomada com um símbolo de "+").
3.  Selecione o SGBD escolhido para o projeto (ex: PostgreSQL ou MySQL) e clique em *Next* (Avançar).
4.  Preencha as configurações da conexão:
    * **Host:** `localhost` (se o banco estiver rodando localmente).
    * **Porta:** A porta padrão do banco (ex: `5432` para Postgres, `3306` para MySQL).
    * **Database:** O nome do banco de dados criado.
    * **Username / Password:** O seu usuário e senha do banco.
5.  Clique em **Test Connection** (Testar Conexão). Se as credenciais estiverem corretas, uma janela de sucesso aparecerá.
6.  Clique em **Finish** (Concluir). A conexão surgirá na aba lateral, bastando expandi-la para acessar as tabelas.

---

## 4. Como Gerar o Script de Banco de Dados (DDL) no DBeaver
Para exportar a estrutura final do modelo (CREATE TABLE, FKs, restrições) em formato SQL:

1.  No *Database Navigator*, expanda a conexão ativa até encontrar o **esquema** do projeto.
2.  Clique com o **botão direito** sobre o banco de dados ou o esquema desejado.
3.  Vá em **Tools** (Ferramentas) > **Generate DDL** (Gerar DDL).
4.  Na janela que se abrir, confira se todas as entidades (Pesquisador, Projeto, Bolsa, etc.) estão selecionadas.
5.  Na aba *Output*, configure a pasta onde o arquivo `.sql` será salvo no seu ambiente.
6.  Clique em **Start** ou *Generate*. O DBeaver criará o script completo.

---

## 5. Como Rodar o Script Python e Gerar os Mocks
O script Python automatiza a inserção de dados fictícios, mantendo a integridade referencial para testes robustos de software.

1.  **Abra o terminal do Ubuntu** diretamente na raiz da pasta do projeto.
2.  Ative o ambiente virtual para isolar as bibliotecas:
    ```bash
    source venv/bin/activate
    ```
3.  Instale as dependências listadas (como os drivers do banco ou bibliotecas como `Faker`):
    ```bash
    pip install -r requirements.txt
    ```
4.  Execute o arquivo Python responsável pelos dados:
    ```bash
    python mock_generator.py
    ```
    *(Caso o nome do script seja diferente, substitua `mock_generator.py` pelo nome correto no seu diretório).*
5.  O script conectará ao banco usando as credenciais configuradas, e inserirá as entidades base (Financiador, Pesquisador, Projeto) antes de inserir as dependentes (Bolsas, Publicações), evitando falhas de Foreign Key.
