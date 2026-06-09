# Guia de Uso: Integração com Editor & Geração de Código

Este guia detalha como utilizar os recursos do **RadIA** integrados ao editor de código do Embarcadero Delphi, bem como as ferramentas de geração automática de DTOs, documentação e projetos completos.

---

## 1. Ações de Contexto no Editor

O RadIA conecta-se nativamente ao editor de código do Delphi usando a Open Tools API (OTA). Você pode acionar a inteligência artificial para trechos específicos de código diretamente no editor.

### Como Utilizar:
1. No editor de código da IDE, **selecione** o trecho de código que deseja analisar ou modificar.
2. Clique com o **botão direito** sobre a seleção.
3. No menu pop-up, navegue até a categoria **RadIA** e selecione uma das seguintes ações:
   * **Explicar Código Selecionado (`/explain`):** Analisa didaticamente a lógica, explicando o fluxo de execução e a finalidade de algoritmos complexos.
   * **Otimizar/Refatorar (`/refactor`):** Reescreve o código visando performance, legibilidade e aplicação de padrões Clean Code e SOLID.
   * **Localizar Bugs (`/bugs`):** Executa uma varredura em busca de memory leaks (ausência de try..finally), exceções não tratadas e falhas de lógica.
   * **Gerar Testes Unitários (`/test`):** Gera automaticamente classes e métodos de testes estruturados baseados no framework DUnitX.

---

## 2. Comparador Visual Inteligente (Smart Diff)

Quando você solicita refatorações ou otimizações de código, o RadIA não altera seu arquivo original imediatamente. Ele apresenta as alterações em uma interface comparativa premium lado a lado.

<p align="center">
  <img src="images/radia_diff_ui_mockup.png" alt="RadIA Smart Diff UI" width="90%" />
</p>

### Funcionamento e Fluxo:
* **Visualização Lado a Lado**: A janela do Smart Diff exibe o código original à esquerda (com destaque vermelho para deleções) e a proposta de código da IA à direita (com destaque verde para adições).
* **Botão [Aplicar Alteração]**: Ao clicar neste botão presente na parte inferior do comparador, o RadIA substitui cirurgicamente o trecho de código correspondente direto no editor da IDE do Delphi.
* **Segurança**: Caso desista das alterações, basta fechar o painel de comparação. O arquivo original permanecerá intocado.

---

## 3. Geração Automática de Documentação XML

O RadIA permite documentar classes e métodos seguindo o padrão XML padrão do Delphi, alimentando diretamente o recurso **Help Insight** da IDE (exibição de dicas de documentação ao posicionar o mouse sobre um método).

### Como Utilizar:
1. Posicione o cursor sobre o cabeçalho de um método ou propriedade (na interface ou implementation).
2. Clique com o botão direito e escolha **RadIA -> Documentação XML Automática** (ou digite `/doc` no chat lateral).
3. A IA gerará a estrutura XML e o RadIA a inserirá logo acima do método correspondente.

### Exemplo de Saída:
```pascal
/// <summary>
///   Calcula o total de vendas do período aplicando descontos e impostos locais.
/// </summary>
/// <param name="AStartDate">Data de início da apuração</param>
/// <param name="AEndDate">Data final da apuração</param>
/// <returns>Valor total calculado em moeda corrente</returns>
function CalculatePeriodTotal(const AStartDate, AEndDate: TDateTime): Currency;
```

---

## 4. Conversor de DTO e Modelos

Escrever classes de transferência de dados (DTOs) ou mapeamentos ORM manualmente a partir de payloads JSON ou tabelas de bancos de dados consome muito tempo. O RadIA automatiza isso.

### Como Utilizar:
1. Cole o payload JSON ou o script DDL SQL no chat lateral.
2. Utilize o comando barra `/dto [formato]` (ex: `/dto vanilla` ou `/dto dext`).
3. Formatos Suportados:
   * **Vanilla Delphi**: Classes puras Pascal com getters/seters convencionais e propriedades.
   * **DEXT ORM**: Modelagem de entidades prontas para persistência usando atributos do framework DEXT.
   * **TMS Aurelius**: Classes mapeadas usando atributos específicos do framework Aurelius.
   * **REST.Json**: Classes com anotações de conversão do framework nativo REST de manipulação de JSON do Delphi.

---

## 5. Geração de Projetos Delphi Inteiros via Prompt

Uma das ferramentas mais poderosas do RadIA é a habilidade de estruturar e salvar um projeto Delphi do zero a partir de uma descrição textual informal no chat.

### Como Utilizar:
1. No chat lateral do RadIA, solicite a criação de um projeto. Exemplo:
   > *"Gere um projeto de console que consuma uma API de clima e salve as informações em arquivos JSON locais."*
   *(Você também pode utilizar o comando barra `/createproject` ou `/createprojectarch` para estruturas seguindo Clean Architecture).*
2. A IA processará a requisição e retornará a lista completa de arquivos estruturados (projeto `.dpr`, configurações `.dproj`, unidades de lógica `.pas` e telas `.dfm`).
3. O RadIA exibirá um painel com estilo *glassmorphism* contendo a lista dos arquivos gerados.
4. **Fluxo de Gravação**:
   * Clique em **Gerar Arquivos** na UI do chat.
   * Um diálogo nativo do Windows será exibido para você selecionar a pasta de destino.

> [!IMPORTANT]
> **Gravação Segura de Projetos:**
> Por medidas de segurança e para evitar sobregravações acidentais de código existente, a pasta selecionada para a geração do projeto **deve estar totalmente vazia**. O RadIA bloqueará o processo de gravação física no disco caso a pasta possua quaisquer outros arquivos.

5. **Abertura na IDE**: Assim que a gravação é concluída com sucesso, o RadIA aciona a Open Tools API e **carrega o novo projeto gerado automaticamente** na IDE do Delphi, pronto para compilação.
