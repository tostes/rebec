-- Clinical trial schema extracted from ct schema dump
-- Recreates tables, sequences, defaults, primary keys, foreign keys, and indexes.

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

--
-- Name: sponsors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS sponsors (
    sponsor_id integer NOT NULL,
    name text NOT NULL,
    sponsor_type text,
    contact_email text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE SEQUENCE IF NOT EXISTS sponsors_sponsor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE sponsors_sponsor_id_seq OWNED BY sponsors.sponsor_id;

ALTER TABLE ONLY sponsors ALTER COLUMN sponsor_id SET DEFAULT nextval('sponsors_sponsor_id_seq'::regclass);

ALTER TABLE ONLY sponsors
    ADD CONSTRAINT sponsors_pkey PRIMARY KEY (sponsor_id);

CREATE UNIQUE INDEX IF NOT EXISTS sponsors_name_lower_idx ON sponsors (lower(name));

--
-- Name: research_institutions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS research_institutions (
    research_institution_id integer NOT NULL,
    name text NOT NULL,
    institution_type text,
    country_id integer NOT NULL,
    city text,
    state_province text,
    postal_code text,
    contact_email text,
    phone text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE SEQUENCE IF NOT EXISTS research_institutions_research_institution_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE research_institutions_research_institution_id_seq OWNED BY research_institutions.research_institution_id;

ALTER TABLE ONLY research_institutions
    ALTER COLUMN research_institution_id SET DEFAULT nextval('research_institutions_research_institution_id_seq'::regclass);

ALTER TABLE ONLY research_institutions
    ADD CONSTRAINT research_institutions_pkey PRIMARY KEY (research_institution_id);

CREATE UNIQUE INDEX IF NOT EXISTS research_institutions_name_country_idx
    ON research_institutions (lower(name), country_id, COALESCE(lower(city), ''), COALESCE(lower(state_province), ''));

ALTER TABLE ONLY research_institutions
    ADD CONSTRAINT research_institutions_country_id_fkey FOREIGN KEY (country_id) REFERENCES vocabulary_country(id);

--
-- Name: trials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS trials (
    trial_id integer NOT NULL,
    public_identifier text NOT NULL,
    official_title text NOT NULL,
    brief_summary text,
    recruitment_status_id integer NOT NULL,
    study_phase_id integer,
    lead_sponsor_id integer,
    responsible_institution_id integer,
    primary_completion_date date,
    overall_completion_date date,
    enrollment_actual integer,
    enrollment_target integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE SEQUENCE IF NOT EXISTS trials_trial_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE trials_trial_id_seq OWNED BY trials.trial_id;

ALTER TABLE ONLY trials ALTER COLUMN trial_id SET DEFAULT nextval('trials_trial_id_seq'::regclass);

ALTER TABLE ONLY trials
    ADD CONSTRAINT trials_pkey PRIMARY KEY (trial_id);

CREATE UNIQUE INDEX IF NOT EXISTS trials_public_identifier_lower_idx ON trials (lower(public_identifier));

ALTER TABLE ONLY trials
    ADD CONSTRAINT trials_lead_sponsor_id_fkey FOREIGN KEY (lead_sponsor_id) REFERENCES sponsors(sponsor_id);

ALTER TABLE ONLY trials
    ADD CONSTRAINT trials_recruitment_status_id_fkey FOREIGN KEY (recruitment_status_id) REFERENCES vocabulary_recruitment_status(id);

ALTER TABLE ONLY trials
    ADD CONSTRAINT trials_responsible_institution_id_fkey FOREIGN KEY (responsible_institution_id) REFERENCES research_institutions(research_institution_id);

ALTER TABLE ONLY trials
    ADD CONSTRAINT trials_study_phase_id_fkey FOREIGN KEY (study_phase_id) REFERENCES vocabulary_study_phase(id);

--
-- Name: trial_countries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS trial_countries (
    trial_country_id integer NOT NULL,
    trial_id integer NOT NULL,
    country_id integer NOT NULL,
    city text,
    site_name text,
    research_institution_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE SEQUENCE IF NOT EXISTS trial_countries_trial_country_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE trial_countries_trial_country_id_seq OWNED BY trial_countries.trial_country_id;

ALTER TABLE ONLY trial_countries ALTER COLUMN trial_country_id SET DEFAULT nextval('trial_countries_trial_country_id_seq'::regclass);

ALTER TABLE ONLY trial_countries
    ADD CONSTRAINT trial_countries_pkey PRIMARY KEY (trial_country_id);

CREATE UNIQUE INDEX IF NOT EXISTS trial_countries_unique_idx
    ON trial_countries (trial_id, country_id, COALESCE(lower(city), ''), COALESCE(lower(site_name), ''), COALESCE(research_institution_id, 0));

ALTER TABLE ONLY trial_countries
    ADD CONSTRAINT trial_countries_country_id_fkey FOREIGN KEY (country_id) REFERENCES vocabulary_country(id);

ALTER TABLE ONLY trial_countries
    ADD CONSTRAINT trial_countries_trial_id_fkey FOREIGN KEY (trial_id) REFERENCES trials(trial_id) ON DELETE CASCADE;

ALTER TABLE ONLY trial_countries
    ADD CONSTRAINT trial_countries_research_institution_id_fkey FOREIGN KEY (research_institution_id) REFERENCES research_institutions(research_institution_id) ON DELETE SET NULL;

--
-- Name: interventions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS interventions (
    intervention_id integer NOT NULL,
    trial_id integer NOT NULL,
    intervention_type_id integer NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE SEQUENCE IF NOT EXISTS interventions_intervention_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE interventions_intervention_id_seq OWNED BY interventions.intervention_id;

ALTER TABLE ONLY interventions ALTER COLUMN intervention_id SET DEFAULT nextval('interventions_intervention_id_seq'::regclass);

ALTER TABLE ONLY interventions
    ADD CONSTRAINT interventions_pkey PRIMARY KEY (intervention_id);

CREATE UNIQUE INDEX IF NOT EXISTS interventions_trial_id_name_key
    ON interventions (trial_id, lower(name));

ALTER TABLE ONLY interventions
    ADD CONSTRAINT interventions_intervention_type_id_fkey FOREIGN KEY (intervention_type_id) REFERENCES vocabulary_intervention_type(id);

ALTER TABLE ONLY interventions
    ADD CONSTRAINT interventions_trial_id_fkey FOREIGN KEY (trial_id) REFERENCES trials(trial_id) ON DELETE CASCADE;

--
-- Name: trial_conditions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS trial_conditions (
    trial_condition_id integer NOT NULL,
    trial_id integer NOT NULL,
    condition_category_id integer,
    condition_name text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE SEQUENCE IF NOT EXISTS trial_conditions_trial_condition_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE trial_conditions_trial_condition_id_seq OWNED BY trial_conditions.trial_condition_id;

ALTER TABLE ONLY trial_conditions ALTER COLUMN trial_condition_id SET DEFAULT nextval('trial_conditions_trial_condition_id_seq'::regclass);

ALTER TABLE ONLY trial_conditions
    ADD CONSTRAINT trial_conditions_pkey PRIMARY KEY (trial_condition_id);

CREATE UNIQUE INDEX IF NOT EXISTS trial_conditions_trial_id_condition_name_key
    ON trial_conditions (trial_id, lower(condition_name));

ALTER TABLE ONLY trial_conditions
    ADD CONSTRAINT trial_conditions_condition_category_id_fkey FOREIGN KEY (condition_category_id) REFERENCES vocabulary_condition_category(id);

ALTER TABLE ONLY trial_conditions
    ADD CONSTRAINT trial_conditions_trial_id_fkey FOREIGN KEY (trial_id) REFERENCES trials(trial_id) ON DELETE CASCADE;

--
-- Name: trial_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS trial_documents (
    trial_document_id integer NOT NULL,
    trial_id integer NOT NULL,
    document_type text NOT NULL,
    document_url text NOT NULL,
    is_confidential boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE SEQUENCE IF NOT EXISTS trial_documents_trial_document_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE trial_documents_trial_document_id_seq OWNED BY trial_documents.trial_document_id;

ALTER TABLE ONLY trial_documents ALTER COLUMN trial_document_id SET DEFAULT nextval('trial_documents_trial_document_id_seq'::regclass);

ALTER TABLE ONLY trial_documents
    ADD CONSTRAINT trial_documents_pkey PRIMARY KEY (trial_document_id);

ALTER TABLE ONLY trial_documents
    ADD CONSTRAINT trial_documents_trial_id_fkey FOREIGN KEY (trial_id) REFERENCES trials(trial_id) ON DELETE CASCADE;

--
-- Name: trial_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS trial_contacts (
    trial_contact_id integer NOT NULL,
    trial_id integer NOT NULL,
    contact_type text NOT NULL,
    given_name text,
    family_name text,
    email text,
    phone text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE SEQUENCE IF NOT EXISTS trial_contacts_trial_contact_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE trial_contacts_trial_contact_id_seq OWNED BY trial_contacts.trial_contact_id;

ALTER TABLE ONLY trial_contacts ALTER COLUMN trial_contact_id SET DEFAULT nextval('trial_contacts_trial_contact_id_seq'::regclass);

ALTER TABLE ONLY trial_contacts
    ADD CONSTRAINT trial_contacts_pkey PRIMARY KEY (trial_contact_id);

CREATE UNIQUE INDEX IF NOT EXISTS trial_contacts_unique_idx
    ON trial_contacts (trial_id, lower(COALESCE(email, '')), lower(COALESCE(phone, '')), contact_type);

ALTER TABLE ONLY trial_contacts
    ADD CONSTRAINT trial_contacts_trial_id_fkey FOREIGN KEY (trial_id) REFERENCES trials(trial_id) ON DELETE CASCADE;

--
-- Name: trial_status_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS trial_status_history (
    trial_status_history_id integer NOT NULL,
    trial_id integer NOT NULL,
    recruitment_status_id integer NOT NULL,
    status_date date NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE SEQUENCE IF NOT EXISTS trial_status_history_trial_status_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE trial_status_history_trial_status_history_id_seq OWNED BY trial_status_history.trial_status_history_id;

ALTER TABLE ONLY trial_status_history ALTER COLUMN trial_status_history_id SET DEFAULT nextval('trial_status_history_trial_status_history_id_seq'::regclass);

ALTER TABLE ONLY trial_status_history
    ADD CONSTRAINT trial_status_history_pkey PRIMARY KEY (trial_status_history_id);

CREATE UNIQUE INDEX IF NOT EXISTS trial_status_history_unique_idx
    ON trial_status_history (trial_id, recruitment_status_id, status_date);

ALTER TABLE ONLY trial_status_history
    ADD CONSTRAINT trial_status_history_recruitment_status_id_fkey FOREIGN KEY (recruitment_status_id) REFERENCES vocabulary_recruitment_status(id);

ALTER TABLE ONLY trial_status_history
    ADD CONSTRAINT trial_status_history_trial_id_fkey FOREIGN KEY (trial_id) REFERENCES trials(trial_id) ON DELETE CASCADE;

--
-- Name: trial_identifiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS trial_identifiers (
    trial_identifier_id integer NOT NULL,
    trial_id integer NOT NULL,
    identifier_type text NOT NULL,
    identifier_value text NOT NULL,
    issued_by text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE SEQUENCE IF NOT EXISTS trial_identifiers_trial_identifier_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE trial_identifiers_trial_identifier_id_seq OWNED BY trial_identifiers.trial_identifier_id;

ALTER TABLE ONLY trial_identifiers ALTER COLUMN trial_identifier_id SET DEFAULT nextval('trial_identifiers_trial_identifier_id_seq'::regclass);

ALTER TABLE ONLY trial_identifiers
    ADD CONSTRAINT trial_identifiers_pkey PRIMARY KEY (trial_identifier_id);

CREATE UNIQUE INDEX IF NOT EXISTS trial_identifiers_unique_idx
    ON trial_identifiers (trial_id, lower(identifier_type), lower(identifier_value));

ALTER TABLE ONLY trial_identifiers
    ADD CONSTRAINT trial_identifiers_trial_id_fkey FOREIGN KEY (trial_id) REFERENCES trials(trial_id) ON DELETE CASCADE;

