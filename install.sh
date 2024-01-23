#!/bin/bash

# Verifica se o script está sendo executado como root
if [[ $EUID -ne 0 ]]; then
    echo "Este script deve ser executado como root"
    exit 1
fi

# Função para centralizar texto
print_centered() {
    term_width=$(tput cols)
    text="$1"
    padding=$(( (term_width - ${#text}) / 2 ))
    printf "%${padding}s" '' # Adiciona espaços antes do texto
    echo "$text"
}

# Função para simular uma barra de progresso
progress_bar() {
    local total_steps=$1
    local current_step=0

    echo -n "Progresso: ["
    while [ $current_step -lt $total_steps ]; do
        echo -n "#"
        ((current_step++))
        sleep 0.1
    done
    echo "] Completo!"
}

# Verifica se o Python 3 está instalado
if ! command -v python3 &>/dev/null; then
    print_centered "Python 3 não está instalado. Instalando..."
    sudo apt install python3 -y &>/dev/null
    progress_bar 10
    print_centered "Python 3 instalado com sucesso."
else
    print_centered "Python 3 já está instalado."
fi

# Verifica e instala dependências, incluindo o supervisor
DEPENDENCIES=("dos2unix" "supervisor")
NEED_INSTALL=()
for dep in "${DEPENDENCIES[@]}"; do
    if ! command -v $dep &>/dev/null; then
        NEED_INSTALL+=($dep)
    else
        if [ $dep == "dos2unix" ]; then
            # Para programas sem verificação de versão específica
            print_centered "$dep já está instalado."
        elif [ $dep == "supervisor" ]; then
            print_centered "$dep já está instalado."

        else
            # Para programas com verificação de versão
            current_version=$($dep -v | cut -d 'v' -f 2 | cut -d '.' -f 1)
            print_centered "$dep já está instalado. Versão atual: $current_version."
        fi
    fi
done

# Instala dependências necessárias
for dep in "${NEED_INSTALL[@]}"; do
    print_centered "Instalando $dep..."
    case $dep in
        dos2unix)
            sudo apt install dos2unix -y &>/dev/null
            ;;
        supervisor)
            sudo apt install supervisor -y &>/dev/null
            ;;
    esac
    progress_bar 10
    current_version=$($dep -v | cut -d 'v' -f 2 | cut -d '.' -f 1)
    print_centered "$dep instalado com sucesso. Versão: $current_version."
done

# Verifica se o diretório /opt/myapp/ existe
if [ -d "/opt/myapp/" ]; then
    print_centered "Diretório /opt/myapp/ já existe. Parando e excluindo processo se existir..."
    sudo supervisorctl stop m-dulo &>/dev/null
    sudo supervisorctl remove m-dulo &>/dev/null
    print_centered "Excluindo arquivos e pastas antigos..."
    sudo rm -rf /opt/myapp/
else
    print_centered "Diretório /opt/myapp/ não existe. Criando..."
fi

# Criar o diretório para o aplicativo
sudo mkdir -p /opt/myapp/

# Baixar o ZIP do repositório ModulosPro diretamente no diretório /opt/myapp/
print_centered "Baixando modulos-pro..."
sudo wget --timeout=30 -P /opt/myapp/ https://github.com/sshturbo/m-dulo/raw/main/modulos.zip &>/dev/null

# Extrair o ZIP diretamente no diretório /opt/myapp/ e remover o arquivo ZIP após a extração
print_centered "Extraindo arquivos..."
sudo unzip /opt/myapp/modulos.zip -d /opt/myapp/ &>/dev/null && sudo rm /opt/myapp/modulos.zip
progress_bar 5

# Dar permissão de execução para scripts .sh e converter para o formato Unix
print_centered "Atualizando permissões..."
files=(
    "SshturboMakeAccount.sh"
    "ExcluirExpiradoApi.sh"
    "killuser.sh"
)

for file in "${files[@]}"; do
    sudo chmod +x /opt/myapp/"$file"
    dos2unix /opt/myapp/"$file" &>/dev/null
done

# Copiar o arquivo m-dulo.conf para /etc/supervisor/conf.d
if [ -f "/opt/myapp/m-dulo.conf" ]; then
    print_centered "Copiando m-dulo.conf para /etc/supervisor/conf.d..."
    sudo cp /opt/myapp/m-dulo.conf /etc/supervisor/conf.d/
    sudo chown root:root /etc/supervisor/conf.d/m-dulo.conf
    sudo chmod 644 /etc/supervisor/conf.d/m-dulo.conf
    print_centered "Arquivo copiado com sucesso."
else
    print_centered "Arquivo m-dulo.conf não encontrado. Verifique se o arquivo existe no repositório."
fi

# Instalar dependências do Python
print_centered "Instalando dependências do Python..."
sudo pip3 install -r requirements.txt --prefix /opt/myapp/ &>/dev/null
progress_bar 5

# Atualizar a configuração do Supervisor
sudo supervisorctl update &>/dev/null

# Iniciar o serviço
print_centered "Iniciando o modulos do painel..."
sudo supervisorctl start m-dulo &>/dev/null

progress_bar 10

print_centered "Modulos instalado com sucesso!"