^XA
^FX Exemplo do laboratorio: modelo guardado na impressora. Dados ficticios.
^FX ATENCAO: a parte 1 grava um arquivo na memoria da impressora.
^FX Envie so para a impressora virtual, nunca para impressoras da empresa.
^FX Parte 1: grava o modelo PRODUTO.ZPL na memoria R: com dois campos variaveis
^DFR:PRODUTO.ZPL^FS
^PW800
^LL400
^FO40,35^A0N,40,40^FN1^FS
^BY2,3,100
^FO40,150^BCN,100,Y,N,N^FN2^FS
^XZ
^XA
^FX Parte 2: usa o modelo e envia so os valores dos campos
^XFR:PRODUTO.ZPL^FS
^FN1^FDPRODUTO EXEMPLO^FS
^FN2^FD000123456789^FS
^PQ2
^XZ
