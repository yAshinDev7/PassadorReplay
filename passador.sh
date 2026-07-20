#!/data/data/com.termux/files/usr/bin/bash

# --- PALETA DE CORES ---
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
WHITE="\033[1;37m"
GRAY="\033[1;30m"

ADB_BIN="/data/data/com.termux/files/usr/bin/adb"
PASTA_LOCAL="/storage/emulated/0/Download/MReplays"

clear

# --- FUNÇÃO 1: CONEXÃO LOCAL (USADA APENAS SE FOR ENVIAR LOCALMENTE) ---
conectar_adb_local() {
    if $ADB_BIN devices | grep -v "List of devices" | grep -q "device"; then
        return 0
    fi

    while true; do
        clear
        echo -e "${BLUE}==============================================${RESET}"
        echo -e "         ${BOLD}${WHITE}yAshinDev REPLAY TOOL${RESET}"
        echo -e "${BLUE}==============================================${RESET}"
        echo -e " ${BOLD}${YELLOW}[!] NENHUM DISPOSITIVO ADB LOCAL DETECTADO${RESET}"
        echo -e " ${GRAY}Para operacoes locais, conecte o ADB do proprio aparelho.${RESET}"
        echo -e "${BLUE}==============================================${RESET}"
        echo -e " ${WHITE}Escolha uma opcao:${RESET}"
        echo -e "  ${BLUE}[ 1 ]${RESET} Digitar IP:PORTA do celular local"
        echo -e "  ${BLUE}[ 2 ]${RESET} Tentar novamente"
        echo -e "  ${BLUE}[ 3 ]${RESET} Sair"
        echo -e "${BLUE}==============================================${RESET}"
        echo -n -e " ${BOLD}${WHITE}> ${RESET}"
        read -r ADB_OPT < /dev/tty

        case "$ADB_OPT" in
            1)
                echo -n -e "\n ${BOLD}${YELLOW}Digite o IP e Porta local (ex: 127.0.0.1:41081): ${RESET}"
                read -r CONN_STR < /dev/tty
                if [ -n "$CONN_STR" ]; then
                    $ADB_BIN connect "$CONN_STR"
                    sleep 2
                fi
                ;;
            2) sleep 1 ;;
            3) exit 0 ;;
            *) echo -e " Opcao invalida." ; sleep 1 ;;
        esac

        if $ADB_BIN devices | grep -v "List of devices" | grep -q "device"; then
            break
        fi
    done
}

# --- FUNÇÃO 2: TRANSFERÊNCIA LOCAL (MREPLAYS -> FF NORMAL NO MESMO CELULAR) ---
transferir_max_normal() {
    conectar_adb_local
    echo -e "\n${GRAY} -> Transferindo arquivos localmente...${RESET}"
    
    if [ ! -d "$PASTA_LOCAL" ]; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} A pasta $PASTA_LOCAL nao foi encontrada."
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    LOCAL_DEV=$($ADB_BIN devices | grep -v "List" | grep "device" | head -n 1 | awk '{print $1}')

    $ADB_BIN -s "$LOCAL_DEV" shell "mkdir -p /storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays 2>/dev/null"
    $ADB_BIN -s "$LOCAL_DEV" shell "cp -f $PASTA_LOCAL/*.bin $PASTA_LOCAL/*.BIN /storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays/ 2>/dev/null"
    $ADB_BIN -s "$LOCAL_DEV" shell "cp -f $PASTA_LOCAL/*.json $PASTA_LOCAL/*.JSON /storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays/ 2>/dev/null"
    
    $ADB_BIN -s "$LOCAL_DEV" shell "for f in /storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays/*.json; do if [ -f \"\$f\" ]; then sed 's/\"[Vv]ersion\":\"[^\"]*\"/\"Version\":\"1.123.15\"/' \"\$f\" > \"\$f.tmp\" && mv -f \"\$f.tmp\" \"\$f\"; fi; done 2>/dev/null"

    COUNT=$($ADB_BIN -s "$LOCAL_DEV" shell "find /storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays -iname '*.bin' 2>/dev/null | wc -l" | tr -d '\r')
    BRAND=$($ADB_BIN -s "$LOCAL_DEV" shell "getprop ro.product.brand" | tr -d '\r' | tr '[:lower:]' '[:upper:]')
    MODEL=$($ADB_BIN -s "$LOCAL_DEV" shell "getprop ro.product.model" | tr -d '\r')
    ANDROID=$($ADB_BIN -s "$LOCAL_DEV" shell "getprop ro.build.version.release" | tr -d '\r')
    BATT=$($ADB_BIN -s "$LOCAL_DEV" shell "dumpsys battery | grep level | awk '{print \$2}'" | tr -d '\r')
    NOW=$(date +"%d/%m/%Y %H:%M")

    clear
    echo -e " "
    echo -e "      ${BOLD}${WHITE}- REPLAY TOOL (MReplays -> Normal Local)${RESET}"
    echo -e "${GRAY}--------------------------------------------${RESET}"
    echo -e "  ${BOLD}RESUMO DA OPERACAO${RESET}"
    echo -e " "
    echo -e "  Arquivos encontrados : ${WHITE}$COUNT${RESET}"
    echo -e "  Replays transferidos : ${WHITE}$COUNT${RESET}"
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
    echo -e "${GRAY}--------------------------------------------${RESET}"
    echo -e " "
    echo -e "  ${BOLD}yAshinDev${RESET}"
    echo -e " "
    read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
}

