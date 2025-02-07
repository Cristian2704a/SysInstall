#!/bin/bash

# Configuração de logging
setup_logging() {
    LOG_DIR="/var/log/autoatende"
    LOG_FILE="$LOG_DIR/install_$(date +%Y%m%d_%H%M%S).log"
    mkdir -p $LOG_DIR
    exec 1> >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)
    echo "=== Iniciando instalação do AutoAtende em $(date) ==="
}

# Função para imprimir o banner
print_banner() {
  clear
  printf "\n\n"
  printf "${BLUE}"
  printf " █████╗ ██╗   ██╗████████╗ ██████╗  █████╗ ████████╗███████╗███╗   ██╗██████╗ ███████╗ \n"
  printf "██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗██╔══██╗╚══██╔══╝██╔════╝████╗  ██║██╔══██╗██╔════╝ \n"
  printf "███████║██║   ██║   ██║   ██║   ██║███████║   ██║   █████╗  ██╔██╗ ██║██║  ██║█████╗   \n"
  printf "██╔══██║██║   ██║   ██║   ██║   ██║██╔══██║   ██║   ██╔══╝  ██║╚██╗██║██║  ██║██╔══╝   \n"
  printf "██║  ██║╚██████╔╝   ██║   ╚██████╔╝██║  ██║   ██║   ███████╗██║ ╚████║██████╔╝███████╗ \n"
  printf "╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═══╝╚═════╝ ╚══════╝ \n"
  printf "            \033[1;37m        ©lucassaud\n"
  printf "${NC}"
  printf "\n"
}

# Funções de coleta de dados
get_mysql_root_password() {
  print_banner
  printf "${WHITE} 💻 Insira senha para o usuario Deploy e Banco de Dados (Não utilizar caracteres especiais):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " mysql_root_password
}

get_repo_info() {
  print_banner
  printf "${WHITE} 💻 Digite o token para baixar o código:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " token_code

  print_banner
  printf "${WHITE} 💻 Digite o nome do repositório (Ex: AA-APP):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " repo_name
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

get_max_whats() {
  print_banner
  printf "${WHITE} 💻 Informe a quantidade de Conexões/Whats que a ${instancia_add} poderá cadastrar:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " max_whats
}

get_max_user() {
  print_banner
  printf "${WHITE} 💻 Informe a quantidade de Usuários/Atendentes que a ${instancia_add} poderá cadastrar:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " max_user
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

get_redis_port() {
  print_banner
  printf "${WHITE} 💻 Digite a porta do REDIS/AGENDAMENTO MSG para a ${instancia_add} (Ex: 5000 A 5999):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " redis_port
}

get_urls() {
  get_mysql_root_password
  get_repo_info
  get_instancia_add
  get_max_whats
  get_max_user
  get_frontend_url
  get_backend_url
  get_backend_port
  get_redis_port
  get_pwa_name
}

# Função para remover uma instância ou sistema completo
software_delete() {
  print_banner
  printf "${WHITE} 💻 Selecione o tipo de remoção:${GRAY_LIGHT}"
  printf "\n\n"
  printf "   [1] Remover uma instância\n"
  printf "   [2] Remover instalação completa do sistema\n"
  printf "   [3] Voltar\n"
  printf "\n"
  read -p "> " delete_type

  case "${delete_type}" in
    1) remove_instance ;;
    2) remove_complete_system ;;
    3) return ;;
    *) echo "Opção inválida" && sleep 2 && software_delete ;;
  esac
}

# Função para remover uma instância específica
remove_instance() {
  print_banner
  printf "${WHITE} 💻 Digite o nome da Instancia/Empresa que será Deletada:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " empresa_delete

  print_banner
  printf "${WHITE} 💻 Removendo a instância ${empresa_delete}...${GRAY_LIGHT}"
  printf "\n\n"

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

  print_banner
  printf "${GREEN} ✅ Instância ${empresa_delete} removida com sucesso!${NC}"
  printf "\n\n"
  sleep 2
}

