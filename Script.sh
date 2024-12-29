#!/bin/bash

# Função para verificar e instalar pacotes, se necessário
instalar_pacote() {
    if ! command -v "$1" &> /dev/null; then
        echo "Instalando $1..."
        pkg install -y "$1"
    else
        echo "$1 já está instalado."
    fi
}

# Atualiza os pacotes e instala dependências necessárias
pkg update && pkg upgrade -y
instalar_pacote git
instalar_pacote wget

# Clona o repositório Termux-XEMU, se ainda não existir
if [ ! -d "$HOME/Termux-XEMU" ]; then
    echo "Clonando o repositório Termux-XEMU..."
    git clone https://github.com/George-Seven/Termux-XEMU.git "$HOME/Termux-XEMU"
else
    echo "O repositório Termux-XEMU já existe."
fi

# Navega até o diretório do projeto e executa o script de instalação
cd "$HOME/Termux-XEMU"
if [ -f "install.sh" ]; then
    chmod +x install.sh
    ./install.sh
else
    echo "Script install.sh não encontrado. Certifique-se de que o repositório foi clonado corretamente."
    exit 1
fi

# Cria o script de interface para conversão e execução de jogos
cat << 'EOF' > "$HOME/xemu_interface.sh"
#!/bin/bash

# Função para converter ISOs para XISO
converter_isos() {
    echo "Convertendo ISOs para XISO..."
    for iso in /storage/emulated/0/Download/XEMU/*.iso; do
        [ -e "$iso" ] || continue
        iso2xiso "$iso" "${iso%.iso}.xiso"
        echo "Convertido: $iso"
    done
}

# Função para listar e iniciar um jogo
iniciar_jogo() {
    echo "Jogos disponíveis:"
    select jogo in /storage/emulated/0/Download/XEMU/*.xiso; do
        [ -e "$jogo" ] || { echo "Seleção inválida."; continue; }
        echo "Iniciando o jogo: $jogo"
        xemu -dvd_path "$jogo"
        break
    done
}

# Menu principal
while true; do
    echo "Selecione uma opção:"
    echo "1) Converter ISOs para XISO"
    echo "2) Iniciar um jogo"
    echo "3) Sair"
    read -p "Opção: " opcao
    case $opcao in
        1) converter_isos ;;
        2) iniciar_jogo ;;
        3) exit 0 ;;
        *) echo "Opção inválida." ;;
    esac
done
EOF

# Dá permissão de execução ao script de interface
chmod +x "$HOME/xemu_interface.sh"

# Configura o Termux para executar a interface automaticamente ao iniciar
if ! grep -q 'bash ~/xemu_interface.sh' "$HOME/.bashrc"; then
    echo 'bash ~/xemu_interface.sh' >> "$HOME/.bashrc"
    echo "Configuração para iniciar a interface adicionada ao .bashrc."
else
    echo "A configuração para iniciar a interface já existe no .bashrc."
fi

echo "Instalação e configuração concluídas. Reinicie o Termux para iniciar a interface."

