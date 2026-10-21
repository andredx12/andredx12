#Requires -Version 3.0
<#
.SYNOPSIS
    Resume um trabalho de impressao capturado (ZPL, EPL ou CPCL) sem expor os
    dados das etiquetas.

.DESCRIPTION
    Le um arquivo gerado por "imprimir para arquivo" ou pela impressora virtual
    (impressora-virtual.ps1) e mostra: linguagem, tamanho da etiqueta,
    configuracoes enviadas, campos (texto, codigo de barras, imagem), uso da
    memoria da impressora e uma lista de indicios para interpretar o resultado.

    Por padrao, o conteudo dos campos (^FD), os comentarios (^FX) e os nomes de
    arquivos na memoria da impressora saem mascarados, para que o resumo possa
    ser compartilhado. O script so le o arquivo: nao envia nada para lugar
    nenhum.

    Sem acentos de proposito, pelo mesmo motivo do coletar-etapa1.ps1.

.PARAMETER Arquivo
    Arquivo capturado (.prn, .zpl, .txt...).

.PARAMETER Dpi
    Resolucao da impressora, usada para converter pontos em milimetros.
    Padrao: 203.

.PARAMETER MostrarDados
    Mostra o conteudo real dos campos, comentarios e nomes. Use so localmente e
    nao compartilhe essa saida.

.PARAMETER Saida
    Tambem salva o resumo neste arquivo.

.EXAMPLE
    .\analisar-captura.ps1 -Arquivo .\capturas\20261021-101500-123.prn
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Arquivo,
    [ValidateRange(100, 1200)][int]$Dpi = 203,
    [switch]$MostrarDados,
    [string]$Saida
)

$ErrorActionPreference = 'Stop'

$caminho = (Resolve-Path -LiteralPath $Arquivo).Path
$bytes = [System.IO.File]::ReadAllBytes($caminho)
# Latin-1 transforma cada byte em exatamente um caractere: nada se perde, nem
# em trechos binarios, e a posicao no texto e a mesma posicao no arquivo.
$latin1 = [System.Text.Encoding]::GetEncoding(28591)
$texto = $latin1.GetString($bytes)
$n = $texto.Length

$Linhas = New-Object System.Collections.Generic.List[string]

function Escrever([string]$Linha = '') { $Linhas.Add($Linha) }

function Titulo([string]$Texto) {
    Escrever
    Escrever ('== ' + $Texto + ' ==')
}

# ---------------------------------------------------------------------------
# Dicionarios
# ---------------------------------------------------------------------------

$Significados = @{
    '^XA' = 'inicio do formato'
    '^XZ' = 'fim do formato'
    '^FO' = 'posicao do campo'
    '^FT' = 'posicao do campo (pela linha de base)'
    '^FD' = 'dados do campo'
    '^FS' = 'fim do campo'
    '^FV' = 'dados variaveis do campo'
    '^FH' = 'dados com codigos hexadecimais'
    '^FN' = 'numero do campo (modelos)'
    '^FB' = 'bloco de texto com quebra de linha'
    '^FR' = 'campo com cores invertidas'
    '^FP' = 'direcao e espacamento do texto'
    '^FW' = 'orientacao padrao dos campos'
    '^FX' = 'comentario'
    '^FC' = 'campo com data/hora do relogio da impressora'
    '^SN' = 'numero de serie (serializacao)'
    '^SF' = 'campo serializado'
    '^CF' = 'fonte padrao'
    '^CW' = 'apelido para uma fonte'
    '^BY' = 'padrao dos codigos de barras: modulo, razao, altura'
    '^GB' = 'caixa ou linha'
    '^GC' = 'circulo'
    '^GD' = 'linha diagonal'
    '^GE' = 'elipse'
    '^GF' = 'imagem (bitmap) enviada junto'
    '^GS' = 'simbolo grafico'
    '^XG' = 'usa imagem guardada na impressora'
    '^IM' = 'usa imagem guardada na impressora'
    '^IS' = 'guarda a etiqueta como imagem na impressora'
    '^IL' = 'carrega imagem guardada'
    '^ID' = 'apaga objeto da memoria da impressora'
    '^DF' = 'grava modelo (formato) na impressora'
    '^XF' = 'usa modelo guardado na impressora'
    '~DG' = 'grava imagem na memoria da impressora'
    '~DY' = 'grava objeto (fonte, imagem) na impressora'
    '~DB' = 'grava fonte bitmap'
    '~DT' = 'grava fonte TrueType'
    '~DU' = 'grava fonte TrueType grande'
    '~DS' = 'grava fonte escalavel'
    '~DE' = 'grava tabela de codificacao'
    '^PW' = 'largura de impressao (pontos)'
    '^LL' = 'comprimento da etiqueta (pontos)'
    '^LH' = 'origem da etiqueta (x,y)'
    '^LS' = 'deslocamento horizontal'
    '^LT' = 'deslocamento vertical'
    '^LR' = 'inverte branco e preto'
    '^PO' = 'orientacao: N normal, I invertida'
    '^PM' = 'espelhar: Y sim, N nao'
    '^PQ' = 'quantidade: total, pausa, copias por serie, sem pausa'
    '^PR' = 'velocidade (pol/s)'
    '^PF' = 'avanca pontos sem imprimir'
    '^MD' = 'ajuste de escurecimento'
    '~SD' = 'escurecimento (00 a 30)'
    '^MN' = 'sensor de midia: N continua, Y ou W espaco entre etiquetas, M marca preta, A automatico'
    '^MT' = 'tipo: T transferencia termica (ribbon), D termica direta'
    '^MM' = 'depois de imprimir: T destacar, P descolar, C cortar, R rebobinar, A aplicador'
    '^MC' = 'limpa a imagem depois de imprimir'
    '^MF' = 'avanco da midia ao ligar ou fechar a tampa'
    '^MU' = 'unidade: D pontos, I polegadas, M milimetros'
    '^CI' = 'codificacao dos caracteres (28 = UTF-8)'
    '^JU' = 'configuracao: S salva, R recarrega, F padrao de fabrica'
    '^JM' = 'pontos por mm: A resolucao total, B metade'
    '^JZ' = 'reimprimir depois de erro'
    '^SZ' = 'versao da linguagem (2 = ZPL II)'
    '^XB' = 'sem recuo (backfeed) apos imprimir'
    '~TA' = 'ajuste da posicao de destaque'
    '~JS' = 'sequencia de recuo (backfeed)'
    '^CC' = 'troca o caractere de comando ^'
    '~CC' = 'troca o caractere de comando ^'
    '^CT' = 'troca o caractere de controle ~'
    '~CT' = 'troca o caractere de controle ~'
    '^CD' = 'troca o delimitador ,'
    '~CD' = 'troca o delimitador ,'
    '~HS' = 'pede o status da impressora'
    '~HI' = 'pede a identificacao da impressora'
    '~HQ' = 'consulta a impressora'
    '^HH' = 'pede a configuracao da impressora'
    '^HW' = 'pede a lista de arquivos da memoria'
    '^WD' = 'imprime a lista de arquivos da memoria'
    '~WC' = 'imprime a etiqueta de configuracao'
    '~JA' = 'cancela todos os trabalhos'
    '~JR' = 'reinicia a impressora'
    '~JC' = 'calibra o sensor de midia'
    '~JL' = 'ajusta o comprimento da etiqueta'
    '~PS' = 'retoma a impressao'
    '~PP' = 'pausa programada'
    '~PH' = 'avanca uma etiqueta'
    '^PH' = 'avanca uma etiqueta'
    '^RF' = 'le ou grava RFID'
    '^RS' = 'configura RFID'
}

