# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [2.2.0] - 2025-02-07

### Adicionado
- Criação do manifest.json para PWA com nome personalizado
- Sistema de divisão em dois arquivos (install.sh e core.sh)
- Logs mais detalhados durante o processo de instalação
- Função de criação do manifest.json antes do build do frontend
- Pergunta para nome personalizado do PWA

### Alterado
- Reestruturado o código em dois arquivos principais para melhor manutenção
- Melhorada a ordem de execução das instalações e configurações
- Ajustada a configuração do PM2 para instalação via root
- Ajustado o processo de build do frontend para garantir manifest.json
- Atualizada a ordem das operações para otimizar o processo de instalação

### Corrigido
- Problema de permissão na instalação do PM2 global
- Erro no processo de build do frontend por falta do manifest.json
- Questão de instalação do NVM e Node.js para o usuário deploy
- Configuração incorreta do PM2 startup
- Erro na porta do Redis no firewall

### Segurança
- Ajustadas as permissões do manifest.json
- Melhoradas as permissões de diretórios para o frontend
- Fortalecida a segurança na criação de diretórios public

### Técnico
- Separação de responsabilidades entre arquivos do instalador
- Otimizado o processo de criação do manifest.json
- Implementada verificação de diretórios antes da criação do manifest.json
- Melhorada a estrutura do código para manutenibilidade
- Padronizada a ordem de execução das funções de instalação

## [2.1.0] - 2025-02-07

### Adicionado
- Campo para informar o nome do repositório a ser clonado
- Sistema de verificação de versão do Redis após instalação
- Verificação de status e conexão do Redis após configuração
- Logs detalhados durante o processo de instalação do Redis
- Verificação de instalação correta do NVM e Node.js

### Alterado
- Instalação do Node.js agora é feita via NVM (versão 20.18.0)
- Atualizado Redis para versão 7 usando repositório oficial
- Melhorada a configuração do PM2 startup script
- Aprimorada a instalação de dependências para o usuário deploy
- Otimizada a configuração do Redis com:
  - Porta personalizada
  - Limite de memória
  - Política de evicção
  - Persistência de dados
  - Configurações de performance

### Corrigido
- Problema com NVM não disponível para o usuário deploy
- Erro de conexão do Redis na porta configurada
- Questão de versão antiga do Redis (atualizado para v7)
- Problema com PM2 não persistindo após reinicialização
- Configurações do ambiente Node.js para o usuário deploy

### Segurança
- Melhoria na configuração de bind do Redis
- Fortalecimento das configurações de senha do Redis
- Ajustes nas permissões de diretórios do usuário deploy

### Técnico
- Adicionado suporte ao repositório oficial do Redis
- Implementada verificação de instalação do Node.js via NVM
- Melhorado o processo de configuração do PM2
- Otimizadas as configurações de ambiente para o Node.js

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
