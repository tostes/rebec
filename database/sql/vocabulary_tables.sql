-- Vocabulary tables for clinical trial administration
-- These tables hold controlled vocabularies referenced by the core schema.

CREATE TABLE IF NOT EXISTS countries (
    country_id SERIAL PRIMARY KEY,
    iso_alpha2 CHAR(2) NOT NULL UNIQUE,
    iso_alpha3 CHAR(3) NOT NULL UNIQUE,
    name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS recruitment_statuses (
    recruitment_status_id SERIAL PRIMARY KEY,
    status_code TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS intervention_types (
    intervention_type_id SERIAL PRIMARY KEY,
    type_code TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS study_phases (
    study_phase_id SERIAL PRIMARY KEY,
    phase_code TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS condition_categories (
    condition_category_id SERIAL PRIMARY KEY,
    category_code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT
);

