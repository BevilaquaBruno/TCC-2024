/* EMPENHOS EMITIDOS */


SELECT TOP (100) [Entidade]
      ,[Credor]
      ,[Empenho]
      ,[Espécie]
      ,[Emissão]
      ,[Valor]
      ,[Descrição_Despesa]
  FROM [empenhos_concordia].[dbo].[empenhos_emitidos_2020]
  WHERE [Empenho] = '1 / 2020';


/* EMPENHOS LIQUIDADOS */


SELECT TOP (100) [Entidade]
    ,[Credor]
    ,[Empenho]
    ,[Liquidação]
    ,[Data]
    ,[Valor_Liquidação]
    ,[Espécie]
FROM [empenhos_concordia].[dbo].[empenhos_liquidados_2020]
WHERE [Empenho] = '1-0/2020';


SELECT TOP (100) [Entidade]
	,[Credor]
	,[Empenho]
	,SUM([Valor_Liquidação]) as Valor_Liquidação
FROM [empenhos_concordia].[dbo].[empenhos_liquidados_2020]
WHERE [Empenho] = '1-0/2020'
GROUP BY [Entidade], [Credor], [Empenho];


/* EMPENHOS PAGOS */


SELECT TOP (100) [Entidade]
      ,[Credor]
      ,[Empenho]
      ,[Nº_Ordem]
      ,[Data]
      ,[Valor_Pago]
  FROM [empenhos_concordia].[dbo].[empenhos_pagos_2020]
  WHERE [Empenho] = '1-0/2020';


SELECT TOP (100) [Entidade]
	,[Credor]
	,[Empenho]
	,SUM([Valor_Pago])
FROM [empenhos_concordia].[dbo].[empenhos_pagos_2020]
WHERE [Empenho] = '1-0/2020'
GROUP BY [Entidade] ,[Credor] ,[Empenho];


/* SCRIPT CRIAÇÃO DW */
create table dim_entidade(
	id int IDENTITY PRIMARY KEY,
	descricao varchar(250)
);


create table dim_credor(
	id int IDENTITY PRIMARY KEY,
	descricao varchar(250)
);


create table dim_empenho(
	id int IDENTITY PRIMARY KEY,
	descricao varchar(250)
);


create table dim_especie(
	id int IDENTITY PRIMARY KEY,
	descricao varchar(250)
);


create table dim_descricao_despesa(
	id int IDENTITY PRIMARY KEY,
	descricao varchar(250)
);


create table fato_empenho_geral (
	id int IDENTITY PRIMARY KEY,
	id_dim_entidade int,
	id_dim_credor int,
	id_dim_empenho int,
	id_dim_especie int,
	id_dim_descricao_despesa int,
	dt_emissao date,
	valor_emitido decimal(20,2),
	valor_liquidado decimal(20,2),
	valor_pago decimal(20,2),
	covid bit 
);


ALTER TABLE fato_empenho_geral ADD CONSTRAINT fk_empenho_entidade FOREIGN KEY (id_dim_entidade) REFERENCES dim_entidade(id);
ALTER TABLE fato_empenho_geral ADD CONSTRAINT fk_empenho_credor FOREIGN KEY (id_dim_credor) REFERENCES dim_credor(id);
ALTER TABLE fato_empenho_geral ADD CONSTRAINT fk_empenho_empenho FOREIGN KEY (id_dim_empenho) REFERENCES dim_empenho(id);
ALTER TABLE fato_empenho_geral ADD CONSTRAINT fk_empenho_especie FOREIGN KEY (id_dim_especie) REFERENCES dim_especie(id);
ALTER TABLE fato_empenho_geral ADD CONSTRAINT fk_empenho_descricao_despesa FOREIGN KEY (id_dim_descricao_despesa) REFERENCES dim_descricao_despesa(id);




/* INSERE DADOS NO DW */
/* CRIA A TABELA DE BASE */
CREATE TABLE empenhos_brutos(
	id int IDENTITY(1,1),
	entidade varchar(255),
	credor varchar(255),
	empenho varchar(20),
	especie varchar(10),
	emissao date,
	valor decimal(20, 2),
	descricao varchar(255)
);


INSERT INTO empenhos_brutos
(entidade, credor, empenho, especie, emissao, valor, descricao)
SELECT e20.Entidade, e20.Credor, e20.Empenho, e20.Espécie, e20.Emissão, e20.Valor, e20.Descrição_Despesa FROM empenhos_emitidos_2020 e20


