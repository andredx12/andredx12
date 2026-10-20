#Requires -Version 3.0
<#
.SYNOPSIS
    Etapa 1 do estudo de impressao Zebra: levantamento somente leitura para
    identificar o programa de etiquetas, a impressora e a forma de conexao.

.DESCRIPTION
    O script apenas LE informacoes do Windows. Ele nao imprime, nao envia nada
    para a impressora, nao acessa a rede e nao altera nenhuma configuracao.

    Antes de rodar, deixe ABERTO o programa usado para imprimir as etiquetas,
    para que ele apareca na secao "Programas com janela aberta".

    O relatorio fica em um arquivo de texto na pasta do script e abre no Bloco
    de Notas. Revise o arquivo e responda as perguntas da secao 10 antes de
    compartilhar. Por padrao, IPs, nomes de computador, usuario, dominio,
    servidores e numeros de serie saem mascarados.

    O arquivo nao tem acentos de proposito: assim funciona no Windows
    PowerShell 5.1 qualquer que seja a codificacao em que for salvo.

.PARAMETER SemMascara
    Nao mascara IPs, nomes e numeros de serie. Use so para guardar um relatorio
    para voce mesmo; nao compartilhe essa versao.

.PARAMETER TodosOsProgramas
    Lista todos os programas instalados, nao so os ligados a etiquetas.

.PARAMETER Saida
    Caminho do relatorio. Padrao: relatorio-etapa1.txt na pasta do script.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\coletar-etapa1.ps1
#>
[CmdletBinding()]
param(
    [switch]$SemMascara,
    [switch]$TodosOsProgramas,
    [string]$Saida
)

$ErrorActionPreference = 'Stop'

if (-not $Saida) {
    $pasta = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
    $Saida = Join-Path $pasta 'relatorio-etapa1.txt'
}

# Termos que indicam software de etiquetas, marcas de impressoras termicas,
# impressao a partir do navegador, ERPs que costumam imprimir etiquetas e
# acesso remoto (quando o programa roda em outro computador).
$Palavras = @(
    'zebra', 'zdesigner', '\bzpl\b', '\bepl\b', 'link-?os',
    'bartender', 'seagull', 'nicelabel', 'nicewatch', 'loftware',
    'teklynx', 'codesoft', 'labelview', 'label ?matrix',
    'brady', 'wasp', 'golabel', 'godex', 'argox', 'elgin', '\btsc\b', '\bsato\b',
    'datamax', 'honeywell', 'intermec',
    'browser ?print', 'qz ?tray', 'neodynamic', 'jsprintmanager', 'printnode',
    'label', 'etiquet', 'r[o\u00f3]tul',
    'totvs', 'protheus', 'smartclient', '\bsap\b', 'senior', 'sankhya',
    'citrix', 'remoteapp'
)
$Regex = '(?i)' + ($Palavras -join '|')
$RegexZebra = '(?i)zebra|zdesigner|\bztc\b|\bzpl\b|\bepl\b|VID_0A5F'

# ---------------------------------------------------------------------------
# Mascaramento de dados sensiveis
# ---------------------------------------------------------------------------

$Sensiveis = New-Object System.Collections.ArrayList

function AdicionarSensivel([string]$Valor, [string]$Rotulo) {
    # Nomes genericos (ex.: um PC chamado ZEBRA01) ficam visiveis para nao
    # apagar do relatorio justamente as palavras que estamos procurando.
    if ($Valor.Length -ge 3 -and $Valor -notmatch $Regex) {
        [void]$Sensiveis.Add(@($Valor, $Rotulo))
    }
}

AdicionarSensivel $env:USERDNSDOMAIN '<dominio>'
AdicionarSensivel $env:COMPUTERNAME '<computador>'
if ($env:USERDOMAIN -ne $env:COMPUTERNAME) { AdicionarSensivel $env:USERDOMAIN '<dominio>' }
AdicionarSensivel $env:USERNAME '<usuario>'