$Barras = @{
    'BC' = 'Code 128'; 'B3' = 'Code 39'; 'BA' = 'Code 93'; 'B1' = 'Code 11'
    'BE' = 'EAN-13'; 'B8' = 'EAN-8'; 'BU' = 'UPC-A'; 'B9' = 'UPC-E'; 'BS' = 'extensao UPC/EAN'
    'B2' = 'Interleaved 2 of 5'; 'BI' = 'Industrial 2 of 5'; 'BJ' = 'Standard 2 of 5'
    'BK' = 'Codabar'; 'BR' = 'GS1 DataBar'; 'BM' = 'MSI'; 'BP' = 'Plessey'; 'BL' = 'LOGMARS'
    'BQ' = 'QR Code'; 'BX' = 'Data Matrix'; 'B7' = 'PDF417'; 'BF' = 'MicroPDF417'
    'BO' = 'Aztec'; 'B0' = 'Aztec'; 'BD' = 'MaxiCode'; 'BB' = 'CODABLOCK'
    'B4' = 'Code 49'; 'B5' = 'Planet Code'; 'BZ' = 'Postal'; 'BT' = 'TLC39'
}

$Formas = @{ '^GB' = 'caixa ou linha'; '^GC' = 'circulo'; '^GD' = 'linha diagonal'; '^GE' = 'elipse' }

# Comandos cujos valores entram na secao "Configuracao enviada".
$ComandosConfig = @(
    '^PW', '^LL', '^LH', '^LS', '^LT', '^LR', '^PO', '^PM', '^PQ', '^PR', '^MD', '~SD',
    '^MN', '^MT', '^MM', '^MU', '^CI', '^JU', '^JM', '^SZ', '^FW', '^BY', '^CF', '~TA', '~JS'
)

# ---------------------------------------------------------------------------
# Utilitarios
# ---------------------------------------------------------------------------

function ParaMm([double]$Pontos) { [math]::Round($Pontos / $Dpi * 25.4, 1) }

function Numero([string]$Valor) {
    $v = 0
    if ([int]::TryParse(($Valor -split ',')[0].Trim(), [ref]$v)) { return $v }
    return $null
}

function Significado([string]$Cod) {
    if ($Significados.ContainsKey($Cod)) { return $Significados[$Cod] }
    if ($Cod -match '^\^A.$') { return 'fonte do campo' }
    if ($Cod -match '^\^B.$' -and $Barras.ContainsKey($Cod.Substring(1))) { return 'codigo de barras ' + $Barras[$Cod.Substring(1)] }
    return $null
}