INSERT INTO empenhos_brutos
(entidade, credor, empenho, especie, emissao, valor, descricao)
SELECT e21.Entidade, e21.Credor, e21.Empenho, e21.Espécie, e21.Emissão, e21.Valor, e21.Descrição_Despesa FROM empenhos_emitidos_2021 e21


INSERT INTO empenhos_brutos
(entidade, credor, empenho, especie, emissao, valor, descricao)
SELECT e22.Entidade, e22.Credor, e22.Empenho, e22.Espécie, e22.Emissão, e22.Valor, e22.Descrição_Despesa FROM empenhos_emitidos_2022 e22


INSERT INTO empenhos_brutos
(entidade, credor, empenho, especie, emissao, valor, descricao)
SELECT e23.Entidade, e23.Credor, e23.Empenho, e23.Espécie, e23.Emissão, e23.Valor, e23.Descrição_Despesa FROM empenhos_emitidos_2023 e23




/*INSERT NAS DIMENSÕES */
INSERT INTO dim_entidade 
	(descricao)
SELECT entidade FROM empenhos_brutos GROUP BY entidade;


INSERT INTO dim_credor 
	(descricao)
SELECT credor FROM empenhos_brutos GROUP BY credor;


INSERT INTO dim_empenho
	(descricao)
SELECT empenho FROM empenhos_brutos GROUP BY empenho;


INSERT INTO dim_especie
	(descricao)
SELECT especie FROM empenhos_brutos GROUP BY especie;


INSERT INTO dim_descricao_despesa
	(descricao)
SELECT descricao from empenhos_brutos group by descricao


/* INSERT NA TABELA DE FATO */
INSERT INTO fato_empenho_geral
(id_dim_credor, id_dim_empenho, id_dim_entidade, id_dim_especie, id_dim_descricao_despesa, dt_emissao, valor_emitido, valor_liquidado, valor_pago, covid)
SELECT
	(SELECT dc.id FROM dim_credor dc WHERE dc.descricao = eb.Credor) as credor,
	(SELECT de.id FROM dim_empenho de WHERE de.descricao = eb.Empenho) as empenho,
	(SELECT dent.id FROM dim_entidade dent WHERE dent.descricao = eb.Entidade) as entidade,
	(SELECT desp.id FROM dim_especie desp WHERE desp.descricao = eb.especie) as especie,
	(SELECT ddesc.id FROM dim_descricao_despesa ddesc WHERE ddesc.descricao = eb.descricao) as descricao_despesa,
	emissao as dt_emissao,	
	Valor as valor_emitido,
	(
		(select IIF(SUM(Valor_Liquidação) IS NULL, 0, SUM(Valor_Liquidação)) from empenhos_liquidados_2020 where REPLACE(REPLACE(Empenho, '-0', ''), '/', ' / ') = eb.empenho AND Entidade = eb.entidade) +
		(select IIF(SUM(Valor_Liquidação) IS NULL, 0, SUM(Valor_Liquidação)) from empenhos_liquidados_2021 where REPLACE(REPLACE(Empenho, '-0', ''), '/', ' / ') = eb.empenho AND Entidade = eb.entidade) +
		(select IIF(SUM(Valor_Liquidação) IS NULL, 0, SUM(Valor_Liquidação)) from empenhos_liquidados_2022 where REPLACE(REPLACE(Empenho, '-0', ''), '/', ' / ') = eb.empenho AND Entidade = eb.entidade) +
		(select IIF(SUM(Valor_Liquidação) IS NULL, 0, SUM(Valor_Liquidação)) from empenhos_liquidados_2023 where REPLACE(REPLACE(Empenho, '-0', ''), '/', ' / ') = eb.empenho AND Entidade = eb.entidade)
	) as valor_liquidado,
	(
		(select IIF(SUM(Valor_Pago) IS NULL, 0, SUM(Valor_Pago)) from empenhos_pagos_2020 where REPLACE(REPLACE(Empenho, '-0', ''), '/', ' / ') = eb.empenho AND Entidade = eb.entidade) +
		(select IIF(SUM(Valor_Pago) IS NULL, 0, SUM(Valor_Pago)) from empenhos_pagos_2021 where REPLACE(REPLACE(Empenho, '-0', ''), '/', ' / ') = eb.empenho AND Entidade = eb.entidade) +
		(select IIF(SUM(Valor_Pago) IS NULL, 0, SUM(Valor_Pago)) from empenhos_pagos_2022 where REPLACE(REPLACE(Empenho, '-0', ''), '/', ' / ') = eb.empenho AND Entidade = eb.entidade) +
		(select IIF(SUM(Valor_Pago) IS NULL, 0, SUM(Valor_Pago)) from empenhos_pagos_2023 where REPLACE(REPLACE(Empenho, '-0', ''), '/', ' / ') = eb.empenho AND Entidade = eb.entidade)
	) as valor_pago,
	IIF(
		(CONCAT(eb.empenho, eb.entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2020)) OR
		(CONCAT(eb.empenho, eb.entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2021)) OR
		(CONCAT(eb.empenho, eb.entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2022))
		, 1, 0) as covid
