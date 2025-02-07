#!/bin/bash

# reset shell colors
tput init

# https://stackoverflow.com/questions/59895/how-to-get-the-source-directory-of-a-bash-script-from-within-the-script-itself
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  PROJECT_ROOT="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$PROJECT_ROOT/$SOURCE"
done
PROJECT_ROOT="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

# Definição das cores
RED="\033[1;31m"
GREEN="\033[1;32m"
BLUE="\033[1;32m"
WHITE="\033[1;37m"
YELLOW="\033[1;33m"
GRAY_LIGHT="\033[0;37m"
CYAN_LIGHT="\033[1;36m"
NC="\033[0m"

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

# Função para obter dados do usuário
get_install_type() {
  print_banner
  printf "${WHITE} 💻 Selecione o tipo de instalação:${GRAY_LIGHT}"
  printf "\n\n"
  printf "   [1] Instalação Primária (Primeira instalação no servidor)\n"
  printf "   [2] Instalação de Instância (Adicionar nova instância)\n"
  printf "   [3] Sair\n"
  printf "\n"
  read -p "> " install_type

  case "${install_type}" in
    1) setup_logging && show_system_menu "primary" ;;
    2) setup_logging && show_system_menu "instance" ;;
    3) exit 0 ;;
    *) echo "Opção inválida" && sleep 2 && get_install_type ;;
  esac
}

# Menu do sistema
show_system_menu() {
  local installation_type=$1
  
  print_banner
  printf "${WHITE} 💻 Selecione a ação desejada:${GRAY_LIGHT}"
  printf "\n\n"
  printf "   [1] Instalar AutoAtende\n"
  printf "   [2] Remover AutoAtende\n"
  printf "   [3] Otimizar Sistema\n"
  printf "   [4] Voltar\n"
  printf "\n"
  read -p "> " option

  case "${option}" in
    1) get_urls && install_autoatende $installation_type ;;
    2) software_delete ;;
    3) optimize_system ;;
    4) get_install_type ;;
    *) echo "Opção inválida" && sleep 2 && show_system_menu $installation_type ;;
  esac
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
}

# Funções de sistema
system_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando o sistema...${GRAY_LIGHT}"
  printf "\n\n"

  sudo apt -y update
  sudo apt -y upgrade
  sudo apt-get install -y build-essential libxshmfence-dev libgbm-dev wget unzip fontconfig locales gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils
}

system_create_user() {
  print_banner
  printf "${WHITE} 💻 Criando usuário deploy...${GRAY_LIGHT}"
  printf "\n\n"

  sudo useradd -m -p $(openssl passwd -6 ${mysql_root_password}) -s /bin/bash -G sudo deploy
  sudo usermod -aG sudo deploy
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
  sudo ufw allow 6379
  sudo ufw allow ${backend_port}
  sudo ufw allow ${redis_port}
  echo "y" | sudo ufw enable
}