# Descreve os dados de um campo sem revela-los: so tamanho e tipo de caractere.
function DescreverDados([string]$Dados, [string]$Tipo) {
    $limpo = $Dados -replace '[\r\n]', ''
    # No QR Code, os 3 primeiros caracteres (ex.: "QA,") sao configuracao.
    if ($Tipo -like '*QR Code' -and $limpo -match '^[HQML][AM],') { $limpo = $limpo.Substring(3) }
    if ($script:UsaUtf8) { $limpo = [System.Text.Encoding]::UTF8.GetString($latin1.GetBytes($limpo)) }
    if ($MostrarDados) { return '"' + $limpo + '"' }
    $qtd = $limpo.Length
    if ($qtd -eq 0) { return '<vazio>' }
    if ($limpo -match '^\d+$') { return "<$qtd digitos>" }
    if ($limpo -match '\d') { return "<$qtd caracteres, com numeros>" }
    return "<$qtd caracteres, sem numeros>"
}

# Nomes de arquivos na impressora (ex.: R:PRODUTO.ZPL) podem citar clientes ou
# produtos: mostra so a unidade de memoria e a extensao.
function DescreverNome([string]$Nome) {
    $Nome = $Nome.Trim()
    if ($MostrarDados) { return $Nome }
    if ($Nome -match '^(?<disp>[A-Za-z]:)?[^.]*(?<ext>\.[A-Za-z0-9]+)?$') {
        return $Matches['disp'] + '<nome>' + $Matches['ext']
    }
    return '<nome>'
}

function DescreverFonte([string]$Cod, [string]$Param) {
    $p = $Param -split ','
    $fonte = $Cod.Substring(2, 1)
    if ($fonte -eq '@' -and $p.Count -ge 4) { $fonte = $p[3].Trim() }
    $descricao = 'fonte ' + $fonte
    if ($p.Count -ge 2 -and $p[1].Trim()) { $descricao += ', altura ' + $p[1].Trim() }
    return $descricao
}

function Primeiros([string]$Param, [int]$Quantidade) {
    return ((($Param -split ',') | Select-Object -First $Quantidade | ForEach-Object { $_.Trim() }) -join ',')
}

function DetectarLinguagem([string]$T) {
    if ($T -match '\^XA' -or $T -match '~(HS|HI|HQ|JA|WC|DG|DY|SD|TA|JS)') { return 'ZPL' }
    if ($T -match '(?m)^! [0U]') { return 'CPCL' }
    if ($T -cmatch '(?m)^N\r?$' -and $T -cmatch '(?m)^P\d+') { return 'EPL' }
    if ($T.StartsWith('%!PS')) { return 'PostScript' }
    if ($T.StartsWith('%PDF')) { return 'PDF' }
    if ($T.StartsWith('PK')) { return 'XPS ou outro arquivo compactado' }
    if ($T.IndexOf([char]27) -ge 0) { return 'PCL ou outro formato com comandos ESC' }
    return 'nao reconhecida'
}

# ---------------------------------------------------------------------------
# Leitura do ZPL
# ---------------------------------------------------------------------------

$prefixos = [char[]]@([char]'^', [char]'~')

function ProximoComando([int]$Desde) {
    if ($Desde -ge $n) { return $n }
    $p = $texto.IndexOfAny($prefixos, $Desde)
    if ($p -lt 0) { return $n }
    return $p
}

# Le os primeiros parametros separados por virgula de um comando que traz dados
# depois deles (^GF, ~DY). Devolve $null se o comando estiver malformado.
function LerParametros([int]$Inicio, [int]$Quantidade) {
    $limite = ProximoComando $Inicio
    $valores = New-Object System.Collections.Generic.List[string]
    $pos = $Inicio
    for ($k = 0; $k -lt $Quantidade; $k++) {
        $virgula = $texto.IndexOf(',', $pos)
        if ($virgula -lt 0 -or $virgula -gt $limite) { return $null }
        $valores.Add($texto.Substring($pos, $virgula - $pos).Trim())
        $pos = $virgula + 1
    }
    return @{ Valores = $valores.ToArray(); Fim = $pos }
}

function NovoFormato([int]$Numero) {
    return @{
        Numero     = $Numero
        Campos     = New-Object System.Collections.Generic.List[object]
        Config     = [ordered]@{}
        PW         = $null
        LL         = $null
        AreaImagem = 0
        Modelo     = $null
        Grava      = $null
    }
}

$Formatos = New-Object System.Collections.Generic.List[object]
$Fora = NovoFormato 0
$atual = $Fora
$campo = $null
$estado = @{ PW = $null; LL = $null; MU = 'D' }
$ConfigGeral = [ordered]@{}
$Contagem = @{}
$Objetos = New-Object System.Collections.Generic.List[string]
$Comentarios = New-Object System.Collections.Generic.List[string]
$Avisos = New-Object System.Collections.Generic.List[string]
$UsaUtf8 = $false

function CampoAtual {
    if ($null -eq $script:campo) {
        $script:campo = @{ Tipo = $null; Posicao = $null; Detalhe = $null; Dados = $null; Numero = $null; Serie = $false }
    }
    return $script:campo
}

