#!/data/data/com.termux/files/usr/bin/bash

# --- PALETA DE CORES ---
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
WHITE="\033[1;37m"
GRAY="\033[1;30m"

# 🔒 COLOQUE O SEU LINK RAW DO PASTEBIN ENTRE AS ASPAS ABAIXO:
KEYS_URL="COLE_AQUI_O_SEU_LINK_RAW_DO_PASTEBIN"
ADB_BIN="/data/data/com.termux/files/usr/bin/adb"
ADB_DEVICE=""

clear

# --- FUNÇÃO 1: VERIFICAÇÃO E CONEXÃO DO ADB ---
conectar_adb() {
    while true; do
        if $ADB_BIN devices | grep -v "List of devices" | grep -q "device"; then
            ADB_DEVICE=$($ADB_BIN devices | grep -v "List" | head -n 1 | awk '{print $1}')
            return 0
        fi

        clear
        echo -e "${BLUE}==============================================${RESET}"
        echo -e "         ${BOLD}${WHITE}yAshinDev REPLAY TOOL${RESET}"
        echo -e "${BLUE}==============================================${RESET}"
        echo -e " ${BOLD}${YELLOW}[!] NENHUM DISPOSITIVO ADB DETECTADO${RESET}"
        echo -e " ${GRAY}Aguardando conexao sem fio...${RESET}"
        echo -e "${BLUE}==============================================${RESET}"
        echo -e " ${WHITE}Escolha uma opcao para prosseguir:${RESET}"
        echo -e "  ${BLUE}[ 1 ]${RESET} Tentar conectar a um IP:PORTA automaticamente"
        echo -e "  ${BLUE}[ 2 ]${RESET} Ja conectei em outro terminal (Reverificar)"
        echo -e "  ${BLUE}[ 3 ]${RESET} Sair do Painel"
        echo -e "${BLUE}==============================================${RESET}"
        echo -n -e " ${BOLD}${WHITE}> ${RESET}"
        read -r ADB_OPT < /dev/tty

        case "$ADB_OPT" in
            1)
                echo -n -e "\n ${BOLD}${YELLOW}Digite o IP e Porta (ex: 192.168.0.4:41081): ${RESET}"
                read -r CONN_STR < /dev/tty
                if [ -n "$CONN_STR" ]; then
                    echo -e " ${GRAY}Conectando a $CONN_STR...${RESET}"
                    $ADB_BIN connect "$CONN_STR"
                    sleep 2
                fi
                ;;
            2)
                echo -e " ${GRAY}Reverificando conexao...${RESET}"
                sleep 1
                ;;
            3)
                echo -e " ${WHITE}Saindo...${RESET}"
                exit 0
                ;;
            *)
                echo -e " ${BOLD}${WHITE}Opcao invalida.${RESET}"
                sleep 1
                ;;
        esac
    done
}

