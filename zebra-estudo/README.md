# Estudo: sistema de impressão Zebra

Material de apoio para entender, com testes autorizados, como a empresa imprime etiquetas em impressoras Zebra.

> ⚠️ **Este repositório é público.** Não coloque aqui relatórios, capturas, prints, modelos de etiqueta nem qualquer dado da empresa. O [`.gitignore`](.gitignore) desta pasta bloqueia capturas e relatórios, mas guarde as evidências em um local privado.

## Onde estamos

| Etapa | Status |
|---|---|
| 1. Identificação | **Quase concluída**: faltam versão do Windows, driver e porta |
| 2. Mapeamento | **Próxima**: observar uma impressão real ([X2](docs/experimentos.md#x2-observar-uma-impressão-real)) |
| 3. Investigação técnica | Não iniciada. Ferramentas prontas |
| 4. Experimentos | Não iniciada. [Catálogo preliminar](docs/experimentos.md) pronto |
| 5. Solução própria | Só depois de entender o sistema atual |
| 6. Documentação | Em andamento, [veja abaixo](#documentação-do-estudo) |

## Conteúdo

```
zebra-estudo/
├── etapa1/coletar-etapa1.ps1        levantamento somente leitura (Etapa 1)
├── ferramentas/
│   ├── analisar-captura.ps1         resume uma captura sem expor os dados
│   ├── impressora-virtual.ps1       finge ser impressora e salva o que recebe
│   └── enviar-arquivo.ps1           envia um arquivo pela porta 9100 (só local, por padrão)
├── laboratorio/                     exemplos de ZPL e exercícios, com dados fictícios
├── docs/
│   ├── glossario.md                 conceitos técnicos com exemplos
│   ├── hipoteses.md                 o que pode ser verdade e como confirmar
│   └── experimentos.md              experimentos com objetivo, procedimento e riscos
└── testes/testar-ferramentas.ps1    testa as ferramentas com dados fictícios
```

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

## Ferramentas para as próximas etapas

Prontas, mas para usar só quando chegarmos lá (ou no [laboratório](laboratorio/README.md), com dados fictícios):

| Ferramenta | Para quê |
|---|---|
| [`analisar-captura.ps1`](ferramentas/analisar-captura.ps1) | Lê um trabalho capturado (ZPL, EPL ou CPCL) e mostra tamanho da etiqueta, campos, configurações, uso da memória da impressora e indícios. Os dados das etiquetas saem mascarados. |
| [`impressora-virtual.ps1`](ferramentas/impressora-virtual.ps1) | Escuta na porta 9100 deste computador e salva cada trabalho recebido, sem imprimir. |
| [`enviar-arquivo.ps1`](ferramentas/enviar-arquivo.ps1) | Envia um arquivo pela porta 9100. Por padrão, só para este computador; impressora de verdade exige `-PermitirRede` e confirmação. |

## Documentação do estudo

| Documento | Status |
|---|---|
| [Glossário](docs/glossario.md) | iniciado |
| [Hipóteses](docs/hipoteses.md) | 10 hipóteses; o status fica no registro privado |
| [Experimentos](docs/experimentos.md) | catálogo preliminar |
| Evidências coletadas | **fora deste repositório**, em local privado |
| Diagrama do processo atual | depende da Etapa 2 |
| Inventário de funcionalidades | depende da Etapa 2 |
| Arquitetura identificada | depende da Etapa 3 |
| Proposta de arquitetura e plano de testes | Etapa 5 |

## Regras de trabalho

- Nada muda na produção sem autorização; prefira o que é reversível.
- Relatórios e capturas ficam no computador da empresa. No chat ou no GitHub, só resumos mascarados.
- Serviços online, como o Labelary, só com dados fictícios.
- Nada de contornar licenças, senhas ou bloqueios de segurança.
