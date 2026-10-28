-- WydenCoin — esquema inicial (v0)
-- Regra de ouro (LGPD): dados pessoais ficam aqui; na blockchain só endereço, valor e código de motivo.

create extension if not exists pgcrypto;

-- ---------- Cadastros base ----------
create table campus (
  id          smallserial primary key,
  nome        text not null unique,
  criado_em   timestamptz not null default now()
);

create type modalidade as enum ('PRESENCIAL', 'DIGITAL');
create type perfil as enum ('aluno', 'admin', 'confirmador');

-- Um registro por pessoa que entra no sistema (ligado ao login do Supabase Auth)
create table usuarios (
  id          uuid primary key references auth.users (id) on delete cascade,
  perfil      perfil not null default 'aluno',
  campus_id   smallint references campus (id),
  criado_em   timestamptz not null default now()
);

create table alunos (
  matricula   text primary key,                       -- vem da planilha (COD_MATRICULA)
  usuario_id  uuid unique references usuarios (id),   -- preenchido quando o aluno faz o primeiro login
  campus_id   smallint not null references campus (id),
  curso       text not null,
  modalidade  modalidade not null,
  criado_em   timestamptz not null default now()
);

-- Carteira custodial no piloto: a chave privada NUNCA fica aqui em texto puro.
create table carteiras (
  aluno_matricula text primary key references alunos (matricula) on delete cascade,
  endereco        text not null unique check (endereco ~ '^0x[0-9a-fA-F]{40}$'),
  tipo            text not null default 'custodial' check (tipo in ('custodial', 'externa')),
  criada_em       timestamptz not null default now()
);

-- ---------- Regras e emissões ----------
create type eixo as enum ('ACADEMICO', 'ESG');
create type frequencia as enum ('CICLO', 'EVENTO', 'SEMESTRE');

create table regras (
  codigo      text primary key check (codigo ~ '^[A-Z0-9_]{2,31}$'),  -- cabe em bytes32 (motivo no contrato)
  descricao   text not null,
  eixo        eixo not null,
  frequencia  frequencia not null,
  valor_wc    integer not null check (valor_wc >= 0),
  ativa       boolean not null default true,
  atualizada_em timestamptz not null default now()
);

-- Cada planilha importada vira uma extração
create table extracoes (
  id              bigserial primary key,
  campus_id       smallint not null references campus (id),
  data_referencia date not null,           -- data em que a planilha foi gerada
  arquivo_nome    text not null,
  importada_por   uuid references usuarios (id),
  importada_em    timestamptz not null default now(),
  status          text not null default 'importada' check (status in ('importada', 'calculada', 'aprovada', 'emitida', 'erro'))
);

-- Linha normalizada da planilha (uma por aluno por extração)
create table indicadores (
  extracao_id            bigint not null references extracoes (id) on delete cascade,
  matricula              text not null references alunos (matricula),
  cr_periodo_anterior    numeric(4,2),
  dt_ult_acesso          date,
  dt_ult_acesso_app      date,
  dt_ult_acesso_sava     date,
  dt_ult_acesso_sia      date,
  perc_presenca_2_sem    numeric(5,4),     -- null = não se aplica (ex.: digital)
  adesao_sm_online       text check (adesao_sm_online in ('SIM', 'PARCIAL', 'NAO')),
  adesao_sm1_pres        text check (adesao_sm1_pres  in ('SIM', 'PARCIAL', 'NAO')),
  adesao_sm2_pres        text check (adesao_sm2_pres  in ('SIM', 'PARCIAL', 'NAO')),
  tempo_estudo           numeric,          -- reservado: aguardando a coordenação
  primary key (extracao_id, matricula)
);

create type status_emissao as enum ('calculada', 'aprovada', 'enviada', 'confirmada', 'falhou');

create table emissoes (
  id            bigserial primary key,
  matricula     text not null references alunos (matricula),
  regra_codigo  text not null references regras (codigo),
  ciclo         text not null,             -- ex.: '2026-10-B' (segunda quinzena) ou id do simulado/semestre
  valor_wc      integer not null check (valor_wc > 0),
  extracao_id   bigint references extracoes (id),
  status        status_emissao not null default 'calculada',
  tx_hash       text,
  criada_em     timestamptz not null default now(),
  -- idempotência: a mesma regra nunca paga duas vezes o mesmo aluno no mesmo ciclo
  unique (matricula, regra_codigo, ciclo)
);

-- ---------- Catálogo e resgates ----------
create table parceiros (
  id          serial primary key,
  nome        text not null,
  contato     text,
  campus_id   smallint references campus (id)
);

