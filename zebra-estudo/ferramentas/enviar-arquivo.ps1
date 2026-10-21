#Requires -Version 3.0
<#
.SYNOPSIS
    Envia um arquivo (por exemplo, ZPL) para uma impressora pela porta RAW 9100.

.DESCRIPTION
    E exatamente o que acontece numa impressao RAW pela rede: abrir uma conexao
    TCP, mandar os bytes e fechar.

    Por seguranca, so envia para este computador (a impressora virtual), a menos
    que voce use -PermitirRede. Use -PermitirRede apenas com uma impressora de
    TESTE e com autorizacao: alem de gastar etiquetas, alguns arquivos mudam a
    configuracao da impressora (^JUS) ou gravam coisas na memoria dela (^DF,
    ~DG). Rode o analisar-captura.ps1 no arquivo antes de enviar.

.PARAMETER Arquivo
    Arquivo a enviar.

.PARAMETER Destino
    Endereco da impressora. Padrao: 127.0.0.1 (impressora virtual).

.PARAMETER Porta
    Porta TCP. Padrao: 9100.

.PARAMETER PermitirRede
    Libera destinos fora deste computador. Pede confirmacao antes de enviar.

.EXAMPLE
    .\enviar-arquivo.ps1 -Arquivo ..\laboratorio\exemplos\01-etiqueta-simples.zpl
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)][string]$Arquivo,
    [string]$Destino = '127.0.0.1',
    [ValidateRange(1, 65535)][int]$Porta = 9100,
    [switch]$PermitirRede
)

$ErrorActionPreference = 'Stop'

$ip = $null
$local = ($Destino -eq 'localhost') -or
    ([System.Net.IPAddress]::TryParse($Destino, [ref]$ip) -and [System.Net.IPAddress]::IsLoopback($ip))
if (-not $local) {
    if (-not $PermitirRede) {
        throw "O destino $Destino fica fora deste computador. Use -PermitirRede somente para uma impressora de TESTE, com autorizacao."
    }
    if (-not $PSCmdlet.ShouldProcess("${Destino}:$Porta", 'Enviar arquivo para uma impressora real')) { return }
}

$dados = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Arquivo).Path)
$cliente = New-Object System.Net.Sockets.TcpClient
try {
    $cliente.Connect($Destino, $Porta)
    $fluxo = $cliente.GetStream()
    $fluxo.Write($dados, 0, $dados.Length)
    $fluxo.Flush()
} finally {
    $cliente.Close()
}
Write-Host ('{0} bytes enviados para {1}:{2}' -f $dados.Length, $Destino, $Porta)
