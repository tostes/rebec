-- Vocabulary tables for clinical trial administration (ct schema)
-- Updated naming aligns with new ct dump conventions.

CREATE TABLE IF NOT EXISTS vocabulary_country (
    id SERIAL PRIMARY KEY,
    iso_alpha2 CHAR(2) NOT NULL UNIQUE,
    iso_alpha3 CHAR(3) NOT NULL UNIQUE,
    name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS vocabulary_recruitment_status (
    id SERIAL PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS vocabulary_intervention_type (
    id SERIAL PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS vocabulary_study_phase (
    id SERIAL PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS vocabulary_condition_category (
    id SERIAL PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT
);

