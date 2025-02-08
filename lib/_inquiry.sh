#!/bin/bash

get_mysql_root_password() {
  print_banner
  printf "${WHITE} 💻 Insira senha para o usuario Deploy e Banco de Dados (Não utilizar caracteres especiais):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " mysql_root_password
}

get_instancia_add() {
  print_banner
  printf "${WHITE} 💻 Informe um nome para a Instancia/Empresa que será instalada (Não utilizar espaços ou caracteres especiais, Utilizar Letras minusculas; ):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " instancia_add
}

get_token_code() {
  print_banner
  printf "${WHITE} 💻 Digite o token para baixar o código:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " token_code
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

set_default_variables() {

  max_whats=1000
  max_user=1000
  backend_port=4029
  redis_port=6379
  
  # Registrando no log
  printf "${WHITE} ℹ️ Configurações padrão definidas:${GRAY_LIGHT}"
  printf "\n"
  printf "   - Máximo de conexões WhatsApp: ${max_whats}\n"
  printf "   - Máximo de usuários: ${max_user}\n"
  printf "   - Porta do backend: ${backend_port}\n"
  printf "   - Porta do Redis: ${redis_port}\n"
  printf "\n"
  sleep 2
}

get_empresa_delete() {
  print_banner
  printf "${WHITE} 💻 Digite o nome da Instancia/Empresa que será Deletada (Digite o mesmo nome de quando instalou):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " empresa_delete
}

get_urls() {
  get_mysql_root_password
  get_token_code
  get_instancia_add
  get_frontend_url
  get_backend_url
  set_default_variables
}

software_delete() {
  get_empresa_delete
  deletar_tudo
}

inquiry_options() {
  print_banner
  printf "${WHITE} 💻 Bem vindo(a) ao AutoAtende! Por favor, selecione uma opção:${GRAY_LIGHT}"
  printf "\n\n"
  printf "   [0] Instalar Nova Instância do AutoAtende\n"
  printf "   [1] Remover uma Instância Existente\n"
  printf "\n"
  read -p "> " option

  case "${option}" in
    0) 
      get_urls
      ;;
    1)
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

validate_inputs() {
  # Validação da senha
  if [[ "${mysql_root_password}" =~ [[:space:]] || "${mysql_root_password}" =~ [^a-zA-Z0-9] ]]; then
    printf "${RED} ⚠️ A senha não pode conter espaços ou caracteres especiais!${GRAY_LIGHT}"
    printf "\n\n"
    get_mysql_root_password
  fi

  # Validação do nome da instância
  if [[ "${instancia_add}" =~ [[:space:]] || "${instancia_add}" =~ [^a-z0-9] ]]; then
    printf "${RED} ⚠️ O nome da instância deve conter apenas letras minúsculas e números!${GRAY_LIGHT}"
    printf "\n\n"
    get_instancia_add
  fi

  # Validação das URLs
  if [[ ! "${frontend_url}" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
    printf "${RED} ⚠️ URL do frontend inválida!${GRAY_LIGHT}"
    printf "\n\n"
    get_frontend_url
  fi

  if [[ ! "${backend_url}" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
    printf "${RED} ⚠️ URL do backend inválida!${GRAY_LIGHT}"
    printf "\n\n"
    get_backend_url
  fi
}

# Função para mostrar o resumo das configurações
show_config_summary() {
  print_banner
  printf "${WHITE} 📝 Resumo das Configurações:${GRAY_LIGHT}"
  printf "\n\n"
  printf "   • Nome da Instância: ${instancia_add}\n"
  printf "   • URL do Frontend: ${frontend_url}\n"
  printf "   • URL do Backend: ${backend_url}\n"
  printf "   • Porta do Backend: ${backend_port}\n"
  printf "   • Porta do Redis: ${redis_port}\n"
  printf "   • Limite de Usuários: ${max_user}\n"
  printf "   • Limite de Conexões WhatsApp: ${max_whats}\n"
  printf "\n"
  printf "${WHITE} ❓ Deseja continuar com a instalação? [S/n]${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " confirm
  
  if [[ "${confirm}" =~ ^[Nn] ]]; then
    printf "${YELLOW} ⚠️ Instalação cancelada pelo usuário.${GRAY_LIGHT}"
    printf "\n\n"
    exit 1
  fi
}