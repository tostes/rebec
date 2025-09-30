CREATE OR REPLACE FUNCTION get_or_create_sponsor(p_name TEXT, p_type TEXT, p_email TEXT)
RETURNS BIGINT AS $$
DECLARE
    v_id BIGINT;
BEGIN
    IF p_name IS NULL OR btrim(p_name) = '' THEN
        RETURN NULL;
    END IF;

    SELECT id INTO v_id
    FROM vocabulary_institution
    WHERE name = p_name;

    IF v_id IS NULL THEN
        INSERT INTO vocabulary_institution(name, email)
        VALUES (p_name, p_email)
        RETURNING id INTO v_id;
    ELSE
        UPDATE vocabulary_institution
        SET email = COALESCE(p_email, email),
            updated_at = NOW()
        WHERE id = v_id;
    END IF;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;
