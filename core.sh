#!/bin/bash

# Configuração de logging
setup_logging() {
    LOG_DIR="/var/log/autoatende"
    LOG_FILE="$LOG_DIR/install_$(date +%Y%m%d_%H%M%S).log"
    mkdir -p $LOG_DIR
    
    # Função para logging limpo
    log_message() {
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
    }
    
    # Redirecionar stdout e stderr para arquivo de log e console
    exec 1> >(while read -r line; do
        # Remove códigos de cores ANSI e processa a linha
        cleaned_line=$(echo "$line" | sed 's/\x1B\[[0-9;]*[[:alpha:]]//g')
        
        if [[ $cleaned_line =~ 💻[[:space:]]+(.*) ]]; then
            # Se a linha começa com emoji, registra apenas o texto após ele
            echo "$(date '+%Y-%m-%d %H:%M:%S') - ${BASH_REMATCH[1]}" >> "$LOG_FILE"
        else
            # Caso contrário, registra a linha completa limpa
            [[ ! -z "$cleaned_line" ]] && echo "$cleaned_line" >> "$LOG_FILE"
        fi
        # Exibe a linha original no console
        echo "$line"
    done)
    
    # Redirecionar stderr para arquivo de log e console
    exec 2> >(while read -r line; do
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $line" | tee -a "$LOG_FILE"
    done)

    log_message "=== Iniciando instalação do AutoAtende ==="
}

# Função para imprimir mensagens no log
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Função para tratar erros
handle_error() {
    local error_message=$1
    log_message "ERRO: $error_message"
    return 1
}

# Funções de coleta de dados
get_mysql_root_password() {
  print_banner
  printf "${WHITE} 💻 Insira senha para o usuario Deploy e Banco de Dados (Não utilizar caracteres especiais):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " mysql_root_password
}

get_token_code() {
  print_banner
  printf "${WHITE} 💻 Digite o token para baixar o código:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " token_code
}

get_pwa_name() {
  print_banner
  printf "${WHITE} 💻 Digite o nome da empresa que será exibido no PWA:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " pwa_name
}

get_instancia_add() {
  print_banner
  printf "${WHITE} 💻 Informe um nome para a Instancia/Empresa (Letras minúsculas, sem espaços/caracteres especiais):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " instancia_add
}

get_frontend_url() {
  print_banner
  printf "${WHITE} 💻 Digite o domínio do FRONTEND/PAINEL para a ${instancia_add}:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " frontend_url
}

get_backend_url() {
  print_banner
  printf "${WHITE} 💻 Digite o domínio do BACKEND/API para a ${instancia_add}:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " backend_url
}

get_backend_port() {
  print_banner
  printf "${WHITE} 💻 Digite a porta do BACKEND para esta instancia (Ex: 4000 A 4999):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " backend_port
}

# Função principal de coleta de dados
get_urls() {
  get_mysql_root_password
  get_token_code
  get_instancia_add
  get_frontend_url
  get_backend_url
  get_backend_port
  get_pwa_name
  
  # Definir valores padrão
  redis_port=6379
  repo_name="Sys"
  max_whats=250
  max_user=500
}

# Função de remoção de instância
remove_instance() {
    log_message "Iniciando remoção de instância"
    read -p "Digite o nome da Instancia/Empresa que será Deletada: " empresa_delete

    log_message "Removendo a instância ${empresa_delete}"

    # Parar e remover serviços
    sudo su - deploy <<EOF
        pm2 delete ${empresa_delete}-backend
        pm2 save
        rm -rf /home/deploy/${empresa_delete}
EOF

    # Remover configurações do nginx
    sudo rm -f /etc/nginx/sites-enabled/${empresa_delete}-*
    sudo rm -f /etc/nginx/sites-available/${empresa_delete}-*

    # Remover banco de dados
    sudo su - postgres <<EOF
        dropdb ${empresa_delete}
        dropuser ${empresa_delete}
EOF

    # Reiniciar nginx
    sudo systemctl restart nginx

    log_message "Instância ${empresa_delete} removida com sucesso"
}

