# Arquitetura do opencode-key-router

Roteador de chaves/perfis para os servidores MCP e providers do [opencode](https://opencode.ai), que permite alternar entre contas (ex.: `SamukDantas` e `IversoSolucao`) sem editar o `opencode.json`.

## Visão geral

O sistema é organizado em três camadas, com separação rígida entre **segredos** (arquivos gitignored) e **config** (versionável, sem tokens):

1. **Seleção e injeção de segredos** — o script `switch-profile.ps1` lê os perfis, pergunta ao usuário qual conta usar e seta as variáveis de ambiente antes de abrir o opencode.
2. **Config sem segredos** — o `opencode.json` referencia os valores via `{env:VARIAVEL}`, sem conter nenhum token.
3. **Runtime** — o opencode consome o config e as env vars, disparando os servidores MCP e o provider de modelo.

## Diagrama de fluxo

```mermaid
flowchart TD
    subgraph L1["1 · Seleção e injeção de segredos (shell)"]
        USER(["Usuário"]) --> SCRIPT["scripts/switch-profile.ps1"]
        SCRIPT --> PROF[("keys/profiles.json<br/>(gitignored)")]
        SCRIPT --> SHARED[("keys/shared.json<br/>(gitignored)")]
        SCRIPT --> MENU{"Menu<br/>[1] Samuk Dantas<br/>[2] IversoSolucao"}
        MENU -->|"id inválido"| ERR["exit 1"]
        MENU -->|"id válido"| ENV["Variáveis de ambiente<br/>GITHUB_TOKEN · OPENCODE_API_KEY<br/>SUPABASE_ACCESS_TOKEN · RESEND_API_KEY · ..."]
    end

    subgraph L2["2 · Config sem segredos"]
        CFG[("opencode.json<br/>refs {env:VARIAVEL}")]
    end

    subgraph L3["3 · Runtime opencode"]
        OC(["opencode"])
        MCP["Servidores MCP<br/>github · supabase · resend · newrelic<br/>grafana · upstash · testsprite · context7"]
        GO["Provider OpenCode Go<br/>(OPENCODE_API_KEY)"]
    end

    subgraph EXT["Externo"]
        SRV["GitHub · Supabase · Resend · New Relic<br/>Grafana · Upstash · TestSprite · Context7"]
        VERCEL["Vercel — auth via CLI (manual)"]
    end

    ENV --> OC
    OC --> CFG
    CFG -->|"environment: {env:VAR}"| MCP
    OC -->|"lê OPENCODE_API_KEY (nativo)"| GO
    MCP --> SRV
    GO --> SRV
    VERCEL -.->|"vercel login / switch"| OC
```

## Diagrama de sequência

```mermaid
sequenceDiagram
    participant U as Usuário
    participant S as switch-profile.ps1
    participant K as profiles.json + shared.json
    participant O as opencode
    participant C as opencode.json
    participant M as Servidores MCP
    participant G as Provider OpenCode Go
    participant E as Serviços externos

    U->>S: pwsh -File switch-profile.ps1
    S->>K: lê perfis + chaves shared
    S->>U: exibe menu [1] / [2]
    U->>S: escolhe perfil
    S->>S: seta $env:* (github_token + env + shared)
    S->>O: executa opencode
    O->>C: lê config ({env:VARIAVEL})
    O->>M: spawn com environment resolvido
    M->>E: autentica (GitHub, Supabase, ...)
    O->>G: lê OPENCODE_API_KEY
    G->>E: autentica (opencode.ai/zen)
```

## Decisões de arquitetura

| Decisão | Justificativa |
|---|---|
| Segredos fora do `opencode.json` | Config versionável sem expor tokens; `keys/` gitignored |
| `{env:VAR}` como contrato | Desacopla "quem define a chave" (script) de "quem a consome" (opencode/MCP) |
| Perfil = identidade completa | Um `switch-profile.ps1` resolve tudo (MCPs + provider + git) |
| `shared.json` separado | Chaves comuns aos perfis (ex.: Context7) — evita duplicação |
| Vercel fora do roteador | Auth é via CLI (`vercel login`/`vercel switch`), não env var — exceção explícita |
| Fallback `{file:}` | Plano B documentado caso `{env:}` falhe em `provider.options` |

## Estrutura de arquivos

```
opencode.json                 # config com {env:} (sem segredos)
scripts/switch-profile.ps1    # menu + carregamento dos perfis
keys/profiles.json            # (NÃO versionado) perfis com tokens reais
keys/profiles.example.json    # template de exemplo
keys/shared.json              # (NÃO versionado) chaves compartilhadas
keys/shared.example.json      # template de exemplo
```

## Segurança

- Os arquivos reais de chaves (`keys/profiles.json` e `keys/shared.json`) estão no `.gitignore` e **nunca** devem ser commitados.
- Se qualquer token for exposto, **rotacione-o** no painel do serviço e atualize o arquivo correspondente.
- Mantenha este repositório **privado**.
