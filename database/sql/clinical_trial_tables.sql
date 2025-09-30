-- Clinical trial schema reconstructed from consolidated ct dump
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/>
--
-- This script recreates the PostgreSQL objects that compose the new
-- clinical trial data model. It mirrors the structures extracted from
-- the `ct` schema dump, preserving sequences, defaults, primary keys,
-- foreign keys, indexes, and author comments.

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', 'public', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Core clinical trial registration table.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/>
CREATE SEQUENCE IF NOT EXISTS ct_id_seq;

CREATE TABLE IF NOT EXISTS ct (
    id BIGINT PRIMARY KEY DEFAULT nextval('ct_id_seq'),
    register_id VARCHAR(15) NOT NULL,
    protocol_number TEXT,
    universal_trial_number TEXT,
    public_title TEXT NOT NULL,
    scientific_title TEXT,
    acronym VARCHAR(50),
    recruitment_status_id BIGINT NOT NULL REFERENCES vocabulary_recruitment_status(id),
    study_phase_id BIGINT REFERENCES vocabulary_study_phase(id),
    brief_summary TEXT,
    detailed_description TEXT,
    enrollment_target INTEGER,
    enrollment_actual INTEGER,
    enrollment_type TEXT,
    study_start_date DATE,
    primary_completion_date DATE,
    completion_date DATE,
    responsible_institution_id BIGINT REFERENCES vocabulary_institution(id),
    primary_sponsor_id BIGINT REFERENCES vocabulary_institution(id),
    study_sponsor_id BIGINT REFERENCES vocabulary_institution(id),
    is_imported BOOLEAN NOT NULL DEFAULT FALSE,
    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ct_register_id_uniq UNIQUE (register_id)
);

ALTER SEQUENCE ct_id_seq OWNED BY ct.id;

COMMENT ON TABLE ct IS 'Main registry record for a clinical trial as defined in the ct dump.';
COMMENT ON COLUMN ct.register_id IS 'Unique registration identifier assigned by the platform.';
COMMENT ON COLUMN ct.recruitment_status_id IS 'Links to vocabulary_recruitment_status.';
COMMENT ON COLUMN ct.study_phase_id IS 'Links to vocabulary_study_phase.';
COMMENT ON COLUMN ct.responsible_institution_id IS 'Institution responsible for conducting the trial.';
COMMENT ON COLUMN ct.primary_sponsor_id IS 'Primary sponsor institution.';
COMMENT ON COLUMN ct.study_sponsor_id IS 'Administrative sponsor or funding source.';

-- Secondary identifiers associated with a clinical trial.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/>
CREATE SEQUENCE IF NOT EXISTS ct_identifier_id_seq;

CREATE TABLE IF NOT EXISTS ct_identifier (
    id BIGINT PRIMARY KEY DEFAULT nextval('ct_identifier_id_seq'),
    ct_id BIGINT NOT NULL REFERENCES ct(id) ON DELETE CASCADE,
    identifier_type TEXT NOT NULL,
    identifier_value TEXT NOT NULL,
    issuing_authority TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ct_identifier_ct_id_identifier_value_uniq UNIQUE (ct_id, identifier_type, identifier_value)
);

ALTER SEQUENCE ct_identifier_id_seq OWNED BY ct_identifier.id;

COMMENT ON TABLE ct_identifier IS 'External identifiers (sponsor codes, registry numbers) for the clinical trial.';

-- Institutions related to the trial and their roles.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/>
CREATE SEQUENCE IF NOT EXISTS ct_institution_id_seq;

CREATE TABLE IF NOT EXISTS ct_institution (
    id BIGINT PRIMARY KEY DEFAULT nextval('ct_institution_id_seq'),
    ct_id BIGINT NOT NULL REFERENCES ct(id) ON DELETE CASCADE,
    institution_id BIGINT NOT NULL REFERENCES vocabulary_institution(id),
    role TEXT NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ct_institution_role_chk CHECK (role <> '')
);