FROM empenhos_brutos eb order by empenho


/* SCRIPTS PARA AJUDA E ENTENDIMENTO */


/* TODOS OS DADOS DA TABELA DE FATO */
select dc.descricao as credor, de.descricao as empenho, dent.descricao as entidade, desp.descricao as especie,
ddd.descricao as despesa, feg.valor_emitido, feg.valor_liquidado, feg.valor_pago, feg.covid 
	from fato_empenho_geral feg
	left join dim_credor dc on dc.id = feg.id_dim_credor
	left join dim_descricao_despesa ddd on ddd.id = feg.id_dim_descricao_despesa
	left join dim_empenho de on de.id = feg.id_dim_empenho
	left join dim_entidade dent on dent.id = feg.id_dim_entidade
	left join dim_especie desp on desp.id = feg.id_dim_especie
	order by de.descricao


/* Foi usado o empenho 1082 / 2020 para a maioria dos testes */


/* Emissão, liquidação e pagamento do empenho 1082 / 2020 */
select * from empenhos_emitidos_2020 where empenho = '1082 / 2020'


select * from empenhos_liquidados_2020 where empenho LIKE '1082/2020'


select * from empenhos_pagos_2020 where empenho LIKE '1082/2020'


/* Teste de select dos campos de liquidação e valor pago para verificar se o somatório estava correto */
select IIF(SUM(Valor_Liquidação) IS NULL, 0, SUM(Valor_Liquidação)) from empenhos_liquidados_2020 where REPLACE(REPLACE(Empenho, '-0', ''), '/', ' / ') = '1 / 2020' AND Entidade = 'FUNDACAO MUNICIPAL DE CULTURA'


select IIF(SUM(Valor_Pago) IS NULL, 0, SUM(Valor_Pago)) from empenhos_pagos_2020 where REPLACE(REPLACE(Empenho, '-0', ''), '/', ' / ') = '1 / 2020' AND Entidade = 'FUNDACAO MUNICIPAL DE CULTURA'


/*  */
select IIF(
		('1082 / 2020' IN (select empenho from empenho_emitido_covid_2020) AND 'FMS - FUNDO MUNICIPAL DE SAUDE DE CONCORDIA' IN (select entidade from empenho_emitido_covid_2020)) OR
		('1082 / 2020' IN (select empenho from empenho_emitido_covid_2021) AND 'FMS - FUNDO MUNICIPAL DE SAUDE DE CONCORDIA' IN (select entidade from empenho_emitido_covid_2021)) OR
		('1082 / 2020' IN (select empenho from empenho_emitido_covid_2022) AND 'FMS - FUNDO MUNICIPAL DE SAUDE DE CONCORDIA' IN (select entidade from empenho_emitido_covid_2022))
		, 1, 0)


select IIF(
		(CONCAT('1082 / 2020','FMS - FUNDO MUNICIPAL DE SAUDE DE CONCORDIA') IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2020)) OR
		(CONCAT('1082 / 2020','FMS - FUNDO MUNICIPAL DE SAUDE DE CONCORDIA') IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2021)) OR
		(CONCAT('1082 / 2020','FMS - FUNDO MUNICIPAL DE SAUDE DE CONCORDIA') IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2022))
		, 1, 0)


select empenho from empenhos_emitidos_2020 group by empenho
select empenho from empenhos_liquidados_2020 where empenho LIKE '%/2020%' group by empenho


select * from empenhos_emitidos_2020 where empenho = '1082 / 2020'
select * from empenho_emitido_covid_2020 where empenho = '1082 / 2020'


