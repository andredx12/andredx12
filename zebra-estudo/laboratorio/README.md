# Laboratório de ZPL

Para aprender ZPL e o caminho de uma impressão **em casa ou em qualquer computador com Windows**, sem impressora e sem dados da empresa. Tudo aqui é fictício.

## Exemplos

| Arquivo | O que mostra |
|---|---|
| [`01-etiqueta-simples.zpl`](exemplos/01-etiqueta-simples.zpl) | Etiqueta de 100 × 50 mm com textos, Code 128, QR Code e moldura. Os comentários (`^FX`) explicam cada comando. |
| [`02-modelo-armazenado.zpl`](exemplos/02-modelo-armazenado.zpl) | Modelo gravado na memória da impressora (`^DF`) e usado depois só com os dados (`^XF`). |
| [`03-imagem-bitmap.zpl`](exemplos/03-imagem-bitmap.zpl) | Uma imagem (`^GF`): é assim que chega uma etiqueta que o driver transformou em bitmap. |

## Roteiro

Abra duas janelas do PowerShell na pasta `zebra-estudo\ferramentas`.

1. **Janela 1:** ligue a impressora virtual.

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\impressora-virtual.ps1
   ```

2. **Janela 2:** "imprima" o exemplo 1.

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\enviar-arquivo.ps1 -Arquivo ..\laboratorio\exemplos\01-etiqueta-simples.zpl
   ```

   Na janela 1 aparece algo como `647 bytes recebidos, linguagem provavel: ZPL -> 20261021-101500-123.prn`. Isso é tudo que uma impressão RAW faz: abrir uma conexão na porta 9100, mandar os bytes e fechar.

3. **Analise a captura**, que fica em `ferramentas\capturas`:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\analisar-captura.ps1 -Arquivo .\capturas\<arquivo>.prn
   ```

   O analisador também lê os exemplos direto, sem passar pela impressora virtual.

4. **Veja a etiqueta desenhada:** cole o ZPL no visualizador online do Labelary (labelary.com/viewer.html).

   > ⚠️ Só com dados fictícios. O Labelary é um serviço externo: nunca envie para ele dados ou capturas da empresa.

## Exercícios

1. Mude `^PW` e `^LL` do exemplo 1 para uma etiqueta de 60 × 40 mm a 203 dpi. Quantos pontos dá? (Dica: `pontos = mm ÷ 25,4 × dpi`.)
2. Troque o Code 128 (`^BC`) por um EAN-13 (`^BE`). O que muda nos dados aceitos? (Dica: EAN-13 só aceita números; procure como a impressora trata o dígito verificador.)
3. Faça a impressora repetir a etiqueta 3 vezes sem enviar o formato 3 vezes.
4. Rode o analisador no exemplo 2 e explique, com suas palavras, por que o formato 1 não imprime nada.
5. Compare os resumos dos exemplos 1 e 3. Como o analisador percebe que uma etiqueta "virou imagem"?
6. Desafio: escreva do zero o ZPL de uma etiqueta de expedição (destinatário, número do pedido e código de barras) e confira no Labelary.

## Testes

Para confirmar que as ferramentas funcionam no PowerShell do seu computador:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ..\testes\testar-ferramentas.ps1
```
