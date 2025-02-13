#!/bin/bash

get_mysql_root_password() {
  print_banner
  printf "${WHITE} 💻 Insira senha para o usuario Deploy e Banco de Dados:${GRAY_LIGHT}"
  printf "\n\n"
  printf "${YELLOW} A senha precisa ter no mínimo 8 caracteres${GRAY_LIGHT}"
  printf "\n\n"
  read -s -p "> " mysql_root_password
  printf "\n"
  
  if [ ${#mysql_root_password} -lt 8 ]; then
    printf "\n${RED} ⚠️ A senha precisa ter no mínimo 8 caracteres!${GRAY_LIGHT}"
    printf "\n\n"
    get_mysql_root_password
  fi

  printf "\n${WHITE} 💻 Digite a senha novamente:${GRAY_LIGHT}"
  printf "\n\n"
  read -s -p "> " mysql_root_password_confirm
  printf "\n"

  if [ "$mysql_root_password" != "$mysql_root_password_confirm" ]; then
    printf "\n${RED} ⚠️ As senhas não conferem!${GRAY_LIGHT}"
    printf "\n\n"
    get_mysql_root_password
  fi
}

get_instancia_add() {
  print_banner
  printf "${WHITE} 💻 Digite o nome da empresa/instância (letras minúsculas, sem espaços/caracteres especiais):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " instancia_add

  if [[ ! $instancia_add =~ ^[a-z0-9]+$ ]]; then
    printf "\n${RED} ⚠️ Use apenas letras minúsculas e números!${GRAY_LIGHT}"
    printf "\n\n"
    get_instancia_add
  fi
}

get_empresa_nome() {
  print_banner
  printf "${WHITE} 💻 Digite o nome da empresa para o PWA (Nome que aparecerá no celular):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " empresa_nome

  if [ -z "$empresa_nome" ]; then
    printf "\n${RED} ⚠️ O nome da empresa não pode ficar vazio!${GRAY_LIGHT}"
    printf "\n\n"
    get_empresa_nome
  fi
}

get_token_code() {
  print_banner
  printf "${WHITE} 💻 Digite o token para baixar o código:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " token_code

  if [ -z "$token_code" ]; then
    printf "\n${RED} ⚠️ O token não pode ficar vazio!${GRAY_LIGHT}"
    printf "\n\n"
    get_token_code
  fi
}

get_frontend_url() {
  print_banner
  printf "${WHITE} 💻 Digite o domínio do FRONTEND/PAINEL (ex: painel.seudominio.com.br):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " frontend_url

  if [[ ! $frontend_url =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    printf "\n${RED} ⚠️ Domínio inválido!${GRAY_LIGHT}"
    printf "\n\n"
    get_frontend_url
  fi
}

get_backend_url() {
  print_banner
  printf "${WHITE} 💻 Digite o domínio do BACKEND/API (ex: api.seudominio.com.br):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " backend_url

  if [[ ! $backend_url =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    printf "\n${RED} ⚠️ Domínio inválido!${GRAY_LIGHT}"
    printf "\n\n"
    get_backend_url
  fi
}

set_default_variables() {
  max_whats=1000
  max_user=1000
  backend_port=4029
  redis_port=6379
}

get_urls() {
  get_mysql_root_password
  get_token_code
  get_instancia_add
  get_empresa_nome
  get_frontend_url
  get_backend_url
  set_default_variables
}

software_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando o AutoAtende...${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2

  # Verificar se existe uma instalação
  if [ ! -d "/home/deploy" ]; then
    printf "${RED} ⚠️ Nenhuma instalação do AutoAtende encontrada!${GRAY_LIGHT}"
    printf "\n\n"
    exit 1
  fi

  # Encontrar todas as instâncias
  instances=$(find /home/deploy -maxdepth 1 -type d -not -name "deploy")
  
  if [ -z "$instances" ]; then
    printf "${RED} ⚠️ Nenhuma instância encontrada!${GRAY_LIGHT}"
    printf "\n\n"
    exit 1
  fi

  # Listar instâncias disponíveis
  printf "${WHITE} Instâncias disponíveis:${GRAY_LIGHT}\n\n"
  i=1
  declare -A instance_map
  for instance in $instances; do
    instance_name=$(basename "$instance")
    instance_map[$i]=$instance_name
    printf "$i) $instance_name\n"
    ((i++))
  done

  # Solicitar escolha da instância
  printf "\n${WHITE} Escolha o número da instância para atualizar:${GRAY_LIGHT}\n"
  read -p "> " choice

  if [[ ! $choice =~ ^[0-9]+$ ]] || [ $choice -lt 1 ] || [ $choice -ge $i ]; then
    printf "\n${RED} ⚠️ Opção inválida!${GRAY_LIGHT}\n\n"
    exit 1
  fi

  selected_instance=${instance_map[$choice]}
  
  # Atualizar a instância selecionada
  cd /home/deploy/$selected_instance

  # Backup do manifest.json
  if [ -f "frontend/public/manifest.json" ]; then
    cp frontend/public/manifest.json /tmp/manifest.json
  fi

  # Atualizar código
  git fetch origin
  git reset --hard origin/main
  git pull origin main

  # Restaurar manifest.json
  if [ -f "/tmp/manifest.json" ]; then
    cp /tmp/manifest.json frontend/public/manifest.json
  fi

  # Atualizar backend
  cd backend
  pm2 stop "$selected_instance-backend"
  rm -rf node_modules
  npm install
  npm run build
  cp .env dist/
  npx sequelize db:migrate
  NODE_ENV=production pm2 start "$selected_instance-backend" --update-env
  rm -rf src
  cd ..

  # Atualizar frontend
  cd frontend
  rm -rf node_modules
  npm install --legacy-peer-deps
  npm run build
  rm -rf src
  cd ..

  # Limpar logs do PM2
  pm2 flush

  printf "\n${GREEN} ✅ Atualização concluída com sucesso!${GRAY_LIGHT}\n\n"
}

software_delete() {
  print_banner
  printf "${WHITE} 💻 Sistema de remoção do AutoAtende${GRAY_LIGHT}"
  printf "\n\n"
  
  # Verificar se existe uma instalação
  if [ ! -d "/home/deploy" ]; then
    printf "${RED} ⚠️ Nenhuma instalação do AutoAtende encontrada!${GRAY_LIGHT}"
    printf "\n\n"
    exit 1
  fi

  printf "${RED} ⚠️ ATENÇÃO: Esta operação irá remover completamente o AutoAtende!${GRAY_LIGHT}"
  printf "\n\n"
  read -p "Tem certeza que deseja continuar? (y/N) " -n 1 -r
  printf "\n\n"

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    printf "${RED} ⚠️ Operação cancelada!${GRAY_LIGHT}"
    printf "\n\n"
    exit 1
  fi

  # Encontrar todas as instâncias
  instances=$(find /home/deploy -maxdepth 1 -type d -not -name "deploy")
  
  # Parar e remover instâncias do PM2
  for instance in $instances; do
    instance_name=$(basename "$instance")
    pm2 delete "$instance_name-backend" 2>/dev/null
  done

  # Remover arquivos e diretórios
  sudo rm -rf /home/deploy
  sudo userdel -r deploy 2>/dev/null
  sudo rm -rf /etc/nginx/sites-available/autoatende*
  sudo rm -rf /etc/nginx/sites-enabled/autoatende*
  
  # Reiniciar serviços
  sudo systemctl restart nginx

  printf "\n${GREEN} ✅ AutoAtende removido com sucesso!${GRAY_LIGHT}\n\n"
}

show_vars() {
  print_banner
  printf "${WHITE} 📝 Confira os dados informados:${GRAY_LIGHT}"
  printf "\n\n"
  printf " Nome da empresa: $instancia_add\n"
  printf " Nome para PWA: $empresa_nome\n"
  printf " URL Frontend: $frontend_url\n"
  printf " URL Backend: $backend_url\n"
  printf " Porta Backend: $backend_port\n"
  printf " Porta Redis: $redis_port\n"
  printf " Limite Usuários: $max_user\n"
  printf " Limite Conexões: $max_whats\n"
  printf "\n"
  read -p "Os dados estão corretos? (y/N) " -n 1 -r
  printf "\n\n"

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    printf "${RED} ⚠️ Instalação cancelada! Execute novamente para recomeçar.${GRAY_LIGHT}"
    printf "\n\n"
    exit 1
  fi
}

inquiry_options() {
  print_banner
  printf "${WHITE} 💻 Bem vindo(a) ao AutoAtende! Selecione uma opção:${GRAY_LIGHT}"
  printf "\n\n"
  printf "   [1] Instalar AutoAtende\n"
  printf "   [2] Atualizar AutoAtende\n"
  printf "   [3] Remover AutoAtende\n"
  printf "\n"
  read -p "> " option

  case "${option}" in
    1) 
      get_urls
      show_vars
      ;;
    2)
      software_update
      exit
      ;;
    3)
      software_delete
      exit
      ;;
    *)
      printf "${RED} ⚠️ Opção inválida!${GRAY_LIGHT}"
      printf "\n\n"
      sleep 2
      inquiry_options
      ;;
  esac
}