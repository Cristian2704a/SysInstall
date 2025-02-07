# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [2.0.0] - 2025-02-06

### Adicionado
- Novo menu inicial para escolher entre instalação primária e instalação de instância
- Sistema de logs completo em `/var/log/autoatende/`
- Opção de otimização do sistema com ajustes automáticos para:
  - PostgreSQL 16
  - Redis 7
  - Nginx
  - Node.js
- Instalação do Node.js via NVM (versão 20.18.0)
- Campo para informar o nome do repositório a ser clonado
- Tratamento de erros em todas as operações

### Alterado
- Removido o uso do Docker para o Redis
- Redis agora é instalado diretamente no sistema operacional
- Melhorado o sistema de firewall (UFW) com configuração específica de portas
- Reorganização completa do código para melhor manutenibilidade
- Atualizado sistema de criação de senhas para maior segurança
- Otimizado processo de instalação e configuração

### Removido
- Suporte ao Docker para Redis
- Configurações hardcoded de repositórios

### Corrigido
- Problemas de permissão no diretório de uploads
- Configurações incorretas do Redis
- Problemas de compatibilidade com versões mais recentes do Node.js
- Questões de segurança no firewall

### Segurança
- Implementada verificação de segurança para senhas
- Melhorada a configuração do firewall
- Adicionada proteção contra acessos indevidos ao Redis
- Fortalecida a segurança do PostgreSQL

## [1.0.0] - Data anterior

- Versão inicial do instalador
