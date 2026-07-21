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

# LISTA DE TODAS AS PASTAS POSSIVEIS DE ORIGEM
LOCAIS_BUSCA=(
    "/storage/emulated/0/Download/MReplays"
    "/sdcard/Download/MReplays"
    "/storage/emulated/0/Android/data/com.dts.freefiremax/files/MReplays"
    "/storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays"
)

clear

# --- FUNCAO: TESTA SE TEMOS ACESSO ROOT REAL ---
tem_root() {
    if command -v su >/dev/null 2>&1; then
        su -c "id" 2>/dev/null | grep -q "uid=0"
        return $?
    fi
    return 1
}

# --- FUNCAO: BUSCA VIA ROOT (su + cp) ---
buscar_via_root() {
    for pasta in "${LOCAIS_BUSCA[@]}"; do
        # -d com su precisa ser testado dentro do su, pois o Termux normal
        # pode nao "ver" a pasta mesmo que ela exista
        if su -c "[ -d '$pasta' ] && echo OK" 2>/dev/null | grep -q OK; then
            su -c "cp -r '$pasta'/* '$PWD/tmp_replays/' " 2>/dev/null
            # ajusta dono/permissao para o Termux conseguir ler/mover os arquivos copiados
            su -c "chmod -R 777 '$PWD/tmp_replays/'" 2>/dev/null

            QTD=$(find ./tmp_replays -iname "*.bin" 2>/dev/null | wc -l)
            if [ "$QTD" -gt 0 ]; then
                echo "$pasta"
                return 0
            else
                rm -rf ./tmp_replays/* 2>/dev/null
            fi
        fi
    done
    echo ""
    return 1
}

# --- FUNCAO PRINCIPAL DE BUSCA: SOMENTE VIA ROOT ---
# A leitura dos replays no aparelho local eh feita exclusivamente com su.
# O adb soh entra depois, para ENVIAR os arquivos ja copiados.
buscar_e_copiar_replays() {
    mkdir -p ./tmp_replays 2>/dev/null
    rm -rf ./tmp_replays/* 2>/dev/null

    if ! tem_root; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Acesso root nao detectado neste aparelho." >&2
        echo -e " ${GRAY}Este script le os replays usando 'su'. Conceda root ao Termux e tente novamente.${RESET}" >&2
        echo ""
        return 1
    fi

    echo -e "${GRAY} -> Buscando replays via root (su)...${RESET}" >&2
    buscar_via_root
}

# --- FUNCAO 1: CONEXAO ADB LOCAL ---
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

# --- FUNCAO 2: TRANSFERENCIA LOCAL (NO MESMO CELULAR) ---
transferir_local() {
    conectar_adb_local
    echo -e "\n${GRAY} -> Buscando replays nas pastas do sistema (via root)...${RESET}"

    LOCAL_DEV=$($ADB_BIN devices | grep -v "List" | grep "device" | head -n 1 | awk '{print $1}')

    ORIGEM=$(buscar_e_copiar_replays)

    if [ -z "$ORIGEM" ]; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Nenhum arquivo .bin foi encontrado nas pastas do sistema."
        echo -e " ${GRAY}Locais verificados:${RESET}"
        for p in "${LOCAIS_BUSCA[@]}"; do
            echo -e "  - $p"
        done
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    PASTA_DESTINO="/storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays"

    echo -e "${GRAY} -> Origem detectada: $ORIGEM${RESET}"
    echo -e "${GRAY} -> Copiando para o FF Normal...${RESET}"

    $ADB_BIN -s "$LOCAL_DEV" shell "mkdir -p $PASTA_DESTINO 2>/dev/null"
    $ADB_BIN -s "$LOCAL_DEV" push ./tmp_replays/. "$PASTA_DESTINO/" 2>/dev/null

    $ADB_BIN -s "$LOCAL_DEV" shell "for f in $PASTA_DESTINO/*.json; do if [ -f \"\$f\" ]; then sed 's/\"[Vv]ersion\":\"[^\"]*\"/\"Version\":\"1.123.15\"/' \"\$f\" > \"\$f.tmp\" && mv -f \"\$f.tmp\" \"\$f\"; fi; done 2>/dev/null"

    COUNT=$(find ./tmp_replays -iname "*.bin" 2>/dev/null | wc -l)
    BRAND=$($ADB_BIN -s "$LOCAL_DEV" shell "getprop ro.product.brand" | tr -d '\r' | tr '[:lower:]' '[:upper:]')
    MODEL=$($ADB_BIN -s "$LOCAL_DEV" shell "getprop ro.product.model" | tr -d '\r')
    ANDROID=$($ADB_BIN -s "$LOCAL_DEV" shell "getprop ro.build.version.release" | tr -d '\r')
    BATT=$($ADB_BIN -s "$LOCAL_DEV" shell "dumpsys battery | grep level | awk '{print \$2}'" | tr -d '\r')
    NOW=$(date +"%d/%m/%Y %H:%M")

    rm -rf ./tmp_replays

    clear
    echo -e " "
    echo -e "      ${BOLD}${WHITE}- REPLAY TOOL (TRANSFERENCIA LOCAL)${RESET}"
    echo -e "${GRAY}--------------------------------------------${RESET}"
    echo -e "  ${BOLD}RESUMO DA OPERACAO${RESET}"
    echo -e " "
    echo -e "  Origem dos arquivos : ${WHITE}$ORIGEM${RESET}"
    echo -e "  Replays encontrados : ${WHITE}$COUNT${RESET}"
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

# --- FUNCAO 3: TRANSFERENCIA EXTERNA (PARA OUTRO CELULAR) ---
transferir_para_outro_celular() {
    clear
    echo -e "${BLUE}==============================================${RESET}"
    echo -e "      ${BOLD}${WHITE}ENVIAR REPLAY PARA OUTRO CELULAR${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    echo -e "  ${BLUE}[ 1 ]${RESET} ${WHITE}ENVIAR PARA FF NORMAL DELE${RESET}"
    echo -e "  ${BLUE}[ 2 ]${RESET} ${WHITE}ENVIAR PARA FF MAX DELE${RESET}"
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

    echo -e "\n${GRAY} -> Escaneando pastas do celular em busca dos replays (via root)...${RESET}"

    # 1. Varre os diretorios via root e copia os replays encontrados para a
    #    memoria do Termux. O adb soh sera usado depois, para ENVIAR.
    ORIGEM_ENCONTRADA=$(buscar_e_copiar_replays)

    COUNT=$(find ./tmp_replays -iname "*.bin" 2>/dev/null | wc -l)

    if [ -z "$ORIGEM_ENCONTRADA" ] || [ "$COUNT" -eq 0 ]; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Nenhum arquivo .bin foi encontrado no seu aparelho."
        echo -e " ${GRAY}Pastas verificadas pelo script:${RESET}"
        for p in "${LOCAIS_BUSCA[@]}"; do
            echo -e "  - $p"
        done
        rm -rf ./tmp_replays
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    echo -e " ${GREEN}[OK] Replays detectados em:${RESET} $ORIGEM_ENCONTRADA"
    echo -e " ${GREEN}[OK] Total de arquivos .bin:${RESET} $COUNT"

    # 2. Pede o IP do celular secundario (sem root - recebe via adb shell,
    #    que tem acesso suficiente para gravar em Android/data)
    echo -n -e "\n ${BOLD}${YELLOW}Digite o IP e Porta do celular que vai RECEBER (ex: 192.168.0.5:43511): ${RESET}"
    read -r ALVO_IP < /dev/tty

    if [ -z "$ALVO_IP" ]; then
        echo -e "\n${BOLD}${WHITE}[!] IP invalido.${RESET}"
        rm -rf ./tmp_replays
        sleep 2
        return 1
    fi

    echo -e "\n${GRAY} -> Conectando ao celular alvo ($ALVO_IP)...${RESET}"
    $ADB_BIN disconnect "$ALVO_IP" >/dev/null 2>&1
    $ADB_BIN connect "$ALVO_IP"
    sleep 2

    if ! $ADB_BIN devices | grep -q "$ALVO_IP"; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Nao foi possivel conectar ao celular alvo via ADB."
        echo -e " ${GRAY}Confira se a depuracao wireless esta ativa no aparelho dele e se o IP:porta estao corretos.${RESET}"
        rm -rf ./tmp_replays
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    if [ "$SUB_OPT" -eq 1 ]; then
        PASTA_REMOTA="/storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays"
        VERSAO_ALVO="1.123.15"
        TIPO_OP="Replays -> Normal Dele"
    else
        PASTA_REMOTA="/storage/emulated/0/Android/data/com.dts.freefiremax/files/MReplays"
        VERSAO_ALVO="2.124.15"
        TIPO_OP="Replays -> Max Dele"
    fi

    echo -e "${GRAY} -> Ajustando versao dos JSONs...${RESET}"
    for f in ./tmp_replays/*.json ./tmp_replays/*.JSON; do
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
    echo -e "  Origem dos arquivos : ${WHITE}$ORIGEM_ENCONTRADA${RESET}"
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
    echo -e " ${BOLD}${YELLOW}MODO DE BUSCA:${RESET} Automatica via ROOT (Downloads / FF / FF Max)"
    echo -e " ${BOLD}${YELLOW}VERSAO FF MAX:${RESET} 2.124.15"
    echo -e " ${BOLD}${YELLOW}VERSAO FF:${RESET} 1.123.15"
    echo -e "${BLUE}==============================================${RESET}"
    echo -e " ${BLUE}[ 1 ]${RESET} ${WHITE}ENVIAR REPLAYS PARA FF NORMAL (Local)${RESET}"
    echo -e " ${BLUE}[ 2 ]${RESET} ${WHITE}ENVIAR REPLAYS PARA FF MAX (Local)${RESET}"
    echo -e " ${BLUE}[ 3 ]${RESET} ${WHITE}PASSAR PARA OUTRO CELULAR (Rede/Wireless)${RESET}"
    echo -e " ${BLUE}[ 4 ]${RESET} ${WHITE}SAIR DO MENU${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    echo -n -e " ${BOLD}${WHITE}> ${RESET}"

    read -r OPTION < /dev/tty

    case "$OPTION" in
        1) transferir_local ;;
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
