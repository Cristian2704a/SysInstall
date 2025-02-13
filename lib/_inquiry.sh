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
  printf "${WHITE} 💻 Digite o domínio do sistema (ex: seudominio.com.br):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " frontend_url

  if [[ ! $frontend_url =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    printf "\n${RED} ⚠️ Domínio inválido!${GRAY_LIGHT}"
    printf "\n\n"
    get_frontend_url
  fi
  
  # Define backend_url como o mesmo domínio
  backend_url="$frontend_url"
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
  set_default_variables
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
  printf "   [2] Remover AutoAtende\n"
  printf "\n"
  read -p "> " option

  case "${option}" in
    1) 
      get_urls
      show_vars
      ;;
    2)
      system_delete
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