# --- FUNÇÃO 3: TRANSFERÊNCIA EXTERNA (CELULAR PARA OUTRO CELULAR) ---
transferir_para_outro_celular() {
    clear
    echo -e "${BLUE}==============================================${RESET}"
    echo -e "      ${BOLD}${WHITE}ENVIAR REPLAY PARA OUTRO CELULAR${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    echo -e "  ${BLUE}[ 1 ]${RESET} ${WHITE}MREPLAYS PARA FF NORMAL DELE${RESET}"
    echo -e "  ${BLUE}[ 2 ]${RESET} ${WHITE}MREPLAYS PARA FF MAX DELE${RESET}"
    echo -e "  ${BLUE}[ 3 ]${RESET} Voltar ao Menu Principal"
    echo -e "${BLUE}==============================================${RESET}"
    echo -n -e " ${BOLD}${WHITE}> ${RESET}"
    read -r SUB_OPT < /dev/tty

    if [ "$SUB_OPT" -eq 3 ] 2>/dev/null; then
        return 0
    fi

    if [ "$SUB_OPT" -ne 1 ] && [ "$SUB_OPT" -ne 2 ]; then
        echo -e "\n${BOLD}${WHITE}[!] Opcao invalida.${RESET}"
        sleep 1
        return 1
    fi

    # 1. Verifica se a pasta existe localmente no Termux
    if [ ! -d "$PASTA_LOCAL" ]; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} A pasta $PASTA_LOCAL nao foi encontrada na memoria do seu celular."
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    # 2. Copia os arquivos da pasta Download/MReplays direto para o ambiente do Termux
    mkdir -p ./tmp_replays 2>/dev/null
    rm -rf ./tmp_replays/* 2>/dev/null
    
    cp -r "$PASTA_LOCAL"/* ./tmp_replays/ 2>/dev/null

    # 3. Conta os arquivos .bin encontrados no Termux
    COUNT=$(find ./tmp_replays -iname "*.bin" 2>/dev/null | wc -l)

    if [ "$COUNT" -eq 0 ]; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Nenhum arquivo .bin foi encontrado em $PASTA_LOCAL."
        echo -e " ${GRAY}Verifique se os arquivos estao realmente salvos dentro de Download/MReplays${RESET}"
        rm -rf ./tmp_replays
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    # 4. Pede o IP do celular secundario
    echo -n -e "\n ${BOLD}${YELLOW}Digite o IP e Porta do celular que vai RECEBER (ex: 192.168.0.5:43511): ${RESET}"
    read -r ALVO_IP < /dev/tty

    if [ -z "$ALVO_IP" ]; then
        echo -e "\n${BOLD}${WHITE}[!] IP invalido.${RESET}"
        rm -rf ./tmp_replays
        sleep 2
        return 1
    fi

    echo -e "\n${GRAY} -> Conectando ao celular alvo ($ALVO_IP)...${RESET}"
    $ADB_BIN disconnect >/dev/null 2>&1
    $ADB_BIN connect "$ALVO_IP"
    sleep 2

    if ! $ADB_BIN devices | grep -q "$ALVO_IP"; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Nao foi possivel conectar ao celular alvo. Verifique o ADB sem fio dele."
        rm -rf ./tmp_replays
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    if [ "$SUB_OPT" -eq 1 ]; then
        PASTA_REMOTA="/storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays"
        VERSAO_ALVO="1.123.15"
        TIPO_OP="MReplays -> Normal Dele"
    else
        PASTA_REMOTA="/storage/emulated/0/Android/data/com.dts.freefiremax/files/MReplays"
        VERSAO_ALVO="2.124.15"
        TIPO_OP="MReplays -> Max Dele"
    fi

    echo -e "${GRAY} -> Alterando versao dos arquivos JSON...${RESET}"
    for f in ./tmp_replays/*.json ./tmp_replays/*.JSON; do
        if [ -f "$f" ]; then
            sed -i 's/"[Vv]ersion":"[^"]*"/"Version":"'"$VERSAO_ALVO"'"/' "$f" 2>/dev/null
        fi
    done

    echo -e "${GRAY} -> Enviando replays para o celular secundario...${RESET}"
    $ADB_BIN -s "$ALVO_IP" shell "mkdir -p $PASTA_REMOTA 2>/dev/null"
    $ADB_BIN -s "$ALVO_IP" push ./tmp_replays/. "$PASTA_REMOTA/" 2>/dev/null

    BRAND=$($ADB_BIN -s "$ALVO_IP" shell "getprop ro.product.brand" | tr -d '\r' | tr '[:lower:]' '[:upper:]')
    MODEL=$($ADB_BIN -s "$ALVO_IP" shell "getprop ro.product.model" | tr -d '\r')
    ANDROID=$($ADB_BIN -s "$ALVO_IP" shell "getprop ro.build.version.release" | tr -d '\r')
    BATT=$($ADB_BIN -s "$ALVO_IP" shell "dumpsys battery | grep level | awk '{print \$2}'" | tr -d '\r')
    NOW=$(date +"%d/%m/%Y %H:%M")

    rm -rf ./tmp_replays

    clear
    echo -e " "
    echo -e "      ${BOLD}${WHITE}- REPLAY INTER-DEVICES ($TIPO_OP)${RESET}"
    echo -e "${GRAY}--------------------------------------------${RESET}"
    echo -e "  ${BOLD}RESUMO DA OPERACAO${RESET}"
    echo -e " "
    echo -e "  Replays encontrados : ${WHITE}$COUNT${RESET}"
    echo -e "  Replays enviados    : ${WHITE}$COUNT${RESET}"
    echo -e "  Celular Destino     : ${WHITE}$ALVO_IP${RESET}"
    echo -e "  Data/Hora           : ${WHITE}$NOW${RESET}"
    echo -e "  Status              : ${GREEN}ENVIADO COM SUCESSO${RESET}"
    echo -e " "
    echo -e "${GRAY}--------------------------------------------${RESET}"
    echo -e "  ${BOLD}INFORMACOES DO CELULAR SECUNDARIO (ALVO)${RESET}"
    echo -e " "
    echo -e "  Marca               : ${WHITE}$BRAND${RESET}"
    echo -e "  Modelo              : ${WHITE}$MODEL${RESET}"
    echo -e "  Versao Android      : ${WHITE}$ANDROID${RESET}"
    echo -e "  Nivel da Bateria    : ${WHITE}${BATT}%${RESET}"
    echo -e "${GRAY}--------------------------------------------${RESET}"
    echo -e " "
    echo -e "  ${BOLD}yAshinDev${RESET}"
    echo -e " "
    
    $ADB_BIN disconnect "$ALVO_IP" >/dev/null 2>&1
    read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
}

# --- LOOP DO MENU PRINCIPAL ---
while true; do
    clear
    echo -e "${BLUE}==============================================${RESET}"
    echo -e " ${BOLD}${GREEN}PASSADOR DE REPLAY BY yAshinDev${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    echo -e " ${BOLD}${YELLOW}ORIGEM FIXA:${RESET} /storage/emulated/0/Download/MReplays"
    echo -e " ${BOLD}${YELLOW}VERSÃO FF MAX:${RESET} 2.124.15"
    echo -e " ${BOLD}${YELLOW}VERSÃO FF:${RESET} 1.123.15"
    echo -e "${BLUE}==============================================${RESET}"
    echo -e " ${BLUE}[ 1 ]${RESET} ${WHITE}MREPLAYS PARA FF NORMAL (Local)${RESET}"
    echo -e " ${BLUE}[ 2 ]${RESET} ${WHITE}MREPLAYS PARA FF MAX (Local)${RESET}"
    echo -e " ${BLUE}[ 3 ]${RESET} ${WHITE}PASSAR PARA OUTRO CELULAR (Rede/Wireless)${RESET}"
    echo -e " ${BLUE}[ 4 ]${RESET} ${WHITE}SAIR DO MENU${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    echo -n -e " ${BOLD}${WHITE}> ${RESET}"
    
    read -r OPTION < /dev/tty

    case "$OPTION" in
        1) transferir_max_normal ;;
        2)
            echo -e "\n${YELLOW}Opcao em desenvolvimento!${RESET}"
            read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
            ;;
        3) transferir_para_outro_celular ;;
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
