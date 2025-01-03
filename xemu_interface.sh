#!/bin/bash

# Definir cores
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
VERMELHO='\033[0;31m'
NC='\033[0m' # Sem cor

# Função para verificar e instalar o XEMU
instalar_xemu() {
    echo -e "${AZUL}Verificando a instalação do XEMU...${NC}"
    if ! command -v xemu &> /dev/null; then
        echo -e "${AMARELO}XEMU não encontrado. Iniciando instalação...${NC}"

        # Atualizar e instalar pacotes necessários
        echo -e "${AMARELO}Atualizando pacotes...${NC}"
        apt update && apt upgrade -y

        echo -e "${AMARELO}Instalando pacotes necessários...${NC}"
        apt install -y x11-repo tigervnc xterm

        # Instalar dependências adicionais e o XEMU
        echo -e "${AMARELO}Instalando o XEMU...${NC}"
        apt install -y --no-install-recommends wget openbox

        wget -O xemu-arm64.deb "https://github.com/George-Seven/Termux-XEMU/releases/latest/download/xemu-arm64.deb"
        apt install ./xemu-arm64.deb

        echo -e "${VERDE}Instalação do XEMU concluída.${NC}"
    else
        echo -e "${VERDE}XEMU já está instalado.${NC}"
    fi
}

# Função para configurar o ambiente gráfico e iniciar o XEMU
iniciar_xemu() {
    echo -e "${AMARELO}Inicializando o ambiente gráfico...${NC}"

    # Configurar o display
    export DISPLAY=:1
    kill -9 $(pgrep -f "termux.x11") 2>/dev/null

    if command -v openbox-session >/dev/null 2>&1; then
        termux-x11 -ac -xstartup openbox-session :1 2>/dev/null
    else
        termux-x11 -ac :1
    fi &
    
    echo -e "${VERDE}Ambiente gráfico inicializado.${NC}"
}

# Função para converter jogos para XISO usando iso2xiso
converter_jogos() {
    echo -e "${AMARELO}Iniciando a conversão de jogos para XISO...${NC}"
    mkdir -p ~/converted_xiso
    for iso in /storage/emulated/0/Download/XEMU/*.iso; do
        if [[ -f "$iso" && ! -f "~/converted_xiso/$(basename "$iso" .iso).xiso" ]]; then
            nome_jogo=$(basename "$iso" .iso)
            echo -e "${AZUL}Convertendo: $iso para ~/converted_xiso/${nome_jogo}.xiso...${NC}"
            iso2xiso "$iso" "~/converted_xiso/${nome_jogo}.xiso"
            if [[ $? -eq 0 ]]; then
                echo -e "${VERDE}Convertido: $iso para ~/converted_xiso/${nome_jogo}.xiso${NC}"
                # Não deleta o arquivo ISO original se o convertido já existir
                echo -e "${VERDE}ISO original preservada: $iso${NC}"
            else
                echo -e "${VERMELHO}Erro na conversão de $iso${NC}"
            fi
        else
            echo -e "${AMARELO}O arquivo convertido já existe. Pulando: $iso${NC}"
        fi
    done
    echo -e "${AMARELO}Conversão concluída. Arquivos salvos em ~/converted_xiso.${NC}"
}

# Função para listar e iniciar jogos
iniciar_jogo() {
    echo -e "${AZUL}Jogos disponíveis na pasta:/storage/emulated/0/Download/XEMU:${NC}"
    select jogo in /storage/emulated/0/Download/XEMU/*.iso; do
        if [[ -n "$jogo" ]]; then
            echo -e "${AMARELO}Iniciando $jogo...${NC}"
            iniciar_xemu
            xemu -dvd_path "$jogo"
            break
        else
            echo -e "${VERMELHO}Seleção inválida. Tente novamente.${NC}"
        fi
    done
}

# Verificar e instalar o XEMU se necessário
instalar_xemu

# Adicionar o script ao .bashrc para execução automática no início
if ! grep -q "xemu_interface.sh" ~/.bashrc; then
    echo -e "${AMARELO}Adicionando o script ao .bashrc para execução automática...${NC}"
    echo "bash ~/xemu_interface.sh" >> ~/.bashrc
    echo -e "${VERDE}Configuração concluída.${NC}"
else
    echo -e "${VERDE}Script já está configurado para ser executado no início.${NC}"
fi

# Menu principal
while true; do
    echo -e "${AMARELO}Selecione uma opção:${NC}"
    echo -e "1) Converter jogos para XISO"
    echo -e "2) Iniciar um jogo"
    echo -e "3) Sair"
    read -p "Opção: " opcao
    case $opcao in
        1) converter_jogos ;;
        2) iniciar_jogo ;;
        3) exit 0 ;;
        *) echo -e "${VERMELHO}Opção inválida. Tente novamente.${NC}" ;;
    esac
done
