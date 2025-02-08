#!/bin/bash

# reset shell colors
tput init

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

# Incluir o arquivo de funções
source "${PROJECT_ROOT}/core.sh"

# Função para remover software
software_delete() {
  printf "${WHITE} 💻 Selecione o tipo de remoção:${GRAY_LIGHT}"
  printf "\n\n"
  printf "   [1] Remover uma instância\n"
  printf "   [2] Remover sistema por completo\n"
  printf "   [3] Voltar\n"
  printf "\n"
  read -p "> " delete_type

  case "${delete_type}" in
    1) remove_instance ;;
    2) remove_complete_system ;;
    3) show_system_menu ;;
    *) echo "Opção inválida" && sleep 2 && software_delete ;;
  esac
}

# Menu principal
get_install_type() {
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
  
  while true; do
    printf "${WHITE} 💻 Selecione a ação desejada:${GRAY_LIGHT}"
    printf "\n\n"
    printf "   [1] Instalar AutoAtende\n"
    printf "   [2] Remover AutoAtende\n"
    printf "   [3] Otimizar Sistema\n"
    printf "   [4] Voltar\n"
    printf "\n"
    read -p "> " option

    case "${option}" in
      1) 
        get_urls
        if [ $? -eq 0 ]; then
          install_autoatende "$installation_type"
          if [ $? -eq 0 ]; then
            break
          fi
        fi
        ;;
      2) software_delete && break ;;
      3) optimize_system && show_system_menu "$installation_type" ;;
      4) get_install_type && break ;;
      *) echo "Opção inválida" && sleep 2 ;;
    esac
  done
}

# Iniciar o instalador
get_install_type