function FecharCampo {
    $c = $script:campo
    if ($null -eq $c) { return }
    if (-not $c.Tipo) {
        if ($c.Numero -and -not $c.Posicao) { $c.Tipo = 'valor para campo do modelo' }
        elseif ($null -ne $c.Dados) { $c.Tipo = 'texto' }
        else { $c.Tipo = 'outro' }
    }
    $script:atual.Campos.Add($c)
    $script:campo = $null
}

function FecharFormato {
    FecharCampo
    $script:atual.PW = $script:estado.PW
    $script:atual.LL = $script:estado.LL
    $script:atual = $script:Fora
}

function RegistrarConfig([string]$Cod, [string]$Valor) {
    $v = $Valor -replace '\s', ''
    foreach ($cfg in @($script:atual.Config, $script:ConfigGeral)) {
        if (-not $cfg.Contains($Cod)) { $cfg[$Cod] = New-Object System.Collections.Generic.List[string] }
        if (-not $cfg[$Cod].Contains($v)) { $cfg[$Cod].Add($v) }
    }
    switch ($Cod) {
        '^PW' { $script:estado.PW = Numero $v }
        '^LL' { $script:estado.LL = Numero $v }
        '^MU' { if ($v) { $script:estado.MU = $v.Substring(0, 1).ToUpperInvariant() } }
    }
}

function LerZpl {
    $i = ProximoComando 0
    while ($i -lt $n) {
        # "~~" aparece no preambulo CT~~CD,~CC^~CT~: o primeiro ~ nao inicia comando.
        if ($texto[$i] -eq [char]'~' -and $i + 1 -lt $n -and $texto[$i + 1] -eq [char]'~') {
            $i = ProximoComando ($i + 1)
            continue
        }
        if ($i + 3 -gt $n) { break }
        $cod = $texto.Substring($i, 3).ToUpperInvariant()
        $ini = $i + 3
        $fim = $null
        $param = ''
        $gf = $null

        # Onde termina cada comando. Quase sempre e no proximo ^ ou ~, com
        # excecoes: troca de caracteres (1 caractere), dados de campo (podem
        # conter ~) e dados binarios (tamanho informado nos parametros).
        switch -Regex ($cod) {
            '^[\^~]C[CTD]$' {
                $fim = [math]::Min($ini + 1, $n)
                $param = $texto.Substring($ini, $fim - $ini)
                break
            }
            '^\^(FD|FV|SN|FX)$' {
                $fim = $texto.IndexOf('^', $ini)
                if ($fim -lt 0) { $fim = $n }
                $param = $texto.Substring($ini, $fim - $ini)
                break
            }
            '^\^GF$' {
                $partes = LerParametros $ini 4
                if ($partes) {
                    $gf = @{
                        Formato  = $partes.Valores[0].ToUpperInvariant()
                        Binarios = Numero $partes.Valores[1]
                        Total    = Numero $partes.Valores[2]
                        PorLinha = Numero $partes.Valores[3]
                    }
                    if (($gf.Formato -eq 'B' -or $gf.Formato -eq 'C') -and $gf.Binarios -gt 0) {
                        $fim = [math]::Min($partes.Fim + $gf.Binarios, $n)
                    } else {
                        $fim = ProximoComando $partes.Fim
                    }
                    $param = $partes.Valores -join ','
                }
                break
            }
            '^~DY$' {
                $partes = LerParametros $ini 5
                if ($partes) {
                    $formatoDY = $partes.Valores[1].ToUpperInvariant()
                    $totalDY = Numero $partes.Valores[3]
                    if (($formatoDY -eq 'B' -or $formatoDY -eq 'C') -and $totalDY -gt 0) {
                        $fim = [math]::Min($partes.Fim + $totalDY, $n)
                    } else {
                        $fim = ProximoComando $partes.Fim
                    }
                    $param = $partes.Valores -join ','
                }
                break
            }
        }
        if ($null -eq $fim) {
            $fim = ProximoComando $ini
            $param = $texto.Substring($ini, $fim - $ini)
        }

        $script:Contagem[$cod] = 1 + [int]$script:Contagem[$cod]
        if ($ComandosConfig -contains $cod) { RegistrarConfig $cod $param }

        switch -Regex ($cod) {
            '^\^XA$' {
                if (-not [object]::ReferenceEquals($script:atual, $script:Fora)) { FecharFormato }
                $script:atual = NovoFormato ($script:Formatos.Count + 1)
                $script:Formatos.Add($script:atual)
                break
            }
            '^\^XZ$' { FecharFormato; break }
            '^\^F[OT]$' {
                $c = CampoAtual
                if ($c.Posicao) { FecharCampo; $c = CampoAtual }
                $c.Posicao = Primeiros $param 2
                break
            }
            '^\^A.$' {
                $c = CampoAtual
                if (-not $c.Tipo) { $c.Tipo = 'texto' }
                $c.Detalhe = DescreverFonte $cod $param
                break
            }
            '^\^BY$' { break }
            '^\^B.$' {
                $c = CampoAtual
                $nomeBarras = $Barras[$cod.Substring(1)]
                if (-not $nomeBarras) { $nomeBarras = '(' + $cod + ')' }
                $c.Tipo = 'codigo de barras ' + $nomeBarras
                break
            }
            '^\^G[BCDE]$' {
                $c = CampoAtual
                $c.Tipo = $Formas[$cod]
                $c.Detalhe = 'medidas ' + (Primeiros $param 3)
                break
            }
            '^\^GF$' {
                $c = CampoAtual
                $c.Tipo = 'imagem (bitmap)'
                if ($gf -and $gf.PorLinha -gt 0 -and $gf.Total -gt 0) {
                    $largura = $gf.PorLinha * 8
                    $altura = [math]::Floor($gf.Total / $gf.PorLinha)
                    $c.Detalhe = "$largura x $altura pontos"
                    $script:atual.AreaImagem += $largura * $altura
                }
                break
            }
            '^\^(XG|IM)$' {
                $c = CampoAtual
                $c.Tipo = 'imagem guardada na impressora'
                $c.Detalhe = DescreverNome (($param -split ',')[0])
                break
            }
            '^\^(FD|FV|SN)$' {
                $c = CampoAtual
                $c.Dados = $param
                if ($cod -eq '^SN') { $c.Serie = $true }
                break
            }
            '^\^SF$' { $c = CampoAtual; $c.Serie = $true; break }
            '^\^FN$' { $c = CampoAtual; $c.Numero = (($param -split '"')[0]).Trim(); break }
            '^\^FX$' { $script:Comentarios.Add($param.Trim()); break }
            '^\^FS$' { FecharCampo; break }
            '^\^DF$' {
                $script:atual.Grava = DescreverNome $param
                $script:Objetos.Add('grava modelo (^DF): ' + $script:atual.Grava)
                break
            }
            '^\^XF$' {
                $script:atual.Modelo = DescreverNome $param
                $script:Objetos.Add('usa modelo guardado (^XF): ' + $script:atual.Modelo)
                break
            }
            '^\^ID$' { $script:Objetos.Add('apaga objeto (^ID): ' + (DescreverNome $param)); break }
            '^~D[GYBTUSE]$' {
                $script:Objetos.Add('grava ' + (Significado $cod).Replace('grava ', '') + ' (' + $cod + '): ' + (DescreverNome (($param -split ',')[0])))
                break
            }
            '^[\^~]CC$' { if ($param -ne '^') { $script:Avisos.Add("O arquivo troca o caractere de comando ^ por '$param' ($cod). Comandos depois disso podem nao ter sido lidos.") }; break }
            '^[\^~]CT$' { if ($param -ne '~') { $script:Avisos.Add("O arquivo troca o caractere de controle ~ por '$param' ($cod). Comandos depois disso podem nao ter sido lidos.") }; break }
            '^[\^~]CD$' { if ($param -ne ',') { $script:Avisos.Add("O arquivo troca o delimitador , por '$param' ($cod). Parametros depois disso podem estar errados.") }; break }
        }
        $i = ProximoComando $fim
    }
    if ([object]::ReferenceEquals($script:atual, $script:Fora)) { FecharCampo } else { FecharFormato }
}

