#Requires -Version 3.0
<#
.SYNOPSIS
    Testa as ferramentas do estudo com dados ficticios.

.DESCRIPTION
    Nao acessa impressoras nem a rede: so a impressora virtual, em uma porta
    deste computador. Rode no seu Windows para confirmar que tudo funciona com o
    PowerShell instalado:

        powershell -NoProfile -ExecutionPolicy Bypass -File .\testar-ferramentas.ps1
#>
$ErrorActionPreference = 'Stop'

$raiz = Split-Path -Parent $PSScriptRoot
$ferramentas = Join-Path $raiz 'ferramentas'
$exemplos = Join-Path (Join-Path $raiz 'laboratorio') 'exemplos'
$analisar = Join-Path $ferramentas 'analisar-captura.ps1'
$virtual = Join-Path $ferramentas 'impressora-virtual.ps1'
$enviar = Join-Path $ferramentas 'enviar-arquivo.ps1'
$etapa1 = Join-Path (Join-Path $raiz 'etapa1') 'coletar-etapa1.ps1'
$ex1 = Join-Path $exemplos '01-etiqueta-simples.zpl'
$ex2 = Join-Path $exemplos '02-modelo-armazenado.zpl'
$ex3 = Join-Path $exemplos '03-imagem-bitmap.zpl'

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('zebra-testes-' + [guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $tmp)
$latin1 = [System.Text.Encoding]::GetEncoding(28591)
$falhas = 0
$total = 0

function Verificar([string]$Nome, [bool]$Condicao) {
    $script:total++
    if ($Condicao) {
        Write-Host "OK     $Nome"
    } else {
        Write-Host "FALHA  $Nome"
        $script:falhas++
    }
}

function Gravar([string]$Nome, [byte[]]$Bytes) {
    $caminho = Join-Path $tmp $Nome
    [System.IO.File]::WriteAllBytes($caminho, $Bytes)
    return $caminho
}

function Analisar([string]$Caminho, [switch]$MostrarDados) {
    return ((& $analisar -Arquivo $Caminho -MostrarDados:$MostrarDados) -join "`n")
}

try {
    Write-Host '--- analisar-captura.ps1'

    $r = Analisar $ex1
    Verificar 'exemplo 1: detecta ZPL' ($r.Contains('Linguagem detectada: ZPL'))
    Verificar 'exemplo 1: tamanho da etiqueta' ($r.Contains('Tamanho: 800 x 400 pontos'))
    Verificar 'exemplo 1: Code 128 com dados mascarados' ($r.Contains('codigo de barras Code 128 | posicao 40,150 | dados <12 digitos>'))
    Verificar 'exemplo 1: QR Code' ($r.Contains('codigo de barras QR Code'))
    Verificar 'exemplo 1: nao mostra os dados' (-not $r.Contains('PRODUTO EXEMPLO'))

    $r = Analisar $ex1 -MostrarDados
    Verificar 'exemplo 1: -MostrarDados mostra texto' ($r.Contains('"PRODUTO EXEMPLO"'))
    Verificar 'exemplo 1: -MostrarDados tira o prefixo do QR Code' ($r.Contains('"LOTE L2026-001"'))

    $r = Analisar $ex2
    Verificar 'exemplo 2: separa modelo gravado de etiqueta' ($r.Contains('1 etiqueta(s), 1 modelo(s) gravado(s)'))
    Verificar 'exemplo 2: identifica o modelo gravado' ($r.Contains('Modelo gravado na impressora: formato 1 (R:<nome>.ZPL)'))
    Verificar 'exemplo 2: indicio de modelo guardado' ($r.Contains('MODELO GUARDADO NA IMPRESSORA'))
    Verificar 'exemplo 2: mascara o nome do modelo' (-not $r.Contains('PRODUTO.ZPL'))

    $r = Analisar $ex3
    Verificar 'exemplo 3: tamanho da imagem' ($r.Contains('imagem (bitmap) | posicao 40,40 | 16 x 16 pontos'))
    Verificar 'exemplo 3: um unico ^GF' ($r.Contains('^GF  x1'))

    # Parecido com o que um driver gera quando transforma a etiqueta em imagem.
    $hex = 'FF' * 400
    $driver = "CT~~CD,~CC^~CT~`r`n^XA~TA000~JSN^LT0^MNW^MTT^PON^PMN^LH0,0^JMA^PR4,4~SD15^JUS^LRN^CI0^XZ`r`n" +
        "^XA`r`n^MMT`r`n^PW80`r`n^LL40`r`n^LS0`r`n^FT0,40^GFA,400,400,10,$hex^FS`r`n^PQ1,0,1,Y^XZ`r`n"
    $r = Analisar (Gravar 'driver.prn' $latin1.GetBytes($driver))
    Verificar 'driver: preambulo CT~~CD,~CC^~CT~ sem avisos' (-not $r.Contains('== Avisos =='))
    Verificar 'driver: formato so de configuracao' ($r.Contains('1 etiqueta(s), 0 modelo(s) gravado(s), 1 so de configuracao'))
    Verificar 'driver: etiqueta como imagem' ($r.Contains('principalmente como IMAGEM'))
    Verificar 'driver: area da imagem' ($r.Contains('Area coberta por imagens (^GF): 100% da etiqueta'))
    Verificar 'driver: avisa que salva configuracao' ($r.Contains('SALVA configuracoes'))
    Verificar 'driver: indicio de ribbon' ($r.Contains('transferencia termica'))

    # Imagem binaria (^GFB) cujos bytes sao justamente ^ e ~.
    $r = Analisar (Gravar 'binario.prn' $latin1.GetBytes('^XA^FO0,0^GFB,4,4,1,^~^~^FS^FO10,10^A0N,20,20^FDabc^FS^XZ'))
    Verificar 'binario: pula os dados pelo tamanho' ($r.Contains('Campos: 2 ('))
    Verificar 'binario: medidas da imagem' ($r.Contains('8 x 4 pontos'))
    Verificar 'binario: nenhum comando falso' (-not $r.Contains('(nao catalogado)'))

    $r = Analisar (Gravar 'til.prn' $latin1.GetBytes('^XA^FO1,1^A0N,20,20^FDa~b^FS^XZ')) -MostrarDados
    Verificar 'dados com ~ ficam inteiros' ($r.Contains('"a~b"'))

    $r = Analisar (Gravar 'cc.prn' $latin1.GetBytes('^XA^CC++FO1,1+FDx+FS+XZ'))
    Verificar 'avisa troca do caractere de comando' ($r.Contains("troca o caractere de comando ^ por '+'"))

    $utf8 = [System.Text.Encoding]::UTF8.GetBytes('^XA^CI28^FO1,1^A0N,20,20^FDCa' + [char]0x00E7 + 'a^FS^XZ')
    $caminhoUtf8 = Gravar 'utf8.prn' $utf8
    Verificar 'UTF-8: conta caracteres, nao bytes' ((Analisar $caminhoUtf8).Contains('<4 caracteres, sem numeros>'))
    Verificar 'UTF-8: mostra acentos' ((Analisar $caminhoUtf8 -MostrarDados).Contains('"Ca' + [char]0x00E7 + 'a"'))

    $epl = "N`r`nq812`r`nQ1218,24`r`nA50,50,0,4,1,1,N,`"SEGREDO`"`r`nB50,100,0,1,2,6,100,B,`"123456`"`r`nP2`r`n"
    $r = Analisar (Gravar 'epl.prn' $latin1.GetBytes($epl))
    Verificar 'EPL: detecta' ($r.Contains('Linguagem detectada: EPL'))
    Verificar 'EPL: largura e quantidade' ($r.Contains('Largura (q): 812 pontos') -and $r.Contains('Quantidade (P): 2'))
    Verificar 'EPL: mascara dados' ($r.Contains('<6 digitos>') -and -not $r.Contains('SEGREDO'))

    $r = Analisar (Gravar 'ps.prn' $latin1.GetBytes("%!PS-Adobe-3.0`n%%EOF`n"))
    Verificar 'PostScript: detecta' ($r.Contains('Linguagem detectada: PostScript'))

    Write-Host '--- impressora-virtual.ps1 e enviar-arquivo.ps1'

    $bloqueado = $false
    try { & $enviar -Arquivo $ex1 -Destino '192.0.2.10' } catch { $bloqueado = $_.Exception.Message -match 'PermitirRede' }
    Verificar 'enviar recusa destino fora deste computador' $bloqueado

    $porta = Get-Random -Minimum 20000 -Maximum 40000
    $pastaCapturas = Join-Path $tmp 'capturas'
    $job = Start-Job -ScriptBlock { param($s, $p, $d) & $s -Porta $p -Pasta $d } -ArgumentList $virtual, $porta, $pastaCapturas
    try {
        $enviado = $false
        for ($t = 0; $t -lt 40 -and -not $enviado; $t++) {
            try { & $enviar -Arquivo $ex1 -Porta $porta; $enviado = $true } catch { Start-Sleep -Milliseconds 500 }
        }
        $capturas = @()
        for ($t = 0; $t -lt 20 -and $capturas.Count -eq 0; $t++) {
            Start-Sleep -Milliseconds 500
            $capturas = @(Get-ChildItem -Path $pastaCapturas -Filter '*.prn' -ErrorAction SilentlyContinue)
        }
        Verificar 'impressora virtual salva o trabalho recebido' ($capturas.Count -eq 1)
        if ($capturas.Count -eq 1) {
            $recebido = [System.BitConverter]::ToString([System.IO.File]::ReadAllBytes($capturas[0].FullName))
            $original = [System.BitConverter]::ToString([System.IO.File]::ReadAllBytes($ex1))
            Verificar 'captura identica ao arquivo enviado' ($recebido -eq $original)
        }
    } finally {
        Stop-Job $job
        Remove-Job $job -Force
    }

    Write-Host '--- coletar-etapa1.ps1 (Windows simulado)'

    $variaveis = 'COMPUTERNAME', 'USERNAME', 'USERDOMAIN', 'USERDNSDOMAIN'
    $originais = @{}
    foreach ($v in $variaveis) { $originais[$v] = [Environment]::GetEnvironmentVariable($v) }
    $relatorio = Join-Path $tmp 'relatorio-etapa1.txt'
    try {
        $env:COMPUTERNAME = 'PC-EXPEDICAO03'
        $env:USERNAME = 'joao.silva'
        $env:USERDOMAIN = 'EMPRESAX'
        $env:USERDNSDOMAIN = 'empresax.local'

        # As funcoes abaixo existem so dentro deste bloco e substituem os
        # comandos do Windows durante a execucao do script da Etapa 1.
        & {
            function Get-CimInstance {
                [CmdletBinding()]
                param([Parameter(Position = 0)][string]$ClassName, [string]$Filter)
                switch ($ClassName) {
                    'Win32_OperatingSystem' { [pscustomobject]@{ Caption = 'Microsoft Windows 10 Pro'; Version = '10.0.19045'; OSArchitecture = '64 bits' } }
                    'Win32_ComputerSystem' { [pscustomobject]@{ Manufacturer = 'Dell Inc.'; Model = 'OptiPlex 3080' } }
                    'Win32_TCPIPPrinterPort' {
                        [pscustomobject]@{ Name = 'IP_192.168.10.50'; HostAddress = '192.168.10.50'; PortNumber = 9100; Protocol = 1; Queue = $null; SNMPEnabled = $true }
                        [pscustomobject]@{ Name = 'zebra-exp.empresax.local'; HostAddress = 'zebra-exp.empresax.local'; PortNumber = 515; Protocol = 2; Queue = 'lp'; SNMPEnabled = $false }
                    }
                    'Win32_Printer' {
                        [pscustomobject]@{ Name = 'ZDesigner ZD220-203dpi ZPL'; DriverName = 'ZDesigner ZD220-203dpi ZPL'; PortName = 'USB001'; HorizontalResolution = 203; VerticalResolution = 203; Default = $true; Shared = $false; ShareName = $null; PNPDeviceID = $null }
                        [pscustomobject]@{ Name = 'Etiquetadora Expedicao'; DriverName = 'ZDesigner ZT230-200dpi ZPL'; PortName = 'IP_192.168.10.50'; HorizontalResolution = 203; VerticalResolution = 203; Default = $false; Shared = $true; ShareName = 'EtqExp'; PNPDeviceID = $null }
                        [pscustomobject]@{ Name = '\\SRV-PRINT01\Etiquetas'; DriverName = 'ZDesigner GC420t (EPL)'; PortName = 'zebra-exp.empresax.local'; HorizontalResolution = $null; VerticalResolution = $null; Default = $false; Shared = $false; ShareName = $null; PNPDeviceID = $null }
                        [pscustomobject]@{ Name = 'ZDesigner ZD220 (redirecionado 2)'; DriverName = 'Remote Desktop Easy Print'; PortName = 'TS001'; HorizontalResolution = $null; VerticalResolution = $null; Default = $false; Shared = $false; ShareName = $null; PNPDeviceID = $null }
                    }
                    'Win32_PnPEntity' { [pscustomobject]@{ Name = 'ZDesigner ZD220-203dpi ZPL'; PNPClass = 'USB'; Status = 'OK'; DeviceID = 'USB\VID_0A5F&PID_0166\D4J213900123' } }
                    'Win32_Process' { [pscustomobject]@{ Name = 'Cmdr.exe'; ExecutablePath = 'C:\Program Files\Seagull\BarTender 2022\Cmdr.exe' } }
                    'Win32_Service' { [pscustomobject]@{ Name = 'Spooler'; DisplayName = 'Spooler de Impressao'; State = 'Running'; StartMode = 'Auto'; PathName = 'C:\Windows\System32\spoolsv.exe' } }
                    default { throw "classe nao simulada: $ClassName" }
                }
            }
            function Get-PrinterDriver {
                [CmdletBinding()] param()
                [pscustomobject]@{ Name = 'ZDesigner ZD220-203dpi ZPL'; Manufacturer = 'ZDesigner'; DriverVersion = (([uint64]5 -shl 48) -bor ([uint64]1 -shl 32) -bor ([uint64]16 -shl 16) -bor [uint64]7417); MajorVersion = 3; PrinterEnvironment = 'Windows x64'; InfPath = 'C:\Windows\System32\DriverStore\FileRepository\zdesigner.inf_amd64\ZDesigner.inf' }
            }
            function Get-ItemProperty {
                [CmdletBinding()] param($Path)
                [pscustomobject]@{ DisplayName = 'BarTender 2022 R6'; DisplayVersion = '11.3.1.205'; Publisher = 'Seagull Scientific'; InstallDate = '20240115'; InstallLocation = 'C:\Program Files\Seagull\BarTender 2022\' }
                [pscustomobject]@{ DisplayName = 'TOTVS SmartClient'; DisplayVersion = '20.3.2'; Publisher = 'TOTVS S.A.'; InstallDate = $null; InstallLocation = 'C:\Users\joao.silva\AppData\Local\TOTVS\' }
                [pscustomobject]@{ DisplayName = 'Google Chrome'; DisplayVersion = '130.0'; Publisher = 'Google LLC'; InstallDate = $null; InstallLocation = $null }
            }
            function Get-Process {
                [CmdletBinding()] param()
                [pscustomobject]@{ ProcessName = 'SistEtq'; Id = 101; MainWindowHandle = [IntPtr]5678; Description = $null; Product = $null; Company = $null; ProductVersion = '1.0.0.0'; Path = 'C:\Users\joao.silva\AppData\Local\SistEtq\SistEtq.exe' }
            }
            function Start-Process { }
            function Write-Host { }
            & $etapa1 -Saida $relatorio
        } | Out-Null
    } finally {
        foreach ($v in $variaveis) { [Environment]::SetEnvironmentVariable($v, $originais[$v]) }
    }
    $conteudo = [System.IO.File]::ReadAllText($relatorio)
    Verificar 'etapa 1: lista programa de etiquetas' ($conteudo.Contains('BarTender 2022 R6'))
    Verificar 'etapa 1: ignora programa sem relacao' (-not $conteudo.Contains('Google Chrome'))
    Verificar 'etapa 1: conexao USB' ($conteudo.Contains('Conexao_provavel : USB'))
    Verificar 'etapa 1: conexao de rede com IP mascarado' ($conteudo.Contains('Porta            : IP_<IP>'))
    Verificar 'etapa 1: impressora compartilhada com servidor mascarado' ($conteudo.Contains('\\<servidor>\Etiquetas'))
    Verificar 'etapa 1: impressora redirecionada' ($conteudo.Contains('redirecionada de uma sessao remota'))
    Verificar 'etapa 1: numero de serie USB mascarado' ($conteudo.Contains('USB\VID_0A5F&PID_0166\<oculto>'))
    Verificar 'etapa 1: versao do driver preservada' ($conteudo.Contains('5.1.16.7417'))
    Verificar 'etapa 1: nenhum dado sensivel vazou' ($conteudo -notmatch '192\.168|joao|PC-EXPEDICAO03|EMPRESAX|empresax|SRV-PRINT01|D4J213900123')
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host ('{0} de {1} verificacoes passaram.' -f ($total - $falhas), $total)
if ($falhas -gt 0) { exit 1 }
