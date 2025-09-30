CREATE OR REPLACE PROCEDURE create_trial(
    p_register_id TEXT,
    p_public_title TEXT,
    p_recruitment_status_code TEXT,
    p_study_phase_code TEXT DEFAULT NULL,
    p_brief_summary TEXT DEFAULT NULL,
    p_primary_sponsor_name TEXT DEFAULT NULL,
    p_primary_sponsor_type TEXT DEFAULT NULL,
    p_primary_sponsor_email TEXT DEFAULT NULL,
    p_responsible_institution_id BIGINT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_recruitment_status_id BIGINT;
    v_study_phase_id BIGINT;
    v_primary_sponsor_id BIGINT;
BEGIN
    SELECT id INTO v_recruitment_status_id
    FROM vocabulary_recruitment_status
    WHERE code = p_recruitment_status_code;

    IF v_recruitment_status_id IS NULL THEN
        RAISE EXCEPTION 'Unknown recruitment status code: %', p_recruitment_status_code;
    END IF;

    IF p_study_phase_code IS NOT NULL THEN
        SELECT id INTO v_study_phase_id
        FROM vocabulary_study_phase
        WHERE code = p_study_phase_code;

        IF v_study_phase_id IS NULL THEN
            RAISE EXCEPTION 'Unknown study phase code: %', p_study_phase_code;
        END IF;
    END IF;

    v_primary_sponsor_id := get_or_create_sponsor(p_primary_sponsor_name, p_primary_sponsor_type, p_primary_sponsor_email);

    INSERT INTO ct (
        register_id,
        public_title,
        scientific_title,
        recruitment_status_id,
        study_phase_id,
        brief_summary,
        primary_sponsor_id,
        responsible_institution_id
    )
    VALUES (
        p_register_id,
        p_public_title,
        p_public_title,
        v_recruitment_status_id,
        v_study_phase_id,
        p_brief_summary,
        v_primary_sponsor_id,
        p_responsible_institution_id
    );
END;
$$;
