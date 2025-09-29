-- Core clinical trial tables that rely on the vocabulary tables.

CREATE TABLE IF NOT EXISTS sponsors (
    sponsor_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    sponsor_type TEXT,
    contact_email TEXT
);

CREATE TABLE IF NOT EXISTS trials (
    trial_id SERIAL PRIMARY KEY,
    public_identifier TEXT NOT NULL UNIQUE,
    official_title TEXT NOT NULL,
    brief_summary TEXT,
    recruitment_status_id INTEGER NOT NULL REFERENCES recruitment_statuses(recruitment_status_id),
    study_phase_id INTEGER REFERENCES study_phases(study_phase_id),
    primary_completion_date DATE,
    overall_completion_date DATE,
    lead_sponsor_id INTEGER REFERENCES sponsors(sponsor_id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS trial_countries (
    trial_country_id SERIAL PRIMARY KEY,
    trial_id INTEGER NOT NULL REFERENCES trials(trial_id) ON DELETE CASCADE,
    country_id INTEGER NOT NULL REFERENCES countries(country_id),
    city TEXT,
    site_name TEXT,
    UNIQUE (trial_id, country_id, COALESCE(city, ''), COALESCE(site_name, ''))
);

CREATE TABLE IF NOT EXISTS interventions (
    intervention_id SERIAL PRIMARY KEY,
    trial_id INTEGER NOT NULL REFERENCES trials(trial_id) ON DELETE CASCADE,
    intervention_type_id INTEGER NOT NULL REFERENCES intervention_types(intervention_type_id),
    name TEXT NOT NULL,
    description TEXT,
    UNIQUE (trial_id, name)
);

CREATE TABLE IF NOT EXISTS trial_conditions (
    trial_condition_id SERIAL PRIMARY KEY,
    trial_id INTEGER NOT NULL REFERENCES trials(trial_id) ON DELETE CASCADE,
    condition_category_id INTEGER REFERENCES condition_categories(condition_category_id),
    condition_name TEXT NOT NULL,
    UNIQUE (trial_id, condition_name)
);

CREATE TABLE IF NOT EXISTS trial_documents (
    trial_document_id SERIAL PRIMARY KEY,
    trial_id INTEGER NOT NULL REFERENCES trials(trial_id) ON DELETE CASCADE,
    document_type TEXT NOT NULL,
    document_url TEXT NOT NULL,
    is_confidential BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

