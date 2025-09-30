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

-- Function: generate_register_code(prefix VARCHAR(3))
-- Author: Legacy CTMS Data Engineering Team

CREATE OR REPLACE FUNCTION generate_register_code(prefix VARCHAR(3))
RETURNS TEXT AS $$
DECLARE
    v_suffix INTEGER;
    v_candidate TEXT;
BEGIN
    IF prefix IS NULL OR LENGTH(prefix) <> 3 THEN
        RAISE EXCEPTION 'Prefix must be exactly three characters';
    END IF;

    SELECT COALESCE(MAX(SUBSTRING(register_id FROM 4)::INTEGER), 0) + 1
    INTO v_suffix
    FROM ct
    WHERE register_id LIKE prefix || '%';

    LOOP
        v_candidate := prefix || TO_CHAR(v_suffix, 'FM0000000');
        EXIT WHEN NOT EXISTS (
            SELECT 1
            FROM ct
            WHERE register_id = v_candidate
        );
        v_suffix := v_suffix + 1;
    END LOOP;

    RETURN v_candidate;
END;
$$ LANGUAGE plpgsql;