# ---------------------------------------------------------------------------
# Resumo do ZPL
# ---------------------------------------------------------------------------

function ResumirZpl {
    LerZpl
    if ($ConfigGeral.Contains('^CI')) {
        $script:UsaUtf8 = @($ConfigGeral['^CI'] | Where-Object { (Numero $_) -eq 28 }).Count -gt 0
    }

    # Um formato com ^DF nao imprime nada: ele so grava o modelo na impressora.
    $detalhados = @($Formatos | Where-Object { $_.Grava -or $_.Campos.Count -gt 0 -or $_.Modelo })
    $conteudo = @($detalhados | Where-Object { -not $_.Grava })
    $modelos = $detalhados.Count - $conteudo.Count
    Escrever ('Formatos (^XA ... ^XZ): {0} ({1} etiqueta(s), {2} modelo(s) gravado(s), {3} so de configuracao)' -f $Formatos.Count, $conteudo.Count, $modelos, ($Formatos.Count - $detalhados.Count))
    if ($estado.MU -ne 'D') {
        $Avisos.Add('A unidade de medida foi trocada (^MU): posicoes e tamanhos nao estao em pontos, entao as conversoes para mm estao erradas.')
    }

    Titulo 'Configuracao enviada'
    if ($ConfigGeral.Count -eq 0) { Escrever '(nenhum comando de configuracao)' }
    foreach ($cod in $ConfigGeral.Keys) {
        $extra = ''
        if ($cod -eq '^PW' -or $cod -eq '^LL') {
            $mm = @($ConfigGeral[$cod] | ForEach-Object { $num = Numero $_; if ($null -ne $num) { '{0} mm' -f (ParaMm $num) } }) -join ' | '
            if ($mm) { $extra = " (= $mm a $Dpi dpi)" }
        }
        Escrever ('{0,-4} {1,-12} {2}{3}' -f $cod, ($ConfigGeral[$cod] -join ' | '), (Significado $cod), $extra)
    }

    $limiteFormatos = 5
    $limiteCampos = 40
    $k = 0
    foreach ($f in $detalhados) {
        $k++
        if ($k -gt $limiteFormatos) {
            Escrever
            Escrever ('... mais {0} formatos nao detalhados.' -f ($detalhados.Count - $limiteFormatos))
            break
        }
        if ($f.Grava) {
            Titulo ('Modelo gravado na impressora: formato {0} ({1})' -f $f.Numero, $f.Grava)
        } else {
            Titulo ('Etiqueta: formato {0}' -f $f.Numero)
        }
        if ($f.PW -and $f.LL) {
            Escrever ('Tamanho: {0} x {1} pontos (cerca de {2} x {3} mm a {4} dpi)' -f $f.PW, $f.LL, (ParaMm $f.PW), (ParaMm $f.LL), $Dpi)
        } else {
            Escrever 'Tamanho: nao informado no arquivo (sem ^PW ou ^LL)'
        }
        if ($f.Config.Contains('^PQ')) { Escrever ('Quantidade (^PQ): ' + (Numero $f.Config['^PQ'][0])) }
        if ($f.Modelo) { Escrever ('Usa modelo guardado na impressora: ' + $f.Modelo) }
        $tipos = @($f.Campos | Group-Object { $_.Tipo } | Sort-Object Count -Descending | ForEach-Object { '{0} {1}' -f $_.Count, $_.Name })
        Escrever ('Campos: {0} ({1})' -f $f.Campos.Count, ($tipos -join ', '))
        if ($f.AreaImagem -gt 0 -and $f.PW -and $f.LL) {
            Escrever ('Area coberta por imagens (^GF): {0}% da etiqueta' -f [math]::Round(100 * $f.AreaImagem / ($f.PW * $f.LL), 1))
        }
        $j = 0
        foreach ($c in $f.Campos) {
            $j++
            if ($j -gt $limiteCampos) {
                Escrever ('  ... mais {0} campos' -f ($f.Campos.Count - $limiteCampos))
                break
            }
            $partes = New-Object System.Collections.Generic.List[string]
            $partes.Add($c.Tipo)
            if ($c.Posicao) { $partes.Add('posicao ' + $c.Posicao) }
            if ($c.Numero) { $partes.Add('campo ^FN' + $c.Numero) }
            if ($c.Detalhe) { $partes.Add($c.Detalhe) }
            if ($c.Serie) { $partes.Add('serializado') }
            if ($null -ne $c.Dados) { $partes.Add('dados ' + (DescreverDados $c.Dados $c.Tipo)) }
            Escrever ('  {0}. {1}' -f $j, ($partes -join ' | '))
        }
    }

    Titulo 'Memoria da impressora'
    if ($Objetos.Count -eq 0) {
        Escrever 'Nenhum comando que grava ou usa arquivos na memoria da impressora.'
    } else {
        $Objetos | Select-Object -Unique | ForEach-Object { Escrever ('- ' + $_) }
    }

    if ($Comentarios.Count -gt 0) {
        Titulo 'Comentarios (^FX)'
        if ($MostrarDados) {
            foreach ($comentario in $Comentarios) { Escrever ('- ' + $comentario) }
        } else {
            Escrever ('{0} comentario(s). Podem citar o modelo ou o programa que gerou o arquivo:' -f $Comentarios.Count)
            Escrever 'veja com -MostrarDados e conte o que encontrar, sem dados confidenciais.'
        }
    }

    $total = [double](($Contagem.Values | Measure-Object -Sum).Sum)
    $naoCatalogados = [double]((@($Contagem.Keys | Where-Object { -not (Significado $_) }) | ForEach-Object { $Contagem[$_] } | Measure-Object -Sum).Sum)
    if ($total -gt 0 -and $naoCatalogados / $total -gt 0.2) {
        $Avisos.Add('Muitos comandos nao catalogados: pode haver dados binarios ou comandos raros. Confira o resumo com cuidado.')
    }

    # Indicios: o que os comandos encontrados significam em ZPL. Sao pistas
    # para confirmar com outros experimentos, nao conclusoes.
    $indicios = New-Object System.Collections.Generic.List[string]
    $imagemDominante = $false
    $nativos = $false
    foreach ($f in $detalhados) {
        $qtdNativos =@($f.Campos | Where-Object { $null -ne $_.Dados -and ($_.Tipo -eq 'texto' -or $_.Tipo -like 'codigo de barras*') }).Count
        if ($qtdNativos -gt 0) { $nativos = $true }
        if ($f.PW -and $f.LL -and $f.AreaImagem -ge 0.5 * $f.PW * $f.LL -and $qtdNativos -le 1) { $imagemDominante = $true }
    }
    if ($imagemDominante) {
        $indicios.Add('A etiqueta chegou principalmente como IMAGEM (^GF). Isso costuma acontecer quando o programa desenha a etiqueta e o driver a transforma em bitmap: textos e codigos de barras nao aparecem como comandos ZPL.')
    } elseif ($Contagem['^GF']) {
        $indicios.Add('Ha imagens (^GF) enviadas junto com a etiqueta, como um logotipo.')
    }
    if ($nativos) {
        $indicios.Add('Ha campos ZPL nativos (^FD): a propria impressora desenha textos e/ou codigos de barras a partir dos comandos.')
    }
    if ($Contagem['^XF']) {
        $indicios.Add('A etiqueta usa um MODELO GUARDADO NA IMPRESSORA (^XF): o computador envia so os valores dos campos (^FN). Parte do sistema mora dentro da impressora.')
    }
    if ($Contagem['^DF']) { $indicios.Add('O trabalho GRAVA um modelo na memoria da impressora (^DF).') }
    if ($Contagem['~DG'] -or $Contagem['~DY'] -or $Contagem['~DB'] -or $Contagem['~DT'] -or $Contagem['~DU'] -or $Contagem['~DS']) {
        $indicios.Add('O trabalho grava imagens ou fontes na memoria da impressora.')
    }
    if ($Contagem['^SN'] -or $Contagem['^SF']) {
        $indicios.Add('A impressora faz a serializacao (^SN/^SF): ela mesma incrementa a numeracao a cada etiqueta.')
    }
    if ($ConfigGeral.Contains('^JU') -and @($ConfigGeral['^JU'] | Where-Object { $_ -like 'S*' }).Count -gt 0) {
        $indicios.Add('O trabalho SALVA configuracoes na impressora (^JUS). Reenviar este arquivo para outra impressora muda a configuracao dela.')
    }
    if ($ConfigGeral.Contains('^MT')) {
        if (@($ConfigGeral['^MT'] | Where-Object { $_ -like 'T*' }).Count) { $indicios.Add('Configurado para transferencia termica (^MTT): indicio de que a impressora usa ribbon.') }
        if (@($ConfigGeral['^MT'] | Where-Object { $_ -like 'D*' }).Count) { $indicios.Add('Configurado para termica direta (^MTD): indicio de que a impressora nao usa ribbon.') }
    }
    if ($UsaUtf8) { $indicios.Add('Os textos usam a codificacao UTF-8 (^CI28).') }
    if ($conteudo.Count -gt 1) {
        $indicios.Add(('O arquivo tem {0} etiquetas em formatos separados: o programa pode mandar um formato por etiqueta em vez de usar ^PQ.' -f $conteudo.Count))
    }
    if (@($conteudo | Where-Object { $_.Config.Contains('^PQ') -and (Numero $_.Config['^PQ'][0]) -gt 1 }).Count) {
        $indicios.Add('A quantidade e definida no ZPL (^PQ maior que 1): a impressora repete a etiqueta sozinha.')
    }
    if ($Contagem['~HS'] -or $Contagem['~HI'] -or $Contagem['~HQ'] -or $Contagem['^HH']) {
        $indicios.Add('Ha pedidos de informacao a impressora (~HS, ~HI, ~HQ ou ^HH): o driver ou o programa espera respostas dela (comunicacao bidirecional).')
    }
    if ($Contagem['^FC']) { $indicios.Add('Ha campos com data/hora do relogio da impressora (^FC).') }
    if ($Contagem['^RF'] -or $Contagem['^RS']) { $indicios.Add('O trabalho usa RFID (^RF/^RS).') }
    if ($indicios.Count -eq 0) { $indicios.Add('Nenhum indicio especial encontrado.') }

    if ($Avisos.Count -gt 0) {
        Titulo 'Avisos'
        foreach ($aviso in $Avisos) { Escrever ('- ' + $aviso) }
    }

    Titulo 'Indicios (para confirmar, nao sao conclusoes)'
    foreach ($indicio in $indicios) { Escrever ('- ' + $indicio) }

    Titulo 'Comandos encontrados'
    $ordenados = $Contagem.GetEnumerator() | Sort-Object @{ Expression = 'Value'; Descending = $true }, @{ Expression = 'Key' }
    foreach ($par in $ordenados) {
        $sig = Significado $par.Key
        if (-not $sig) { $sig = '(nao catalogado)' }
        Escrever ('{0,-4} x{1,-5} {2}' -f $par.Key, $par.Value, $sig)
    }
}

