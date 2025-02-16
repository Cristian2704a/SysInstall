#!/bin/bash

software_delete() {
    print_banner
    printf "${WHITE} 💻 Removendo instalação existente do AutoAtende...${GRAY_LIGHT}"
    printf "\n\n"
    
    read -p "⚠️  Tem certeza que deseja remover completamente o AutoAtende? Esta ação não pode ser desfeita! (y/N) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        printf "\n${RED} ❌ Operação cancelada pelo usuário.${GRAY_LIGHT}"
        printf "\n\n"
        exit 1
    fi

    # Parar todos os serviços primeiro
    printf "\n${WHITE} 🛑 Parando serviços...${GRAY_LIGHT}"
    if id "deploy" &>/dev/null; then
        sudo su - deploy <<EOF
        pm2 delete all
        pm2 save
        pm2 cleardump
EOF
    fi

    # Remover Nginx sites
    printf "\n${WHITE} 🗑️ Removendo configurações do Nginx...${GRAY_LIGHT}"
    sudo rm -rf /etc/nginx/sites-enabled/*
    sudo rm -rf /etc/nginx/sites-available/*
    sudo systemctl restart nginx

    # Remover bancos de dados e usuário PostgreSQL
    printf "\n${WHITE} 🗑️ Removendo bancos de dados...${GRAY_LIGHT}"
    if command -v psql &>/dev/null; then
        sudo su - postgres <<EOF
        psql -c "DROP DATABASE IF EXISTS $(ls -1 /home/deploy 2>/dev/null);"
        psql -c "DROP ROLE IF EXISTS $(ls -1 /home/deploy 2>/dev/null);"
EOF
    fi

    # Remover Redis
    printf "\n${WHITE} 🗑️ Limpando Redis...${GRAY_LIGHT}"
    if command -v redis-cli &>/dev/null; then
        redis-cli FLUSHALL
    fi

    # Remover diretórios e usuário deploy
    printf "\n${WHITE} 🗑️ Removendo arquivos e usuário deploy...${GRAY_LIGHT}"
    if id "deploy" &>/dev/null; then
        # Matar todos os processos do usuário deploy
        sudo pkill -u deploy || true
        
        # Remover diretório home e usuário
        sudo rm -rf /home/deploy
        sudo userdel -f -r deploy
    fi

    # Remover PM2
    printf "\n${WHITE} 🗑️ Removendo PM2...${GRAY_LIGHT}"
    sudo npm uninstall -g pm2

    printf "\n${GREEN} ✅ AutoAtende removido com sucesso!${GRAY_LIGHT}"
    printf "\n\n"
    
    read -p "Pressione ENTER para voltar ao menu principal..."
    inquiry_options
}