# Função de remoção completa do sistema
remove_complete_system() {
    print_banner
    log_message "ATENÇÃO: Isso removerá completamente o sistema e todas as instâncias"
    read -p "Digite 'CONFIRMAR' para prosseguir com a remoção: " confirmation

    if [ "$confirmation" != "CONFIRMAR" ]; then
        log_message "Operação cancelada pelo usuário"
        return 1
    fi

    log_message "Iniciando remoção completa do sistema"

    # 1. Parar todos os serviços primeiro
    log_message "Parando serviços..."
    sudo systemctl stop nginx
    sudo systemctl stop redis-server
    sudo systemctl stop postgresql
    
    # 2. Remover PM2 e suas configurações
    log_message "Removendo PM2..."
    sudo su - deploy << EOF 2>/dev/null
        pm2 delete all
        pm2 kill
        pm2 unstartup systemd
EOF
    sudo npm remove -g pm2
    sudo rm -rf /usr/lib/node_modules/pm2
    sudo rm -f /etc/systemd/system/pm2-*
    sudo rm -rf /root/.pm2

    # 3. Remover usuário deploy e seus arquivos
    log_message "Removendo usuário deploy..."
    sudo pkill -u deploy
    sudo userdel -r deploy 2>/dev/null
    sudo rm -rf /home/deploy

    # 4. Remover Redis completamente
    log_message "Removendo Redis..."
    sudo systemctl stop redis-server
    sudo apt-get remove --purge -y redis-server redis-tools
    sudo rm -rf /etc/redis
    sudo rm -rf /var/lib/redis
    sudo rm -f /etc/init.d/redis-server

    # 5. Remover PostgreSQL
    log_message "Removendo PostgreSQL..."
    sudo systemctl stop postgresql
    sudo su - postgres << EOF 2>/dev/null
        psql -c "DROP DATABASE template1;"
        for db in \$(psql -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';"); do
            dropdb "\$db"
        done
EOF
    sudo apt-get remove --purge -y postgresql*
    sudo rm -rf /etc/postgresql
    sudo rm -rf /var/lib/postgresql
    sudo rm -rf /var/log/postgresql

    # 6. Remover Nginx
    log_message "Removendo Nginx..."
    sudo systemctl stop nginx
    sudo apt-get remove --purge -y nginx nginx-common
    sudo rm -rf /etc/nginx
    sudo rm -rf /var/log/nginx

    # 7. Limpar pacotes e dependências
    log_message "Limpando sistema..."
    sudo apt-get autoremove -y
    sudo apt-get autoclean
    sudo apt-get clean

    # 8. Remover diretórios residuais
    log_message "Removendo diretórios residuais..."
    sudo rm -rf /var/www/html/*
    sudo rm -rf /etc/systemd/system/pm2-*
    sudo rm -rf /var/log/autoatende/*

    # 9. Recarregar systemd
    log_message "Recarregando systemd..."
    sudo systemctl daemon-reload

    # 10. Remover regras do firewall
    log_message "Removendo regras do firewall..."
    sudo ufw delete allow 80
    sudo ufw delete allow 443
    sudo ufw delete allow 5432
    sudo ufw delete allow 3000
    sudo ufw delete allow 8080

    # 11. Limpar fontes apt
    log_message "Limpando fontes apt..."
    sudo rm -f /etc/apt/sources.list.d/redis.list
    sudo rm -f /etc/apt/sources.list.d/pgdg*
    sudo rm -f /usr/share/keyrings/redis-archive-keyring.gpg
    sudo rm -f /usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg

    # 12. Atualizar sistema
    log_message "Atualizando sistema..."
    sudo apt-get update -y

    log_message "Sistema removido com sucesso"
    log_message "Para reinstalar, use a opção 'Instalação Primária'"
}

# Funções de sistema
system_update() {
    print_banner
    log_message "Atualizando o sistema"
    sudo apt-get -y update >> "$LOG_FILE" 2>&1 || handle_error "Falha na atualização do sistema"
    sudo apt-get -y upgrade >> "$LOG_FILE" 2>&1 || handle_error "Falha no upgrade do sistema"
    sudo apt-get install -y build-essential libgbm-dev wget unzip fontconfig locales >> "$LOG_FILE" 2>&1
}

system_create_user() {
    print_banner
    log_message "Criando usuário deploy"
    
    # Criar usuário
    useradd -m -p $(openssl passwd -6 ${mysql_root_password}) -s /bin/bash -G sudo deploy
    usermod -aG sudo deploy
    usermod -aG www-data deploy
    usermod -aG deploy www-data

    # Criar diretórios necessários
    sudo mkdir -p /home/deploy/.pm2
    sudo chown -R deploy:deploy /home/deploy/.pm2
    sudo chmod -R 775 /home/deploy/.pm2

    sudo su - deploy << EOF
        mkdir -p ~/.pm2
        echo 'export NVM_DIR="\$HOME/.nvm"' >> ~/.bashrc
        echo '[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"' >> ~/.bashrc
        echo '[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"' >> ~/.bashrc
EOF
}

setup_firewall() {
    print_banner
    log_message "Configurando firewall"
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 22
    sudo ufw allow 80
    sudo ufw allow 443
    sudo ufw allow 5432
    sudo ufw allow ${redis_port}
    sudo ufw allow ${backend_port}
    echo "y" | sudo ufw enable
}

system_node_install() {
    print_banner
    log_message "Instalando Node.js 20 e PM2"

    # Instalar PM2 globalmente como root
    sudo su - root << EOF
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt install -y nodejs
        sudo npm install -g npm@latest
        sudo npm install -g pm2@latest
        sudo pm2 startup ubuntu -u deploy
        sudo env PATH=\$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u deploy --hp /home/deploy
EOF

    # Instalar NVM e Node.js para o usuário deploy
    sudo su - deploy << EOF
        rm -rf ~/.nvm
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        export NVM_DIR="\$HOME/.nvm"
        [ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
        nvm install 20.18.0
        nvm use 20.18.0
        nvm alias default 20.18.0
EOF

    # Salvar configuração do PM2
    sudo su - deploy << EOF
        pm2 save
EOF
}

system_redis_install() {
    print_banner
    log_message "Instalando Redis"

    # Adicionar repositório do Redis
    curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

    sudo apt-get update
    sudo apt-get install -y redis-server

    # Configurar Redis
    sudo tee /etc/redis/redis.conf > /dev/null << EOF
port ${redis_port}
bind 127.0.0.1
supervised systemd
maxmemory 2gb
maxmemory-policy allkeys-lru
requirepass ${mysql_root_password}
appendonly yes
appendfsync everysec
no-appendfsync-on-rewrite yes
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
EOF

    sudo systemctl restart redis-server
    sudo systemctl enable redis-server
}

system_postgres_install() {
    print_banner
    log_message "Instalando PostgreSQL"

    sudo apt install -y postgresql-common
    sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y
    sudo apt update
    sudo apt install -y postgresql-16 postgresql-client-16
    
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
}

system_nginx_install() {
    print_banner
    log_message "Instalando nginx"

    sudo apt install -y nginx
    sudo rm -rf /etc/nginx/sites-enabled/default
    sudo rm -rf /etc/nginx/sites-available/default
    
    # Configurações otimizadas para o Nginx
    sudo tee /etc/nginx/nginx.conf > /dev/null << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 2048;
    multi_accept on;
    use epoll;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;
    gzip_disable "msie6";
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF
}

system_certbot_install() {
    log_message "Instalando certbot"
    sudo apt install -y snapd
    sudo snap install core
    sudo snap refresh core
    sudo apt-get remove certbot
    sudo snap install --classic certbot
    sudo ln -sf /snap/bin/certbot /usr/bin/certbot
}

create_manifest_json() {
    log_message "Criando manifest.json para PWA"

    sudo su - deploy << EOF
        mkdir -p /home/deploy/${instancia_add}/frontend/public
        
        cat > /home/deploy/${instancia_add}/frontend/public/manifest.json << END
{
    "short_name": "${pwa_name}",
    "name": "${pwa_name}",
    "icons": [
        {
            "src": "favicon.ico",
            "sizes": "64x64 32x32 24x24 16x16",
            "type": "image/x-icon"
        },
        {
            "src": "android-chrome-192x192.png",
            "sizes": "192x192",
            "type": "image/png"
        }
    ],
    "start_url": ".",
    "display": "standalone",
    "theme_color": "#000000",
    "background_color": "#ffffff"
}
END

        chmod 775 /home/deploy/${instancia_add}/frontend/public/manifest.json
EOF
}

# Backend
backend_postgres_create() {
    log_message "Configurando banco de dados PostgreSQL"

    sudo su - postgres <<EOF
        createdb ${instancia_add}
        psql -c "CREATE USER ${instancia_add} WITH ENCRYPTED PASSWORD '${mysql_root_password}';"
        psql -c "ALTER USER ${instancia_add} WITH SUPERUSER;"
        psql -c "GRANT ALL PRIVILEGES ON DATABASE ${instancia_add} TO ${instancia_add};"
EOF
}

backend_env_create() {
    log_message "Configurando variáveis de ambiente do backend"

    JWT_SECRET=$(openssl rand -hex 32)
    JWT_REFRESH_SECRET=$(openssl rand -hex 32)

    sudo su - deploy << EOF
        cat <<[-]EOF > /home/deploy/${instancia_add}/backend/.env
NODE_ENV=production
BACKEND_URL=${backend_url}
BACKEND_PUBLIC_PATH=/home/deploy/${instancia_add}/backend/public
BACKEND_LOGS_PATH=/home/deploy/${instancia_add}/backend/logs
BACKEND_SESSION_PATH=/home/deploy/${instancia_add}/backend/metadados
FRONTEND_URL=${frontend_url}
PROXY_PORT=443
PORT=${backend_port}

DB_HOST=localhost
DB_DIALECT=postgres
DB_USER=${instancia_add}
DB_PASS=${mysql_root_password}
DB_NAME=${instancia_add}
DB_PORT=5432

REDIS_URI=redis://:${mysql_root_password}@127.0.0.1:${redis_port}
REDIS_OPT_LIMITER_MAX=1
REDIS_OPT_LIMITER_DURATION=3000
REDIS_HOST=127.0.0.1
REDIS_PORT=${redis_port}
REDIS_PASSWORD=${mysql_root_password}

USER_LIMIT=${max_user}
CONNECTIONS_LIMIT=${max_whats}

JWT_SECRET=${JWT_SECRET}
JWT_REFRESH_SECRET=${JWT_REFRESH_SECRET}
[-]EOF
EOF
}

backend_install() {
    log_message "Instalando backend"

    sudo su - deploy <<EOF
        cd /home/deploy/${instancia_add}/backend
        
        mkdir -p logs
        mkdir -p public/company1/{medias,tasks,announcements,logos,backgrounds,quickMessages,profile}
        
        sudo chown -R deploy:www-data public
        sudo chmod -R 775 public
        
        sudo chown -R deploy:www-data logs
        sudo chmod -R 775 logs

        sudo usermod -a -G www-data deploy
        
        sudo chmod g+s public
        sudo chmod g+s logs
        
        npm install
        npm run build
        
        npx sequelize db:migrate
        npx sequelize db:seed:all
        
        rm -rf src
EOF
}

backend_start_pm2() {
    log_message "Iniciando PM2 (backend)"

    sudo su - deploy << EOF
        cat > /home/deploy/${instancia_add}/backend/ecosystem.config.js << 'END'
module.exports = {
    apps: [{
        name: "${instancia_add}-backend",
        script: "./dist/server.js",
        node_args: "--expose-gc --max-old-space-size=8192",
        exec_mode: "fork",
        max_memory_restart: "6G",
        max_restarts: 5,
        instances: 1,
        watch: false,
        error_file: "/home/deploy/${instancia_add}/backend/logs/error.log",
        out_file: "/home/deploy/${instancia_add}/backend/logs/out.log",
        env: {
            NODE_ENV: "production"
        }
    }]
}
END

        cd /home/deploy/${instancia_add}/backend
        pm2 start ecosystem.config.js --env production
        pm2 save
EOF
}

backend_nginx_setup() {
    log_message "Configurando nginx (backend)"

    backend_hostname=$(echo "${backend_url/https:\/\/}")

    sudo su - root << EOF
        cat > /etc/nginx/sites-available/${instancia_add}-backend << 'END'
server {
    server_name $backend_hostname;
    location / {
        proxy_pass http://127.0.0.1:${backend_port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_cache_bypass \$http_upgrade;
    }

    # Bloquear solicitacoes de arquivos do GitHub
    location ~ /\.git {
        deny all;
    }
}
END

        ln -s /etc/nginx/sites-available/${instancia_add}-backend /etc/nginx/sites-enabled
EOF
}

# Frontend
frontend_env_create() {
    log_message "Configurando variáveis de ambiente do frontend"

    backend_hostname=$(echo "${backend_url/https:\/\/}")

    sudo su - deploy << EOF
        cat <<[-]EOF > /home/deploy/${instancia_add}/frontend/.env
REACT_APP_BACKEND_URL=${backend_url}
REACT_APP_BACKEND_PROTOCOL=https
REACT_APP_BACKEND_HOST=${backend_hostname}
REACT_APP_BACKEND_PORT=443
REACT_APP_HOURS_CLOSE_TICKETS_AUTO=24
REACT_APP_LOCALE=pt-br
REACT_APP_TIMEZONE=America/Sao_Paulo
REACT_APP_FACEBOOK_APP_ID=
[-]EOF
EOF
}

frontend_install() {
    log_message "Instalando frontend"

    sudo su - deploy <<EOF
        cd /home/deploy/${instancia_add}/frontend
        npm install --legacy-peer-deps
        npm run build
        rm -rf src
EOF
}

frontend_nginx_setup() {
    log_message "Configurando nginx (frontend)"

    frontend_hostname=$(echo "${frontend_url/https:\/\/}")

    sudo su - root << EOF
        cat > /etc/nginx/sites-available/${instancia_add}-frontend << 'END'
server {
    server_name $frontend_hostname;
    
    root /home/deploy/${instancia_add}/frontend/build;
    index index.html;

    location / {
        try_files \$uri /index.html;
    }
}
END

        ln -s /etc/nginx/sites-available/${instancia_add}-frontend /etc/nginx/sites-enabled
EOF
}

# Função para otimizar o sistema
optimize_system() {
  
  printf "${WHITE} 💻 Otimizando o sistema...${GRAY_LIGHT}"
  printf "\n\n"

  # Otimizar PostgreSQL para Ubuntu 24.04
  sudo tee /etc/postgresql/16/main/conf.d/optimizations.conf > /dev/null << EOF
shared_buffers = '256MB'
effective_cache_size = '1GB'
work_mem = '32MB'
maintenance_work_mem = '256MB'
random_page_cost = 1.1
effective_io_concurrency = 200
wal_buffers = '16MB'
min_wal_size = '1GB'
max_wal_size = '4GB'
checkpoint_completion_target = 0.9
default_statistics_target = 100
EOF

  # Otimizar Redis
  sudo tee -a /etc/redis/redis.conf > /dev/null << EOF
maxmemory-policy allkeys-lru
maxmemory 512mb
EOF

  # Otimizar Nginx
  sudo tee /etc/nginx/conf.d/optimizations.conf > /dev/null << EOF
proxy_buffer_size 128k;
proxy_buffers 4 256k;
proxy_busy_buffers_size 256k;
client_max_body_size 100M;
EOF

  # Otimizar Sistema (kernel parameters)
  sudo tee -a /etc/sysctl.conf > /dev/null << EOF
# Otimizações de Sistema de Arquivos
fs.file-max = 2097152
fs.nr_open = 1048576

# Otimizações de Rede
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 16384
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.nf_conntrack_max = 262144

# Otimizações TCP
net.ipv4.tcp_wmem = 4096 87380 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.ip_forward = 1
net.ipv4.conf.ens3.forwarding = 1
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30
EOF

  # Aplicar alterações
  sudo systemctl restart postgresql
  sudo systemctl restart redis-server
  sudo systemctl restart nginx
  sudo sysctl -p

  
  printf "${GREEN} ✅ Sistema otimizado com sucesso!${NC}"
  printf "\n\n"
  sleep 2
}

# Função principal de instalação
install_autoatende() {
    local installation_type=$1

    if [[ $installation_type == "primary" ]]; then
        system_update
        system_create_user        
        system_node_install      
        system_redis_install
        system_postgres_install
        system_nginx_install
        system_certbot_install
        setup_firewall
    fi

    # Clone do repositório
    sudo su - deploy <<EOF
        git clone -b main https://lucassaud:${token_code}@github.com/AutoAtende/Sys.git /home/deploy/${instancia_add}
EOF

    # Criar o manifest.json antes de tudo
    create_manifest_json

    # Configuração do backend
    backend_postgres_create
    backend_env_create
    backend_install
    backend_start_pm2
    backend_nginx_setup

    # Configuração do frontend
    frontend_env_create
    frontend_install
    frontend_nginx_setup

    # Configuração do SSL
    backend_domain=$(echo "${backend_url/https:\/\/}")
    frontend_domain=$(echo "${frontend_url/https:\/\/}")

    sudo certbot --nginx -d $backend_domain -d $frontend_domain --non-interactive --agree-tos --email deploy@deploy.com

    sudo systemctl restart nginx

    log_message "Instalação concluída com sucesso!"
}