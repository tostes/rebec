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
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS vocabulary_institution_name_legal_name_uniq
    ON vocabulary_institution (name, COALESCE(legal_name, ''));

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

-- Detailed classification for interventions grouped under broader categories.
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

-- Granular breakdown for intervention types capturing sub classifications.
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
    CONSTRAINT vocabulary_intervention_subtype_type_code_uniq UNIQUE (intervention_type_id, code)
);

ALTER SEQUENCE vocabulary_intervention_subtype_id_seq OWNED BY vocabulary_intervention_subtype.id;

-- Canonical registry of interventions harmonised across data sources.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_intervention_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_intervention (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_intervention_id_seq'),
    intervention_type_id BIGINT REFERENCES vocabulary_intervention_type(id),
    intervention_subtype_id BIGINT REFERENCES vocabulary_intervention_subtype(id),
    code VARCHAR(100),
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_intervention_code_uniq UNIQUE (code)
);

CREATE UNIQUE INDEX IF NOT EXISTS vocabulary_intervention_name_type_uniq
    ON vocabulary_intervention (LOWER(name), COALESCE(intervention_type_id, 0));

ALTER SEQUENCE vocabulary_intervention_id_seq OWNED BY vocabulary_intervention.id;

-- Recruitment lifecycle statuses for registered clinical trials.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_recruitment_status_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_recruitment_status (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_recruitment_status_id_seq'),
    code VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_recruitment_status_code_uniq UNIQUE (code)
);

ALTER SEQUENCE vocabulary_recruitment_status_id_seq OWNED BY vocabulary_recruitment_status.id;

-- Study phases aligned with the harmonised clinical trial data model.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_study_phase_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_study_phase (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_study_phase_id_seq'),
    code VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_study_phase_code_uniq UNIQUE (code)
);

ALTER SEQUENCE vocabulary_study_phase_id_seq OWNED BY vocabulary_study_phase.id;

-- Controlled vocabulary grouping therapeutic condition categories.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_condition_category_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_condition_category (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_condition_category_id_seq'),
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_condition_category_code_uniq UNIQUE (code)
);

ALTER SEQUENCE vocabulary_condition_category_id_seq OWNED BY vocabulary_condition_category.id;

-- Secondary identifier types captured for harmonised registry references.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/
CREATE SEQUENCE IF NOT EXISTS vocabulary_secondary_identify_type_id_seq;

CREATE TABLE IF NOT EXISTS vocabulary_secondary_identify_type (
    id BIGINT PRIMARY KEY DEFAULT nextval('vocabulary_secondary_identify_type_id_seq'),
    code VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT vocabulary_secondary_identify_type_code_uniq UNIQUE (code)
);

ALTER SEQUENCE vocabulary_secondary_identify_type_id_seq OWNED BY vocabulary_secondary_identify_type.id;
