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
