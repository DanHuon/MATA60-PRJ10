-- ====================================================================================
-- Políticas de Acesso (DCL) e Backup
-- Criação de perfis de usuário com permissões restritas e documentação da estratégia de backup lógico do banco de dados.
-- ====================================================================================

-- ====================================================================================
-- PARTE 1: POLÍTICAS DE PRIVACIDADE E SEGURANÇA (DCL)
-- ====================================================================================

-- ------------------------------------------------------------------------------------
-- Role 1: Administrador do Laboratório
-- ------------------------------------------------------------------------------------
DROP ROLE IF EXISTS admin_pesquisa;
CREATE ROLE admin_pesquisa WITH
  LOGIN
  SUPERUSER
  PASSWORD 'admin_prj10_pwd';

-- ------------------------------------------------------------------------------------
-- Role 2: Gestor de Recursos Humanos
-- Vinculado ao requisito operacional (R3, R4)
-- ------------------------------------------------------------------------------------
DROP ROLE IF EXISTS gestor_rh;
CREATE ROLE gestor_rh WITH
  LOGIN
  PASSWORD 'gestor_rh_pwd';

-- Concessão de privilégios de leitura necessários para validação de integridade referencial (FK)
GRANT SELECT ON TABLE projeto, bolsa TO gestor_rh;

-- Concessão de privilégios operacionais (CRUD) para manutenção do corpo científico
GRANT SELECT, INSERT, UPDATE ON TABLE pesquisador, contrato TO gestor_rh;

-- Revoga explicitamente a permissão de exclusão física para mitigar fraudes e perda de histórico
REVOKE DELETE ON TABLE contrato FROM gestor_rh;
REVOKE DELETE ON TABLE pesquisador FROM gestor_rh;

-- Privilégio obrigatório para o PostgreSQL gerenciar chaves do tipo SERIAL
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO gestor_rh;

-- ------------------------------------------------------------------------------------
-- Role 3: Auditor Financeiro Externo
-- Vinculado ao requisito de governança (R8, R9)
-- ------------------------------------------------------------------------------------
DROP ROLE IF EXISTS auditor_financeiro;
CREATE ROLE auditor_financeiro WITH
  LOGIN
  PASSWORD 'auditor_pwd';

-- Concessão de visibilidade restrita ao ecossistema financeiro e auditoria contábil
GRANT SELECT ON TABLE financiador, bolsa, financia TO auditor_financeiro;

-- Acesso direto ao cache analítico das Materialized Views criadas na Entrega 2
GRANT SELECT ON TABLE mv_estrategica_aportes_anuais, mv_operacional_equidade_incentivos TO auditor_financeiro;


-- ====================================================================================
-- PARTE 2: POLÍTICA DE BACKUP E PRESERVAÇÃO DE DADOS
-- ====================================================================================

/*
  Na estratégia de proteção dos dados adotamos o modelo de Backup Lógico utilizando o utilitário nativo pg_dump do PostgreSQL.
  Desse jeito garantimos a consistência dos dados sem interromper as transações ativas.

  Comando para execução manual via Terminal do Servidor (Segurança via Variável de Ambiente):
  Para evitar a vulnerabilidade de exposição de credenciais (Hardcoded Credentials), a senha é passada via PGPASSWORD.
  
  PGPASSWORD='senha_segura' pg_dump -U admin_pesquisa -h localhost -F c -f /var/backups/postgres/prj10_db_$(date +\%Y-\%m-\%d).dump prj10_db

  Parâmetros do pg_dump explicados:
  -U admin_pesquisa : Define o usuário administrador da execução.
  -F c              : Define o formato "Custom", compactado e flexível para restaurações parciais.
  -f                : Define o caminho físico de saída mascarando a data atual do sistema.

  Automação e Agendamento em Produção (Linux Crontab):
  A instrução abaixo programa a execução diária em horário de baixa utilização (03:00 da madrugada):
  
  0 3 * * * PGPASSWORD='senha_segura' pg_dump -U admin_pesquisa -h localhost -F c -f /var/backups/postgres/prj10_db_$(date +\%Y-\%m-\%d).dump prj10_db

  Plano de Recuperação e Contingência (Disaster Recovery):
  O processo de restauração utiliza a flag -1 (Single Transaction) para encapsular a operação em uma transação ACID.
  Isso garante um rollback completo em caso de falha interruptiva, impedindo um estado inconsistente.
  
  PGPASSWORD='senha_segura' pg_restore -U admin_pesquisa -h localhost -d prj10_db -1 /var/backups/postgres/prj10_db_$(date +\%Y-\%m-\%d).dump
*/