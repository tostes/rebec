# Integração do Django Auth com MySQL Legado

Este documento descreve o resultado da auditoria feita nas tabelas `auth_*` do banco MySQL legado e os ajustes necessários para que o Django 4.2+ possa operar sobre elas sem divergências de esquema. Também apresenta opções de configuração do Django, um roteiro de execução do script de alinhamento e alternativas caso os ajustes sejam inviáveis.

## 1. Auditoria do Esquema Atual

A inspeção foi conduzida com `SHOW CREATE TABLE` nas quatro tabelas principais (`auth_user`, `auth_group`, `auth_permission` e `auth_user_groups`) e nas tabelas de relacionamento (`auth_user_user_permissions`, `auth_group_permissions`). O resultado resume-se abaixo.

| Tabela | Coluna | Esquema atual | Expectativa padrão do Django | Observações |
| --- | --- | --- | --- | --- |
| `auth_user` | `id` | `int(11)` auto increment, PK | `int` auto increment, PK | OK (apenas conferir `UNSIGNED` ausente). |
| | `password` | `varchar(128)` NOT NULL | `varchar(128)` NOT NULL | OK. |
| | `last_login` | `datetime` NOT NULL DEFAULT `'0000-00-00 00:00:00'` | `datetime(6)` NULL | Django permite `NULL` e não aceita `0000-00-00`. |
| | `is_superuser` | `tinyint(1)` NOT NULL DEFAULT 0 | `boolean` NOT NULL DEFAULT 0 | OK se mapeado como `tinyint(1)`. |
| | `username` | `varchar(30)` NOT NULL UNIQUE | `varchar(150)` NOT NULL UNIQUE | Django 1.10+ exige 150 caracteres. |
| | `first_name` | `varchar(30)` NOT NULL DEFAULT '' | `varchar(150)` NOT NULL DEFAULT '' | Django aumentou o limite para 150. |
| | `last_name` | `varchar(30)` NOT NULL DEFAULT '' | `varchar(150)` NOT NULL DEFAULT '' | Mesmo ajuste do primeiro nome. |
| | `email` | `varchar(75)` NOT NULL DEFAULT '' | `varchar(254)` NOT NULL DEFAULT '' | Ajustar comprimento para compatibilidade com RFC. |
| | `is_staff`, `is_active` | `tinyint(1)` NOT NULL DEFAULT 0/1 | `boolean` NOT NULL DEFAULT 0/1 | OK se permanecerem como `tinyint(1)`. |
| | `date_joined` | `datetime` NOT NULL DEFAULT `'0000-00-00 00:00:00'` | `datetime(6)` NOT NULL | Remover data inválida; preferir `CURRENT_TIMESTAMP`. |
| | Engine/Collation | `MyISAM`, `latin1_swedish_ci` | `InnoDB`, `utf8mb4_unicode_ci` | Necessário para FK e unicode. |
| `auth_group` | `name` | `varchar(80)` UNIQUE | `varchar(150)` UNIQUE | Django 4.0 ampliou para 150. |
| `auth_permission` | `name` | `varchar(50)` NOT NULL | `varchar(255)` NOT NULL | Ajustar comprimento. |
| | `content_type_id` | `int(11)` FK sem `ON DELETE` | `int` FK `ON DELETE CASCADE` | Ajustar FK para refletir comportamento padrão. |
| `auth_group_permissions` | `permission_id` | FK sem índice composto | FK com índice único (`(group_id, permission_id)`) | Ajustar índice exclusivo e engine. |
| `auth_user_groups` | `group_id` | FK sem índice composto | FK com índice único (`(user_id, group_id)`) | Ajustar índice exclusivo e engine. |
| `auth_user_user_permissions` | idem | idem | Ajustar índice exclusivo e engine. |

> **Nota:** Se existirem colunas extras herdadas (ex.: `legacy_uuid` ou flags adicionais), podem ser mantidas desde que marcadas como opcionais e documentadas no `AUTH_PROFILE_MODULE` ou em um `User` customizado.

## 2. Ajustes Recomendados

1. **Normalizar tipos e tamanhos** para `username`, `first_name`, `last_name`, `email`, `auth_group.name` e `auth_permission.name`.
2. **Permitir `NULL` em `last_login`** e remover valores sentinela `0000-00-00 00:00:00`.
3. **Migrar engine para InnoDB** e collation para `utf8mb4_unicode_ci` em todas as tabelas `auth_*`.
4. **Garantir índices compostos** (`UNIQUE`) nas tabelas de relacionamento para impedir duplicidades e alinhar ao Django.
5. **Adicionar chaves estrangeiras com `ON DELETE CASCADE`** conforme o padrão do Django.
6. **Habilitar `datetime(6)`** (microsegundos) quando possível; caso a versão do MySQL seja anterior a 5.6.4, registrar como limitação.

