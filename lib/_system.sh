#!/bin/bash

system_update() {
  print_banner
  printf "${WHITE} 💻 Vamos preparar o sistema para o AutoAtende...${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2
  sudo su - root <<EOF
  sudo apt -y update
  sudo apt-get -y upgrade
  sudo apt-get install -y build-essential libxshmfence-dev libgbm-dev wget unzip fontconfig locales gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils
  sudo apt-get autoremove -y
EOF
  sleep 2
}

system_node_install() {
  print_banner
  printf "${WHITE} 💻 Instalando nodejs...${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2
  sudo su - root <<EOF
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt install -y nodejs
  sudo npm install -g npm@10.8.0
  
  # Instalando PostgreSQL 16
  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt \$(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get update -y
  sudo apt-get -y install postgresql-16
  
  sudo timedatectl set-timezone America/Sao_Paulo
EOF
  sleep 2
}

system_redis_install() {
  print_banner
  printf "${WHITE} 💻 Instalando e configurando Redis...${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2
  sudo su - root <<EOF
  # Instalando Redis
  sudo apt install -y redis-server
  
  # Configurando Redis
  sudo cp /etc/redis/redis.conf /etc/redis/redis.conf.backup
  
  # Atualizando configurações do Redis
  sudo sed -i 's/^bind 127.0.0.1/bind 127.0.0.1/' /etc/redis/redis.conf
  sudo sed -i 's/# requirepass foobared/requirepass ${mysql_root_password}/' /etc/redis/redis.conf
  sudo sed -i 's/# maxmemory <bytes>/maxmemory 2gb/' /etc/redis/redis.conf
  sudo sed -i 's/# maxmemory-policy noeviction/maxmemory-policy noeviction/' /etc/redis/redis.conf
  
  # Reiniciando serviço
  sudo systemctl enable redis-server
  sudo systemctl restart redis-server
EOF
  sleep 2
}

system_create_user() {
  print_banner
  printf "${WHITE} 💻 Criando usuário deploy...${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2
  
  # Escapando caracteres especiais da senha
  ESCAPED_PASSWORD=$(printf '%q' "$mysql_root_password")
  
  sudo su - root <<EOF
  useradd -m -s /bin/bash -G sudo deploy
  echo "deploy:${ESCAPED_PASSWORD}" | chpasswd
  usermod -aG sudo deploy
EOF
  sleep 2
}

system_git_clone() {
  print_banner
  printf "${WHITE} 💻 Fazendo download do código AutoAtende...${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2
sudo su - deploy <<EOF
  git clone -b main https://lucassaud:${token_code}@github.com/AutoAtende/Sys.git /home/deploy/${instancia_add}
EOF
  sleep 2
}

system_pm2_install() {
  print_banner
  printf "${WHITE} 💻 Instalando o pm2...${GRAY_LIGHT}\n\n"
  sudo su - root <<EOF
  npm install -g pm2@latest
  pm2 startup ubuntu
  env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u deploy --hp /home/deploy
EOF
  sleep 2
  printf "${WHITE} ✔️ pm2 instalado com sucesso!${GRAY_LIGHT}\n"
  sleep 2
}

system_fail2ban_install() {
  print_banner
  printf "${WHITE} 💻 Instalando fail2ban...${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2
  sudo su - root <<EOF
  sudo apt install fail2ban -y && sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
EOF
  sleep 2
}

system_fail2ban_conf() {
  print_banner
  printf "${WHITE} 💻 Configurando o fail2ban...${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2
  sudo su - root <<EOF
  sudo systemctl enable fail2ban
  sudo systemctl start fail2ban
EOF
  sleep 2
}

system_firewall_conf() {
  print_banner
  printf "${WHITE} 💻 Configurando o firewall...${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2
  sudo su - root <<EOF
  sudo ufw default allow outgoing
  sudo ufw default deny incoming
  sudo ufw allow ssh
  sudo ufw allow 22
  sudo ufw allow 80
  sudo ufw allow 443
  sudo ufw enable
EOF
  sleep 2
}

system_nginx_install() {
  print_banner
  printf "${WHITE} 💻 Instalando nginx...${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2
  sudo su - root <<EOF
  sudo apt install -y nginx
  rm /etc/nginx/sites-enabled/default
  rm /etc/nginx/sites-available/default
EOF
  sleep 2
}

system_certbot_install() {
  print_banner
  printf "${WHITE} 💻 Instalando certbot...${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2
  sudo su - root <<EOF
  apt-get remove certbot
  snap install --classic certbot
  ln -s /snap/bin/certbot /usr/bin/certbot
EOF
  sleep 2
}

system_nginx_conf() {
  print_banner
  printf "${WHITE} 💻 Configurando nginx...${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2
sudo su - root << EOF
cat > /etc/nginx/conf.d/deploy.conf << 'END'
client_max_body_size 100M;
END
EOF
  sleep 2
}

system_nginx_restart() {
  print_banner
  printf "${WHITE} 💻 Reiniciando nginx...${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2
  sudo su - root <<EOF
  service nginx restart
EOF
  sleep 2
}

system_certbot_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando certbot, Já estamos perto do fim...${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2
  backend_domain=$(echo "${backend_url/https:\/\/}")
  frontend_domain=$(echo "${frontend_url/https:\/\/}")
  sudo su - root <<EOF
  certbot -m $deploy_email \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains $backend_domain,$frontend_domain
EOF
  sleep 2
}

system_check_node_version() {
  print_banner
  printf "${WHITE} 💻 Verificando versão do Node.js...${GRAY_LIGHT}"
  printf "\n\n"
  
  if ! command -v node &> /dev/null; then
    printf "${RED} ⚠️ Node.js não encontrado. Instalando...${GRAY_LIGHT}\n"
    system_node_install
    return
  fi
  
  CURRENT_NODE_VERSION=$(node -v | sed 's/v\([0-9]*\).*/\1/')
  if [[ ! "$CURRENT_NODE_VERSION" =~ ^[0-9]+$ ]] || [ "$CURRENT_NODE_VERSION" -lt 18 ]; then
    printf "${RED} ⚠️ Versão do Node.js ($CURRENT_NODE_VERSION) incompatível. Atualizando...${GRAY_LIGHT}\n"
    system_node_install
  else
    printf "${GREEN} ✅ Versão do Node.js ($CURRENT_NODE_VERSION) compatível.${GRAY_LIGHT}\n"
  fi
  sleep 2
}