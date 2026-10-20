# Estudo: sistema de impressão Zebra

Material de apoio para entender, com testes autorizados, como a empresa imprime etiquetas em impressoras Zebra.

> ⚠️ **Este repositório é público.** Não coloque aqui relatórios, prints, modelos de etiqueta nem qualquer dado da empresa. Guarde as evidências em um local privado.

## Etapa 1: identificação

O script [`etapa1/coletar-etapa1.ps1`](etapa1/coletar-etapa1.ps1) faz um levantamento **somente leitura** no computador que imprime as etiquetas.

| O que ele lê | Perguntas que responde |
|---|---|
| Versão do Windows e se a sessão é local ou remota (RDP/Citrix) | D1, C1 |
| Programas instalados ligados a etiquetas, impressão, ERP ou acesso remoto (nome, versão, fabricante, pasta) | A1, A2, A3 |
| Programas com janela aberta, incluindo o de etiquetas se estiver aberto | A1, A4 |
| Processos e serviços relacionados rodando em segundo plano | A4 |
| Impressoras: driver, porta, tipo provável de conexão, resolução do driver | B1, C1, C2 |
| Portas de rede das impressoras: porta TCP e protocolo (RAW/LPR), com o endereço mascarado | C1 |
| Drivers: fabricante e versão | C2 |
| Dispositivos Zebra ligados por USB (código de fabricante `0A5F`) | B1, C1 |

O que ele **não** faz: não imprime, não envia nada para a impressora, não acessa a rede, não altera configurações e não abre arquivos de modelos ou de configuração.

No fim do relatório há as perguntas que só uma pessoa consegue responder (tipo de etiqueta, campos preenchidos, ribbon etc.).

### Como rodar

1. **Peça autorização** ao gestor ou à TI. Se quiserem, mostre o script: é texto puro e dá para ler tudo.
2. Salve `coletar-etapa1.ps1` no computador que imprime as etiquetas, por exemplo na Área de Trabalho. Se copiar o conteúdo para o Bloco de Notas, salve com o tipo **Todos os arquivos** para não virar `.ps1.txt`.
3. **Abra o programa de etiquetas** e deixe-o aberto, sem imprimir nada.
4. Abra o **Windows PowerShell** pelo menu Iniciar e rode:

   ```powershell
   cd ([Environment]::GetFolderPath('Desktop'))
   powershell -NoProfile -ExecutionPolicy Bypass -File .\coletar-etapa1.ps1
   ```

   O `-ExecutionPolicy Bypass` vale só para essa execução e não muda nenhuma configuração do Windows. Se a política da empresa ou o antivírus bloquear o script, **não tente contornar**: peça para a TI rodar ou responda às perguntas da Etapa 1 manualmente.
5. O arquivo `relatorio-etapa1.txt` abre no Bloco de Notas. **Revise**, responda à seção 10 e cole o conteúdo no chat, junto com os prints, se tiver.

Opções:

- `-TodosOsProgramas`: lista todos os programas instalados, útil se o sistema de etiquetas tiver um nome que o script não reconhece.
- `-SemMascara`: não oculta IPs, nomes e números de série. Use só para guardar uma cópia para você e não compartilhe essa versão.
- `-Saida <caminho>`: salva o relatório em outro lugar.

Requer PowerShell 3.0 ou mais recente (já vem no Windows 8, 10 e 11).

### Privacidade

Por padrão, o relatório mascara IPs, nomes de servidores, nome do computador, usuário, domínio e números de série dos dispositivos. Mesmo assim, **revise antes de enviar**: nomes de impressoras e de programas internos podem identificar a empresa.