# Aplicada ao relatorio inteiro: nomes do computador, do usuario e do dominio.
function Ocultar([string]$Texto) {
    if ($SemMascara -or -not $Texto) { return $Texto }
    $t = $Texto -replace '(?i)(\\Users\\)(?!(?:Public|Default|All Users)\\)[^\\\r\n]+', '$1<usuario>'
    foreach ($par in $Sensiveis) {
        $t = $t -replace ('(?i)(?<!\w)' + [regex]::Escape($par[0]) + '(?!\w)'), $par[1]
    }
    return $t
}

# Aplicada so a campos de rede: num texto qualquer, a regra de IP tambem
# apagaria numeros de versao como 5.1.16.7417.
function OcultarRede([string]$Texto) {
    if ($SemMascara -or -not $Texto) { return $Texto }
    $t = $Texto -replace '(?<!\d)(?:\d{1,3}\.){3}\d{1,3}(?!\d)', '<IP>'
    return ($t -replace '^\\\\[^\\]+', '\\<servidor>')
}

function OcultarEndereco([string]$Endereco) {
    if ($SemMascara -or -not $Endereco) { return $Endereco }
    if ($Endereco -match '^(?:\d{1,3}\.){3}\d{1,3}$') { return '<IP>' }
    return '<host>'
}

# Em IDs de dispositivo USB, a ultima parte costuma ser o numero de serie.
function OcultarId([string]$Id) {
    if ($SemMascara -or -not $Id) { return $Id }
    return ($Id -replace '\\[^\\]+$', '\<oculto>')
}

# ---------------------------------------------------------------------------
# Utilitarios
# ---------------------------------------------------------------------------

# Algumas propriedades de processos falham sem permissao de administrador.
function Valor($Objeto, [string]$Propriedade) {
    try { return $Objeto.$Propriedade } catch { return $null }
}

function SimNao($Condicao) {
    if ($Condicao) { 'sim' } else { 'nao' }
}

function VersaoDriver($Numero) {
    # Get-PrinterDriver devolve a versao como um numero de 64 bits,
    # com 16 bits para cada parte de a.b.c.d.
    try {
        $n = [uint64]$Numero
        if ($n -eq 0) { return $null }
        return '{0}.{1}.{2}.{3}' -f (($n -shr 48) -band 0xFFFF), (($n -shr 32) -band 0xFFFF),
            (($n -shr 16) -band 0xFFFF), ($n -band 0xFFFF)
    } catch {
        return [string]$Numero
    }
}

$PortasRede = @{}
$Impressoras = @()

function NomePorta([string]$Porta) {
    if ($SemMascara) { return $Porta }
    $tcp = $PortasRede[$Porta]
    if ($tcp -and $tcp.HostAddress) {
        $Porta = $Porta.Replace([string]$tcp.HostAddress, (OcultarEndereco $tcp.HostAddress))
    }
    return OcultarRede $Porta
}

# Deduz o tipo de conexao pelo nome da porta. E um indicio, nao uma prova.
function ConexaoProvavel($Impressora) {
    $nome = [string]$Impressora.Name
    $porta = [string]$Impressora.PortName
    if ($nome.StartsWith('\\') -or $porta.StartsWith('\\')) { return 'compartilhada por outro computador ou servidor' }
    if ($nome -match 'redirec|in session \d+' -or $porta -match '^TS\d+') { return 'redirecionada de uma sessao remota (RDP/Citrix)' }
    if ($PortasRede.ContainsKey($porta)) { return 'rede TCP/IP' }
    if ($porta -match '^USB\d+') { return 'USB' }
    if ($porta -match '^COM\d+') { return 'serial (COM)' }
    if ($porta -match '^LPT\d+') { return 'paralela (LPT)' }
    if ($porta -match '^WSD') { return 'rede (WSD)' }
    if ($porta -match '^(FILE|PORTPROMPT|nul|SHRFAX)') { return 'virtual (arquivo, PDF ou fax)' }
    return 'nao identificada pela porta'
}

