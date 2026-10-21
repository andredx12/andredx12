# Glossário

Termos que aparecem no estudo, com exemplos. Quando surgir um termo novo, ele entra aqui.

## Impressão térmica

- **Impressora térmica**: imprime aquecendo pontos minúsculos da cabeça de impressão. As impressoras de etiqueta da Zebra funcionam assim.
- **Térmica direta**: o calor escurece o próprio papel, que é sensível ao calor. Não usa fita. A etiqueta desbota com o tempo, o sol e o calor; é comum em etiquetas de expedição.
- **Transferência térmica**: o calor derrete a tinta de uma fita (ribbon) sobre a etiqueta. Dura mais; é comum na identificação de produtos.
- **Ribbon**: a fita de tinta da transferência térmica. Se há um rolo de ribbon na impressora, ela usa transferência térmica. No ZPL, o comando `^MT` indica o modo: `^MTT` (transferência) ou `^MTD` (direta).
- **Resolução (dpi)**: pontos por polegada. As mais comuns são 203 dpi (8 pontos por mm), 300 dpi (cerca de 12 por mm) e 600 dpi (cerca de 24 por mm).
- **Ponto (dot)**: a menor unidade que a impressora imprime. No ZPL, posições e tamanhos são medidos em pontos. Fórmula: `pontos = mm ÷ 25,4 × dpi`. Exemplo: 100 mm a 203 dpi = 100 ÷ 25,4 × 203 ≈ 800 pontos.
- **Sensor de mídia**: como a impressora acha o começo de cada etiqueta, pelo espaço entre elas (*gap*) ou por uma marca preta no verso. No ZPL, comando `^MN`.

## Linguagens das impressoras

- **ZPL (Zebra Programming Language)**: a linguagem de texto das impressoras Zebra. Cada etiqueta fica entre `^XA` (início) e `^XZ` (fim). Exemplo:

  ```
  ^XA
  ^FO50,50^A0N,40,40^FDOla^FS
  ^XZ
  ```

  `^FO50,50` posiciona o campo, `^A0N,40,40` escolhe a fonte, `^FD` traz os dados e `^FS` fecha o campo.
- **Comandos `^` e `~`**: os que começam com `^` montam a etiqueta (comandos de formato). Os que começam com `~` são comandos de controle, que a impressora executa assim que recebe (ex.: `~HS` pede o status).
- **EPL**: linguagem mais antiga, herdada das impressoras Eltron, escrita em linhas como `A50,50,0,4,1,1,N,"texto"`. Algumas impressoras Zebra aceitam EPL e ZPL.
- **CPCL**: linguagem usada principalmente nas impressoras móveis (portáteis) da Zebra.
- **Campo**: cada elemento da etiqueta: um texto, um código de barras, uma linha ou uma imagem. No ZPL, vai de `^FO` até `^FS`.
- **Imagem `^GF` (bitmap)**: comando que envia uma imagem ponto a ponto. Se a etiqueta inteira chega como um `^GF` grande, o texto virou imagem: a impressora não "sabe" que ali há palavras.
- **Formato armazenado (`^DF` / `^XF`)**: o modelo da etiqueta pode ficar guardado na memória da impressora. `^DF` grava e `^XF` usa; o computador então envia só os valores dos campos (`^FN1`, `^FN2`...).
- **Serialização (`^SN`)**: a própria impressora incrementa um número a cada etiqueta (0001, 0002...).

## Etiquetas e códigos

- **Modelo (template ou layout)**: o desenho da etiqueta, com partes fixas (logotipo, títulos) e campos variáveis (produto, lote, data).
- **Campo fixo e campo variável**: o fixo é igual em toda etiqueta; o variável muda a cada impressão.
- **Simbologia**: o "idioma" de um código de barras. Exemplos: Code 128 (letras e números, muito usado na indústria), EAN-13 (13 dígitos, produtos no varejo), QR Code e Data Matrix (códigos 2D, que guardam mais informação).
- **GS1**: organização que padroniza códigos de produtos e de logística (EAN-13, GS1-128...). Os códigos EAN emitidos pela GS1 Brasil começam com 789 ou 790.

## Windows e impressão

