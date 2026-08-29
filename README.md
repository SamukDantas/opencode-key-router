# opencode-key-router

Roteador de chaves/perfis para os servidores MCP do [opencode](https://opencode.ai), que permite alternar entre contas (ex.: `SamukDantas` e `IversoSolucao`) sem editar o `opencode.json`.

## Como funciona

O `opencode.json` não contém nenhuma chave em texto puro — todos os segredos são referenciados via `{env:VARIAVEL}`. Quem fornece os valores é o script `scripts/switch-profile.ps1`, que carrega um perfil e seta as variáveis de ambiente antes de abrir o opencode.

```
switch-profile.ps1
   ├─ lê keys/profiles.json   (perfis: github_token + env)
   ├─ lê keys/shared.json     (chaves compartilhadas entre perfis)
   ├─ seta $env:* no processo
   └─ executa opencode
```

## Estrutura

```
opencode.json                 # config com {env:} (sem segredos)
scripts/switch-profile.ps1    # menu + carregamento dos perfis
keys/profiles.json            # (NÃO versionado) perfis com tokens reais
keys/profiles.example.json    # template de exemplo
keys/shared.json              # (NÃO versionado) chaves compartilhadas
keys/shared.example.json      # template de exemplo
```

## Uso

```powershell
pwsh -File scripts/switch-profile.ps1

Selecione o perfil:
[1] Samuk Dantas
[2] Iverso Solução
Opcao: 2
```

## Adicionando um perfil/account

1. Copie `keys/profiles.example.json` para `keys/profiles.json` (se ainda não existir).
2. Adicione uma entrada em `profiles` com `id`, `label`, `github_token`, `git_name`, `git_email` e o bloco `env` (chaves dos serviços).
3. Chaves compartilhadas entre todos os perfis ficam em `keys/shared.json`.

### Serviços com chave por perfil

| Serviço | Variável de ambiente |
|---|---|
| GitHub | `GITHUB_TOKEN` |
| Supabase | `SUPABASE_ACCESS_TOKEN` |
| Resend | `RESEND_API_KEY` |
| New Relic | `NEWRELIC_API_KEY`, `NEWRELIC_ACCOUNT_ID` |
| Grafana | `GRAFANA_SERVICE_ACCOUNT_TOKEN` |
| Upstash | `UPSTASH_API_KEY`, `UPSTASH_EMAIL` |
| TestSprite | `TESTSPRITE_API_KEY` |
| OpenCode Go | `OPENCODE_API_KEY` |

### Compartilhados (não alternam)

| Serviço | Variável |
|---|---|
| Context7 | `CONTEXT7_API_KEY` |

> **Vercel**: a autenticação é via CLI (`vercel login` / `vercel switch`), não por variável de ambiente — troque manualmente ao alternar de conta.

> **OpenCode Go**: autentique o provider via env var `OPENCODE_API_KEY`. Se o Go estiver salvo no auth store (`/connect`), remova com `opencode auth logout` para a env var assumir.

## Segurança

- Os arquivos reais de chaves (`keys/profiles.json` e `keys/shared.json`) estão no `.gitignore` e **nunca** devem ser commitados.
- Se qualquer token for exposto, **rotacione-o** no painel do serviço e atualize o arquivo correspondente.
- Mantenha este repositório **privado**.
