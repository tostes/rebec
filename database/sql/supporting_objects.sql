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
-- Author: REBEC Modernization Team

CREATE OR REPLACE FUNCTION generate_register_code(prefix VARCHAR(3))
RETURNS TEXT AS $$
DECLARE
    v_candidate TEXT;
    v_prefix TEXT := UPPER(prefix);
BEGIN
    IF prefix IS NULL OR LENGTH(prefix) <> 3 THEN
        RAISE EXCEPTION 'Prefix must be exactly three characters';
    END IF;

    LOOP
        v_candidate := v_prefix || UPPER(SUBSTRING(md5(random()::text || clock_timestamp()::text), 1, 6));
        EXIT WHEN NOT EXISTS (
            SELECT 1
            FROM trials
            WHERE public_identifier = v_candidate
        );
    END LOOP;

    RETURN v_candidate;
END;
$$ LANGUAGE plpgsql;

-- Function: get_full_trial_json_auto_multilang(p_ct_id INTEGER)
-- Author: REBEC Modernization Team

CREATE OR REPLACE FUNCTION get_full_trial_json_auto_multilang(p_ct_id INTEGER)
RETURNS JSONB AS $$
DECLARE
    v_payload JSONB;
BEGIN
    IF p_ct_id IS NULL THEN
        RAISE EXCEPTION 'Trial identifier cannot be null';
    END IF;

    SELECT jsonb_build_object(
        'trial_id', t.trial_id,
        'public_identifier', t.public_identifier,
        'official_title', t.official_title,
        'official_title_multilang', CASE
            WHEN t.official_title IS NULL THEN NULL
            ELSE jsonb_strip_nulls(jsonb_build_object(
                'default', t.official_title,
                'pt-BR', t.official_title,
                'en-US', t.official_title
            ))
        END,
        'brief_summary', t.brief_summary,
        'brief_summary_multilang', CASE
            WHEN t.brief_summary IS NULL THEN NULL
            ELSE jsonb_strip_nulls(jsonb_build_object(
                'default', t.brief_summary,
                'pt-BR', t.brief_summary,
                'en-US', t.brief_summary
            ))
        END,
        'recruitment_status', jsonb_build_object(
            'id', rs.id,
            'code', rs.code,
            'description', rs.description
        ),
        'study_phase', CASE
            WHEN sp.id IS NULL THEN NULL
            ELSE jsonb_build_object(
                'id', sp.id,
                'code', sp.code,
                'description', sp.description
            )
        END,
        'primary_completion_date', to_jsonb(t.primary_completion_date),
        'overall_completion_date', to_jsonb(t.overall_completion_date),
        'enrollment', jsonb_strip_nulls(jsonb_build_object(
            'actual', t.enrollment_actual,
            'target', t.enrollment_target
        )),
        'lead_sponsor', CASE
            WHEN s.sponsor_id IS NULL THEN NULL
            ELSE jsonb_build_object(
                'sponsor_id', s.sponsor_id,
                'name', s.name,
                'sponsor_type', s.sponsor_type,
                'contact_email', s.contact_email
            )
        END,
        'responsible_institution', CASE
            WHEN ri.research_institution_id IS NULL THEN NULL
            ELSE jsonb_build_object(
                'research_institution_id', ri.research_institution_id,
                'name', ri.name,
                'country', jsonb_build_object(
                    'id', vc.id,
                    'code', vc.iso_alpha2,
                    'name', vc.name
                ),
                'city', ri.city,
                'state_province', ri.state_province
            )
        END,
        'countries', COALESCE(country_data.countries, '[]'::jsonb),
        'interventions', COALESCE(intervention_data.interventions, '[]'::jsonb),
        'conditions', COALESCE(condition_data.conditions, '[]'::jsonb),
        'documents', COALESCE(document_data.documents, '[]'::jsonb),
        'contacts', COALESCE(contact_data.contacts, '[]'::jsonb),
        'identifiers', COALESCE(identifier_data.identifiers, '[]'::jsonb),
        'status_history', COALESCE(status_history_data.status_history, '[]'::jsonb),
        'created_at', to_jsonb(t.created_at),
        'updated_at', to_jsonb(t.updated_at)
    )
    INTO v_payload
    FROM trials AS t
    JOIN vocabulary_recruitment_status AS rs ON rs.id = t.recruitment_status_id
    LEFT JOIN vocabulary_study_phase AS sp ON sp.id = t.study_phase_id
    LEFT JOIN sponsors AS s ON s.sponsor_id = t.lead_sponsor_id
    LEFT JOIN research_institutions AS ri ON ri.research_institution_id = t.responsible_institution_id
    LEFT JOIN vocabulary_country AS vc ON vc.id = ri.country_id
    LEFT JOIN LATERAL (
        SELECT jsonb_agg(
            jsonb_build_object(
                'trial_country_id', tc.trial_country_id,
                'country_id', tc.country_id,
                'country_code', c.iso_alpha2,
                'country_name', c.name,
                'city', tc.city,
                'site_name', tc.site_name,
                'research_institution_id', tc.research_institution_id
            ) ORDER BY c.name, tc.city, tc.site_name
        ) AS countries
        FROM trial_countries AS tc
        JOIN vocabulary_country AS c ON c.id = tc.country_id
        WHERE tc.trial_id = t.trial_id
    ) AS country_data ON TRUE
    LEFT JOIN LATERAL (
        SELECT jsonb_agg(
            jsonb_build_object(
                'intervention_id', i.intervention_id,
                'name', i.name,
                'description', i.description,
                'intervention_type', jsonb_build_object(
                    'id', it.id,
                    'code', it.code,
                    'description', it.description
                )
            ) ORDER BY i.name
        ) AS interventions
        FROM interventions AS i
        JOIN vocabulary_intervention_type AS it ON it.id = i.intervention_type_id
        WHERE i.trial_id = t.trial_id
    ) AS intervention_data ON TRUE
    LEFT JOIN LATERAL (
        SELECT jsonb_agg(
            jsonb_build_object(
                'trial_condition_id', tc.trial_condition_id,
                'condition_name', tc.condition_name,
                'condition_category', CASE
                    WHEN cc.id IS NULL THEN NULL
                    ELSE jsonb_build_object(
                        'id', cc.id,
                        'code', cc.code,
                        'name', cc.name,
                        'description', cc.description
                    )
                END
            ) ORDER BY tc.condition_name
        ) AS conditions
        FROM trial_conditions AS tc
        LEFT JOIN vocabulary_condition_category AS cc ON cc.id = tc.condition_category_id
        WHERE tc.trial_id = t.trial_id
    ) AS condition_data ON TRUE
    LEFT JOIN LATERAL (
        SELECT jsonb_agg(
            jsonb_build_object(
                'trial_document_id', td.trial_document_id,
                'document_type', td.document_type,
                'document_url', td.document_url,
                'is_confidential', td.is_confidential,
                'created_at', to_jsonb(td.created_at)
            ) ORDER BY td.created_at, td.trial_document_id
        ) AS documents
        FROM trial_documents AS td
        WHERE td.trial_id = t.trial_id
    ) AS document_data ON TRUE
    LEFT JOIN LATERAL (
        SELECT jsonb_agg(
            jsonb_strip_nulls(jsonb_build_object(
                'trial_contact_id', tc.trial_contact_id,
                'contact_type', tc.contact_type,
                'given_name', tc.given_name,
                'family_name', tc.family_name,
                'email', tc.email,
                'phone', tc.phone
            )) ORDER BY tc.trial_contact_id
        ) AS contacts
        FROM trial_contacts AS tc
        WHERE tc.trial_id = t.trial_id
    ) AS contact_data ON TRUE
    LEFT JOIN LATERAL (
        SELECT jsonb_agg(
            jsonb_strip_nulls(jsonb_build_object(
                'trial_identifier_id', ti.trial_identifier_id,
                'identifier_type', ti.identifier_type,
                'identifier_value', ti.identifier_value,
                'issued_by', ti.issued_by
            )) ORDER BY ti.trial_identifier_id
        ) AS identifiers
        FROM trial_identifiers AS ti
        WHERE ti.trial_id = t.trial_id
    ) AS identifier_data ON TRUE
    LEFT JOIN LATERAL (
        SELECT jsonb_agg(
            jsonb_strip_nulls(jsonb_build_object(
                'trial_status_history_id', tsh.trial_status_history_id,
                'status_date', to_jsonb(tsh.status_date),
                'note', tsh.note,
                'recruitment_status', jsonb_build_object(
                    'id', hrs.id,
                    'code', hrs.code,
                    'description', hrs.description
                )
            )) ORDER BY tsh.status_date DESC, tsh.trial_status_history_id DESC
        ) AS status_history
        FROM trial_status_history AS tsh
        JOIN vocabulary_recruitment_status AS hrs ON hrs.id = tsh.recruitment_status_id
        WHERE tsh.trial_id = t.trial_id
    ) AS status_history_data ON TRUE
    WHERE t.trial_id = p_ct_id;

    IF v_payload IS NULL THEN
        RAISE EXCEPTION 'Trial % not found', p_ct_id;
    END IF;

    RETURN v_payload;
END;
$$ LANGUAGE plpgsql;
