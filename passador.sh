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
ADB_DEVICE=""

clear

# --- FUNÇÃO 1: VERIFICAÇÃO E CONEXÃO DO ADB LOCAL ---
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

# --- FUNÇÃO 2: TRANSFERÊNCIA LOCAL (MAX -> NORMAL NO MESMO APARELHO) ---
transferir_max_normal() {
    echo -e "\n${GRAY} -> Transferindo arquivos...${RESET}"
    
    CMD_VERIFICA="[ -d /storage/emulated/0/Android/data/com.dts.freefiremax/files/MReplays ] && echo 'OK' || echo 'ERRO'"
    
    CHECK_PASTA=$($ADB_BIN shell "$CMD_VERIFICA" | tr -d '\r')
    if [ "$CHECK_PASTA" != "OK" ]; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Pasta do Free Fire Max nao encontrada."
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    $ADB_BIN shell "mkdir -p /storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays 2>/dev/null"
    $ADB_BIN shell "cp -f /storage/emulated/0/Android/data/com.dts.freefiremax/files/MReplays/*.bin /storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays/ 2>/dev/null"
    $ADB_BIN shell "cp -f /storage/emulated/0/Android/data/com.dts.freefiremax/files/MReplays/*.json /storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays/ 2>/dev/null"
    
    $ADB_BIN shell "for f in /storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays/*.json; do if [ -f \"\$f\" ]; then sed 's/\"[Vv]ersion\":\"[^\"]*\"/\"Version\":\"1.123.15\"/' \"\$f\" > \"\$f.tmp\" && mv -f \"\$f.tmp\" \"\$f\"; fi; done 2>/dev/null"

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

# --- FUNÇÃO 3: TRANSFERÊNCIA EXTERNA (CELULAR PARA OUTRO CELULAR) ---
transferir_para_outro_celular() {
    clear
    echo -e "${BLUE}==============================================${RESET}"
    echo -e "      ${BOLD}${WHITE}ENVIAR REPLAY PARA OUTRO CELULAR${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    echo -e "  ${BLUE}[ 1 ]${RESET} ${WHITE}SEU FF MAX PARA FF NORMAL DELE${RESET}"
    echo -e "  ${BLUE}[ 2 ]${RESET} ${WHITE}SEU FF NORMAL PARA FF MAX DELE${RESET}"
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

    # Garante a identificacao do celular principal
    LOCAL_DEV=$($ADB_BIN devices | grep -v "List" | grep "device" | head -n 1 | awk '{print $1}')
    if [ -z "$LOCAL_DEV" ]; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Celular principal desconectado do ADB."
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    echo -n -e "\n ${BOLD}${YELLOW}Digite o IP e Porta do celular que vai RECEBER (ex: 192.168.0.5:43511): ${RESET}"
    read -r ALVO_IP < /dev/tty

    if [ -z "$ALVO_IP" ]; then
        echo -e "\n${BOLD}${WHITE}[!] IP invalido.${RESET}"
        sleep 2
        return 1
    fi

    echo -e "\n${GRAY} -> Emparelhando com o celular alvo...${RESET}"
    $ADB_BIN connect "$ALVO_IP"
    sleep 2

    if ! $ADB_BIN devices | grep -q "$ALVO_IP"; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Nao foi possivel conectar ao celular alvo. Verifique o ADB sem fio dele.${RESET}"
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    if [ "$SUB_OPT" -eq 1 ]; then
        PASTA_LOCAL="/storage/emulated/0/Android/data/com.dts.freefiremax/files/MReplays"
        PASTA_REMOTA="/storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays"
        VERSAO_ALVO="1.123.15"
        TIPO_OP="Seu Max -> Normal Dele"
    else
        PASTA_LOCAL="/storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays"
        PASTA_REMOTA="/storage/emulated/0/Android/data/com.dts.freefiremax/files/MReplays"
        VERSAO_ALVO="2.124.15"
        TIPO_OP="Seu Normal -> Max Dele"
    fi

    echo -e "${GRAY} -> Puxando replays direto da pasta do jogo...${RESET}"
    
    mkdir -p ./tmp_replays 2>/dev/null
    rm -rf ./tmp_replays/* 2>/dev/null

    # Lista os arquivos direto da pasta do jogo no celular principal
    ARQUIVOS=$($ADB_BIN -s "$LOCAL_DEV" shell "ls $PASTA_LOCAL" 2>/dev/null | tr -d '\r')

    if [ -z "$ARQUIVOS" ]; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Nenhum arquivo encontrado direto na pasta do Free Fire."
        echo -e " ${GRAY}Caminho verificado: $PASTA_LOCAL${RESET}"
        rm -rf ./tmp_replays
        $ADB_BIN disconnect "$ALVO_IP" >/dev/null 2>&1
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    # Puxa arquivo por arquivo direto da pasta do jogo usando o ADB do celular local
    for arquivo in $ARQUIVOS; do
        if [[ "$arquivo" == *".bin"* || "$arquivo" == *".BIN"* || "$arquivo" == *".json"* || "$arquivo" == *".JSON"* ]]; then
            $ADB_BIN -s "$LOCAL_DEV" pull "$PASTA_LOCAL/$arquivo" "./tmp_replays/$arquivo" >/dev/null 2>&1
        fi
    done

    # Busca no Termux ignorando maiusculas/minusculas
    COUNT=$(find ./tmp_replays -iname "*.bin" 2>/dev/null | wc -l)

    if [ "$COUNT" -eq 0 ]; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Falha ao transferir arquivos da pasta original para o Termux."
        rm -rf ./tmp_replays
        $ADB_BIN disconnect "$ALVO_IP" >/dev/null 2>&1
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    echo -e "${GRAY} -> Modificando compatibilidade de versao...${RESET}"
    for f in ./tmp_replays/*.json; do
        if [ -f "$f" ]; then
            sed -i 's/"[Vv]ersion":"[^"]*"/"Version":"'"$VERSAO_ALVO"'"/' "$f" 2>/dev/null
        fi
    done

    echo -e "${GRAY} -> Enviando arquivos para o celular alvo...${RESET}"
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

# --- 4. VALIDAÇÃO INICIAL DO ADB (Abre direto aqui) ---
conectar_adb

# --- 5. LOOP DO MENU PRINCIPAL ---
while true; do
    if ! $ADB_BIN devices | grep -v "List of devices" | grep -q "device"; then
        echo -e "\n${BOLD}${WHITE}[!] Conexao ADB local perdida! Reestabelecendo...${RESET}"
        sleep 1
        conectar_adb
    fi

    clear
    echo -e "${BLUE}==============================================${RESET}"
    echo -e " ${BOLD}${GREEN}PASSADOR DE REPLAY BY yAshinDev${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    echo -e " ${BOLD}${YELLOW}DISPOSITIVO LOCAL CONECTADO${RESET}"
    echo -e " device:${WHITE}${ADB_DEVICE}${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    echo -e " ${BOLD}${YELLOW}VERSÃO FF MAX:${RESET} 2.124.15"
    echo -e " ${BOLD}${YELLOW}VERSÃO FF:${RESET} 1.123.15"
    echo -e "${BLUE}==============================================${RESET}"
    echo -e " ${BLUE}[ 1 ]${RESET} ${WHITE}FREE FIRE MAX PARA NORMAL (Local)${RESET}"
    echo -e " ${BLUE}[ 2 ]${RESET} ${WHITE}FREE FIRE NORMAL PARA MAX (Local)${RESET}"
    echo -e " ${BLUE}[ 3 ]${RESET} ${WHITE}PASSAR PARA OUTRO CELULAR (Rede/Wireless)${RESET}"
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
            transferir_para_outro_celular
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
