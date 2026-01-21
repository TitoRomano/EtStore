CREATE TABLE Vendas(
	
	VendaID INT IDENTITY(1,1 ) PRIMARY KEY,

	NomeCliente VARCHAR (100) NOT NULL,
	CPFCliente VARCHAR (14) NULL,

	NumeroVenda VARCHAR(20) UNIQUE,

	DataVenda DATETIME DEFAULT GETDATE(),
	DataCancelamento DATETIME NULL,

	Subtotal DECIMAL (10,2) DEFAULT 0,
	DescontoVenda DECIMAL(10,2) DEFAULT 0,
	TotalVenda DECIMAL(10,2) DEFAULT 0,
	TotalCusto DECIMAL(10,2) DEFAULT 0,

	Lucro AS (TotalVenda - TotalCusto),
	MargemLucro AS CASE
		WHEN TotalVenda > 0 THEN ((TotalVenda - TotalCusto) / TotalVenda) * 100
		ELSE 0
	END, 

	FormaPagamento VARCHAR(20) DEFAULT 'Dinheiro' CHECK (FormaPagamento IN (
		'DInheiro', 'Cartão Débito', 'Cartão Crédito', 'PIX', 'Transferência', 'Fiado')),

	NumeroParcelas INT DEFAULT 1 CHECK (NumeroParcelas BETWEEN 1 AND 12),
	ValorEntrada DECIMAL(10,2) DEFAULT 0,

	Status VARCHAR(20) DEFAULT 'Concluida' CHECK (Status IN('Concluida', 'Cancelado', 'Pedente', 'Orçamento', 'Devolvida')),

	DataCadastro DATETIME DEFAULT GETDATE(),
	DataAtualizacao DATETIME DEFAULT GETDATE(),

	CONSTRAINT CHK_Total_Positivo CHECK (TotalVenda >= 0),
	CONSTRAINT CHK_Data_Cancelamento CHECK (
		(Status = 'Cancelada' AND DataCancelamento IS NOT NULL) OR
		(Status != 'Cancelada' AND DataCancelamento IS NULL)
	)
);

CREATE SEQUENCE SeqNumeroVenda
	START WITH 1000
	INCREMENT BY 1;

GO

CREATE TRIGGER trg_Gerar_Numero_Venda
ON Vendas
INSTEAD OF INSERT
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @DataAtual VARCHAR(8) = FORMAT(GETDATE(), 'yyyyMMdd');
	DECLARE @ProximoNumero INT;

	SELECT @ProximoNumero = NEXT VALUE FOR SeqNumeroVenda;


	INSERT INTO Vendas (
		NomeCliente, CPFCliente, NumeroVenda, DataVenda,
		Subtotal, DescontoVenda, TotalVenda, TotalCusto,
		FormaPagamento, NumeroParcelas, ValorEntrada,
		Status, DataCadastro, DataAtualizacao
	)

	SELECT
		NomeCliente,
		CPFCliente,
		CONCAT('VENDA-', @DataAtual, '-', @ProximoNumero),
		COALESCE(DataVenda, GETDATE()),
		COALESCE(Subtotal, 0),
		COALESCE(DescontoVenda, 0),
		COALESCE(TotalVenda, 0),
		COALESCE(TotalCusto, 0),
		COALESCE(FormaPagamento, 'Dinheiro'),
		COALESCE(NumeroParcelas, 1),
		COALESCE(ValorEntrada, 0),
		COALESCE(Status, 'Concluida'),
		COALESCE(DataCadastro, GETDATE()),
		COALESCE(DataAtualizacao, GETDATE())

	FROM inserted;

	PRINT 'Número de venda geardo automaticamente.';
END;

CREATE INDEX idx_vendas_datas ON Vendas(DataVenda);
CREATE INDEX idx_vendas_status ON Vendas(Status);
CREATE INDEX idx_vendas_cliente ON Vendas(CPFCliente) WHERE CPFCliente IS NOT NULL;
CREATE INDEX idx_vendas_numero ON Vendas(NumeroVenda);

GO

CREATE VIEW vw_Vendas_Dashboard AS
SELECT
	v.VendaID,
	v.NumeroVenda,
	v.DataVenda,
	v.NomeCliente,
	v.CPFCliente,
	v.Subtotal,
	v.DescontoVenda,
	v.TotalVenda,
	v.TotalCusto,
	v.Lucro,
	v.MargemLucro,
	v.FormaPagamento,
	v.Status,
	
	YEAR(v.DataVenda) AS AnoVenda,
	MONTH(v.DataVenda) AS MesVenda,
	DAY(v.DataVenda) AS DiaVenda,
	DATEPART(WEEKDAY,v.DataVenda) AS DiaSemana,
	DATEPART(HOUR, v.DataVenda) AS HoraVenda,

	CASE
		WHEN v.TotalVenda > 10 THEN 'Alto Valor'
		WHEN v.TotalVenda > 5 THEN 'Médio Valor'
		ELSE 'Baixo Valor'
	END AS ClassificacaoValor,

	CASE
		WHEN v.MargemLucro > 50 THEN 'Alta Margem'
		WHEN v.MargemLucro > 30 THEN 'Média Margem'
		WHEN v.MargemLucro > 10 THEN 'Baixa MArgem'
		ELSE 'Margem Crítica'
	END AS ClassificacaoMargem

FROM Vendas v
WHERE v.Status IN ('Concluida', 'Pendente');