# ---------------------------------------------------------------------------
# Montagem do relatorio
# ---------------------------------------------------------------------------

$Relatorio = New-Object System.Collections.Generic.List[string]

function Escrever([string]$Linha = '') { $Relatorio.Add($Linha) }

function Titulo([string]$Texto) {
    Escrever
    Escrever ('=' * 72)
    Escrever $Texto
    Escrever ('=' * 72)
}

# Cada secao roda isolada: se uma falhar, o erro vai para o relatorio e as
# outras continuam.
function Secao([string]$Texto, [scriptblock]$Coleta) {
    Write-Host "Coletando: $Texto"
    Titulo $Texto
    try {
        $itens = @(& $Coleta)
        if ($itens.Count -eq 0) { Escrever '(nada encontrado)' }
        foreach ($item in $itens) {
            if ($item -is [string]) {
                Escrever $item
            } else {
                Escrever (($item | Format-List | Out-String -Width 4096).Trim())
                Escrever
            }
        }
    } catch {
        Escrever ('(nao foi possivel coletar: ' + $_.Exception.Message + ')')
    }
}

$ehAdmin = $false
try {
    $identidade = [Security.Principal.WindowsIdentity]::GetCurrent()
    $ehAdmin = ([Security.Principal.WindowsPrincipal]$identidade).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
} catch { }

Escrever 'ESTUDO DE IMPRESSAO ZEBRA - ETAPA 1 (IDENTIFICACAO)'
Escrever ('Gerado em: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm'))
Escrever ('Mascara de dados: ' + $(if ($SemMascara) { 'DESATIVADA - nao compartilhe este arquivo' } else { 'ativada' }))
Escrever ('Rodou como administrador (elevado): ' + (SimNao $ehAdmin))
Escrever ('PowerShell: ' + $PSVersionTable.PSVersion)
Escrever
Escrever 'Este relatorio contem evidencias, nao conclusoes.'
Escrever 'Revise tudo antes de compartilhar e oculte o que for confidencial.'

Secao '1. Sistema operacional e sessao (D1)' {
    $so = Get-CimInstance Win32_OperatingSystem
    $pc = Get-CimInstance Win32_ComputerSystem
    [pscustomobject]@{
        Sistema          = $so.Caption
        Versao           = $so.Version
        Arquitetura      = $so.OSArchitecture
        Fabricante_do_PC = $pc.Manufacturer
        Modelo_do_PC     = $pc.Model
        Sessao           = $env:SESSIONNAME
    }
    'Obs.: Sessao "Console" = uso local; "RDP-Tcp#..." ou "ICA-..." = sessao remota.'
}

$chavesDesinstalacao = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$tituloProgramas = if ($TodosOsProgramas) {
    '2. Todos os programas instalados (A1, A2, A3)'
} else {
    '2. Programas instalados ligados a etiquetas, impressao, ERP ou acesso remoto (A1, A2, A3)'
}

Secao $tituloProgramas {
    # Le o registro em vez de usar Win32_Product: consultar Win32_Product faz
    # o Windows verificar (e as vezes reparar) cada programa MSI instalado.
    Get-ItemProperty -Path $chavesDesinstalacao -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -and ($TodosOsProgramas -or "$($_.DisplayName) $($_.Publisher)" -match $Regex) } |
        Sort-Object DisplayName, DisplayVersion -Unique |
        ForEach-Object {
            [pscustomobject]@{
                Programa     = $_.DisplayName
                Versao       = $_.DisplayVersion
                Fabricante   = $_.Publisher
                Instalado_em = $_.InstallDate
                Pasta        = $_.InstallLocation
            }
        }
}

