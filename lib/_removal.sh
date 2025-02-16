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
        sudo su - deploy <<EOF || true
        pm2 delete all
        pm2 save
        pm2 cleardump
EOF
    fi

    # Remover Nginx sites
    printf "\n${WHITE} 🗑️ Removendo configurações do Nginx...${GRAY_LIGHT}"
    sudo find /etc/nginx/sites-enabled/ -type l -delete
    sudo find /etc/nginx/sites-available/ -type f -delete
    sudo systemctl restart nginx

    # Remover bancos de dados e usuário PostgreSQL
    printf "\n${WHITE} 🗑️ Removendo bancos de dados...${GRAY_LIGHT}"
    if command -v psql &>/dev/null; then
        # Obter lista de instâncias
        instances=$(ls -1 /home/deploy 2>/dev/null)
        if [ ! -z "$instances" ]; then
            for instance in $instances; do
                sudo su - postgres <<EOF
                dropdb --if-exists ${instance}
                dropuser --if-exists ${instance}
EOF
            done
        fi
    fi

    # Remover Redis
    printf "\n${WHITE} 🗑️ Limpando Redis...${GRAY_LIGHT}"
    if command -v redis-cli &>/dev/null; then
        # Tentar limpar o Redis mesmo se não souber a senha
        redis-cli FLUSHALL || true
        sudo systemctl restart redis-server
    fi

    # Remover diretórios e usuário deploy
    printf "\n${WHITE} 🗑️ Removendo arquivos e usuário deploy...${GRAY_LIGHT}"
    if id "deploy" &>/dev/null; then
        # Matar todos os processos do usuário deploy
        sudo pkill -u deploy || true
        
        # Remover PM2 startup
        sudo su - deploy <<EOF || true
        pm2 unstartup
EOF
        
        # Remover diretório home e usuário
        sudo rm -rf /home/deploy
        sudo userdel -f deploy
    fi

    # Remover PM2
    printf "\n${WHITE} 🗑️ Removendo PM2...${GRAY_LIGHT}"
    sudo npm uninstall -g pm2 || true

    printf "\n${GREEN} ✅ AutoAtende removido com sucesso!${GRAY_LIGHT}"
    printf "\n\n"
    
    read -p "Pressione ENTER para voltar ao menu principal..."
    inquiry_options
}