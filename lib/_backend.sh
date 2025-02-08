#!/bin/bash

backend_redis_create() {
  print_banner
  printf "${WHITE} 💻 Criando Redis & Banco Postgres...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  usermod -aG docker deploy
  docker run --name redis-${instancia_add} -p ${redis_port}:6379 --restart always -v redis-data-${instancia_add}:/data --detach redis:latest redis-server --requirepass ${mysql_root_password} --maxmemory 2gb --maxmemory-policy noeviction
  sudo su - postgres
  createdb ${instancia_add};
  psql
  CREATE USER ${instancia_add} SUPERUSER INHERIT CREATEDB CREATEROLE;
  ALTER USER ${instancia_add} PASSWORD '${mysql_root_password}';
  \q
  exit
EOF

sleep 2

}

backend_set_env() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente (backend)...${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2
  
  backend_url=$(echo "${backend_url/https:\/\/}")
  backend_url=${backend_url%%/*}
  backend_url=https://$backend_url
  
  frontend_url=$(echo "${frontend_url/https:\/\/}")
  frontend_url=${frontend_url%%/*}
  frontend_url=https://$frontend_url
  
  JWT_SECRET=$(openssl rand -hex 32)
  JWT_REFRESH_SECRET=$(openssl rand -hex 32)

sudo su - deploy << EOF
  cat <<[-]EOF > /home/deploy/${instancia_add}/backend/.env
NODE_ENV=production
BACKEND_URL=${backend_url}
FRONTEND_URL=${frontend_url}
PORT=${backend_port}

DB_HOST=localhost
DB_DIALECT=postgres
DB_USER=${instancia_add}
DB_PASS=${mysql_root_password}
DB_NAME=${instancia_add}
DB_PORT=5432

REDIS_URI=redis://:${mysql_root_password}@127.0.0.1:${redis_port}
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

backend_node_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependências do backend...${GRAY_LIGHT}"
  printf "\n\n"


  sleep 2

sudo su - deploy <<EOF
cd /home/deploy/${instancia_add}/backend
mkdir logs
chmod 777 logs
mkdir public
chmod 777 public
mkdir -p public/company1
chmod 777 public/company1
mkdir -p public/company1/medias
chmod 777 public/company1/medias
mkdir -p public/company1/tasks
chmod 777 public/company1/tasks
mkdir -p public/company1/announcements
chmod 777 public/company1/announcements
mkdir -p public/company1/logos
chmod 777 public/company1/logos
mkdir -p public/company1/backgrounds
chmod 777 public/company1/backgrounds
mkdir -p public/company1/quickMessages
chmod 777 public/company1/quickMessages
mkdir -p public/company1/profile
chmod 777 public/company1/profile
npm install
EOF

  printf "${GREEN}Instalação das dependências concluída com sucesso!\n"

  sleep 2
}

backend_node_build() {
  print_banner
  printf "${WHITE} 💻 Compilando o código do backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - deploy <<EOF
cd /home/deploy/${instancia_add}/backend
npm run build
cp .env dist/
rm -rf src
EOF

  sleep 2
}

backend_db_migrate() {
  print_banner
  printf "${WHITE} 💻 Executando db:migrate...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - deploy <<EOF
cd /home/deploy/${instancia_add}/backend
npx sequelize db:migrate
npx sequelize db:migrate
npx sequelize db:migrate
EOF

  sleep 2
}

backend_redis_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando Redis para o backend...${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2
  
  # As configurações já foram feitas na instalação do Redis
  # Apenas verificando se o serviço está rodando
  sudo systemctl status redis-server --no-pager
  
  sleep 2
}

backend_db_seed() {
  print_banner
  printf "${WHITE} 💻 Executando db:seed...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - deploy <<EOF
cd /home/deploy/${instancia_add}/backend
npx sequelize db:seed:all
EOF

  sleep 2
}

backend_start_pm2() {
  print_banner
  printf "${WHITE} 💻 Iniciando pm2 (backend)...${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2

  # Criar o arquivo de configuração do PM2
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

EOF

  # Configurar PM2 startup
  sudo su - root << EOF
pm2 startup
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u deploy --hp /home/deploy
EOF

  # Iniciar a aplicação usando o arquivo de configuração
  sudo su - deploy << EOF
cd /home/deploy/${instancia_add}/backend
NODE_ENV=production pm2 start ecosystem.config.js --update-env
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

  # BLoquear solicitacoes de arquivos do GitHub
  location ~ /\.git {
    deny all;
  }

}
END
ln -s /etc/nginx/sites-available/${instancia_add}-backend /etc/nginx/sites-enabled
EOF

  sleep 2
}