Secao '3. Programas com janela aberta agora (A1, A4)' {
    'Obs.: o programa de etiquetas so aparece aqui se estava aberto.'
    ''
    Get-Process |
        Where-Object { $_.MainWindowHandle -ne 0 -and $_.Id -ne $PID } |
        Sort-Object ProcessName |
        ForEach-Object {
            [pscustomobject]@{
                Processo   = $_.ProcessName
                Descricao  = Valor $_ 'Description'
                Produto    = Valor $_ 'Product'
                Fabricante = Valor $_ 'Company'
                Versao     = Valor $_ 'ProductVersion'
                Caminho    = Valor $_ 'Path'
            }
        }
}

Secao '4. Processos relacionados rodando em segundo plano (A4)' {
    Get-CimInstance Win32_Process |
        Where-Object { "$($_.Name) $($_.ExecutablePath)" -match $Regex } |
        Sort-Object Name, ExecutablePath -Unique |
        ForEach-Object {
            [pscustomobject]@{
                Processo = $_.Name
                Caminho  = $_.ExecutablePath
            }
        }
}

Secao '5. Servicos do Windows relacionados e spooler de impressao (A4)' {
    Get-CimInstance Win32_Service |
        Where-Object { $_.Name -eq 'Spooler' -or "$($_.Name) $($_.DisplayName) $($_.PathName)" -match $Regex } |
        Sort-Object DisplayName |
        ForEach-Object {
            [pscustomobject]@{
                Servico    = $_.DisplayName
                Nome       = $_.Name
                Estado     = $_.State
                Inicio     = $_.StartMode
                Executavel = $_.PathName
            }
        }
}

Secao '6. Impressoras instaladas (B1, C1, C2)' {
    try {
        foreach ($p in @(Get-CimInstance Win32_TCPIPPrinterPort)) { $script:PortasRede[$p.Name] = $p }
    } catch { }
    $script:Impressoras = @(Get-CimInstance Win32_Printer)
    $script:Impressoras |
        ForEach-Object {
            [pscustomobject]@{
                Impressora       = OcultarRede $_.Name
                Parece_Zebra     = SimNao ("$($_.Name) $($_.DriverName) $($_.PNPDeviceID)" -match $RegexZebra)
                Driver           = $_.DriverName
                Porta            = NomePorta $_.PortName
                Conexao_provavel = ConexaoProvavel $_
                Resolucao_driver = $(if ($_.HorizontalResolution) { '{0} x {1} dpi' -f $_.HorizontalResolution, $_.VerticalResolution })
                Padrao           = SimNao $_.Default
                Compartilhada    = $(if ($_.Shared) { 'sim (' + $_.ShareName + ')' } else { 'nao' })
            }
        } |
        Sort-Object @{ Expression = 'Parece_Zebra'; Descending = $true }, Impressora
}

Secao '7. Portas de rede usadas pelas impressoras (C1)' {
    $usadas = @($Impressoras | ForEach-Object { [string]$_.PortName })
    $PortasRede.Values |
        Where-Object { $usadas -contains $_.Name } |
        ForEach-Object {
            $p = $_
            [pscustomobject]@{
                Porta     = NomePorta $p.Name
                Endereco  = OcultarEndereco $p.HostAddress
                Porta_TCP = $p.PortNumber
                Protocolo = $(switch ($p.Protocol) { 1 { 'RAW' } 2 { 'LPR' } default { $p.Protocol } })
                Fila_LPR  = $p.Queue
                SNMP      = SimNao $p.SNMPEnabled
                Usada_por = (@($Impressoras | Where-Object { $_.PortName -eq $p.Name } | ForEach-Object { OcultarRede $_.Name }) -join ', ')
            }
        }
}

