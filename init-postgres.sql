-- Criar tabela de exemplo para o departamento de vendas
CREATE TABLE IF NOT EXISTS sales_data (
    id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    sale_amount DECIMAL(10,2),
    sale_date DATE,
    region VARCHAR(50)
);

-- Inserir dados de exemplo
INSERT INTO sales_data (product_name, sale_amount, sale_date, region) VALUES
('Laptop', 1299.99, '2024-01-15', 'North'),
('Mouse', 29.99, '2024-01-16', 'South'),
('Keyboard', 89.99, '2024-01-17', 'East'),
('Monitor', 399.99, '2024-01-18', 'West'),
('Headphones', 149.99, '2024-01-19', 'North');

-- Criar usuário para Gravitino
CREATE USER gravitino_user WITH PASSWORD 'gravitino_pass';
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO gravitino_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO gravitino_user;
