# Apache Gravitino - Caso de Estudo

## 📋 Visão Geral
Este projeto contém um caso de estudo prático para aprender Apache Gravitino localmente. O exemplo simula um ambiente de data lakehouse para uma empresa fictícia "DataCorp" que precisa gerenciar dados de vendas vindos de diferentes fontes.

## 🎯 Objetivos
- Entender os conceitos básicos do Apache Gravitino
- Aprender a gerenciar metadados de forma unificada
- Explorar recursos de descoberta e governança de dados
- Demonstrar interoperabilidade entre diferentes sistemas

## 🏢 Cenário
A DataCorp possui:
- **Dados transacionais** (PostgreSQL)
- **Dados de logs** (Apache Iceberg)
- **Dados de analytics** (Apache Hive)

## 🚀 Pré-requisitos
- Docker e Docker Compose
- Apache Gravitino rodando localmente na porta 8090
- curl instalado
- jq instalado (opcional, para formatação JSON)

## 📁 Estrutura do Projeto

```
apache_gravitino/
├── README.md                # Este arquivo
├── docker-compose.yml       # Configuração do ambiente Docker
├── gravitino-data/          # Dados persistentes do Gravitino
├── gravitino-logs/          # Logs do Gravitino
├── init-postgres.sql        # Script de inicialização do PostgreSQL
├── pyproject.toml           # Configuração de dependências Python (se aplicável)
├── setup-gravitino.sh       # Script de configuração inicial
└── trino-config/            # Configurações do Trino
    ├── catalog/
    │   ├── gravitino.properties     # Propriedades do catálogo Gravitino para Trino
    │   └── postgresql.properties   # Propriedades do catálogo PostgreSQL para Trino
    └── config.properties           # Configuração principal do Trino
```

### 1. ✅ Configuração Inicial

Primeiro, verifique se o Gravitino está rodando corretamente:

```bash
# Verificar se o Gravitino está rodando
curl -X GET http://localhost:8090/api/version

# Verificar o metalake criado
curl -X GET http://localhost:8090/api/metalakes/demo_metalake
```

**Resposta esperada:**
```json
{
  "version": "0.5.0",
  "compileDate": "2024-01-15",
  "gitCommit": "abc123"
}
```

### 2. 🗂️ Criando Catálogos

#### Catálogos
```bash
# Catálogo para Dados Transacionais (In-Memory)
curl -X POST http://localhost:8090/api/metalakes/demo_metalake/catalogs \
  -H "Content-Type: application/json" \
  -d '{
    "name": "transactional_catalog",
    "type": "RELATIONAL",
    "provider": "memory",
    "comment": "Catálogo in-memory para dados transacionais",
    "properties": {
      "location": "memory://transactional-data"
    }
  }'

# Catálogo para Data Lake (In-Memory)
curl -X POST http://localhost:8090/api/metalakes/demo_metalake/catalogs \
  -H "Content-Type: application/json" \
  -d '{
    "name": "datalake_catalog",
    "type": "RELATIONAL", 
    "provider": "memory",
    "comment": "Catálogo in-memory para data lake",
    "properties": {
      "location": "memory://datalake-data"
    }
  }'

# Catálogo para Analytics (In-Memory)
curl -X POST http://localhost:8090/api/metalakes/demo_metalake/catalogs \
  -H "Content-Type: application/json" \
  -d '{
    "name": "analytics_catalog",
    "type": "RELATIONAL",
    "provider": "memory", 
    "comment": "Catálogo in-memory para dados analíticos",
    "properties": {
      "location": "memory://analytics-data"
    }
  }'
```

### 3. 🏗️ Criando Schemas

#### Schema para Vendas
```bash
curl -X POST http://localhost:8090/api/metalakes/demo_metalake/catalogs/postgres_catalog/schemas \
  -H "Content-Type: application/json" \
  -d '{
    "name": "sales_schema",
    "comment": "Schema para dados de vendas",
    "properties": {}
  }'
```

#### Schema para Analytics
```bash
curl -X POST http://localhost:8090/api/metalakes/demo_metalake/catalogs/iceberg_catalog/schemas \
  -H "Content-Type: application/json" \
  -d '{
    "name": "analytics_schema",
    "comment": "Schema para dados analíticos",
    "properties": {}
  }'
```

### 4. 📊 Criando Tabelas

