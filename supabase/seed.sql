-- Dados de exemplo para desenvolvimento. NUNCA colocar matrículas reais aqui.
insert into campus (nome) values ('FACI Wyden — Belém');

insert into regras (codigo, descricao, eixo, frequencia, valor_wc) values
  ('SIA_15D',     'Acessou o SIA nos últimos 15 dias',                       'ACADEMICO', 'CICLO',    20),
  ('SAVA_15D',    'Acessou o ambiente virtual nos últimos 15 dias',          'ACADEMICO', 'CICLO',    20),
  ('PRES_100',    'Presença de 100% nas últimas 2 semanas',                  'ACADEMICO', 'CICLO',    40),
  ('PRES_60',     'Presença entre 60% e 99% nas últimas 2 semanas',          'ACADEMICO', 'CICLO',    20),
  ('DIG_ESTUDO',  'Aluno digital acessou o ambiente virtual em 15 dias',     'ACADEMICO', 'CICLO',    40),
  ('SIM_FEZ',     'Fez o simulado',                                          'ACADEMICO', 'EVENTO',  100),
  ('SIM_PARCIAL', 'Fez parte do simulado',                                   'ACADEMICO', 'EVENTO',   50),
  ('CR_9',        'CR do período anterior a partir de 9',                    'ACADEMICO', 'SEMESTRE',150),
  ('CR_8',        'CR do período anterior de 8 a 8,99',                      'ACADEMICO', 'SEMESTRE',100),
  ('CR_7',        'CR do período anterior de 7 a 7,99',                      'ACADEMICO', 'SEMESTRE', 50),
  ('VOLTOU',      'Estava há mais de 30 dias sem acesso e voltou',           'ACADEMICO', 'CICLO',    50),
  ('PRES_SUBIU',  'Subiu de faixa de presença em relação ao ciclo anterior', 'ACADEMICO', 'CICLO',    20);

insert into parceiros (nome, campus_id) values ('Cantina', 1), ('Financeiro', 1), ('Coordenação', 1);

insert into beneficios (nome, preco_wc, quantidade_total, limite_por_aluno_mes, validade_dias, parceiro_id, confirmador_tipo, campus_id) values
  ('Voucher de 20% na cantina',                 100, 30,   2,    15, 1, 'cantina',    1),
  ('Mentoria de 1 hora',                        200, null, 1,    30, 3, 'mentor',     1),
  ('Desconto em ingresso de cinema',            250, 20,   1,    30, 3, 'parceiro',   1),
  ('Kit agenda, caneta e brindes',              300, 25,   1,    30, 3, 'admin',      1),
  ('Voucher de 100% no AWS Community Day',      400, 10,   1,    60, 3, 'evento',     1),
  ('Desconto na mensalidade (não bolsistas)',   800, 5,    1,    60, 2, 'financeiro', 1);

insert into alunos (matricula, campus_id, curso, modalidade) values
  ('TESTE0001', 1, 'SISTEMAS DE INFORMACAO', 'PRESENCIAL'),
  ('TESTE0002', 1, 'SISTEMAS DE INFORMACAO', 'DIGITAL');
