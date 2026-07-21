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

MAX_PKG="com.dts.freefiremax"
NORMAL_PKG="com.dts.freefireth"

MAX_PASTA="/storage/emulated/0/Android/data/${MAX_PKG}/files/MReplays"
NORMAL_PASTA="/storage/emulated/0/Android/data/${NORMAL_PKG}/files/MReplays"

# Pasta de estagio usada SOMENTE para enviar a OUTRO celular. Fica na
# memoria compartilhada (nao na area privada do Termux), pois pastas
# dentro de Android/data/<pacote> so sao legiveis por outro app (mesmo
# Termux com adb) se antes forem copiadas para fora dali via root.
STAGE_DIR="/storage/emulated/0/.replaytool_stage"

# Fallback caso a deteccao dinamica de versao falhe por algum motivo
VER_NORMAL_FALLBACK="1.128.2"
VER_MAX_FALLBACK="2.126.1"

clear

# --- FUNCAO: TESTA SE TEMOS ACESSO ROOT REAL ---
tem_root() {
    if command -v su >/dev/null 2>&1; then
        su -c "id" 2>/dev/null | grep -q "uid=0"
        return $?
    fi
    return 1
}

# --- FUNCAO: EXTRAI versionName DE UM TEXTO DE 'dumpsys package' ---
extrair_version_name() {
    grep -m1 "versionName" | tr -d '\r' | sed -n 's/.*versionName=\([^ ]*\).*/\1/p'
}

# --- FUNCAO: DETECTA A VERSAO INSTALADA DE UM PACOTE NESTE APARELHO ---
# Tenta sem root primeiro (dumpsys package costuma ser legivel por
# qualquer app); se vier vazio, tenta de novo via su.
versao_local() {
    local pkg="$1"
    local ver=""

    ver=$(dumpsys package "$pkg" 2>/dev/null | extrair_version_name)

    if [ -z "$ver" ] && tem_root; then
        ver=$(su -c "dumpsys package $pkg" 2>/dev/null | extrair_version_name)
    fi

    echo "$ver"
}

# --- FUNCAO: DETECTA A VERSAO INSTALADA DE UM PACOTE NO CELULAR REMOTO ---
versao_remota() {
    local serial="$1"
    local pkg="$2"
    $ADB_BIN -s "$serial" shell "dumpsys package $pkg" 2>/dev/null | extrair_version_name
}

# --- FUNCAO: DIAGNOSTICO DETALHADO (mostra o que o su realmente ve) ---
diagnosticar_pasta() {
    local caminho="$1"
    echo -e "\n${GRAY}--- DIAGNOSTICO ---${RESET}"

    echo -e "${GRAY}Testando acesso root basico:${RESET}"
    su -c "id" 2>&1

    echo -e "\n${GRAY}Conteudo de: /storage/emulated/0/Android/data/com.dts.freefiremax/files/ ${RESET}"
    su -c "ls -la '/storage/emulated/0/Android/data/com.dts.freefiremax/files/' 2>&1"

    echo -e "\n${GRAY}Conteudo de: $caminho ${RESET}"
    su -c "ls -la '$caminho' 2>&1"

    echo -e "\n${GRAY}Busca recursiva por *.bin dentro da pasta do FF Max: ${RESET}"
    su -c "find '/storage/emulated/0/Android/data/com.dts.freefiremax/files/' -iname '*.bin' 2>&1"

    echo -e "${GRAY}-------------------${RESET}"
}

# --- FUNCAO: COPIA DIRETA VIA ROOT ENTRE DUAS PASTAS DO MESMO APARELHO ---
# Espelha exatamente a logica do script original (cp direto com su),
# sem passar pelo Termux em nenhum momento.
copiar_local_root() {
    local src="$1"
    local dst="$2"

    if ! su -c "[ -d '$src' ] && echo OK" 2>/dev/null | grep -q OK; then
        echo "0"
        return 1
    fi

    su -c "mkdir -p '$dst'" 2>/dev/null
    # busca recursiva, caso os replays estejam em subpastas dentro de MReplays
    su -c "find '$src' -type f -iname '*.bin' -exec cp -f {} '$dst'/ \;" 2>/dev/null
    su -c "find '$src' -type f -iname '*.json' -exec cp -f {} '$dst'/ \;" 2>/dev/null

    su -c "find '$dst' -iname '*.bin' 2>/dev/null | wc -l"
}

