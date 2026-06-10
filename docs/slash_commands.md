# Comandos de Barra (Slash Commands) do Rad IA

O Rad IA suporta atalhos rápidos de comandos diretamente no chat, facilitando a execução de tarefas comuns sem a necessidade de digitar prompts extensos ou usar o mouse.

---

## Como Utilizar

Basta digitar o caractere `/` na caixa de entrada do chat. Um menu flutuante surgirá abaixo do campo de digitação, permitindo selecionar o comando desejado com as setas `↑`/`↓` do teclado e pressionar `Enter` para inseri-lo.

---

## Tabela de Comandos Disponíveis

| Comando | Descrição | Contexto Automático da IDE |
| :--- | :--- | :--- |
| `/explain` | Analisa e explica didaticamente a lógica do código selecionado no editor. | Envia o trecho de código selecionado. |
| `/refactor` | Otimiza a performance, legibilidade e aplica boas práticas (Clean Code/SOLID) no código selecionado. | Envia o trecho de código selecionado. |
| `/bugs` | Varre o código selecionado em busca de memory leaks, tratamento incorreto de exceções e erros de lógica. | Envia o trecho de código selecionado. |
| `/doc` | Gera comentários de documentação no formato XML (`/// <summary>`) compatível com o Delphi Help Insight. | Envia a assinatura do método selecionado. |
| `/template` | Abre o menu flutuante de biblioteca de templates para escolha de prompts reutilizáveis. | — |
| `/stacktrace` | Analisa logs de erro ou exceções (MadExcept, EurekaLog ou RTL) e aponta a causa raiz na unit ativa. | Envia o texto da unit aberta no editor como referência de código para a linha do erro. |
| `/review` | Executa uma análise estática abrangente de toda a unit ativa em busca de memory leaks (falta de try..finally) e anti-padrões. | Envia o código completo do arquivo ativo no editor. |
| `/createproject` | Cria um projeto Delphi vanilla completo no disco e o carrega na IDE com base em uma especificação textual. | — |
| `/createprojectarch` | Cria um projeto Delphi baseado em arquitetura limpa (SOLID) no disco e o carrega na IDE com base em especificação. | — |

---

## Customização e Backups de Comandos

O Rad IA permite que você edite, exclua ou adicione novos comandos e templates de prompts diretamente nas opções do plugin na IDE (`Tools -> Options -> Rad IA -> Templates`).

Cada template cadastrado pode especificar:
- **Slash Command**: O comando que acionará o template diretamente no chat (ex: `/explain`).
- **Is Project Generator**: Um indicador se aquele template gera um projeto físico compilável no disco.
- **Importação/Exportação**: Você pode exportar seus templates para arquivos JSON e importá-los em outras máquinas de forma transacional, mesclando com os existentes ou substituindo-os.