#### Tabela de Vendas (PostgreSQL)
```bash
curl -X POST http://localhost:8090/api/metalakes/demo_metalake/catalogs/postgres_catalog/schemas/sales_schema/tables \
  -H "Content-Type: application/json" \
  -d '{
    "name": "sales_transactions",
    "comment": "Tabela de transações de vendas",
    "columns": [
      {
        "name": "transaction_id",
        "type": "integer",
        "comment": "ID único da transação",
        "nullable": false,
        "autoIncrement": true
      },
      {
        "name": "customer_id",
        "type": "integer",
        "comment": "ID do cliente",
        "nullable": false
      },
      {
        "name": "product_id",
        "type": "integer",
        "comment": "ID do produto",
        "nullable": false
      },
      {
        "name": "quantity",
        "type": "integer",
        "comment": "Quantidade vendida",
        "nullable": false
      },
      {
        "name": "unit_price",
        "type": "decimal(10,2)",
        "comment": "Preço unitário",
        "nullable": false
      },
      {
        "name": "transaction_date",
        "type": "timestamp",
        "comment": "Data da transação",
        "nullable": false
      }
    ],
    "properties": {}
  }'
```

#### Tabela de Analytics Agregadas (Iceberg)
```bash
curl -X POST http://localhost:8090/api/metalakes/demo_metalake/catalogs/iceberg_catalog/schemas/analytics_schema/tables \
  -H "Content-Type: application/json" \
  -d '{
    "name": "sales_summary",
    "comment": "Resumo de vendas por produto e data",
    "columns": [
      {
        "name": "product_id",
        "type": "integer",
        "comment": "ID do produto",
        "nullable": false
      },
      {
        "name": "sales_date",
        "type": "date",
        "comment": "Data das vendas",
        "nullable": false
      },
      {
        "name": "total_quantity",
        "type": "bigint",
        "comment": "Quantidade total vendida",
        "nullable": false
      },
      {
        "name": "total_revenue",
        "type": "decimal(15,2)",
        "comment": "Receita total",
        "nullable": false
      },
      {
        "name": "avg_unit_price",
        "type": "decimal(10,2)",
        "comment": "Preço médio unitário",
        "nullable": false
      }
    ],
    "properties": {
      "format": "parquet",
      "location": "s3://datacorp-warehouse/analytics/sales_summary/"
    }
  }'
```

### 5. 🔍 Comandos de Exploração

#### Listar todos os catálogos
```bash
curl -X GET http://localhost:8090/api/metalakes/demo_metalake/catalogs
```

#### Listar schemas de um catálogo
```bash
curl -X GET http://localhost:8090/api/metalakes/demo_metalake/catalogs/postgres_catalog/schemas
```

#### Listar tabelas de um schema
```bash
curl -X GET http://localhost:8090/api/metalakes/demo_metalake/catalogs/postgres_catalog/schemas/sales_schema/tables
```

#### Obter detalhes de uma tabela
```bash
curl -X GET http://localhost:8090/api/metalakes/demo_metalake/catalogs/postgres_catalog/schemas/sales_schema/tables/sales_transactions
```

#### Comando útil para visualizar JSON formatado
```bash
curl -X GET http://localhost:8090/api/metalakes/demo_metalake/catalogs | jq '.'
```

### 6. 🎯 Casos de Uso Práticos

#### 6.1 Descoberta de Dados
```bash
# Encontrar todas as tabelas que contêm informações de vendas
curl -X GET http://localhost:8090/api/metalakes/demo_metalake/catalogs | jq '.catalogs[] | select(.comment | contains("vendas"))'

# Buscar por padrões de nome
curl -X GET http://localhost:8090/api/metalakes/demo_metalake/catalogs/postgres_catalog/schemas/sales_schema/tables | jq '.tables[] | select(.name | contains("sales"))'
```

#### 6.2 Governança e Linhagem
```bash
# Adicionar tags e propriedades para governança
curl -X PUT http://localhost:8090/api/metalakes/demo_metalake/catalogs/postgres_catalog/schemas/sales_schema/tables/sales_transactions \
  -H "Content-Type: application/json" \
  -d '{
    "updates": [
      {
        "type": "setProperty",
        "property": "data_classification",
        "value": "sensitive"
      },
      {
        "type": "setProperty", 
        "property": "owner",
        "value": "sales_team"
      },
      {
        "type": "setProperty",
        "property": "retention_days",
        "value": "2555"
      }
    ]
  }'
```

#### 6.3 Consulta Cross-Catalog
```bash
# Script para listar todas as tabelas de todos os catálogos
#!/bin/bash
for catalog in $(curl -s http://localhost:8090/api/metalakes/demo_metalake/catalogs | jq -r '.catalogs[].name'); do
  echo "=== Catálogo: $catalog ==="
  curl -s http://localhost:8090/api/metalakes/demo_metalake/catalogs/$catalog/schemas | jq -r '.schemas[].name' | while read schema; do
    echo "  Schema: $schema"
    curl -s http://localhost:8090/api/metalakes/demo_metalake/catalogs/$catalog/schemas/$schema/tables | jq -r '.tables[].name' | while read table; do
      echo "    - $table"
    done
  done
done
```

