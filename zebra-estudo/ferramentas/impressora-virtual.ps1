#Requires -Version 3.0
<#
.SYNOPSIS
    Impressora virtual: recebe trabalhos de impressao RAW (porta 9100) e salva
    cada um em arquivo, sem imprimir nada.

.DESCRIPTION
    Finge ser uma impressora de rede. Tudo o que chegar na porta e salvo, byte a
    byte, como um arquivo .prn na pasta de capturas.

    Por padrao so aceita conexoes deste proprio computador (127.0.0.1): nada
    fica exposto na rede.

    No laboratorio: envie os arquivos de exemplo com enviar-arquivo.ps1.
    Na Etapa 4, so com autorizacao: crie uma impressora de TESTE no Windows
    apontando para 127.0.0.1, porta 9100, protocolo RAW, e imprima nela para ver
    o que o programa de etiquetas manda para a impressora.

    As capturas podem conter dados da empresa. Deixe-as neste computador, nao
    envie para ninguem e apague quando terminar.

    Para parar: Ctrl+C.

.PARAMETER Porta
    Porta TCP. Padrao: 9100, a porta RAW das impressoras de rede.

.PARAMETER Endereco
    Endereco em que a impressora virtual escuta. Padrao: 127.0.0.1 (so este
    computador). Nao use 0.0.0.0 em rede da empresa.

.PARAMETER Pasta
    Onde salvar as capturas. Padrao: pasta "capturas" ao lado do script.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\impressora-virtual.ps1
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 65535)][int]$Porta = 9100,
    [string]$Endereco = '127.0.0.1',
    [string]$Pasta
)

$ErrorActionPreference = 'Stop'

if (-not $Pasta) {
    $base = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
    $Pasta = Join-Path $base 'capturas'
}
[void](New-Item -ItemType Directory -Path $Pasta -Force)

# Mesmo criterio do analisar-captura.ps1, repetido para este script funcionar
# sozinho.
function LinguagemProvavel([string]$T) {
    if ($T -match '\^XA' -or $T -match '~(HS|HI|HQ|JA|WC|DG|DY|SD|TA|JS)') { return 'ZPL' }
    if ($T -match '(?m)^! [0U]') { return 'CPCL' }
    if ($T -cmatch '(?m)^N\r?$' -and $T -cmatch '(?m)^P\d+') { return 'EPL' }
    return 'outra'
}

$latin1 = [System.Text.Encoding]::GetEncoding(28591)
$ouvinte = New-Object System.Net.Sockets.TcpListener -ArgumentList ([System.Net.IPAddress]::Parse($Endereco)), $Porta
$ouvinte.Start()
Write-Host "Impressora virtual ouvindo em ${Endereco}:$Porta"
Write-Host "Capturas em: $Pasta"
Write-Host 'Ctrl+C para parar.'

try {
    while ($true) {
        # Pending() + Start-Sleep, em vez de esperar parado no AcceptTcpClient(),
        # para o Ctrl+C funcionar.
        if (-not $ouvinte.Pending()) {
            Start-Sleep -Milliseconds 200
            continue
        }
        $cliente = $ouvinte.AcceptTcpClient()
        $memoria = New-Object System.IO.MemoryStream
        try {
            $cliente.ReceiveTimeout = 15000
            $fluxo = $cliente.GetStream()
            $buffer = New-Object byte[] 65536
            while (($lidos = $fluxo.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $memoria.Write($buffer, 0, $lidos)
            }
        } catch {
            Write-Host 'Aviso: a conexao parou de enviar dados ou caiu; salvando o que chegou.'
        } finally {
            $cliente.Close()
        }
        if ($memoria.Length -eq 0) { continue }

        $dados = $memoria.ToArray()
        $nome = (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.prn'
        [System.IO.File]::WriteAllBytes((Join-Path $Pasta $nome), $dados)
        $linguagem = LinguagemProvavel ($latin1.GetString($dados))
        Write-Host ('[{0}] {1} bytes recebidos, linguagem provavel: {2} -> {3}' -f (Get-Date -Format 'HH:mm:ss'), $dados.Length, $linguagem, $nome)
    }
} finally {
    $ouvinte.Stop()
    Write-Host 'Impressora virtual parada.'
}
