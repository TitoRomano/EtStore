CREATE TABLE Produtos (
	ProdutoID INT IDENTITY(1,1) PRIMARY KEY,
	CodigoBarras VARCHAR(50) UNIQUE,
	NomeProduto VARCHAR(100) NOT NULL,
	Descricao VARCHAR(300),
	
	CategoriaID INT NOT NULL,
	MarcaID INT,

	PrecoCusto DECIMAL(10,2) NOT NULL,
	PrecoVenda DECIMAL(10,2) NOT NULL,
	MargemLucro AS (PrecoVenda - PrecoCusto),

	QuantidadeEstoque INT DEFAULT 0,
	EstoqueMinimo INT DEFAULT 2,
	EstoqueMaximo INT DEFAULT 100,

	Ativo BIT DEFAULT 1,
	Destaque BIT DEFAULT 0,
	Novo BIT DEFAULT 1,

	DataCadastro DATETIME DEFAULT GETDATE(),
	DataAtualizacao DATETIME,
	DataUltimaCompra DATETIME,

	FOREIGN KEY (CategoriaID) REFERENCES Categoria(CategoriasID),
	FOREIGN KEY (MarcaID) REFERENCES Marcas(MarcaID),

	CONSTRAINT CHK_Precos CHECK (PrecoVenda > PrecoCusto),
	CONSTRAINT CHK_Estoque CHECK (QuantidadeEstoque >= 0)
);

CREATE INDEX idx_produtos_categoria ON Produtos(CategoriaID);
CREATE INDEX idx_produtos_marca ON Produtos(MarcaID);
CREATE INDEX idx_produtos_ativo ON Produtos(Ativo);
CREATE INDEX idx_produtos_destaque ON Produtos(Destaque);

CREATE INDEX idx_produtos_nome ON Produtos(NomeProduto);

CREATE INDEX idx_produtos_estoque_baixo ON Produtos(QuantidadeEstoque) 
WHERE QuantidadeEstoque < 2;

GO

CREATE VIEW vw_Produtos_Estoque_Baixo AS
SELECT
    p.ProdutoID,
    p.NomeProduto,
    p.QuantidadeEstoque,
    p.EstoqueMinimo,       
    p.EstoqueMaximo,
    c.NomeCategoria,
    m.NomeMarca,
    (p.EstoqueMinimo - p.QuantidadeEstoque) AS QuantidadeFaltante,  
    CASE
        WHEN p.QuantidadeEstoque = 0 THEN 'CRÍTICO'
        WHEN p.QuantidadeEstoque < p.EstoqueMinimo THEN 'BAIXO'
        ELSE 'NORMAL'
    END AS StatusEstoque
FROM Produtos p
JOIN Categoria c ON p.CategoriaID = c.CategoriasID
LEFT JOIN Marcas m ON p.MarcaID = m.MarcaID
WHERE p.QuantidadeEstoque <= p.EstoqueMinimo 
AND p.Ativo = 1;