-- Supporting database objects: functions, procedures, and triggers

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'trials_set_updated_at'
    ) THEN
        CREATE TRIGGER trials_set_updated_at
        BEFORE UPDATE ON trials
        FOR EACH ROW
        EXECUTE FUNCTION set_updated_at();
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION get_or_create_sponsor(p_name TEXT, p_type TEXT, p_email TEXT)
RETURNS INTEGER AS $$
DECLARE
    v_id INTEGER;
BEGIN
    IF p_name IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT sponsor_id INTO v_id
    FROM sponsors
    WHERE name = p_name;

    IF v_id IS NULL THEN
        INSERT INTO sponsors(name, sponsor_type, contact_email)
        VALUES (p_name, p_type, p_email)
        RETURNING sponsor_id INTO v_id;
    END IF;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE create_trial(
    p_public_identifier TEXT,
    p_official_title TEXT,
    p_recruitment_status_code TEXT,
    p_study_phase_code TEXT DEFAULT NULL,
    p_brief_summary TEXT DEFAULT NULL,
    p_lead_sponsor_name TEXT DEFAULT NULL,
    p_lead_sponsor_type TEXT DEFAULT NULL,
    p_lead_sponsor_email TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_recruitment_status_id INTEGER;
    v_study_phase_id INTEGER;
    v_lead_sponsor_id INTEGER;
BEGIN
    SELECT recruitment_status_id INTO v_recruitment_status_id
    FROM recruitment_statuses
    WHERE status_code = p_recruitment_status_code;

    IF v_recruitment_status_id IS NULL THEN
        RAISE EXCEPTION 'Unknown recruitment status code: %', p_recruitment_status_code;
    END IF;

    IF p_study_phase_code IS NOT NULL THEN
        SELECT study_phase_id INTO v_study_phase_id
        FROM study_phases
        WHERE phase_code = p_study_phase_code;

        IF v_study_phase_id IS NULL THEN
            RAISE EXCEPTION 'Unknown study phase code: %', p_study_phase_code;
        END IF;
    END IF;

    v_lead_sponsor_id := get_or_create_sponsor(p_lead_sponsor_name, p_lead_sponsor_type, p_lead_sponsor_email);

    INSERT INTO trials (
        public_identifier,
        official_title,
        recruitment_status_id,
        study_phase_id,
        brief_summary,
        lead_sponsor_id
    )
    VALUES (
        p_public_identifier,
        p_official_title,
        v_recruitment_status_id,
        v_study_phase_id,
        p_brief_summary,
        v_lead_sponsor_id
    );
END;
$$;

