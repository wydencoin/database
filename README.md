# database — WydenCoin

Esquema do banco (Supabase/Postgres 16), migrações e dados de exemplo. Responsável: **Luiz Felipe** (até dezembro), depois **Henrique**.

## Tabelas
| Grupo | Tabelas |
| --- | --- |
| Pessoas | `campus`, `usuarios` (liga ao login), `alunos` (matrícula), `carteiras` |
| Regras e emissões | `regras`, `extracoes`, `indicadores`, `emissoes` (única por aluno + regra + ciclo) |
| Catálogo | `parceiros`, `beneficios`, `resgates` (código de voucher gerado automaticamente) |
| ESG | `acoes_esg`, `participacoes_esg` |
| Blockchain | `eventos_blockchain` (preenchida pelo indexador da API) |

RLS ligado: o aluno logado só lê o que é dele; a API e o motor usam a *service role*.

## Rodar
```bash
npm i -g supabase          # ou: brew install supabase/tap/supabase
supabase init              # cria supabase/config.toml (só na primeira vez)
supabase start             # Postgres local em Docker
supabase db reset          # aplica migrations/ e seed.sql
```
Nova mudança no banco = **nova migração** (`supabase migration new <nome>`), nunca editar uma migração já aplicada.

**Nunca coloque matrículas reais em `seed.sql`.**