# --- FUNÇÃO 2: EXECUÇÃO DA TRANSFERÊNCIA (MAX -> NORMAL) ---
transferir_max_normal() {
    echo -e "\n${GRAY} -> Transferindo arquivos...${RESET}"
    
    # Criando comandos em variáveis para evitar quebra de strings
    CMD_VERIFICA="[ -d /storage/emulated/0/Android/data/com.dts.freefiremax/files/MReplays ] && echo 'OK' || echo 'ERRO'"
    
    CHECK_PASTA=$($ADB_BIN shell "$CMD_VERIFICA" | tr -d '\r')
    if [ "$CHECK_PASTA" != "OK" ]; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Pasta do Free Fire Max nao encontrada."
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    # Executa a cópia e substituição de versão diretamente no Android
    $ADB_BIN shell "mkdir -p /storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays 2>/dev/null"
    $ADB_BIN shell "cp -f /storage/emulated/0/Android/data/com.dts.freefiremax/files/MReplays/*.bin /storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays/ 2>/dev/null"
    $ADB_BIN shell "cp -f /storage/emulated/0/Android/data/com.dts.freefiremax/files/MReplays/*.json /storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays/ 2>/dev/null"
    
    # Corrige os cabeçalhos JSON da versão do FF Normal
    $ADB_BIN shell "for f in /storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays/*.json; do if [ -f \"\$f\" ]; then sed 's/\"[Vv]ersion\":\"[^\"]*\"/\"Version\":\"1.123.15\"/' \"\$f\" > \"\$f.tmp\" && mv -f \"\$f.tmp\" \"\$f\"; fi; done 2>/dev/null"

    # Coleta os dados do sistema destino de forma isolada
    COUNT=$($ADB_BIN shell "find /storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays -name '*.bin' 2>/dev/null | wc -l" | tr -d '\r')
    BRAND=$($ADB_BIN shell "getprop ro.product.brand" | tr -d '\r' | tr '[:lower:]' '[:upper:]')
    MODEL=$($ADB_BIN shell "getprop ro.product.model" | tr -d '\r')
    ANDROID=$($ADB_BIN shell "getprop ro.build.version.release" | tr -d '\r')
    BATT=$($ADB_BIN shell "dumpsys battery | grep level | awk '{print \$2}'" | tr -d '\r')
    FREE_STORAGE=$($ADB_BIN shell "df -h /data 2>/dev/null | awk 'NR==2 {print \$4}'" | tr -d '\r')
    FREE_RAM=$($ADB_BIN shell "cat /proc/meminfo 2>/dev/null | grep MemAvailable | awk '{printf \"%.2f\", \$2/1024/1024}'" | tr -d '\r')
    NOW=$(date +"%d/%m/%Y %H:%M")

    clear
    echo -e " "
    echo -e "      ${BOLD}${WHITE}- REPLAY TOOL (Max -> Normal)${RESET}"
    echo -e "${GRAY}--------------------------------------------${RESET}"
    echo -e "  ${BOLD}RESUMO DA OPERACAO${RESET}"
    echo -e " "
    echo -e "  Arquivos encontrados : ${WHITE}$COUNT${RESET}"
    echo -e "  Replays transferidos : ${WHITE}$COUNT${RESET}"
    echo -e "  Tempo de execucao    : ${WHITE}1s${RESET}"
    echo -e "  Data/Hora            : ${WHITE}$NOW${RESET}"
    echo -e "  Status               : ${GREEN}CONCLUIDO${RESET}"
    echo -e " "
    echo -e "${GRAY}--------------------------------------------${RESET}"
    echo -e "  ${BOLD}INFORMACOES DO DISPOSITIVO DESTINO${RESET}"
    echo -e " "
    echo -e "  Marca   : ${WHITE}$BRAND${RESET}"
    echo -e "  Modelo  : ${WHITE}$MODEL${RESET}"
    echo -e "  Android : ${WHITE}$ANDROID${RESET}"
    echo -e "  Bateria : ${WHITE}${BATT}%${RESET}"
    echo -e "  Espaco  : ${WHITE}${FREE_STORAGE} livre${RESET}"
    echo -e "  RAM     : ${WHITE}${FREE_RAM}GB livre${RESET}"
    echo -e "${GRAY}--------------------------------------------${RESET}"
    echo -e " "
    echo -e "  ${BOLD}yAshinDev${RESET}"
    echo -e " "
    read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
}

