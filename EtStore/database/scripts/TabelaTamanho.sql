CREATE TABLE Tamanhos(
	TamanhoID INT IDENTITY(1,1) PRIMARY KEY,
	TipoTamanho VARCHAR(20)NOT NULL
		CHECK(TipoTamanho IN ('Roupa', 'Calçado', 'Perfume', 'Acessório', 'Único')),
	ValorTamanho VARCHAR (10) NOT NULL,
	Descricao VARCHAR(200),
	OrdemExibicao INT,
	DataCadastro DATETIME DEFAULT GETDATE(),
	CONSTRAINT UQ_Tipo_Valor UNIQUE (TipoTamanho, ValorTamanho)
);

INSERT INTO Tamanhos(TipoTamanho, ValorTamanho, Descricao, OrdemExibicao)
VALUES ('Único', 'Unico', 'Tamanho único', 99);

CREATE INDEX idx_tamanhos_tipo ON Tamanhos(TipoTamanho);
CREATE INDEX idx_tamanhos_ordem ON Tamanhos(OrdemExibicao);