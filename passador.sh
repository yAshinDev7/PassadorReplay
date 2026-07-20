#!/data/data/com.termux/files/usr/bin/bash

# --- 1. GARANTE PERMISSÃO DE ROOT NO CELULAR PRINCIPAL ---
if [ "$(id -u)" -ne 0 ]; then
    exec su -c "bash $0 $@"
fi

# --- PALETA DE CORES ---
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
WHITE="\033[1;37m"
GRAY="\033[1;30m"

ADB_BIN="/data/data/com.termux/files/usr/bin/adb"

# --- LOCAIS DE BUSCA DE REPLAYS COM ROOT ---
LOCAIS_BUSCA=(
    "/sdcard/Android/data/com.dts.freefiremax/files/MReplays"
    "/sdcard/Android/data/com.dts.freefireth/files/MReplays"
    "/sdcard/Download/MReplays"
    "/storage/emulated/0/Download/MReplays"
)

# --- FUNÇÃO DE EXTRAÇÃO LOCAL ---
extrair_replays_locais() {
    rm -rf ./tmp_replays 2>/dev/null
    mkdir -p ./tmp_replays

    PASTA_ACHADA=""

    for pasta in "${LOCAIS_BUSCA[@]}"; do
        if [ -d "$pasta" ]; then
            cp -rf "$pasta"/* ./tmp_replays/ 2>/dev/null
            
            QTD=$(find ./tmp_replays -iname "*.bin" 2>/dev/null | wc -l)
            if [ "$QTD" -gt 0 ]; then
                PASTA_ACHADA="$pasta"
                break
            else
                rm -rf ./tmp_replays/* 2>/dev/null
            fi
        fi
    done

    echo "$PASTA_ACHADA"
}

# --- FUNÇÃO 1: TRANSFERÊNCIA LOCAL (NO PRÓPRIO CELULAR) ---
transferir_local() {
    start_time=$(date +%s)
    SRC="/sdcard/Android/data/com.dts.freefiremax/files/MReplays"
    DST="/sdcard/Android/data/com.dts.freefireth/files/MReplays"
    VER="1.128.2"

    if [ ! -d "$SRC" ]; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Pasta do FF Max nao encontrada."
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    mkdir -p "$DST" 2>/dev/null
    count=$(find "$SRC" -iname "*.bin" 2>/dev/null | wc -l)

    if [ "$count" -gt 0 ]; then
        cp -f "$SRC"/*.bin "$DST/" 2>/dev/null
        cp -f "$SRC"/*.json "$DST/" 2>/dev/null
        for f in "$DST"/*.json; do
            [ -f "$f" ] && sed -i 's/"[Vv]ersion":"[^"]*"/"Version":"'"$VER"'"/' "$f" 2>/dev/null
        done
    else
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Nenhum replay .bin foi encontrado na origem."
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    duration=$(( $(date +%s) - start_time ))
    [ $duration -le 0 ] && duration=1

    BRAND=$(getprop ro.product.brand | tr '[:lower:]' '[:upper:]')
    MODEL=$(getprop ro.product.model)
    ANDROID=$(getprop ro.build.version.release)
    BATT=$(dumpsys battery | grep level | awk '{print $2}')
    FREE_STORAGE=$(df -h /data | awk 'NR==2 {print $4}')
    FREE_RAM=$(cat /proc/meminfo | grep MemAvailable | awk '{printf "%.2f", $2/1024/1024}')
    NOW=$(date +"%d/%m/%Y %H:%M")

    clear
    echo -e " "
    echo -e "      ${BOLD}${WHITE}- REPLAY TOOL (Max -> Normal Local)${RESET}"
    echo -e "${GRAY}--------------------------------------------${RESET}"
    echo -e "  ${BOLD}RESUMO DA OPERACAO${RESET}"
    echo -e " "
    echo -e "  Arquivos encontrados : ${WHITE}$count${RESET}"
    echo -e "  Replays transferidos : ${WHITE}$count${RESET}"
    echo -e "  Tempo de execucao    : ${WHITE}${duration}s${RESET}"
    echo -e "  Data/Hora            : ${WHITE}$NOW${RESET}"
    echo -e "  Status               : ${GREEN}CONCLUIDO${RESET}"
    echo -e " "
    echo -e "${GRAY}--------------------------------------------${RESET}"
    echo -e "  ${BOLD}INFORMACOES DO DISPOSITIVO${RESET}"
    echo -e " "
    echo -e "  Marca   : ${WHITE}$BRAND${RESET}"
    echo -e "  Modelo  : ${WHITE}$MODEL${RESET}"
    echo -e "  Android : ${WHITE}$ANDROID${RESET}"
    echo -e "  Bateria : ${WHITE}${BATT}%${RESET}"
    echo -e "  Espaco  : ${WHITE}${FREE_STORAGE}B livre${RESET}"
    echo -e "  RAM     : ${WHITE}${FREE_RAM}GB livre${RESET}"
    echo -e "${GRAY}--------------------------------------------${RESET}"
    echo -e " "
    echo -e "  ${BOLD}yAshinDev${RESET}"
    echo -e " "
    read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
}

# --- FUNÇÃO 2: TRANSFERÊNCIA VIA ADB PARA O OUTRO CELULAR ---
transferir_para_outro_celular() {
    clear
    echo -e "${BLUE}==============================================${RESET}"
    echo -e "      ${BOLD}${WHITE}ENVIAR REPLAY PARA OUTRO CELULAR (ADB)${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    echo -e "  ${BLUE}[ 1 ]${RESET} ${WHITE}ENVIAR PARA FF NORMAL DELE${RESET}"
    echo -e "  ${BLUE}[ 2 ]${RESET} ${WHITE}ENVIAR PARA FF MAX DELE${RESET}"
    echo -e "  ${BLUE}[ 3 ]${RESET} Voltar ao Menu Principal"
    echo -e "${BLUE}==============================================${RESET}"
    echo -n -e " ${BOLD}${WHITE}> ${RESET}"
    read -r SUB_OPT < /dev/tty

    if [ "$SUB_OPT" -eq 3 ] 2>/dev/null; then return 0; fi

    echo -e "\n${GRAY} -> Buscando replays locais com acesso Root...${RESET}"
    
    PASTA_ORIGEM=$(extrair_replays_locais)
    count=$(find ./tmp_replays -iname "*.bin" 2>/dev/null | wc -l)

    if [ -z "$PASTA_ORIGEM" ] || [ "$count" -eq 0 ]; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Nenhum arquivo .bin foi encontrado em seu celular."
        rm -rf ./tmp_replays
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    echo -e " ${GREEN}[OK] Replays encontrados em:${RESET} $PASTA_ORIGEM"
    echo -e " ${GREEN}[OK] Total de arquivos .bin:${RESET} $count"

    echo -n -e "\n ${BOLD}${YELLOW}Digite o IP e Porta do celular sem root (ex: 192.168.0.5:43511): ${RESET}"
    read -r ALVO_IP < /dev/tty

    if [ -z "$ALVO_IP" ]; then
        echo -e "\n${BOLD}${WHITE}[!] IP invalido.${RESET}"
        rm -rf ./tmp_replays
        sleep 2
        return 1
    fi

    echo -e "\n${GRAY} -> Conectando via ADB sem fio ($ALVO_IP)...${RESET}"
    $ADB_BIN disconnect >/dev/null 2>&1
    $ADB_BIN connect "$ALVO_IP"
    sleep 2

    if ! $ADB_BIN devices | grep -q "$ALVO_IP"; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Nao foi possivel conectar ao celular alvo via ADB."
        echo -e " ${GRAY}Certifique-se de que a Depuracao sem fio / Brevent esta ativa no alvo.${RESET}"
        rm -rf ./tmp_replays
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    start_time=$(date +%s)

    if [ "$SUB_OPT" -eq 1 ]; then
        DST_REMOTA="/sdcard/Android/data/com.dts.freefireth/files/MReplays"
        VER="1.128.2"
        TIPO_OP="Max -> Normal (Celular Secundario)"
    else
        DST_REMOTA="/sdcard/Android/data/com.dts.freefiremax/files/MReplays"
        VER="2.124.15"
        TIPO_OP="Max -> Max (Celular Secundario)"
    fi

    echo -e "${GRAY} -> Atualizando versao nos arquivos JSON...${RESET}"
    for f in ./tmp_replays/*.json ./tmp_replays/*.JSON; do
        if [ -f "$f" ]; then
            sed -i 's/"[Vv]ersion":"[^"]*"/"Version":"'"$VER"'"/' "$f" 2>/dev/null
        fi
    done

    echo -e "${GRAY} -> Enviando arquivos via ADB Push para o destino...${RESET}"
    $ADB_BIN -s "$ALVO_IP" shell "mkdir -p $DST_REMOTA 2>/dev/null"
    $ADB_BIN -s "$ALVO_IP" push ./tmp_replays/. "$DST_REMOTA/" 2>/dev/null

    duration=$(( $(date +%s) - start_time ))
    [ $duration -le 0 ] && duration=1

    BRAND=$($ADB_BIN -s "$ALVO_IP" shell "getprop ro.product.brand" | tr -d '\r' | tr '[:lower:]' '[:upper:]')
    MODEL=$($ADB_BIN -s "$ALVO_IP" shell "getprop ro.product.model" | tr -d '\r')
    ANDROID=$($ADB_BIN -s "$ALVO_IP" shell "getprop ro.build.version.release" | tr -d '\r')
    BATT=$($ADB_BIN -s "$ALVO_IP" shell "dumpsys battery | grep level | awk '{print \$2}'" | tr -d '\r')
    FREE_STORAGE=$($ADB_BIN -s "$ALVO_IP" shell "df -h /data 2>/dev/null | awk 'NR==2 {print \$4}'" | tr -d '\r')
    NOW=$(date +"%d/%m/%Y %H:%M")

    rm -rf ./tmp_replays

    clear
    echo -e " "
    echo -e "      ${BOLD}${WHITE}- REPLAY TOOL ($TIPO_OP)${RESET}"
    echo -e "${GRAY}--------------------------------------------${RESET}"
    echo -e "  ${BOLD}RESUMO DA OPERACAO${RESET}"
    echo -e " "
    echo -e "  Arquivos encontrados : ${WHITE}$count${RESET}"
    echo -e "  Replays transferidos : ${WHITE}$count${RESET}"
    echo -e "  Tempo de execucao    : ${WHITE}${duration}s${RESET}"
    echo -e "  Data/Hora            : ${WHITE}$NOW${RESET}"
    echo -e "  Status               : ${GREEN}CONCLUIDO VIA ADB${RESET}"
    echo -e " "
    echo -e "${GRAY}--------------------------------------------${RESET}"
    echo -e "  ${BOLD}INFORMACOES DO DISPOSITIVO SECUNDARIO${RESET}"
    echo -e " "
    echo -e "  Marca   : ${WHITE}$BRAND${RESET}"
    echo -e "  Modelo  : ${WHITE}$MODEL${RESET}"
    echo -e "  Android : ${WHITE}$ANDROID${RESET}"
    echo -e "  Bateria : ${WHITE}${BATT}%${RESET}"
    echo -e "  Espaco  : ${WHITE}${FREE_STORAGE}B livre${RESET}"
    echo -e "${GRAY}--------------------------------------------${RESET}"
    echo -e " "
    echo -e "  ${BOLD}yAshinDev${RESET}"
    echo -e " "
    
    $ADB_BIN disconnect "$ALVO_IP" >/dev/null 2>&1
    read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
}

# --- FUNÇÃO 3: ABRIR ADB SHELL DO SEGUNDO CELULAR ---
abrir_terminal_remoto() {
    clear
    echo -e "${BLUE}==============================================${RESET}"
    echo -e "        ${BOLD}${WHITE}ACESSAR TERMINAL DO OUTRO CELULAR${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    echo -n -e " ${BOLD}${YELLOW}Digite o IP e Porta do celular secundario: ${RESET}"
    read -r ALVO_IP < /dev/tty

    if [ -z "$ALVO_IP" ]; then
        echo -e "\n${BOLD}${WHITE}[!] IP invalido.${RESET}"
        sleep 2
        return 1
    fi

    echo -e "\n${GRAY} -> Conectando...${RESET}"
    $ADB_BIN disconnect >/dev/null 2>&1
    $ADB_BIN connect "$ALVO_IP"
    sleep 2

    if $ADB_BIN devices | grep -q "$ALVO_IP"; then
        echo -e "\n${GREEN}[OK] Conectado com sucesso! Entrando no ADB Shell...${RESET}"
        echo -e "${GRAY}Digite 'exit' para sair do celular remoto.${RESET}\n"
        $ADB_BIN -s "$ALVO_IP" shell
    else
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Falha ao conectar no dispositivo."
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
    fi
}

# --- LOOP MENU PRINCIPAL ---
while true; do
    clear
    echo -e "${BLUE}==============================================${RESET}"
    echo -e " ${BOLD}${GREEN}PASSADOR DE REPLAY BY yAshinDev${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    echo -e " ${BOLD}${YELLOW}MODO LOCAL:${RESET} ROOT ATIVO"
    echo -e " ${BOLD}${YELLOW}MODO REMOTO:${RESET} ADB WIRELESS / BREVENT"
    echo -e " ${BOLD}${YELLOW}VERSAO ALVO:${RESET} 1.128.2"
    echo -e "${BLUE}==============================================${RESET}"
    echo -e " ${BLUE}[ 1 ]${RESET} ${WHITE}TRANSFERIR LOCAL (Max -> Normal no seu celular)${RESET}"
    echo -e " ${BLUE}[ 2 ]${RESET} ${WHITE}ENVIAR REPLAYS PARA OUTRO CELULAR (Sem Root)${RESET}"
    echo -e " ${BLUE}[ 3 ]${RESET} ${WHITE}ABRIR ADB SHELL DO OUTRO CELULAR${RESET}"
    echo -e " ${BLUE}[ 4 ]${RESET} ${WHITE}SAIR DO MENU${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    echo -n -e " ${BOLD}${WHITE}> ${RESET}"
    
    read -r OPTION < /dev/tty

    case "$OPTION" in
        1) transferir_local ;;
        2) transferir_para_outro_celular ;;
        3) abrir_terminal_remoto ;;
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