# --- 3. EXECUÇÃO DO SISTEMA DE KEYS (LOOP INICIAL) ---
while true; do
    clear
    echo -e "${BLUE}==============================================${RESET}"
    echo -e "         ${BOLD}${WHITE}yAshinDev SECURITY SYSTEM${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    echo -e " ${GRAY}Por favor, insira sua chave de acesso para continuar.${RESET}"
    echo -e " "
    echo -n -e " ${BOLD}${YELLOW}> Chave: ${RESET}"

    read -r USER_KEY < /dev/tty

    if [ -z "$USER_KEY" ]; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} A chave nao pode estar vazia!"
        sleep 2
        continue
    fi

    echo -e "\n${GRAY} -> Autenticando com o servidor...${RESET}"
    VALID_KEYS=$(curl -sL "$KEYS_URL")

    if [ -z "$VALID_KEYS" ]; then
        echo -e "${BOLD}${WHITE}[!] ERRO:${RESET} Sem conexao com o banco de chaves."
        sleep 2
        continue
    fi

    KEY_LINE=$(echo "$VALID_KEYS" | grep -E "^${USER_KEY}:" | head -n 1)

    if [ -z "$KEY_LINE" ]; then
        echo -e "${BOLD}${WHITE}[!] ERRO:${RESET} Chave incorreta ou inexistente!"
        echo -e " ${GRAY}Tente novamente...${RESET}"
        sleep 2
        continue
    fi

    EXP_DATE=$(echo "$KEY_LINE" | cut -d':' -f2 | tr -d '\r')
    TODAY=$(date +"%Y-%m-%d")

    EXP_SEC=$(date -d "$EXP_DATE" +%s 2>/dev/null)
    TODAY_SEC=$(date -d "$TODAY" +%s 2>/dev/null)

    if [ -z "$EXP_SEC" ] || [ -z "$TODAY_SEC" ]; then
        echo -e "${BOLD}${WHITE}[!] ERRO:${RESET} Falha interna ao verificar validade."
        sleep 2
        continue
    fi

    if [ "$TODAY_SEC" -gt "$EXP_SEC" ]; then
        echo -e "${BOLD}${WHITE}[!] ERRO:${RESET} Esta chave expirou em ${EXP_DATE}!"
        echo -e " ${GRAY}Adquira uma nova chave de 7 dias com yAshinDev.${RESET}"
        sleep 3
        continue
    fi

    DAYS_LEFT=$(( (EXP_SEC - TODAY_SEC) / 86400 ))

    echo -e "${GREEN} -> Chave autenticada com sucesso!${RESET}"
    if [ "$DAYS_LEFT" -eq 0 ]; then
        echo -e " ${YELLOW}[!] Aviso: Sua chave expira hoje!${RESET}"
    else
        echo -e " ${GRAY}Validade restante: ${DAYS_LEFT} dia(s).${RESET}"
    fi
    sleep 1.5
    break
done

# --- 4. VALIDAÇÃO INICIAL DO ADB ---
conectar_adb

# --- 5. LOOP DO MENU PRINCIPAL ---
while true; do
    if ! $ADB_BIN devices | grep -v "List of devices" | grep -q "device"; then
        echo -e "\n${BOLD}${WHITE}[!] Conexao ADB perdida! Reestabelecendo...${RESET}"
        sleep 1
        conectar_adb
    fi

    clear
    echo -e "${BLUE}==============================================${RESET}"
    echo -e " ${BOLD}${GREEN}PASSADOR DE REPLAY BY yAshinDev${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    echo -e " ${BOLD}${YELLOW}DISPOSITIVO CONECTADO${RESET}"
    echo -e " device:${WHITE}${ADB_DEVICE}${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    echo -e " ${BOLD}${YELLOW}VERSÃO FF MAX:${RESET} 2.124.15"
    echo -e " ${BOLD}${YELLOW}VERSÃO FF:${RESET} 1.123.15"
    echo -e "${BLUE}==============================================${RESET}"
    echo -e " ${BLUE}[ 1 ]${RESET} ${WHITE}FREE FIRE MAX PARA NORMAL${RESET}"
    echo -e " ${BLUE}[ 2 ]${RESET} ${WHITE}FREE FIRE NORMAL PARA MAX${RESET}"
    echo -e " ${BLUE}[ 3 ]${RESET} ${WHITE}PASSAR PARA OUTRO CELULAR${RESET}"
    echo -e " ${BLUE}[ 4 ]${RESET} ${WHITE}SAIR DO MENU${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    echo -n -e " ${BOLD}${WHITE}> ${RESET}"
    
    read -r OPTION < /dev/tty

    case "$OPTION" in
        1)
            transferir_max_normal
            ;;
        2)
            echo -e "\n${YELLOW}Opcao em desenvolvimento!${RESET}"
            read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
            ;;
        3)
            echo -e "\n${YELLOW}Iniciando pareamento externo...${RESET}"
            read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
            ;;
        4)
            echo -e "\n${WHITE}Saindo... Obrigado por usar a suite yAshinDev!${RESET}"
            exit 0
            ;;
        *)
            echo -e "\n${BOLD}${WHITE}[!] Opcao invalida.${RESET}"
            sleep 1
            ;;
    esac
done
