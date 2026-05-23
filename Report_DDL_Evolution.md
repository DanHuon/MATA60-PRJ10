# Relatório de Refatoração e Evolução do Banco de Dados (PRJ10 - Marco 1)

Este relatório documenta as decisões arquiteturais e as alterações estruturais realizadas entre a versão inicial do script DDL (rascunho `Tabelas.sql`) e a versão oficial de produção implementada no banco de dados.

Todas as alterações foram ancoradas nas exigências do barema da disciplina MATA60, nas regras da metodologia MAD (ISO 11179-5) e nas boas práticas descritas em nossa bibliografia oficial (Elmasri & Navathe; Silberschatz, Korth & Sudarshan).

---

## 1. Nomenclatura e Padrão Corporativo (Metodologia MAD)
* **Alteração:** Todas as tabelas, chaves e colunas foram convertidas de *PascalCase* ou *camelCase* para o padrão estrito **snake_case** em letras minúsculas.
* **Exemplos de correção:** * `Projeto` $
rightarrow$ `projeto`
    * `fk_Financiador_id_financiador` $
ightarrow$ `id_financiador`
* **Justificativa Teórica:** O padrão MAD (ISO 11179-5) exige padronização semântica. No PostgreSQL, o uso de letras maiúsculas forçaria o uso de aspas duplas em todas as queries (`SELECT * FROM "Projeto"`), o que é uma má prática de desenvolvimento e contraria as normas do projeto.

## 2. Integridade de Entidade e Restrições de Domínio
* **Alteração (Chaves Autoincrementais):** Os atributos identificadores primários (como `id_projeto INTEGER PRIMARY KEY`) foram substituídos por `SERIAL PRIMARY KEY`.
* **Justificativa Teórica:** A substituição garante a geração automática e sequencial de IDs (*sequences* no Postgres), o que é fundamental para evitar concorrência e facilitar inserções em massa (Fase 3).
* **Alteração (Obrigatoriedade):** Cláusulas `NOT NULL` foram adicionadas a praticamente todos os atributos descritivos vitais (ex: `titulo_projeto`, `data_inicio`, `email`, `primeiro_nome`).
* **Justificativa Teórica:** Eliminar valores nulos impede a perda de semântica e falhas na lógica de negócio (*Silberschatz, Cap. 4*). Um projeto de pesquisa não pode existir no banco sem um título.

## 3. Evolução Arquitetural de Chaves Estrangeiras (Mapeamento MER $
ightarrow$ Físico)
O mapeamento físico foi ajustado para refletir fielmente o nosso Modelo Entidade-Relacionamento aprovado na Fase 1 (*Elmasri, Cap. 5*).

### 3.1. Tabela Associativa (`financia`)
* **Erro Corrigido:** O rascunho possuía uma chave primária composta `PRIMARY KEY (fk_Financiador, fk_Projeto)`. No entanto, definia a restrição `ON DELETE SET NULL` para a foreign key do projeto.
* **Correção Aplicada:** Mudado para `ON DELETE CASCADE` no projeto e `RESTRICT` no financiador.
* **Justificativa Teórica:** Uma coluna que faz parte de uma Chave Primária (Integridade de Entidade) nunca pode ser anulada (`NULL`). Se o sistema apagasse o projeto e setasse a FK como nula, o banco de dados corromperia imediatamente.

### 3.2. Tabela Transacional Central (`contrato`)
* **Evolução:** A tabela foi configurada como uma "Entidade Forte" (com `id_contrato` autônomo) que recebe as Chaves Estrangeiras do `pesquisador` e do `projeto`.
* **Correção da Bolsa (Restrição UNIQUE):** Adicionamos a cláusula `UNIQUE` no atributo `id_bolsa` dentro do contrato, e definimos a exclusão como `ON DELETE SET NULL`.
* **Justificativa Teórica:** A restrição `UNIQUE` reflete a cardinalidade 1:1 condicional do nosso MER: uma bolsa só pode estar alocada a um único contrato por vez. Se a bolsa for extinta do banco, o contrato não some (o pesquisador continua no projeto), mas o campo da bolsa fica em branco (`SET NULL`), respeitando o fluxo financeiro.

### 3.3. Entidade Fraca (`relatorio`)
* **Correção Estrutural:** O rascunho original tratava o relatório como uma tabela comum. A nova DDL aplicou formalmente a restrição estrutural de uma **Entidade Fraca**.
* **Correção Aplicada:** A Chave Estrangeira `id_projeto` foi fundida com o discriminador parcial `sequencial_relatorio` para formarem a `PRIMARY KEY (id_projeto, sequencial_relatorio)`. Adicionou-se `ON DELETE CASCADE`.
* **Justificativa Teórica:** (*Elmasri, Cap. 3*) Um relatório não tem existência autônoma. Se o projeto (entidade forte identificadora) for apagado, todos os seus relatórios desaparecem automaticamente.

---
## Conclusão da Refatoração
A transição da versão rascunho para a arquitetura de produção garantiu um banco de dados **100% normalizado**, protegido contra anomalias de atualização (*fan traps*) e pronto para lidar com a alta volumetria (11.000 transações de pesquisa e contratos) exigida na Fase 3 do projeto.
