# AutoAtende - Instalador

Este é o instalador oficial do AutoAtende, uma plataforma SaaS de atendimento multicanal.

## Requisitos do Sistema

- Ubuntu 20.04 LTS ou superior
- Mínimo de 2GB de RAM
- 2 vCPUs
- 40GB de armazenamento
- Domínios configurados para frontend e backend

## Tecnologias Utilizadas

- Node.js 20.x
- PostgreSQL 16
- Redis
- Nginx
- PM2
- Certbot (Let's Encrypt)
- Fail2ban

## Pré-requisitos

1. Um servidor Ubuntu limpo (recomendamos uma nova instalação)
2. Dois domínios configurados apontando para o IP do seu servidor:
   - Um para o frontend (ex: painel.seudominio.com.br)
   - Um para o backend (ex: api.seudominio.com.br)
3. Token de acesso ao repositório

## Instalação

1. Faça login no seu servidor via SSH
2. Execute o comando abaixo:

```bash
wget https://raw.githubusercontent.com/AutoAtende/instalador/main/install.sh && sudo chmod +x install.sh && ./install.sh
```

3. Siga as instruções na tela para configurar sua instância

## Informações Solicitadas Durante a Instalação

- Senha para o usuário deploy e banco de dados
- Token de acesso ao repositório
- Nome da instância (apenas letras minúsculas sem espaços)
- Nome da empresa para o PWA
- Domínio do frontend
- Domínio do backend

## Primeiro Acesso

Após a instalação, acesse o frontend através do domínio configurado e utilize as credenciais:

- Email: admin@autoatende.com.br
- Senha: 123456

**IMPORTANTE:** Altere a senha padrão após o primeiro acesso!

## Recursos Instalados

- Backend (Node.js + PostgreSQL)
- Frontend (React)
- Redis para cache e filas
- Nginx como proxy reverso
- Certificados SSL automáticos
- PM2 para gerenciamento de processos
- Fail2ban para segurança

## Estrutura de Diretórios

```
/home/deploy/[instancia]/
├── backend/
│   ├── dist/
│   ├── public/
│   └── logs/
└── frontend/
    └── build/
```

## Segurança

O instalador configura automaticamente:

- Firewall (UFW)
- Fail2ban
- Certificados SSL
- Senhas seguras para Redis e PostgreSQL
- Permissões de arquivos e diretórios

## Suporte

Para suporte, entre em contato através dos canais oficiais do AutoAtende.

## Licença

Este software é proprietário. Todos os direitos reservados.
