# Changelog

Todas as alterações notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [1.0.0] - 2025-02-08

### Adicionado
- Instalador automatizado para o AutoAtende
- Configuração automática do ambiente Node.js 20.x
- Instalação e configuração do PostgreSQL 16
- Configuração do Redis com senha e limites de memória
- Sistema de deploy automático para frontend e backend
- Configuração do Nginx como proxy reverso
- Instalação e configuração do PM2
- Geração automática de certificados SSL via Let's Encrypt
- Configuração do Fail2ban para segurança
- Sistema de verificação de instalações existentes
- Validação de domínios e senhas
- Criação automática de diretórios e permissões
- Configuração de variáveis de ambiente para frontend e backend
- Sistema de migrações e seeds automáticos
- Configuração de firewall (UFW)

### Configurações de Segurança
- Implementação de proteção contra ataques via Fail2ban
- Configuração segura do Redis
- Permissões restritas para arquivos e diretórios
- Firewall configurado com regras específicas
- Configuração segura do Nginx

### Melhorias no Sistema
- Otimização das configurações do PM2
- Estrutura organizada de diretórios
- Sistema de logs centralizado
- Validações de entrada durante a instalação
- Mensagens claras de progresso e status
- Confirmação de dados antes da instalação

### Correções
- Ajuste nas permissões do diretório public
- Correção na configuração do Redis para conexões locais
- Ajuste no timeout das requisições do Nginx

### Notas da Versão
- Versão inicial do instalador automático
- Requer Ubuntu 20.04 LTS ou superior
- Compatível com Node.js 20.x
- Suporte a PostgreSQL 16
