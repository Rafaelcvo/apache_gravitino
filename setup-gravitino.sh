#!/bin/bash

# setup-gravitino.sh - Script ÚNICO para configurar e iniciar o Gravitino

echo "🚀 Configurando ambiente Apache Gravitino..."

# Criar diretórios necessários
mkdir -p gravitino-data gravitino-logs trino-config/catalog

# Criar script de inicialização do PostgreSQL
cat > init-postgres.sql << 'EOF'
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
EOF

# Criar configuração do Trino
cat > trino-config/config.properties << 'EOF'
coordinator=true
node-scheduler.include-coordinator=true
http-server.http.port=8080
query.max-memory=1GB
query.max-memory-per-node=256MB
discovery-server.enabled=true
discovery.uri=http://localhost:8080
EOF

# Criar configuração do catálogo Gravitino para Trino
cat > trino-config/catalog/gravitino.properties << 'EOF'
connector.name=gravitino
gravitino.uri=http://gravitino:8090
gravitino.metalake=metalake_demo
EOF

# Criar configuração do catálogo PostgreSQL para Trino
cat > trino-config/catalog/postgresql.properties << 'EOF'
connector.name=postgresql
connection-url=jdbc:postgresql://postgres:5432/sales
connection-user=postgres
connection-password=postgres
EOF

# Iniciar serviços
echo "🚀 Iniciando serviços..."
docker-compose up -d

# Aguardar serviços ficarem prontos
echo "⏳ Aguardando serviços ficarem prontos..."
sleep 45

# Configurar metalake e catálogos automaticamente
echo "🔧 Configurando metalake e catálogos..."

# Criar metalake
curl -X POST \
  http://localhost:8090/api/metalakes \
  -H "Content-Type: application/json" \
  -d '{
    "name": "demo_metalake",
    "comment": "Metalake de demonstração",
    "properties": {}
  }' 2>/dev/null

# Criar catálogo PostgreSQL
curl -X POST \
  http://localhost:8090/api/metalakes/demo_metalake/catalogs \
  -H "Content-Type: application/json" \
  -d '{
    "name": "postgres_catalog",
    "type": "RELATIONAL",
    "provider": "jdbc-postgresql",
    "comment": "Catálogo PostgreSQL",
    "properties": {
      "jdbc-url": "jdbc:postgresql://postgres:5432/demo_db",
      "jdbc-user": "postgres",
      "jdbc-password": "postgres"
    }
  }' 2>/dev/null

echo ""
echo "✅ Gravitino configurado com sucesso!"
echo ""
echo "🌐 Acesso aos serviços:"
echo "- Gravitino Web UI: http://localhost:8090"
echo "- Trino: http://localhost:8080"
echo "- MinIO: http://localhost:9090 (admin/minioadmin)"
echo ""
echo "📊 Para parar os serviços:"
echo "docker-compose down"