Secao '8. Drivers das impressoras (C2)' {
    $usados = @($Impressoras | ForEach-Object { [string]$_.DriverName } | Sort-Object -Unique)
    if (Get-Command Get-PrinterDriver -ErrorAction SilentlyContinue) {
        Get-PrinterDriver |
            Where-Object { $usados -contains $_.Name } |
            ForEach-Object {
                [pscustomobject]@{
                    Driver        = $_.Name
                    Fabricante    = $_.Manufacturer
                    Versao        = VersaoDriver $_.DriverVersion
                    Modelo_driver = 'v' + $_.MajorVersion
                    Ambiente      = $_.PrinterEnvironment
                    Arquivo_INF   = $(if ($_.InfPath) { Split-Path $_.InfPath -Leaf })
                }
            }
    } else {
        # Windows sem o modulo PrintManagement: o WMI traz menos detalhes.
        Get-CimInstance Win32_PrinterDriver |
            ForEach-Object {
                $partes = ([string]$_.Name).Split(',')
                if ($usados -contains $partes[0]) {
                    [pscustomobject]@{
                        Driver        = $partes[0]
                        Modelo_driver = 'v' + $partes[1]
                        Site          = $_.OEMUrl
                    }
                }
            }
    }
}

Secao '9. Dispositivos Zebra conectados por USB (B1, C1)' {
    # 0A5F e o codigo de fabricante USB (Vendor ID) da Zebra.
    Get-CimInstance Win32_PnPEntity -Filter "DeviceID LIKE '%VID_0A5F%' OR Name LIKE '%Zebra%' OR Name LIKE '%ZDesigner%'" |
        ForEach-Object {
            [pscustomobject]@{
                Dispositivo = $_.Name
                Classe      = $_.PNPClass
                Status      = $_.Status
                ID          = OcultarId $_.DeviceID
            }
        }
}

Titulo '10. Perguntas que so voce consegue responder (preencha antes de enviar)'
$perguntas = @(
    'A1. O programa de etiquetas estava aberto quando o script rodou? Qual o nome que aparece na janela dele?',
    'A4. Voce imprime direto nesse programa ou a partir de outro sistema (ERP, sistema da producao, planilha)?',
    'A5. Precisa fazer login para usar o programa? (nao escreva usuario nem senha)',
    'B1. Modelo escrito na etiqueta da impressora (ex.: ZT230, ZD220). Nao precisa do numero de serie.',
    'B2. Quantas impressoras e quantos computadores imprimem etiquetas?',
    'B3. Existe um rolo de fita (ribbon) alem do rolo de etiquetas? (sim / nao)',
    'C1. Que cabo sai da impressora: USB, rede, serial ou nenhum (Wi-Fi)?',
    'D2. Este computador serve so para imprimir etiquetas ou tambem para outras tarefas?',
    'D3. Voce tem permissao de administrador neste computador? (sim / nao / nao sei)',
    'E1. Para que servem as etiquetas (produto, lote, expedicao...) e qual o tamanho aproximado (ex.: 100 x 50 mm)?',
    'E2. O que aparece na etiqueta: textos, codigo de barras (qual tipo?), QR Code, logotipo, data, numero sequencial?',
    'E3. Quais campos voce digita e quais ja aparecem preenchidos ou sao escolhidos em uma lista?',
    'E4. Existem varios modelos de etiqueta? Quem cria ou altera os modelos?',
    'E5. Como se escolhe a quantidade? Da para reimprimir uma etiqueta antiga? O numero sequencial continua ou repete?',
    'E6. Quantas etiquetas sao impressas por dia, mais ou menos?'
)
foreach ($pergunta in $perguntas) {
    Escrever
    Escrever $pergunta
    Escrever 'Resposta: '
}
Escrever
Escrever 'Se puder, envie tambem prints da tela principal, da tela de preenchimento'
Escrever 'e da janela Ajuda > Sobre, com os dados confidenciais ocultos.'

$texto = Ocultar ($Relatorio -join [Environment]::NewLine)
Set-Content -Path $Saida -Value $texto -Encoding UTF8

Write-Host ''
Write-Host "Relatorio salvo em: $Saida"
Write-Host 'Revise o arquivo, responda a secao 10 e envie o conteudo no chat.'
try { Start-Process notepad.exe -ArgumentList ('"' + $Saida + '"') } catch { }