# ---------------------------------------------------------------------------
# EPL, CPCL e outros formatos
# ---------------------------------------------------------------------------

function MascararAspas([string]$Linha) {
    if ($MostrarDados) { return $Linha }
    $resultado = $Linha
    foreach ($m in [regex]::Matches($Linha, '"([^"]*)"')) {
        $resultado = $resultado.Replace($m.Value, (DescreverDados $m.Groups[1].Value ''))
    }
    return $resultado
}

function ResumirEpl {
    # EPL diferencia maiusculas de minusculas (B e b sao comandos diferentes).
    $contagemEpl = New-Object 'System.Collections.Generic.Dictionary[string,int]' ([StringComparer]::Ordinal)
    $amostras = New-Object System.Collections.Generic.List[string]
    $largura = $null; $comprimento = $null; $quantidade = $null
    foreach ($linha in ($texto -split '\r?\n')) {
        $t = $linha.Trim()
        if (-not $t) { continue }
        if ($t -cmatch '^(GW|LO|LE|LW|LS|FS|FE|FR|FK|FI)') { $c = $Matches[1] } else { $c = $t.Substring(0, 1) }
        if ($contagemEpl.ContainsKey($c)) { $contagemEpl[$c]++ } else { $contagemEpl[$c] = 1 }
        if ($t -cmatch '^q(\d+)') { $largura = [int]$Matches[1] }
        if ($t -cmatch '^Q(\d+)') { $comprimento = [int]$Matches[1] }
        if ($t -cmatch '^P(\d+)') { $quantidade = [int]$Matches[1] }
        if ($t -cmatch '^[ABb]\d' -and $amostras.Count -lt 15) { $amostras.Add((MascararAspas $t)) }
    }
    function Qtd([string]$Cod) { if ($contagemEpl.ContainsKey($Cod)) { $contagemEpl[$Cod] } else { 0 } }

    Titulo 'Resumo EPL'
    if ($largura) { Escrever ('Largura (q): {0} pontos (cerca de {1} mm a {2} dpi)' -f $largura, (ParaMm $largura), $Dpi) }
    if ($comprimento) { Escrever ('Comprimento (Q): {0} pontos (cerca de {1} mm a {2} dpi)' -f $comprimento, (ParaMm $comprimento), $Dpi) }
    if ($quantidade) { Escrever ('Quantidade (P): ' + $quantidade) }
    Escrever ('Textos (A): {0} | codigos de barras (B): {1} | codigos 2D (b): {2} | imagens (GW): {3} | linhas e caixas: {4}' -f (Qtd 'A'), (Qtd 'B'), (Qtd 'b'), (Qtd 'GW'), ((Qtd 'LO') + (Qtd 'LE') + (Qtd 'LW') + (Qtd 'LS') + (Qtd 'X')))
    if ($amostras.Count -gt 0) {
        Titulo 'Campos (primeiros 15, dados mascarados)'
        foreach ($amostra in $amostras) { Escrever ('  ' + $amostra) }
    }
    Titulo 'Indicios (para confirmar, nao sao conclusoes)'
    Escrever '- Linguagem EPL: mais antiga que o ZPL. A impressora precisa aceitar EPL, e uma solucao propria teria de gerar EPL ou ser testada com ZPL.'
    if ((Qtd 'FR') -gt 0) { Escrever '- Usa formulario guardado na impressora (FR): o modelo mora na memoria dela.' }
    if ((Qtd 'FS') -gt 0) { Escrever '- Grava um formulario na memoria da impressora (FS).' }
    if ((Qtd 'GW') -gt 0) { Escrever '- Tem imagens (GW) enviadas junto.' }
}