select Empenho from empenhos_emitidos_2020 
where Empenho IN (
	select REPLACE(REPLACE(Empenho, '-0', ''), '/', ' / ') as empenho_formatado from empenhos_liquidados_2020 group by Empenho
)
select * from empenhos_liquidados_2020





CREATE TABLE empenhos_pagos_brutos (
	id int IDENTITY(1,1),
	entidade varchar(255),
	credor varchar(255),
	empenho varchar(255),
	n_ordem int,
	data_pgto date,
	valor_pago decimal(18,10),
	covid int
);

INSERT INTO empenhos_pagos_brutos
(entidade, credor, empenho, n_ordem, data_pgto, valor_pago, covid)
SELECT e20.Entidade, e20.Credor, e20.Empenho, e20.Nº_Ordem, e20.Data, e20.Valor_Pago,
IIF(
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2020)) OR
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2021)) OR
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2022))
	, 1, 0) as covid
FROM empenhos_pagos_2020 e20

INSERT INTO empenhos_pagos_brutos
(entidade, credor, empenho, n_ordem, data_pgto, valor_pago, covid)
SELECT e20.Entidade, e20.Credor, e20.Empenho, e20.Nº_Ordem, e20.Data, e20.Valor_Pago,
IIF(
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2020)) OR
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2021)) OR
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2022))
	, 1, 0) as covid
FROM empenhos_pagos_2021 e20

INSERT INTO empenhos_pagos_brutos
(entidade, credor, empenho, n_ordem, data_pgto, valor_pago, covid)
SELECT e20.Entidade, e20.Credor, e20.Empenho, e20.Nº_Ordem, e20.Data, e20.Valor_Pago,
IIF(
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2020)) OR
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2021)) OR
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2022))
	, 1, 0) as covid
FROM empenhos_pagos_2022 e20

INSERT INTO empenhos_pagos_brutos
(entidade, credor, empenho, n_ordem, data_pgto, valor_pago, covid)
SELECT e20.Entidade, e20.Credor, e20.Empenho, e20.Nº_Ordem, e20.Data, e20.Valor_Pago,
IIF(
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2020)) OR
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2021)) OR
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2022))
	, 1, 0) as covid
FROM empenhos_pagos_2023 e20

drop table empenhos_liquidados_brutos

CREATE TABLE empenhos_liquidados_brutos (
	id int IDENTITY(1,1),
	entidade varchar(255),
	credor varchar(255),
	empenho varchar(255),
	liquidacao int,
	data_liquidacao date,
	valor float,
	especie varchar(255),
	covid int
);

INSERT INTO empenhos_liquidados_brutos
(entidade, credor, empenho, liquidacao, data_liquidacao, valor, especie, covid)
SELECT e20.Entidade, e20.Credor, e20.Empenho, e20.Liquidação, e20.Data, e20.Valor_Liquidação, e20.Espécie,
IIF(
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2020)) OR
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2021)) OR
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2022))
	, 1, 0) as covid
FROM empenhos_liquidados_2020 e20

INSERT INTO empenhos_liquidados_brutos
(entidade, credor, empenho, liquidacao, data_liquidacao, valor, especie, covid)
SELECT e20.Entidade, e20.Credor, e20.Empenho, e20.Liquidação, e20.Data, e20.Valor_Liquidação, e20.Espécie,
IIF(
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2020)) OR
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2021)) OR
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2022))
	, 1, 0) as covid
FROM empenhos_liquidados_2021 e20

INSERT INTO empenhos_liquidados_brutos
(entidade, credor, empenho, liquidacao, data_liquidacao, valor, especie, covid)
SELECT e20.Entidade, e20.Credor, e20.Empenho, e20.Liquidação, e20.Data, e20.Valor_Liquidação, e20.Espécie,
IIF(
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2020)) OR
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2021)) OR
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2022))
	, 1, 0) as covid
FROM empenhos_liquidados_2022 e20

INSERT INTO empenhos_liquidados_brutos
(entidade, credor, empenho, liquidacao, data_liquidacao, valor, especie, covid)
SELECT e20.Entidade, e20.Credor, e20.Empenho, e20.Liquidação, e20.Data, e20.Valor_Liquidação, e20.Espécie,
IIF(
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2020)) OR
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2021)) OR
	(CONCAT(REPLACE(REPLACE(e20.Empenho, '-0', ''), '/', ' / '), e20.Entidade) IN (select CONCAT(empenho, entidade) from empenho_emitido_covid_2022))
	, 1, 0) as covid
FROM empenhos_liquidados_2023 e20