Caso algum ajuste seja impeditivo (por exemplo, necessidade de manter `username` com 30 caracteres devido à integração externa), recomenda-se definir um `AUTH_USER_MODEL` personalizado que reflita os limites do legado e ajustar as views/forms manualmente.

## 3. Configuração do Django (`DATABASES`) e Roteamento

```python
# settings.py
DATABASES = {
    "default": {  # PostgreSQL principal do ReBEC
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("PGDATABASE", "rebec"),
        "USER": os.environ.get("PGUSER", "rebec"),
        "PASSWORD": os.environ.get("PGPASSWORD", ""),
        "HOST": os.environ.get("PGHOST", "localhost"),
        "PORT": os.environ.get("PGPORT", "5432"),
    },
    "legacy_auth": {  # MySQL legado
        "ENGINE": "django.db.backends.mysql",
        "NAME": os.environ.get("MYSQL_DATABASE", "legacy_auth"),
        "USER": os.environ.get("MYSQL_USER", "rebec"),
        "PASSWORD": os.environ.get("MYSQL_PASSWORD", ""),
        "HOST": os.environ.get("MYSQL_HOST", "localhost"),
        "PORT": os.environ.get("MYSQL_PORT", "3306"),
        "OPTIONS": {
            "charset": "utf8mb4",
            "init_command": "SET sql_mode='STRICT_TRANS_TABLES'",
        },
    },
}

DATABASE_ROUTERS = ["rebec.db_routers.AuthRouter"]
```

Exemplo de roteador que envia o app `auth` para o MySQL legado e evita migrações acidentais:

```python
# rebec/db_routers.py
class AuthRouter:
    app_label = "auth"

    def db_for_read(self, model, **hints):
        if model._meta.app_label == self.app_label:
            return "legacy_auth"
        return None

    def db_for_write(self, model, **hints):
        if model._meta.app_label == self.app_label:
            return "legacy_auth"
        return None

    def allow_relation(self, obj1, obj2, **hints):
        if {obj1._meta.app_label, obj2._meta.app_label} == {self.app_label}:
            return True
        return None

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        if app_label == self.app_label:
            return db == "legacy_auth"
        return db == "default"
```

> **Replicação & Migração:** Se a instância MySQL for replicada, garanta que o Django aponte sempre para o nó primário para operações de escrita (criação de usuários/senhas). Para migrações futuras ao PostgreSQL, planeje uma janela de manutenção onde o `legacy_auth` seja tornado somente leitura, sincronize os dados e atualize o roteador para apontar para a nova base.

## 4. Script de Alinhamento do Esquema

O script [`database/sql/mysql_auth_alignment.sql`](../database/sql/mysql_auth_alignment.sql) aplica todas as alterações listadas. Recomenda-se executá-lo em horário controlado e após backup completo.

**Passos sugeridos:**

1. `mysqldump --routines --triggers --single-transaction legacy_auth auth_% > backup-auth.sql`
2. `mysql --defaults-file=/caminho/.my.cnf legacy_auth < database/sql/mysql_auth_alignment.sql`
3. Revisar logs e validar com `SHOW TABLE STATUS LIKE 'auth_user';`
4. Atualizar variáveis de ambiente do Django e testar login.

> **Ajustes manuais:** caso os nomes das chaves estrangeiras existentes sejam diferentes dos usados no script (`*_ibfk_*`), adapte os comandos `DROP FOREIGN KEY` antes de executar.

## 5. Quando optar por um `AUTH_USER_MODEL` personalizado?

- Se o legado utiliza chaves primárias não inteiras ou UUIDs.
- Se o username precisar permanecer com 30 caracteres.
- Se existirem campos obrigatórios adicionais que não existem no modelo padrão do Django.

Nesses cenários, implemente um modelo customizado compatível com o esquema legado (ex.: `class LegacyUser(AbstractBaseUser)`), registrando-o via `AUTH_USER_MODEL` e criando um `UserManager` que respeite as restrições existentes.

## 6. Próximos Passos

- Executar o script de alinhamento em staging.
- Ajustar formulários/admin do Django para respeitar os novos tamanhos de campo.
- Monitorar os primeiros logins para validar integridade.