ALTER SEQUENCE ct_institution_id_seq OWNED BY ct_institution.id;

COMMENT ON TABLE ct_institution IS 'Associates registered institutions to the clinical trial with a specific role.';

-- Contact information for the clinical trial.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/>
CREATE SEQUENCE IF NOT EXISTS ct_contact_id_seq;

CREATE TABLE IF NOT EXISTS ct_contact (
    id BIGINT PRIMARY KEY DEFAULT nextval('ct_contact_id_seq'),
    ct_id BIGINT NOT NULL REFERENCES ct(id) ON DELETE CASCADE,
    contact_role TEXT NOT NULL,
    person_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    institution_id BIGINT REFERENCES vocabulary_institution(id),
    country_id BIGINT REFERENCES vocabulary_country(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ct_contact_role_chk CHECK (contact_role <> '')
);

ALTER SEQUENCE ct_contact_id_seq OWNED BY ct_contact.id;

COMMENT ON TABLE ct_contact IS 'Contact roster for the trial (scientific and public contacts).';

-- Reported conditions linked to the trial.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/>
CREATE SEQUENCE IF NOT EXISTS ct_condition_id_seq;

CREATE TABLE IF NOT EXISTS ct_condition (
    id BIGINT PRIMARY KEY DEFAULT nextval('ct_condition_id_seq'),
    ct_id BIGINT NOT NULL REFERENCES ct(id) ON DELETE CASCADE,
    condition_name TEXT NOT NULL,
    condition_category_id BIGINT REFERENCES vocabulary_condition_category(id),
    mesh_term TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER SEQUENCE ct_condition_id_seq OWNED BY ct_condition.id;

COMMENT ON TABLE ct_condition IS 'Diseases or health conditions targeted by the clinical trial.';

-- Declared keywords supporting free-text search.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/>
CREATE SEQUENCE IF NOT EXISTS ct_keyword_id_seq;

CREATE TABLE IF NOT EXISTS ct_keyword (
    id BIGINT PRIMARY KEY DEFAULT nextval('ct_keyword_id_seq'),
    ct_id BIGINT NOT NULL REFERENCES ct(id) ON DELETE CASCADE,
    keyword TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ct_keyword_keyword_chk CHECK (keyword <> '')
);

ALTER SEQUENCE ct_keyword_id_seq OWNED BY ct_keyword.id;

COMMENT ON TABLE ct_keyword IS 'Search keywords supplied by the registrant.';

-- Study interventions.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/>
CREATE SEQUENCE IF NOT EXISTS ct_intervention_id_seq;

CREATE TABLE IF NOT EXISTS ct_intervention (
    id BIGINT PRIMARY KEY DEFAULT nextval('ct_intervention_id_seq'),
    ct_id BIGINT NOT NULL REFERENCES ct(id) ON DELETE CASCADE,
    intervention_type_id BIGINT REFERENCES vocabulary_intervention_type(id),
    intervention_category_id BIGINT REFERENCES vocabulary_intervention_category(id),
    name TEXT NOT NULL,
    description TEXT,
    other_names TEXT,
    arm_group TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER SEQUENCE ct_intervention_id_seq OWNED BY ct_intervention.id;

COMMENT ON TABLE ct_intervention IS 'Interventions evaluated in the clinical trial.';

-- Outcome measures declared by the investigators.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/>
CREATE SEQUENCE IF NOT EXISTS ct_outcome_id_seq;

CREATE TABLE IF NOT EXISTS ct_outcome (
    id BIGINT PRIMARY KEY DEFAULT nextval('ct_outcome_id_seq'),
    ct_id BIGINT NOT NULL REFERENCES ct(id) ON DELETE CASCADE,
    outcome_type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    time_frame TEXT,
    is_safety_issue BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ct_outcome_type_chk CHECK (outcome_type IN ('PRIMARY', 'SECONDARY', 'OTHER'))
);

ALTER SEQUENCE ct_outcome_id_seq OWNED BY ct_outcome.id;

COMMENT ON TABLE ct_outcome IS 'Primary and secondary outcome measures for the clinical trial.';

-- Recruitment locations and facilities.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/>
CREATE SEQUENCE IF NOT EXISTS ct_location_id_seq;

CREATE TABLE IF NOT EXISTS ct_location (
    id BIGINT PRIMARY KEY DEFAULT nextval('ct_location_id_seq'),
    ct_id BIGINT NOT NULL REFERENCES ct(id) ON DELETE CASCADE,
    country_id BIGINT NOT NULL REFERENCES vocabulary_country(id),
    state TEXT,
    city TEXT,
    institution_id BIGINT REFERENCES vocabulary_institution(id),
    postal_code TEXT,
    status TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER SEQUENCE ct_location_id_seq OWNED BY ct_location.id;

COMMENT ON TABLE ct_location IS 'Geographic locations where the trial recruits participants.';

-- Documents uploaded or referenced by the registrant.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/>
CREATE SEQUENCE IF NOT EXISTS ct_document_id_seq;

CREATE TABLE IF NOT EXISTS ct_document (
    id BIGINT PRIMARY KEY DEFAULT nextval('ct_document_id_seq'),
    ct_id BIGINT NOT NULL REFERENCES ct(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL,
    description TEXT,
    url TEXT,
    file_name TEXT,
    version TEXT,
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER SEQUENCE ct_document_id_seq OWNED BY ct_document.id;

COMMENT ON TABLE ct_document IS 'Registry documents (protocols, consent forms, approvals).';

-- Ethics committee approvals linked to the trial.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/>
CREATE SEQUENCE IF NOT EXISTS ct_ethics_approval_id_seq;

CREATE TABLE IF NOT EXISTS ct_ethics_approval (
    id BIGINT PRIMARY KEY DEFAULT nextval('ct_ethics_approval_id_seq'),
    ct_id BIGINT NOT NULL REFERENCES ct(id) ON DELETE CASCADE,
    committee_name TEXT NOT NULL,
    approval_number TEXT,
    approval_date DATE,
    institution_id BIGINT REFERENCES vocabulary_institution(id),
    country_id BIGINT REFERENCES vocabulary_country(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER SEQUENCE ct_ethics_approval_id_seq OWNED BY ct_ethics_approval.id;

COMMENT ON TABLE ct_ethics_approval IS 'Institutional review board approvals associated with the trial.';

-- Recruitment milestones to trace historical changes.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/>
CREATE SEQUENCE IF NOT EXISTS ct_status_history_id_seq;

CREATE TABLE IF NOT EXISTS ct_status_history (
    id BIGINT PRIMARY KEY DEFAULT nextval('ct_status_history_id_seq'),
    ct_id BIGINT NOT NULL REFERENCES ct(id) ON DELETE CASCADE,
    recruitment_status_id BIGINT NOT NULL REFERENCES vocabulary_recruitment_status(id),
    status_date DATE NOT NULL,
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER SEQUENCE ct_status_history_id_seq OWNED BY ct_status_history.id;

COMMENT ON TABLE ct_status_history IS 'Historical log of recruitment status transitions for the trial.';

-- Auditing table capturing raw import metadata.
-- Author: Diego Tostes – <https://www.linkedin.com/in/diegotostes/>
CREATE SEQUENCE IF NOT EXISTS ct_import_log_id_seq;

CREATE TABLE IF NOT EXISTS ct_import_log (
    id BIGINT PRIMARY KEY DEFAULT nextval('ct_import_log_id_seq'),
    ct_id BIGINT REFERENCES ct(id) ON DELETE SET NULL,
    source_system TEXT NOT NULL,
    source_identifier TEXT,
    payload JSONB,
    imported_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER SEQUENCE ct_import_log_id_seq OWNED BY ct_import_log.id;

COMMENT ON TABLE ct_import_log IS 'Stores metadata about imported records from external registries.';