system_node_install() {
  print_banner
  printf "${WHITE} 💻 Instalando NVM e Node.js 20.18...${GRAY_LIGHT}"
  printf "\n\n"

  # Instalar NVM
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  
  # Carregar NVM no ambiente atual
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  
  # Instalar Node.js 20.18
  nvm install 20.18.0
  nvm use 20.18.0
  nvm alias default 20.18.0

  # Atualizar NPM para a última versão
  npm install -g npm@latest

  # Adicionar NVM ao .bashrc do usuário deploy
  sudo su - deploy << EOF
    echo 'export NVM_DIR="\$HOME/.nvm"' >> ~/.bashrc
    echo '[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"' >> ~/.bashrc
    echo '[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"' >> ~/.bashrc
    
    # Instalar NVM para o usuário deploy
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Carregar NVM e instalar Node.js
    export NVM_DIR="\$HOME/.nvm"
    [ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
    nvm install 20.18.0
    nvm use 20.18.0
    nvm alias default 20.18.0
EOF
}

system_redis_install() {
  print_banner
  printf "${WHITE} 💻 Instalando Redis...${GRAY_LIGHT}"
  printf "\n\n"

  sudo apt install -y redis-server
  sudo sed -i 's/supervised no/supervised systemd/' /etc/redis/redis.conf
  
  # Configurando senha do Redis
  sudo sed -i "s/# requirepass foobared/requirepass ${mysql_root_password}/" /etc/redis/redis.conf
  
  sudo systemctl restart redis.service
  sudo systemctl enable redis.service
}

system_postgres_install() {
  print_banner
  printf "${WHITE} 💻 Instalando PostgreSQL 16...${GRAY_LIGHT}"
  printf "\n\n"

  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt update
  sudo apt install -y postgresql-16
}

system_nginx_install() {
  print_banner
  printf "${WHITE} 💻 Instalando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sudo apt install -y nginx
  sudo rm -rf /etc/nginx/sites-enabled/default
  sudo rm -rf /etc/nginx/sites-available/default
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

# Funções de otimização
optimize_postgresql() {
  print_banner
  printf "${WHITE} 💻 Otimizando PostgreSQL...${GRAY_LIGHT}"
  printf "\n\n"

  total_memory=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  shared_buffers=$((total_memory / 4 / 1024))
  maintenance_work_mem=$((total_memory / 10 / 1024))
  effective_cache_size=$((total_memory * 3 / 4 / 1024))

  sudo -u postgres psql -c "ALTER SYSTEM SET shared_buffers = '${shared_buffers}MB';"
  sudo -u postgres psql -c "ALTER SYSTEM SET work_mem = '4MB';"
  sudo -u postgres psql -c "ALTER SYSTEM SET maintenance_work_mem = '${maintenance_work_mem}MB';"
  sudo -u postgres psql -c "ALTER SYSTEM SET effective_cache_size = '${effective_cache_size}MB';"
  sudo -u postgres psql -c "ALTER SYSTEM SET checkpoint_timeout = '15min';"
  sudo -u postgres psql -c "ALTER SYSTEM SET checkpoint_completion_target = '0.9';"
  sudo -u postgres psql -c "ALTER SYSTEM SET wal_buffers = '16MB';"
  sudo -u postgres psql -c "ALTER SYSTEM SET max_connections = '200';"

  sudo systemctl restart postgresql
}

optimize_redis() {
  print_banner
  printf "${WHITE} 💻 Otimizando Redis...${GRAY_LIGHT}"
  printf "\n\n"

  total_memory=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  maxmemory=$((total_memory / 2 / 1024))

  sudo tee -a /etc/redis/redis.conf > /dev/null <<EOT
maxmemory ${maxmemory}mb
maxmemory-policy allkeys-lru
EOT

  sudo systemctl restart redis
}

optimize_nginx() {
  print_banner
  printf "${WHITE} 💻 Otimizando Nginx...${GRAY_LIGHT}"
  printf "\n\n"

  cpu_cores=$(nproc)

  sudo tee /etc/nginx/nginx.conf > /dev/null <<EOT
user www-data;
worker_processes $cpu_cores;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;
    
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    gzip on;
    gzip_disable "msie6";
    
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOT

  sudo systemctl restart nginx
}

optimize_nodejs() {
  print_banner
  printf "${WHITE} 💻 Otimizando Node.js...${GRAY_LIGHT}"
  printf "\n\n"

  export NODE_OPTIONS="--max-old-space-size=8096"
  
  if command -v pm2 &> /dev/null; then
    pm2 reload all --update-env
  fi
}

optimize_system() {
  print_banner
  printf "${WHITE} 💻 Iniciando otimização do sistema...${GRAY_LIGHT}"
  printf "\n\n"

  optimize_postgresql
  optimize_redis
  optimize_nginx
  optimize_nodejs

  print_banner
  printf "${GREEN} ✅ Sistema otimizado com sucesso!${NC}"
  printf "\n\n"
  sleep 2
}

# Função de instalação do backend
backend_install() {
  print_banner
  printf "${WHITE} 💻 Instalando backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/backend
  npm install
  npm run build
  
  # Criar diretórios necessários
  mkdir -p logs
  chmod 777 logs
  mkdir -p public/company1/{medias,tasks,announcements,logos,backgrounds,quickMessages,profile}
  chmod -R 777 public
EOF
}

# Função de configuração do banco de dados
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

# Configuração do ambiente backend
backend_env_create() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente do backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # Gera JWT_SECRET
  JWT_SECRET=$(openssl rand -hex 32)
  # Gera JWT_REFRESH_SECRET
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

# Configuração do PM2 para o backend
backend_start_pm2() {
  print_banner
  printf "${WHITE} 💻 Iniciando PM2 (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # Criar arquivo de configuração do PM2
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

# Configuração do Nginx para o backend
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

  # Bloquear solicitações de arquivos do GitHub
  location ~ /\.git {
    deny all;
  }
}
END

ln -s /etc/nginx/sites-available/${instancia_add}-backend /etc/nginx/sites-enabled
EOF

  sleep 2
}

# Instalação e configuração do frontend
frontend_install() {
  print_banner
  printf "${WHITE} 💻 Instalando frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/frontend
  npm install --legacy-peer-deps
  npm run build
EOF
}

# Configuração do ambiente frontend
frontend_env_create() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente do frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - deploy << EOF
  cat <<[-]EOF > /home/deploy/${instancia_add}/frontend/.env
REACT_APP_BACKEND_URL=${backend_url}
REACT_APP_HOURS_CLOSE_TICKETS_AUTO=24
REACT_APP_LOCALE=pt-br
REACT_APP_TIMEZONE=America/Sao_Paulo
[-]EOF
EOF

  sleep 2
}

# Configuração do Nginx para o frontend
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

# Função para remover uma instância
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

# Iniciar o instalador
get_install_type