# Função para remover completamente o sistema
remove_complete_system() {
  print_banner
  printf "${WHITE} ⚠️ ATENÇÃO: Isso removerá completamente o sistema e todas as instâncias.${NC}"
  printf "\n\n"
  printf "${WHITE} Digite 'CONFIRMAR' para prosseguir com a remoção:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " confirmation

  if [ "$confirmation" != "CONFIRMAR" ]; then
    print_banner
    printf "${RED} ❌ Operação cancelada pelo usuário${NC}"
    printf "\n\n"
    sleep 2
    return
  fi

  print_banner
  printf "${WHITE} 🗑️ Removendo sistema...${GRAY_LIGHT}"
  printf "\n\n"

  # Logging detalhado de cada operação
  echo "=== Iniciando remoção completa do sistema em $(date) ===" | tee -a "$LOG_FILE"

  # Parar e remover serviços PM2
  echo "Parando serviços PM2..." | tee -a "$LOG_FILE"
  sudo su - deploy << EOF 2>&1 | tee -a "$LOG_FILE"
    pm2 list
    pm2 kill
    pm2 save
    pm2 unstartup systemd
EOF

  # Listar e remover instâncias
  echo "Listando instâncias antes da remoção..." | tee -a "$LOG_FILE"
  ls -la /home/deploy/ 2>&1 | tee -a "$LOG_FILE"

  # Remover bancos de dados PostgreSQL
  echo "Removendo bancos de dados PostgreSQL..." | tee -a "$LOG_FILE"
  sudo su - postgres << EOF 2>&1 | tee -a "$LOG_FILE"
    psql -l
    for db in \$(psql -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';"); do
      echo "Removendo banco \$db"
      dropdb "\$db"
    done
EOF

  # Remover usuário deploy e seus arquivos
  echo "Removendo usuário deploy e arquivos..." | tee -a "$LOG_FILE"
  sudo pkill -u deploy 2>&1 | tee -a "$LOG_FILE"
  sudo deluser --remove-home deploy 2>&1 | tee -a "$LOG_FILE"

  # Remover pacotes do sistema
  echo "Removendo pacotes do sistema..." | tee -a "$LOG_FILE"
  sudo apt remove --purge -y nginx postgresql redis-server 2>&1 | tee -a "$LOG_FILE"
  sudo apt autoremove -y 2>&1 | tee -a "$LOG_FILE"

  # Remover configurações
  echo "Removendo arquivos de configuração..." | tee -a "$LOG_FILE"
  sudo rm -rf /etc/nginx/sites-enabled/* 2>&1 | tee -a "$LOG_FILE"
  sudo rm -rf /etc/nginx/sites-available/* 2>&1 | tee -a "$LOG_FILE"
  sudo rm -rf /etc/postgresql 2>&1 | tee -a "$LOG_FILE"
  sudo rm -rf /etc/redis 2>&1 | tee -a "$LOG_FILE"
  sudo rm -rf /var/lib/postgresql 2>&1 | tee -a "$LOG_FILE"
  sudo rm -rf /var/lib/redis 2>&1 | tee -a "$LOG_FILE"

  echo "=== Remoção do sistema concluída em $(date) ===" | tee -a "$LOG_FILE"

  print_banner
  printf "${GREEN} ✅ Sistema removido com sucesso!${NC}"
  printf "\n${GREEN} ℹ️ Log completo disponível em: ${LOG_FILE}${NC}"
  printf "\n${GREEN} ℹ️ Para reinstalar, use a opção 'Instalação Primária'${NC}"
  printf "\n\n"
  sleep 2
}
# Funções de sistema
system_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando o sistema...${GRAY_LIGHT}"
  printf "\n\n"

  # Atualização do sistema e instalação de dependências para Ubuntu 24.04
  sudo apt -y update
  sudo apt -y upgrade
  sudo apt-get install -y build-essential libgbm-dev wget unzip fontconfig locales gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libnss3 xdg-utils git
  sudo apt-get autoremove -y
}

system_create_user() {
  print_banner
  printf "${WHITE} 💻 Criando usuário deploy...${GRAY_LIGHT}"
  printf "\n\n"

  # Criar usuário deploy
  useradd -m -p $(openssl passwd -6 ${mysql_root_password}) -s /bin/bash -G sudo deploy
  usermod -aG sudo deploy
  
  # Adicionar usuário www-data ao grupo deploy e vice-versa
  usermod -aG www-data deploy
  usermod -aG deploy www-data

  # Configurar NVM no bashrc do usuário deploy
  sudo su - deploy << EOF
    echo 'export NVM_DIR="\$HOME/.nvm"' >> ~/.bashrc
    echo '[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"' >> ~/.bashrc
    echo '[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"' >> ~/.bashrc
EOF
}

setup_firewall() {
  print_banner
  printf "${WHITE} 💻 Configurando firewall...${GRAY_LIGHT}"
  printf "\n\n"

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
  printf "${WHITE} 💻 Instalando Node.js 20 e PM2...${GRAY_LIGHT}"
  printf "\n\n"

  # Primeiro instalar PM2 globalmente como root
  sudo su - root << EOF
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt install -y nodejs
  sudo npm install -g npm@latest
  sudo npm install -g pm2@latest
  sudo pm2 startup ubuntu -u deploy
  sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u deploy --hp /home/deploy
EOF

  # Depois instalar NVM e Node.js para o usuário deploy
  sudo su - deploy << EOF
    # Remover instalações anteriores do NVM se existirem
    rm -rf ~/.nvm

    # Instalar NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Carregar NVM imediatamente
    export NVM_DIR="\$HOME/.nvm"
    [ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
    
    # Instalar Node.js
    nvm install 20.18.0
    nvm use 20.18.0
    nvm alias default 20.18.0
EOF

  # Salvar a configuração do PM2
  sudo su - deploy << EOF
    pm2 save
EOF

  sleep 2
}

system_redis_install() {
  print_banner
  printf "${WHITE} 💻 Instalando Redis...${GRAY_LIGHT}"
  printf "\n\n"

  # Adicionar repositório do Redis para Ubuntu 24.04
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

  sleep 2
}

system_postgres_install() {
  print_banner
  printf "${WHITE} 💻 Instalando PostgreSQL...${GRAY_LIGHT}"
  printf "\n\n"

  # Instalar PostgreSQL 16 no Ubuntu 24.04
  sudo apt install -y postgresql-common
  sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y
  sudo apt update
  sudo apt install -y postgresql-16 postgresql-client-16
  
  # Iniciar e habilitar o serviço
  sudo systemctl start postgresql
  sudo systemctl enable postgresql
}

system_nginx_install() {
  print_banner
  printf "${WHITE} 💻 Instalando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sudo apt install -y nginx
  sudo rm -rf /etc/nginx/sites-enabled/default
  sudo rm -rf /etc/nginx/sites-available/default
  
  # Configurações otimizadas para o Nginx no Ubuntu 24.04
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
  print_banner
  printf "${WHITE} 💻 Instalando certbot...${GRAY_LIGHT}"
  printf "\n\n"

  sudo apt install -y snapd
  sudo snap install core
  sudo snap refresh core
  sudo apt-get remove certbot
  sudo snap install --classic certbot
  sudo ln -sf /snap/bin/certbot /usr/bin/certbot
}

create_manifest_json() {
  print_banner
  printf "${WHITE} 💻 Criando manifest.json para PWA...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - deploy << EOF
  # Garantir que o diretório public existe
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

  chmod 755 /home/deploy/${instancia_add}/frontend/public/manifest.json
EOF

  sleep 2
}

# Backend
backend_postgres_create() {
  print_banner
  printf "${WHITE} 💻 Configurando banco de dados...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - postgres <<EOF
  createdb ${instancia_add}
  psql -c "CREATE USER ${instancia_add} WITH ENCRYPTED PASSWORD '${mysql_root_password}';"
  psql -c "ALTER USER ${instancia_add} WITH SUPERUSER;"
  psql -c "GRANT ALL PRIVILEGES ON DATABASE ${instancia_add} TO ${instancia_add};"
EOF
}

backend_env_create() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente do backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  JWT_SECRET=$(openssl rand -hex 32)
  JWT_REFRESH_SECRET=$(openssl rand -hex 32)

sudo su - deploy << EOF
  cat <<[-]EOF > /home/deploy/${instancia_add}/backend/.env
NODE_ENV=production
BACKEND_URL=${backend_url}
BACKEND_PUBLIC_PATH=/home/deploy/${instancia_add}/backend/public
BACKEND_LOGS_PATH=/home/deploy/${instancia_add}/backend/logs
BACKEND_SESSION_PATH=/home/deploy/${instancia_add}/backend/.sessions
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

  sleep 2
}

backend_install() {
  print_banner
  printf "${WHITE} 💻 Instalando backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

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

  sleep 2
}

backend_start_pm2() {
  print_banner
  printf "${WHITE} 💻 Iniciando PM2 (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

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

  sleep 2
}

backend_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando nginx (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

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

  sleep 2
}

# Frontend
frontend_env_create() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente do frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

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

  sleep 2
}

frontend_install() {
  print_banner
  printf "${WHITE} 💻 Instalando frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/frontend
  npm install --legacy-peer-deps
  npm run build
  rm -rf src
EOF

  sleep 2
}

frontend_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando nginx (frontend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

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

  sleep 2
}

# Função principal de instalação
install_autoatende() {
  local installation_type=$1

  if [[ $installation_type == "primary" ]]; then
    system_update
    system_node_install
    system_redis_install
    system_postgres_install
    system_nginx_install
    system_certbot_install
    setup_firewall
    system_create_user
  fi

  # Clone do repositório
  sudo su - deploy <<EOF
    git clone -b main https://lucassaud:${token_code}@github.com/AutoAtende/${repo_name}.git /home/deploy/${instancia_add}
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

  print_banner
  printf "${GREEN} ✅ Instalação concluída com sucesso!${NC}"
  printf "\n\n"
  sleep 2
}

# Função para otimizar o sistema (opcional)
optimize_system() {
  print_banner
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

  # Otimizar Sistema
  sudo tee -a /etc/sysctl.conf > /dev/null << EOF
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
EOF

  # Aplicar alterações
  sudo systemctl restart postgresql
  sudo systemctl restart redis-server
  sudo systemctl restart nginx
  sudo sysctl -p

  print_banner
  printf "${GREEN} ✅ Sistema otimizado com sucesso!${NC}"
  printf "\n\n"
  sleep 2
}