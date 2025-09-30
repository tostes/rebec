-- Vocabulary tables aligning with the consolidated clinical trials data model.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/

-- Countries participating in clinical trials.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_country_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_country (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_country_id_seq'),
    ibge_code VARCHAR(10),
    iso_alpha2 CHAR(2) NOT NULL,
    iso_alpha3 CHAR(3),
    iso_numeric CHAR(3),
    name TEXT NOT NULL,
    official_name TEXT,
    continent TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_country_iso_alpha2_uniq UNIQUE (iso_alpha2),
    CONSTRAINT vocabulary_country_iso_alpha3_uniq UNIQUE (iso_alpha3)
);

ALTER SEQUENCE vocabulary_country_id_seq OWNED BY vocabulary_country.id;

-- High-level classification for sponsor and site institutions.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_institution_type_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_institution_type (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_institution_type_id_seq'),
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_institution_type_code_uniq UNIQUE (code)
);

ALTER SEQUENCE vocabulary_institution_type_id_seq OWNED BY vocabulary_institution_type.id;

-- Scope of operation for registered institutions (local, national, international, etc.).
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_institution_scope_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_institution_scope (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_institution_scope_id_seq'),
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_institution_scope_code_uniq UNIQUE (code)
);

ALTER SEQUENCE vocabulary_institution_scope_id_seq OWNED BY vocabulary_institution_scope.id;

-- Nature of the institution (public, private, philanthropic, etc.).
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_institution_nature_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_institution_nature (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_institution_nature_id_seq'),
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_institution_nature_code_uniq UNIQUE (code)
);

ALTER SEQUENCE vocabulary_institution_nature_id_seq OWNED BY vocabulary_institution_nature.id;

-- Master list of registered institutions (sponsors, collaborators, research centers, etc.).
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_institution_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_institution (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_institution_id_seq'),
    name TEXT NOT NULL,
    legal_name TEXT,
    acronym VARCHAR(50),
    registration_code VARCHAR(50),
    institution_type_id BIGINT REFERENCES vocabulary_institution_type(id),
    institution_scope_id BIGINT REFERENCES vocabulary_institution_scope(id),
    institution_nature_id BIGINT REFERENCES vocabulary_institution_nature(id),
    country_id BIGINT REFERENCES vocabulary_country(id),
    state TEXT,
    city TEXT,
    address TEXT,
    postal_code VARCHAR(20),
    phone VARCHAR(50),
    email TEXT,
    website TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_institution_unique UNIQUE (name, COALESCE(legal_name, ''))
);

ALTER SEQUENCE vocabulary_institution_id_seq OWNED BY vocabulary_institution.id;

-- High-level classification for interventions.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_intervention_category_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_intervention_category (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_intervention_category_id_seq'),
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_intervention_category_code_uniq UNIQUE (code)
);

ALTER SEQUENCE vocabulary_intervention_category_id_seq OWNED BY vocabulary_intervention_category.id;

-- Specific intervention types as used by the registry.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_intervention_type_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_intervention_type (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_intervention_type_id_seq'),
    intervention_category_id BIGINT REFERENCES vocabulary_intervention_category(id),
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_intervention_type_code_uniq UNIQUE (code)
);

ALTER SEQUENCE vocabulary_intervention_type_id_seq OWNED BY vocabulary_intervention_type.id;

-- Subtypes and additional qualifiers for interventions.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_intervention_subtype_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_intervention_subtype (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_intervention_subtype_id_seq'),
    intervention_type_id BIGINT NOT NULL REFERENCES vocabulary_intervention_type(id),
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_intervention_subtype_code_uniq UNIQUE (intervention_type_id, code)
);

ALTER SEQUENCE vocabulary_intervention_subtype_id_seq OWNED BY vocabulary_intervention_subtype.id;

-- Secondary identifier types (e.g., UMIN, ISRCTN, NCT).
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_secondary_identifier_type_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_secondary_identifier_type (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_secondary_identifier_type_id_seq'),
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    issuing_agency TEXT,
    url_template TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_secondary_identifier_type_code_uniq UNIQUE (code)
);

ALTER SEQUENCE vocabulary_secondary_identifier_type_id_seq OWNED BY vocabulary_secondary_identifier_type.id;

-- Study design allocation enums.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_study_design_allocation_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_study_design_allocation (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_study_design_allocation_id_seq'),
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_study_design_allocation_code_uniq UNIQUE (code)
);

ALTER SEQUENCE vocabulary_study_design_allocation_id_seq OWNED BY vocabulary_study_design_allocation.id;

-- Study design intervention model enums.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_study_design_intervention_model_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_study_design_intervention_model (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_study_design_intervention_model_id_seq'),
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_study_design_intervention_model_code_uniq UNIQUE (code)
);

ALTER SEQUENCE vocabulary_study_design_intervention_model_id_seq OWNED BY vocabulary_study_design_intervention_model.id;

-- Study design masking enums.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_study_design_masking_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_study_design_masking (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_study_design_masking_id_seq'),
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_study_design_masking_code_uniq UNIQUE (code)
);

ALTER SEQUENCE vocabulary_study_design_masking_id_seq OWNED BY vocabulary_study_design_masking.id;

-- Study design primary purpose enums.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_study_design_primary_purpose_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_study_design_primary_purpose (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_study_design_primary_purpose_id_seq'),
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_study_design_primary_purpose_code_uniq UNIQUE (code)
);

ALTER SEQUENCE vocabulary_study_design_primary_purpose_id_seq OWNED BY vocabulary_study_design_primary_purpose.id;

-- Study design observational model enums.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_study_design_observational_model_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_study_design_observational_model (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_study_design_observational_model_id_seq'),
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_study_design_observational_model_code_uniq UNIQUE (code)
);

ALTER SEQUENCE vocabulary_study_design_observational_model_id_seq OWNED BY vocabulary_study_design_observational_model.id;

-- Study design time perspective enums.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_study_design_time_perspective_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_study_design_time_perspective (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_study_design_time_perspective_id_seq'),
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_study_design_time_perspective_code_uniq UNIQUE (code)
);

ALTER SEQUENCE vocabulary_study_design_time_perspective_id_seq OWNED BY vocabulary_study_design_time_perspective.id;

-- Study design endpoint classification enums.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_study_design_endpoint_classification_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_study_design_endpoint_classification (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_study_design_endpoint_classification_id_seq'),
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_study_design_endpoint_classification_code_uniq UNIQUE (code)
);

ALTER SEQUENCE vocabulary_study_design_endpoint_classification_id_seq OWNED BY vocabulary_study_design_endpoint_classification.id;

