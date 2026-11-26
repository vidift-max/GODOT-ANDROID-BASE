# GAME LAB Connect — Godot Editor Plugin

Versão inicial: **0.1.0**  
Compatibilidade pretendida: **Godot 4.7.2** (GDScript / EditorPlugin).

## O que esta versão faz

- Adiciona o painel **GAME LAB Connect** ao dock lateral do editor.
- Mostra a versão do Godot e o caminho do projeto aberto.
- Permite informar o endereço do serviço e um token Bearer.
- Testa a ponte existente do GAME LAB pelo endpoint autenticado `GET /health`.
- Mantém o token somente na memória da sessão do editor; não o grava no projeto nem no Git.

Esta versão **não** cria ou altera cenas, scripts ou recursos. Também não executa comandos arbitrários. Essas funções serão adicionadas depois que o protocolo de operações tipadas estiver implementado e testado.

## Instalação manual

1. Copie a pasta `addons/gamelab_connect` para a pasta `addons/` do seu projeto Godot.
2. Abra o projeto no Godot.
3. Entre em **Project > Project Settings > Plugins**.
4. Ative **GAME LAB Connect**.
5. O painel aparecerá como um dock lateral.

## Conexão com a ponte atual

O plugin consulta `GET /health` e envia:

```http
Authorization: Bearer SEU_TOKEN
Accept: application/json
```

A ponte de simulação existente está documentada em:

- `vidift-max/GAME-LAB/studio/docs/GODOT_BRIDGE.md`
- Endpoint: `GET /health`
- Porta padrão do serviço: `8765`

A ponte atual escuta somente em `127.0.0.1`. Para conectar um tablet a um serviço hospedado em outro computador, será necessário um túnel privado com HTTPS ou uma VPN privada com proxy TLS. Não exponha a porta diretamente à internet.

O plugin bloqueia HTTP em endereços externos. HTTP é permitido somente para `localhost` e `127.0.0.1`.

## Segurança

- Não coloque tokens no código, no arquivo `project.godot`, em commits ou em capturas de tela.
- O token é mantido apenas no campo da interface durante a sessão.
- Use HTTPS para conexões remotas.
- O plugin não envia arquivos do projeto nesta versão.
- A extensão não altera o APK original do Godot.

## Próximas etapas

1. Validar a instalação no Godot 4.7.2 Android.
2. Implementar protocolo de leitura do projeto com escopo limitado.
3. Adicionar prévia e aprovação explícita antes de qualquer escrita.
4. Integrar tarefas autorizadas ao worker GAME LAB.
5. Implementar criação/edição de cenas e scripts com histórico e rollback.
