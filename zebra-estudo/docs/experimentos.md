# Catálogo de experimentos

> **Preliminar.** Estes experimentos não dependem do programa que a empresa usa, mas a ordem e os detalhes serão ajustados depois do relatório da Etapa 1. Faça um de cada vez e só os que já tiverem autorização.

Ordem: do que não tem risco nenhum (só observar) até o que precisa de autorização e de ajuda da TI.

| Exp. | Etapa | Precisa de autorização? | Status |
|---|---|---|---|
| [X1. Levantamento somente leitura](#x1-levantamento-somente-leitura) | 1 | Para rodar scripts no PC | pronto para rodar |
| [X2. Observar uma impressão real](#x2-observar-uma-impressão-real) | 2 | Do operador e do gestor | a fazer |
| [X3. Ver conexões e arquivos do programa](#x3-ver-conexões-e-arquivos-do-programa) | 3 | Não muda nada, mas combine antes | a fazer |
| [X8. Localizar os modelos e ver a data de modificação](#x8-localizar-os-modelos-e-ver-a-data-de-modificação) | 2 e 3 | Não muda nada | a fazer |
| [X4. Imprimir para arquivo](#x4-imprimir-para-arquivo) | 3 e 4 | Sim | a fazer |
| [X5. Capturar com a impressora virtual](#x5-capturar-com-a-impressora-virtual) | 4 | Sim, e ajuda da TI | a fazer |
| [X6. Comparar duas capturas](#x6-comparar-duas-capturas) | 4 | Sim (mesmas do X4/X5) | a fazer |
| [X7. Impressão física de teste](#x7-impressão-física-de-teste) | 4 | Sim | só se necessário |

---

## X1. Levantamento somente leitura

1. **Objetivo:** identificar o programa, a impressora, o driver e a forma de conexão.
2. **Hipótese:** H1 a H5. Ainda não sabemos qual vale.
3. **Procedimento:** seguir [Como rodar](../README.md#como-rodar) com o [script da Etapa 1](../etapa1/coletar-etapa1.ps1).
4. **Resultado esperado:** relatório com programas, impressoras, portas, drivers e as respostas manuais.
5. **Interpretação:** as seções 2 e 3 apontam o programa (H1, H3, H4); a sessão e as portas apontam a conexão (H5); o nome do driver costuma indicar a linguagem (ZPL ou EPL).
6. **Riscos e precauções:** o script só lê informações. Revise o relatório antes de compartilhar.

## X2. Observar uma impressão real

1. **Objetivo:** mapear as telas, os campos e os passos de quem imprime.
2. **Hipótese:** H2 e H3 (de onde sai a impressão), H8 (de onde vêm os dados), H9 (onde são digitados) e H10 (se o modelo muda a cada impressão).
3. **Procedimento:**
   1. Combine com quem imprime e com o gestor.
   2. Acompanhe uma impressão normal, sem interferir.
   3. Anote como o modelo é aberto (qual arquivo, de qual pasta) e quantos modelos existem.
   4. Anote cada campo, só o nome e nunca o valor: digitado, escolhido em uma lista ou preenchido sozinho. Veja se é digitado numa janela que aparece ao imprimir ou direto no texto da etiqueta.
   5. Pergunte de onde vêm as informações digitadas: papel, tela de outro sistema, memória.
   6. Se houver número de série, pergunte como se sabe o próximo e o que impede repetir.
   7. Anote como se define a quantidade e se o arquivo do modelo é salvo depois de imprimir.
   8. Pergunte como funcionam reimpressão, cancelamento e erros (ex.: acabou a etiqueta ou o ribbon).
   9. Tire prints com os dados ocultos.
4. **Resultado esperado:** a sequência de telas e a lista de campos, o começo do diagrama do processo atual.
5. **Interpretação:** campos preenchidos sozinhos indicam consulta a outra fonte (H8); se a impressão sai de uma tela do ERP, H2 ganha força. Uma janela pedindo os dados ao imprimir confirma H9: o modelo tem campos definidos. Editar o texto direto na etiqueta descarta H9: o modelo é reaproveitado como um desenho. Salvar depois de imprimir confirma H10: o arquivo muda a cada etiqueta, o que afeta reimpressões e histórico.
6. **Riscos e precauções:** nenhum, desde que você só observe. Se abrir o modelo para olhar, feche sem salvar. Não fotografe dados confidenciais.

## X3. Ver conexões e arquivos do programa

1. **Objetivo:** descobrir de onde vêm os dados e onde ficam os modelos.
2. **Hipótese:** H8 e H2.
3. **Procedimento:**
   1. Abra o programa e faça-o buscar um dado (ex.: digitar um código de produto), **sem imprimir**.
   2. Tecle Win+R, digite `resmon` e Enter.
   3. Aba **Rede** → **Conexões TCP**: marque o processo do programa e anote as portas remotas (oculte os endereços).
   4. Aba **CPU** → **Identificadores Associados**: pesquise o nome do programa e anote os tipos de arquivo e as pastas (oculte nomes).
   5. Alternativa em PowerShell: `Get-NetTCPConnection -OwningProcess (Get-Process <nome>).Id`.
4. **Resultado esperado:** uma lista de portas remotas e de tipos de arquivo usados.
5. **Interpretação:** portas 1433, 5432, 3306, 1521 ou 3050 indicam banco de dados; 80 ou 443, uma API ou sistema web; arquivos `.xlsx`, `.csv` ou `.mdb`, dados em arquivo. Nenhuma conexão nem arquivo de dados sugere digitação ou dados locais.
6. **Riscos e precauções:** só leitura. Nomes de servidores e caminhos são confidenciais: oculte antes de compartilhar.

## X8. Localizar os modelos e ver a data de modificação

1. **Objetivo:** saber onde ficam os arquivos de modelo e se eles são alterados a cada impressão.
2. **Hipótese:** H10.
3. **Procedimento:**
   1. No Explorador de Arquivos, pesquise pela extensão dos modelos (ex.: `.lbl` no ZebraDesigner 2, `.btw` no BarTender). Outra opção: no programa, use Arquivo > Abrir só para ver a pasta e cancele.
   2. Clique com o botão direito no arquivo > Propriedades. Anote a pasta (oculte nomes de pessoas e servidores) e as datas de criação e de modificação.
   3. Repita depois de um dia de impressões e compare.
4. **Resultado esperado:** a pasta dos modelos e as datas de cada arquivo.
5. **Interpretação:** abrir um arquivo não muda a data de modificação; só salvar muda. Se a data acompanha os dias de impressão, o modelo é salvo a cada uso (H10); se for antiga, não é. Uma pasta de rede (`\\servidor\...`) significa que os modelos dependem de outro computador.
6. **Riscos e precauções:** nenhum, é só leitura. Não renomeie nem mova os arquivos.

## X4. Imprimir para arquivo

1. **Objetivo:** obter os bytes que o programa mandaria para a impressora, sem imprimir nada.
2. **Hipótese:** H6 e H7, e qual linguagem é usada (ZPL ou EPL).
3. **Procedimento:**
   1. Confirme com o responsável que pode fazer uma impressão de teste.
   2. Em vez de dados reais, preencha os campos com valores fictícios e fáceis de reconhecer (ex.: `9999`, `TESTE`). Assim a captura não tem dados confidenciais e mostra onde cada campo entra no ZPL.
   3. No diálogo de impressão, procure "Imprimir em arquivo" ou "Print to file". Nem todo programa tem essa opção. Se não houver, não troque a porta da impressora de produção: use o X5.
   4. Salve o `.prn` no computador da empresa.
   5. Rode `ferramentas/analisar-captura.ps1 -Arquivo <arquivo>.prn`.
   6. Compartilhe só o resumo.
4. **Resultado esperado:** um arquivo `.prn` e um resumo com linguagem, campos e indícios.
5. **Interpretação:** veja a seção "Indícios" do resumo e compare com H6 e H7. Se os campos aparecem como texto (`^FD`) com os valores fictícios, a captura pode servir de modelo para uma solução própria: basta trocar esses valores pelos reais. Se a etiqueta veio como imagem (`^GF`), esse atalho não funciona.
6. **Riscos e precauções:** **mesmo sem papel, para o programa é uma impressão.** Contadores e números de série podem avançar, e o sistema pode registrar a etiqueta como impressa. Se você trocar a impressora no modelo e salvar, altera o modelo de produção. Confirme esses pontos antes, não salve o modelo e não tire o `.prn` do computador da empresa.

## X5. Capturar com a impressora virtual

1. **Objetivo:** capturar exatamente o que a impressora receberia, quando o programa não tem "imprimir em arquivo".
2. **Hipótese:** H6, H7 e H2.
3. **Procedimento** (precisa de administrador, então peça à TI):
   1. Rode `ferramentas/impressora-virtual.ps1`. Ela escuta em 127.0.0.1, porta 9100.
   2. Crie uma impressora **nova**, sem mexer na de produção, com o **mesmo driver** da impressora real e uma porta TCP/IP para 127.0.0.1, porta 9100, protocolo RAW. Em PowerShell como administrador:

      ```powershell
      Add-PrinterPort -Name 'CAPTURA_9100' -PrinterHostAddress '127.0.0.1' -PortNumber 9100
      Add-Printer -Name 'ZEBRA-TESTE-CAPTURA' -DriverName '<nome exato do driver>' -PortName 'CAPTURA_9100'
      ```

   3. Nas propriedades da nova impressora, aba Portas, desmarque "Ativar suporte bidirecional", para o driver não esperar respostas que a impressora virtual não dá.
   4. No programa, imprima **uma** etiqueta de teste escolhendo `ZEBRA-TESTE-CAPTURA`.
   5. Analise o `.prn` salvo com `analisar-captura.ps1`.
   6. Desfaça tudo:

      ```powershell
      Remove-Printer -Name 'ZEBRA-TESTE-CAPTURA'
      Remove-PrinterPort -Name 'CAPTURA_9100'
      ```

4. **Resultado esperado:** um `.prn` igual ao que a impressora real receberia.
5. **Interpretação:** a mesma do X4. Como a fila de teste usa o mesmo driver, a captura representa o que acontece na produção.
6. **Riscos e precauções:** os mesmos do X4. Não deixe a impressora de teste como padrão e remova tudo no final.

## X6. Comparar duas capturas

1. **Objetivo:** separar o que é modelo (fixo) do que é dado (variável) e ver como cada campo da tela vira ZPL.
2. **Hipótese:** H6 e H8.
3. **Procedimento:**
   1. Faça duas capturas do mesmo modelo (X4 ou X5), mudando **um único** dado.
   2. Compare os dois resumos.
   3. No computador da empresa, compare os arquivos: `fc.exe /n captura1.prn captura2.prn`.
4. **Resultado esperado:** poucas linhas diferentes.
5. **Interpretação:** as diferenças mostram onde cada dado entra no ZPL. Se só mudam os valores de `^FN`, o modelo está na impressora (H6).
6. **Riscos e precauções:** os mesmos do X4, duas vezes.

## X7. Impressão física de teste

1. **Objetivo:** confirmar que um arquivo ZPL imprime igual à etiqueta original.
2. **Hipótese:** uma solução própria consegue reproduzir a etiqueta.
3. **Procedimento:**
   1. Use uma impressora de teste, ou um horário combinado, com etiquetas de teste.
   2. Rode `analisar-captura.ps1` no arquivo e confira que ele **não** tem `^JUS`, `^DF` nem `~DG`, que mudam a configuração ou a memória da impressora.
   3. Impressora de rede: `ferramentas/enviar-arquivo.ps1 -Arquivo <arquivo> -Destino <IP> -PermitirRede`. Impressora USB: a TI pode compartilhá-la no PC de teste e usar `copy /b <arquivo> \\localhost\<compartilhamento>`.
   4. Compare a etiqueta impressa com uma original e leia o código de barras com o leitor da empresa.
4. **Resultado esperado:** etiqueta igual e código de barras legível.
5. **Interpretação:** se ficar igual, a geração de ZPL está certa. Diferenças de posição costumam vir de resolução (dpi) ou origem (`^LH`) diferentes.
6. **Riscos e precauções:** gasta etiquetas e ribbon. Não use a impressora de produção em horário de operação.
