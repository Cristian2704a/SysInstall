#!/bin/bash

software_delete() {
  print_banner
  printf "${WHITE} 💻 Removendo instalação existente do AutoAtende...${GRAY_LIGHT}"
  printf "\n\n"
  
  # Solicitar confirmação
  read -p "Tem certeza que deseja remover o AutoAtende? Esta ação não pode ser desfeita! (y/N) " -n 1 -r
  echo
  
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    printf "\n${RED} ❌ Operação cancelada pelo usuário.${GRAY_LIGHT}"
    printf "\n\n"
    exit 1
  fi

  # Lista todas as instâncias no diretório deploy
  instances=$(ls -d /home/deploy/*/ 2>/dev/null)
  
  if [ -z "$instances" ]; then
    printf "\n${RED} ❌ Nenhuma instalação do AutoAtende encontrada.${GRAY_LIGHT}"
    printf "\n\n"
    exit 1
  fi

  # Para cada instância encontrada
  for instance in $instances; do
    instance_name=$(basename $instance)
    
    printf "\n${WHITE} 🗑️ Removendo instância: $instance_name ${GRAY_LIGHT}"
    
    # Parar e remover processos do PM2
    sudo su - deploy <<EOF
    pm2 delete ${instance_name}-backend
    pm2 save
EOF

    # Remover arquivos do nginx
    sudo rm -f /etc/nginx/sites-enabled/${instance_name}-frontend
    sudo rm -f /etc/nginx/sites-enabled/${instance_name}-backend
    sudo rm -f /etc/nginx/sites-available/${instance_name}-frontend
    sudo rm -f /etc/nginx/sites-available/${instance_name}-backend
    
    # Remover banco de dados e usuário PostgreSQL
    sudo su - postgres <<EOF
    dropdb ${instance_name}
    dropuser ${instance_name}
EOF

    # Remover diretório da instância
    sudo rm -rf /home/deploy/${instance_name}
  done

  # Remover usuário deploy se não houver mais instâncias
  if [ -z "$(ls -A /home/deploy/)" ]; then
    sudo userdel -r deploy
  fi

  # Reiniciar nginx
  sudo systemctl restart nginx

  printf "\n${GREEN} ✅ AutoAtende removido com sucesso!${GRAY_LIGHT}"
  printf "\n\n"
}