# --- FUNCAO: AJUSTA A VERSAO NOS JSONs DE UMA PASTA (VIA ROOT) ---
ajustar_versao_root() {
    local pasta="$1"
    local ver="$2"
    su -c "for f in '$pasta'/*.json; do [ -f \"\$f\" ] && sed -i 's/\"[Vv]ersion\":\"[^\"]*\"/\"Version\":\"$ver\"/' \"\$f\"; done" 2>/dev/null
}

# --- FUNCAO: INFO DO DISPOSITIVO LOCAL (sem adb) ---
info_dispositivo_local() {
    BRAND=$(getprop ro.product.brand 2>/dev/null | tr '[:lower:]' '[:upper:]')
    MODEL=$(getprop ro.product.model 2>/dev/null)
    ANDROID=$(getprop ro.build.version.release 2>/dev/null)
    BATT=$(dumpsys battery 2>/dev/null | grep level | awk '{print $2}')
}

# --- FUNCAO: TRANSFERENCIA LOCAL GENERICA (MAX<->NORMAL, MESMO APARELHO) ---
# direcao: "max_para_normal" ou "normal_para_max"
transferir_local_direcao() {
    local direcao="$1"
    local src dst pkg_dst nome_dst

    if [ "$direcao" = "max_para_normal" ]; then
        src="$MAX_PASTA"
        dst="$NORMAL_PASTA"
        pkg_dst="$NORMAL_PKG"
        nome_dst="FF Normal"
    else
        src="$NORMAL_PASTA"
        dst="$MAX_PASTA"
        pkg_dst="$MAX_PKG"
        nome_dst="FF Max"
    fi

    if ! tem_root; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Acesso root nao detectado neste aparelho."
        echo -e " ${GRAY}Este script precisa de root para ler/escrever nas pastas Android/data.${RESET}"
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    echo -e "\n${GRAY} -> Copiando replays via root...${RESET}"
    COUNT=$(copiar_local_root "$src" "$dst")

    if [ -z "$COUNT" ] || [ "$COUNT" -eq 0 ] 2>/dev/null; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Nenhum arquivo .bin foi encontrado em:"
        echo -e "  ${WHITE}$src${RESET}"
        diagnosticar_pasta "$src"
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    echo -e "${GRAY} -> Detectando versao instalada do $nome_dst...${RESET}"
    VER=$(versao_local "$pkg_dst")
    if [ -z "$VER" ]; then
        if [ "$pkg_dst" = "$NORMAL_PKG" ]; then
            VER="$VER_NORMAL_FALLBACK"
        else
            VER="$VER_MAX_FALLBACK"
        fi
        echo -e "${YELLOW} -> Nao foi possivel detectar automaticamente. Usando versao padrao: $VER${RESET}"
    else
        echo -e "${GREEN} -> Versao detectada: $VER${RESET}"
    fi

    ajustar_versao_root "$dst" "$VER"

    info_dispositivo_local
    NOW=$(date +"%d/%m/%Y %H:%M")

    clear
    echo -e " "
    echo -e "      ${BOLD}${WHITE}- REPLAY TOOL (TRANSFERENCIA LOCAL)${RESET}"
    echo -e "${GRAY}--------------------------------------------${RESET}"
    echo -e "  ${BOLD}RESUMO DA OPERACAO${RESET}"
    echo -e " "
    echo -e "  Origem                : ${WHITE}$src${RESET}"
    echo -e "  Destino               : ${WHITE}$dst${RESET}"
    echo -e "  Replays transferidos  : ${WHITE}$COUNT${RESET}"
    echo -e "  Versao aplicada       : ${WHITE}$VER${RESET}"
    echo -e "  Data/Hora             : ${WHITE}$NOW${RESET}"
    echo -e "  Status                : ${GREEN}CONCLUIDO${RESET}"
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

# --- FUNCAO 1: CONEXAO ADB (usada SOMENTE para enviar a outro celular) ---
conectar_adb_alvo() {
    local alvo="$1"
    $ADB_BIN disconnect "$alvo" >/dev/null 2>&1
    $ADB_BIN connect "$alvo"
    sleep 2
    $ADB_BIN devices | grep -q "$alvo"
}

# --- FUNCAO: PREPARA O STAGE (copia via root para a memoria compartilhada) ---
preparar_stage() {
    local src="$1"

    rm -rf "$STAGE_DIR" 2>/dev/null
    mkdir -p "$STAGE_DIR" 2>/dev/null

    if ! tem_root; then
        echo "0"
        return 1
    fi

    if ! su -c "[ -d '$src' ] && echo OK" 2>/dev/null | grep -q OK; then
        echo "0"
        return 1
    fi

    su -c "find '$src' -type f -iname '*.bin' -exec cp -f {} '$STAGE_DIR'/ \;" 2>/dev/null
    su -c "find '$src' -type f -iname '*.json' -exec cp -f {} '$STAGE_DIR'/ \;" 2>/dev/null
    # garante que o Termux (uid proprio, sem root) consiga ler/mover depois
    su -c "chmod -R 777 '$STAGE_DIR'" 2>/dev/null

    find "$STAGE_DIR" -iname "*.bin" 2>/dev/null | wc -l
}

# --- FUNCAO 3: TRANSFERENCIA EXTERNA (PARA OUTRO CELULAR) ---
transferir_para_outro_celular() {
    clear
    echo -e "${BLUE}==============================================${RESET}"
    echo -e "      ${BOLD}${WHITE}ENVIAR REPLAY PARA OUTRO CELULAR${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    echo -e "  ${BLUE}[ 1 ]${RESET} ${WHITE}ENVIAR MEU FF MAX -> FF NORMAL DELE${RESET}"
    echo -e "  ${BLUE}[ 2 ]${RESET} ${WHITE}ENVIAR MEU FF NORMAL -> FF MAX DELE${RESET}"
    echo -e "  ${BLUE}[ 3 ]${RESET} Voltar ao Menu Principal"
    echo -e "${BLUE}==============================================${RESET}"
    echo -n -e " ${BOLD}${WHITE}> ${RESET}"
    read -r SUB_OPT < /dev/tty

    if [ "$SUB_OPT" = "3" ]; then
        return 0
    fi

    if [ "$SUB_OPT" != "1" ] && [ "$SUB_OPT" != "2" ]; then
        echo -e "\n${BOLD}${WHITE}[!] Opcao invalida.${RESET}"
        sleep 1
        return 1
    fi

    if ! tem_root; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Acesso root nao detectado neste aparelho."
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    if [ "$SUB_OPT" = "1" ]; then
        SRC_LOCAL="$MAX_PASTA"
        PASTA_REMOTA="/storage/emulated/0/Android/data/${NORMAL_PKG}/files/MReplays"
        PKG_REMOTO="$NORMAL_PKG"
        TIPO_OP="Meu Max -> Normal dele"
    else
        SRC_LOCAL="$NORMAL_PASTA"
        PASTA_REMOTA="/storage/emulated/0/Android/data/${MAX_PKG}/files/MReplays"
        PKG_REMOTO="$MAX_PKG"
        TIPO_OP="Meu Normal -> Max dele"
    fi

    echo -e "\n${GRAY} -> Copiando replays via root para a area de envio...${RESET}"
    COUNT=$(preparar_stage "$SRC_LOCAL")

    if [ -z "$COUNT" ] || [ "$COUNT" -eq 0 ] 2>/dev/null; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Nenhum arquivo .bin foi encontrado em:"
        echo -e "  ${WHITE}$SRC_LOCAL${RESET}"
        rm -rf "$STAGE_DIR" 2>/dev/null
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    echo -e " ${GREEN}[OK] Total de arquivos .bin:${RESET} $COUNT"

    echo -n -e "\n ${BOLD}${YELLOW}Digite o IP e Porta do celular que vai RECEBER (ex: 192.168.0.5:43511): ${RESET}"
    read -r ALVO_IP < /dev/tty

    if [ -z "$ALVO_IP" ]; then
        echo -e "\n${BOLD}${WHITE}[!] IP invalido.${RESET}"
        rm -rf "$STAGE_DIR" 2>/dev/null
        sleep 2
        return 1
    fi

    echo -e "\n${GRAY} -> Conectando ao celular alvo ($ALVO_IP)...${RESET}"
    if ! conectar_adb_alvo "$ALVO_IP"; then
        echo -e "\n${BOLD}${WHITE}[!] ERRO:${RESET} Nao foi possivel conectar ao celular alvo via ADB."
        echo -e " ${GRAY}Confira se a depuracao sem fio esta ativa no aparelho dele e se o IP:porta estao corretos.${RESET}"
        rm -rf "$STAGE_DIR" 2>/dev/null
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar..." < /dev/tty
        return 1
    fi

    echo -e "${GRAY} -> Detectando versao do app no celular alvo...${RESET}"
    VER=$(versao_remota "$ALVO_IP" "$PKG_REMOTO")
    if [ -z "$VER" ]; then
        if [ "$PKG_REMOTO" = "$NORMAL_PKG" ]; then
            VER="$VER_NORMAL_FALLBACK"
        else
            VER="$VER_MAX_FALLBACK"
        fi
        echo -e "${YELLOW} -> Nao foi possivel detectar automaticamente. Usando versao padrao: $VER${RESET}"
    else
        echo -e "${GREEN} -> Versao detectada no aparelho alvo: $VER${RESET}"
    fi

    echo -e "${GRAY} -> Ajustando versao dos JSONs...${RESET}"
    for f in "$STAGE_DIR"/*.json "$STAGE_DIR"/*.JSON; do
        if [ -f "$f" ]; then
            sed -i 's/"[Vv]ersion":"[^"]*"/"Version":"'"$VER"'"/' "$f" 2>/dev/null
        fi
    done

    echo -e "${GRAY} -> Enviando arquivos para o celular alvo...${RESET}"
    $ADB_BIN -s "$ALVO_IP" shell "mkdir -p $PASTA_REMOTA 2>/dev/null"
    $ADB_BIN -s "$ALVO_IP" push "$STAGE_DIR"/. "$PASTA_REMOTA/" 2>/dev/null

    BRAND=$($ADB_BIN -s "$ALVO_IP" shell "getprop ro.product.brand" | tr -d '\r' | tr '[:lower:]' '[:upper:]')
    MODEL=$($ADB_BIN -s "$ALVO_IP" shell "getprop ro.product.model" | tr -d '\r')
    ANDROID=$($ADB_BIN -s "$ALVO_IP" shell "getprop ro.build.version.release" | tr -d '\r')
    BATT=$($ADB_BIN -s "$ALVO_IP" shell "dumpsys battery | grep level | awk '{print \$2}'" | tr -d '\r')
    NOW=$(date +"%d/%m/%Y %H:%M")

    rm -rf "$STAGE_DIR" 2>/dev/null

    clear
    echo -e " "
    echo -e "      ${BOLD}${WHITE}- REPLAY INTER-DEVICES ($TIPO_OP)${RESET}"
    echo -e "${GRAY}--------------------------------------------${RESET}"
    echo -e "  ${BOLD}RESUMO DA OPERACAO${RESET}"
    echo -e " "
    echo -e "  Origem dos arquivos : ${WHITE}$SRC_LOCAL${RESET}"
    echo -e "  Replays enviados    : ${WHITE}$COUNT${RESET}"
    echo -e "  Versao aplicada     : ${WHITE}$VER${RESET}"
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
    echo -e " ${BOLD}${YELLOW}LEITURA/ESCRITA LOCAL:${RESET} Via ROOT (sem adb)"
    echo -e " ${BOLD}${YELLOW}ENVIO A OUTRO CELULAR:${RESET} Via ADB (rede)"
    echo -e " ${BOLD}${YELLOW}VERSOES:${RESET} Detectadas automaticamente"
    echo -e "${BLUE}==============================================${RESET}"
    echo -e " ${BLUE}[ 1 ]${RESET} ${WHITE}FF MAX -> FF NORMAL (Local)${RESET}"
    echo -e " ${BLUE}[ 2 ]${RESET} ${WHITE}FF NORMAL -> FF MAX (Local)${RESET}"
    echo -e " ${BLUE}[ 3 ]${RESET} ${WHITE}PASSAR PARA OUTRO CELULAR (Rede/Wireless)${RESET}"
    echo -e " ${BLUE}[ 4 ]${RESET} ${WHITE}SAIR DO MENU${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    echo -n -e " ${BOLD}${WHITE}> ${RESET}"

    read -r OPTION < /dev/tty

    case "$OPTION" in
        1) transferir_local_direcao "max_para_normal" ;;
        2) transferir_local_direcao "normal_para_max" ;;
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