- **Driver de impressora**: software que traduz o que o Windows desenha para a linguagem da impressora (no caso da Zebra, geralmente ZPL).
- **ZDesigner × ZebraDesigner**: *ZDesigner* é o nome dos drivers da Zebra para Windows. *ZebraDesigner* é um programa de criação de etiquetas. Ter o driver ZDesigner instalado não significa usar o programa ZebraDesigner.
- **Drivers v3 e v4**: dois modelos de driver do Windows. O v4 é o mais recente e usa XPS internamente.
- **Spooler (Spooler de Impressão)**: serviço do Windows (`spoolsv.exe`) que recebe os trabalhos e os entrega à impressora, um de cada vez.
- **Fila de impressão**: cada "impressora" que aparece no Windows é, na verdade, uma fila com um nome, um driver e uma porta. Duas filas podem apontar para a mesma impressora física.
- **Trabalho de impressão (job)**: uma impressão enviada para a fila.
- **Arquivos de spool (`.SPL` e `.SHD`)**: arquivos temporários de cada trabalho, em `C:\Windows\System32\spool\PRINTERS`. Normalmente são apagados depois da impressão.
- **Tipo de dados RAW × EMF**: em RAW, os bytes já estão na linguagem da impressora e passam direto. Em EMF, o Windows guarda o desenho e o driver converte depois.
- **Impressão gráfica (GDI)**: o programa desenha a etiqueta como desenharia uma página, e o driver converte. O resultado pode ser ZPL com campos nativos ou uma imagem (`^GF`).
- **Impressão RAW (direta)**: o programa monta o ZPL sozinho e o envia pronto, sem conversão pelo driver.
- **Imprimir para arquivo**: em vez de mandar para a impressora, salva num arquivo (geralmente `.prn`) os bytes que iriam para ela.

## Conexões

- **Porta de impressora**: por onde a fila entrega os bytes: USB, rede, serial ou arquivo.
- **USB001**: porta virtual que o Windows cria quando uma impressora USB é instalada.
- **Porta TCP/IP padrão**: porta de rede do Windows para impressoras com endereço IP.
- **RAW 9100**: o jeito mais comum de imprimir pela rede: abrir uma conexão TCP na porta 9100 e mandar os bytes. Também é chamado de AppSocket ou JetDirect.
- **LPR/LPD (porta 515)**: protocolo de impressão em rede mais antigo, que usa um nome de fila.
- **SNMP**: protocolo que o Windows usa para consultar o status de impressoras de rede (porta UDP 161).
- **WSD**: impressoras de rede que o Windows descobre e instala automaticamente.
- **Impressora compartilhada (`\\servidor\impressora`)**: fila que fica em outro computador; o seu PC manda o trabalho para ele.
- **Sessão remota e impressora redirecionada**: quando o programa roda num servidor (Área de Trabalho Remota/RDP ou Citrix), a impressora local aparece lá como "redirecionada", em portas como `TS001`.
- **Vendor ID (VID) e Product ID (PID)**: códigos que identificam o fabricante e o modelo de um dispositivo USB. O VID da Zebra é `0A5F`.
- **Zebra Browser Print**: aplicativo da Zebra que permite que páginas web imprimam em impressoras Zebra ligadas ao computador.
- **QZ Tray**: aplicativo de outra empresa com a mesma ideia: deixa sistemas web enviarem comandos RAW para impressoras locais.
- **Link-OS e SDKs da Zebra**: Link-OS é a plataforma das impressoras Zebra mais recentes. A Zebra também oferece SDKs (bibliotecas) para programas conversarem com as impressoras.

## Investigação

- **Engenharia reversa caixa-preta**: entender um sistema observando o que entra e o que sai, sem acesso ao código. É o que fazemos aqui, sempre dentro da licença e com autorização.
- **Fato, evidência e hipótese**: fato é o que foi observado; evidência é o registro desse fato (print, relatório, captura); hipótese é uma explicação ainda não confirmada.
- **Captura**: cópia exata dos bytes que um programa enviou para a impressora.
- **Impressora virtual**: programa que finge ser uma impressora para guardar o que recebe, sem imprimir.
- **Produção × teste**: produção é o que a empresa usa de verdade; teste é uma cópia ou um equipamento separado, onde um erro não atrapalha ninguém.
- **Efeito colateral**: algo que muda além do que você queria observar. Exemplo: imprimir "só para arquivo" e o sistema avançar o número de série ou registrar a etiqueta como impressa.
