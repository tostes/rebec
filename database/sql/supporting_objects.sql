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