#### 6.4 Auditoria e Monitoramento
```bash
# Verificar propriedades de governança
curl -X GET http://localhost:8090/api/metalakes/demo_metalake/catalogs/postgres_catalog/schemas/sales_schema/tables/sales_transactions | jq '.properties'

# Listar todas as tabelas com suas classificações
curl -X GET http://localhost:8090/api/metalakes/demo_metalake/catalogs/postgres_catalog/schemas/sales_schema/tables | jq '.tables[] | {name: .name, classification: .properties.data_classification}'
```

### 7. ✅ Benefícios Demonstrados

| Benefício | Descrição | Exemplo no Caso de Estudo |
|-----------|-----------|---------------------------|
| **Unificação de Metadados** | Todos os sistemas são gerenciados através de uma única interface | PostgreSQL e Iceberg no mesmo namespace |
| **Descoberta de Dados** | Fácil localização de datasets através de APIs padronizadas | Busca cross-catalog por tabelas de vendas |
| **Governança** | Propriedades e tags aplicadas consistentemente | Tags de classificação e ownership |
| **Interoperabilidade** | Diferentes engines usam os mesmos metadados | Spark, Trino, Flink podem usar o mesmo catálogo |
| **Evolução de Schema** | Mudanças versionadas e controladas | Updates de propriedades e estruturas |

### 8. 🚀 Próximos Passos

#### Nível Básico
- [ ] Completar todos os comandos deste README
- [ ] Explorar diferentes tipos de catálogos
- [ ] Experimentar com schemas e tabelas customizadas

#### Nível Intermediário
- [ ] Integrar com ferramentas de query (Spark, Trino, etc.)
- [ ] Implementar controle de acesso baseado em roles
- [ ] Configurar diferentes backends de storage

#### Nível Avançado
- [ ] Configurar lineage tracking
- [ ] Adicionar métricas e monitoramento
- [ ] Explorar recursos de versionamento de schema
- [ ] Implementar pipelines de ETL usando os metadados

### 9. 📚 Recursos Adicionais

#### Documentação Oficial
- [Apache Gravitino Documentation](https://gravitino.apache.org/docs/)
- [REST API Reference](https://gravitino.apache.org/docs/api/)
- [Connectors Guide](https://gravitino.apache.org/docs/connectors/)

#### Exemplos de Integração
- [Spark Integration](https://gravitino.apache.org/docs/spark-connector/)
- [Trino Integration](https://gravitino.apache.org/docs/trino-connector/)
- [Flink Integration](https://gravitino.apache.org/docs/flink-connector/)

#### Community
- [GitHub Repository](https://github.com/apache/gravitino)
- [Mailing Lists](https://gravitino.apache.org/community/)
- [Issue Tracker](https://github.com/apache/gravitino/issues)

## 🐛 Troubleshooting

### Problemas Comuns

#### Gravitino não responde
```bash
# Verificar se o container está rodando
docker ps | grep gravitino

# Verificar logs
docker logs gravitino-container-name
```

#### Erro de conexão com catálogos
```bash
# Verificar configuração do catálogo
curl -X GET http://localhost:8090/api/metalakes/demo_metalake/catalogs/postgres_catalog

# Testar conectividade
curl -X POST http://localhost:8090/api/metalakes/demo_metalake/catalogs/postgres_catalog/test-connection
```

#### Problemas de permissão
```bash
# Verificar configurações de autenticação
curl -X GET http://localhost:8090/api/metalakes/demo_metalake/catalogs/postgres_catalog/schemas/sales_schema/tables/sales_transactions | jq '.properties'
```

## 🤝 Contribuindo

Este README é um documento vivo. Sugestões de melhorias são bem-vindas:

1. Fork este repositório
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto é licenciado sob a Apache License 2.0 - veja o arquivo [LICENSE](LICENSE) para detalhes.

---

## 📝 Conclusão

Este caso de estudo demonstra como o Apache Gravitino pode servir como uma camada unificada de metadados, simplificando o gerenciamento de dados em ambientes multi-engine e multi-storage. A capacidade de descobrir, governar e evoluir schemas de forma consistente é fundamental para arquiteturas modernas de data lakehouse.

**Próximos passos recomendados:**
1. Execute todos os comandos na ordem apresentada
2. Experimente com seus próprios dados
3. Explore integrações com ferramentas que você já usa
4. Contribua com melhorias para este documento

**Lembre-se:** O Gravitino é mais poderoso quando integrado com ferramentas de processamento como Spark, Trino ou Flink. Este README focou na API REST, mas explore também os conectores específicos para cada ferramenta.

---
*README criado para fins educacionais - Apache Gravitino POC*