function ResumirCpcl {
    $contagemCpcl = @{}
    foreach ($linha in ($texto -split '\r?\n')) {
        $t = $linha.Trim()
        if (-not $t) { continue }
        $palavra = ($t -split '\s+')[0].ToUpperInvariant()
        $contagemCpcl[$palavra] = 1 + [int]$contagemCpcl[$palavra]
    }
    Titulo 'Resumo CPCL'
    Escrever 'Comandos (primeira palavra de cada linha, sem os dados):'
    foreach ($par in ($contagemCpcl.GetEnumerator() | Sort-Object @{ Expression = 'Value'; Descending = $true })) {
        Escrever ('  {0} x{1}' -f $par.Key, $par.Value)
    }
    Titulo 'Indicios (para confirmar, nao sao conclusoes)'
    Escrever '- Linguagem CPCL, usada principalmente em impressoras moveis da Zebra. A analise detalhada de CPCL ainda nao foi implementada.'
}

function ResumirOutro([string]$Linguagem) {
    $imprimiveis = 0
    foreach ($b in $bytes) {
        if (($b -ge 32 -and $b -le 126) -or $b -eq 9 -or $b -eq 10 -or $b -eq 13) { $imprimiveis++ }
    }
    Titulo 'Resumo'
    if ($bytes.Length -gt 0) {
        Escrever ('Caracteres de texto: {0}% do arquivo' -f [math]::Round(100 * $imprimiveis / $bytes.Length))
    }
    Titulo 'Indicios (para confirmar, nao sao conclusoes)'
    Escrever '- O trabalho nao esta numa linguagem de impressora Zebra. A fila pode usar um driver que nao e da Zebra, ou o arquivo pode ser de outro tipo.'
}

# ---------------------------------------------------------------------------
# Execucao
# ---------------------------------------------------------------------------

$linguagem = DetectarLinguagem $texto

Escrever 'RESUMO DE CAPTURA DE IMPRESSAO'
Escrever ('Arquivo: {0} ({1} bytes)' -f [System.IO.Path]::GetFileName($caminho), $bytes.Length)
Escrever ('Dados dos campos: ' + $(if ($MostrarDados) { 'VISIVEIS - nao compartilhe esta saida' } else { 'ocultos' }))
Escrever ('Resolucao usada nas conversoes: {0} dpi (ajuste com -Dpi)' -f $Dpi)
Escrever ('Linguagem detectada: ' + $linguagem)

switch ($linguagem) {
    'ZPL'   { ResumirZpl }
    'EPL'   { ResumirEpl }
    'CPCL'  { ResumirCpcl }
    default { ResumirOutro $linguagem }
}

if ($Saida) {
    Set-Content -LiteralPath $Saida -Value ($Linhas -join [Environment]::NewLine) -Encoding UTF8
}
$Linhas
