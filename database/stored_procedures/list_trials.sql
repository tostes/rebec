CREATE OR REPLACE FUNCTION list_trials()
RETURNS SETOF jsonb
LANGUAGE sql
AS $$
    SELECT jsonb_build_object(
        'trial_id', t.trial_id,
        'public_identifier', t.public_identifier,
        'official_title', t.official_title,
        'brief_summary', t.brief_summary,
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
        'created_at', to_jsonb(t.created_at),
        'updated_at', to_jsonb(t.updated_at)
    )
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
    ORDER BY t.trial_id;
$$;