create table beneficios (
  id                 serial primary key,
  nome               text not null,
  descricao          text,
  preco_wc           integer not null check (preco_wc > 0),
  quantidade_total   integer check (quantidade_total >= 0),   -- null = sem limite
  limite_por_aluno_mes integer check (limite_por_aluno_mes > 0),
  validade_dias      integer not null default 30 check (validade_dias > 0),
  parceiro_id        integer references parceiros (id),
  confirmador_tipo   text not null check (confirmador_tipo in ('cantina', 'financeiro', 'mentor', 'evento', 'admin', 'parceiro')),
  campus_id          smallint references campus (id),
  ativo              boolean not null default true,
  criado_em          timestamptz not null default now()
);

create type status_resgate as enum ('RESGATADO', 'UTILIZADO', 'CANCELADO', 'EXPIRADO');

create table resgates (
  id               bigserial primary key,
  matricula        text not null references alunos (matricula),
  beneficio_id     integer not null references beneficios (id),
  valor_wc         integer not null check (valor_wc > 0),
  codigo_voucher   text not null unique default upper(substr(encode(gen_random_bytes(6), 'hex'), 1, 8)),
  status           status_resgate not null default 'RESGATADO',
  onchain_id       numeric,              -- id do resgate no RedemptionManager
  tx_hash          text,
  confirmado_por   uuid references usuarios (id),
  criado_em        timestamptz not null default now(),
  expira_em        timestamptz not null,
  atualizado_em    timestamptz not null default now()
);
create index on resgates (matricula, status);

-- ---------- Eixo ESG (Ericka) ----------
create table acoes_esg (
  id           serial primary key,
  nome         text not null,
  ods          smallint[] not null,
  regra_codigo text not null references regras (codigo),
  data_acao    date not null,
  organizador  text,
  campus_id    smallint not null references campus (id)
);

create table participacoes_esg (
  acao_id      integer not null references acoes_esg (id) on delete cascade,
  matricula    text not null references alunos (matricula),
  evidencia    text,                     -- ex.: id do check-in por QR code ou caminho da foto no R2
  validada_por uuid references usuarios (id),
  validada_em  timestamptz,
  primary key (acao_id, matricula)
);

-- ---------- Espelho da blockchain (indexador) ----------
create table eventos_blockchain (
  tx_hash       text not null,
  log_index     integer not null,
  bloco         bigint not null,
  contrato      text not null,
  evento        text not null,           -- RewardMinted, Transfer, RedemptionCreated...
  dados         jsonb not null,
  registrado_em timestamptz not null default now(),
  primary key (tx_hash, log_index)
);

-- ---------- Visões úteis ----------
-- Saldo calculado a partir das emissões confirmadas e resgates (a fonte de verdade é a blockchain;
-- esta visão serve para conferência e para o dashboard).
create view saldo_aluno as
select a.matricula,
       coalesce((select sum(valor_wc) from emissoes e where e.matricula = a.matricula and e.status = 'confirmada'), 0) as emitido,
       coalesce((select sum(valor_wc) from resgates r where r.matricula = a.matricula and r.status = 'RESGATADO'), 0) as reservado,
       coalesce((select sum(valor_wc) from resgates r where r.matricula = a.matricula and r.status = 'UTILIZADO'), 0) as utilizado
from alunos a;

-- ---------- Segurança (RLS) ----------
alter table usuarios           enable row level security;
alter table alunos             enable row level security;
alter table carteiras          enable row level security;
alter table emissoes           enable row level security;
alter table resgates           enable row level security;
alter table beneficios         enable row level security;
alter table regras             enable row level security;
alter table indicadores        enable row level security;
alter table extracoes          enable row level security;
alter table participacoes_esg  enable row level security;

-- Aluno logado enxerga só o que é dele; a API usa a service role e não passa pelo RLS.
create policy aluno_ve_proprio_cadastro on alunos     for select using (usuario_id = auth.uid());
create policy aluno_ve_propria_carteira on carteiras  for select using (aluno_matricula in (select matricula from alunos where usuario_id = auth.uid()));
create policy aluno_ve_proprias_emissoes on emissoes  for select using (matricula in (select matricula from alunos where usuario_id = auth.uid()));
create policy aluno_ve_proprios_resgates on resgates  for select using (matricula in (select matricula from alunos where usuario_id = auth.uid()));
create policy todos_veem_catalogo_ativo on beneficios for select using (ativo);
create policy todos_veem_regras_ativas on regras      for select using (ativa);
-- indicadores, extracoes e participacoes_esg: sem política = só a service role (API/motor) acessa.
