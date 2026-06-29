# PRJ10: Sistema de Gerenciamento de Recursos Humanos em Pesquisa

Este repositório contém todos os artefatos SQL para a implementação e operação do banco de dados do projeto PRJ10, desenvolvido para a disciplina MATA60 - Banco de Dados.

O projeto foi construído utilizando PostgreSQL e segue uma arquitetura autocontida, onde todas as operações, desde a criação da estrutura até a carga de dados e políticas de segurança, são gerenciadas puramente via SQL, sem dependências de scripts externos.

## Arquitetura e Ordem de Execução

Para reproduzir o ambiente completo, os scripts devem ser executados na ordem numérica estrita de **01 a 09**. Cada arquivo representa uma camada lógica da arquitetura do banco de dados.

| Ordem | Arquivo | Propósito |
|:-----:|---------|-----------|
| 1 | `01_Tabelas_DDL.sql` | **Estrutura (DDL):** Cria o esquema relacional, tabelas, chaves e restrições. |
| 2 | `02_Trigger_Regra_Negocio.sql` | **Regra de Negócio:** Implementa uma trigger para garantir a consistência entre projetos, contratos e bolsas. |
| 3 | `03_DML_Carga_Dados.sql` | **Carga de Dados (DML):** Popula o banco com um grande volume de dados sintéticos gerados via SQL. |
| 4 | `04_Views_Consultas_Dashboards.sql` | **Camada Analítica:** Cria as `Materialized Views` e as consultas em tempo real para os dashboards. |
| 5 | `05_Procedures_Telas_Transacoes.sql` | **Camada Operacional:** Define as `Stored Procedures` (lógica de telas) e as transações ACID. |
| 6 | `06_Indices_Basicos.sql` | **Otimização (Plano 1):** Cria índices básicos em chaves estrangeiras e filtros comuns. |
| 7 | `07_Indices_Compostos.sql` | **Otimização (Plano 2):** Adiciona índices compostos para otimizar consultas analíticas. |
| 8 | `08_Indices_Parciais.sql` | **Otimização (Plano 3):** Adiciona índices parciais para otimizar o acesso a subconjuntos de dados. |
| 9 | `09_Politicas_Acesso.sql` | **Segurança (DCL):** Cria os perfis de acesso (`Roles`) e documenta a política de backup. |

---

## Destaques da Implementação (Artefatos da Etapa 2)

Esta entrega implementa rotinas avançadas de banco de dados para atender aos requisitos de sistemas de informação complexos.

### Consultas e Dashboards
*   **10 Consultas de Dashboard:** Localizadas em `04_Views_Consultas_Dashboards.sql`.
*   **2 Materialized Views:** Para otimizar consultas analíticas de alto custo, foram criadas:
    1.  `mv_estrategica_aportes_anuais`: Consolida anualmente os aportes financeiros por tipo (público/privado).
    2.  `mv_operacional_equidade_incentivos`: Calcula um ranking de valores de bolsa dentro de cada projeto.
*   **8 Consultas em Tempo Real:** Complementam as MVs com informações que exigem dados atualizados no momento do acesso.

### Rotinas Avançadas e Transações
*   **2 Stored Procedures:** Localizadas em `05_Procedures_Telas_Transacoes.sql`, representam a lógica de negócio de duas telas operacionais:
    1.  `sp_promover_voluntario`: Simula a promoção de um pesquisador voluntário para bolsista, realizando múltiplos `INSERT`s e `UPDATE`s.
    2.  `sp_encerramento_emergencial`: Simula o encerramento administrativo de um projeto, cancelando contratos e registrando um relatório final.
*   **2 Transações Explícitas:** No mesmo arquivo, as chamadas para as procedures são encapsuladas em blocos `BEGIN/COMMIT`, garantindo a execução atômica (ACID) das operações.
*   **1 Trigger de Regra de Negócio:** O arquivo `02_Trigger_Regra_Negocio.sql` implementa a `tg_valida_bolsa_contrato`, que impede a inserção de dados inconsistentes na camada de banco de dados, garantindo a integridade lógica do sistema.

### Políticas de Acesso e Segurança
O arquivo `09_Politicas_Acesso.sql` estabelece uma arquitetura de segurança robusta:
*   **3 Perfis de Acesso (`Roles`):**
    *   `admin_pesquisa`: Superusuário com controle total.
    *   `gestor_rh`: Perfil operacional para gerenciar pesquisadores e contratos, com a restrição de **não poder deletar registros** (`REVOKE DELETE`), preservando o histórico.
    *   `auditor_financeiro`: Perfil de leitura restrito a dados financeiros e às `Materialized Views` para fins de auditoria.
*   **Política de Backup:** O arquivo documenta a estratégia de backup lógico utilizando a ferramenta nativa `pg_dump` do PostgreSQL. A automação via `cron` e o uso de formato customizado (`-F c`) são detalhados como boas práticas para um ambiente de produção.

---

## Instruções para Execução

1.  Crie um banco de dados vazio em uma instância PostgreSQL (ex: `CREATE DATABASE prj10_db;`).
2.  Conecte-se a este banco de dados.
3.  Execute os scripts SQL na ordem numérica, de `01_Tabelas_DDL.sql` a `09_Politicas_Acesso.sql`.

O script `03_DML_Carga_Dados.sql` é re-executável e limpará e repovoará o banco de dados sempre que for executado.
```bash
pg_dump -U postgres -h localhost -F c -f backup_prj10.dump prj10_db