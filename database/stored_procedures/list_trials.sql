CREATE OR REPLACE FUNCTION list_trials()
RETURNS SETOF jsonb
LANGUAGE sql
AS $$
    SELECT jsonb_build_object(
        'ct_id', c.id,
        'register_id', c.register_id,
        'public_title', c.public_title,
        'scientific_title', c.scientific_title,
        'brief_summary', c.brief_summary,
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
        'primary_sponsor', CASE
            WHEN ps.id IS NULL THEN NULL
            ELSE jsonb_build_object(
                'id', ps.id,
                'name', ps.name,
                'email', ps.email,
                'country_id', ps.country_id
            )
        END,
        'responsible_institution', CASE
            WHEN ri.id IS NULL THEN NULL
            ELSE jsonb_build_object(
                'id', ri.id,
                'name', ri.name,
                'country', CASE
                    WHEN ric.id IS NULL THEN NULL
                    ELSE jsonb_build_object(
                        'id', ric.id,
                        'code', ric.iso_alpha2,
                        'name', ric.name
                    )
                END
            )
        END,
        'locations', COALESCE(location_data.locations, '[]'::jsonb),
        'interventions', COALESCE(intervention_data.interventions, '[]'::jsonb),
        'conditions', COALESCE(condition_data.conditions, '[]'::jsonb),
        'documents', COALESCE(document_data.documents, '[]'::jsonb),
        'created_at', to_jsonb(c.created_at),
        'updated_at', to_jsonb(c.updated_at)
    )
    FROM ct AS c
    JOIN vocabulary_recruitment_status AS rs ON rs.id = c.recruitment_status_id
    LEFT JOIN vocabulary_study_phase AS sp ON sp.id = c.study_phase_id
    LEFT JOIN vocabulary_institution AS ps ON ps.id = c.primary_sponsor_id
    LEFT JOIN vocabulary_institution AS ri ON ri.id = c.responsible_institution_id
    LEFT JOIN vocabulary_country AS ric ON ric.id = ri.country_id
    LEFT JOIN LATERAL (
        SELECT jsonb_agg(
            jsonb_build_object(
                'ct_location_id', cl.id,
                'country', jsonb_build_object(
                    'id', loc_country.id,
                    'code', loc_country.iso_alpha2,
                    'name', loc_country.name
                ),
                'state', cl.state,
                'city', cl.city,
                'institution', CASE
                    WHEN loc_inst.id IS NULL THEN NULL
                    ELSE jsonb_build_object(
                        'id', loc_inst.id,
                        'name', loc_inst.name
                    )
                END,
                'postal_code', cl.postal_code,
                'status', cl.status
            ) ORDER BY loc_country.name, cl.state, cl.city
        ) AS locations
        FROM ct_location AS cl
        JOIN vocabulary_country AS loc_country ON loc_country.id = cl.country_id
        LEFT JOIN vocabulary_institution AS loc_inst ON loc_inst.id = cl.institution_id
        WHERE cl.ct_id = c.id
    ) AS location_data ON TRUE
    LEFT JOIN LATERAL (
        SELECT jsonb_agg(
            jsonb_build_object(
                'ct_intervention_id', ci.id,
                'name', ci.name,
                'description', ci.description,
                'intervention_type', CASE
                    WHEN it.id IS NULL THEN NULL
                    ELSE jsonb_build_object(
                        'id', it.id,
                        'code', it.code,
                        'description', it.description
                    )
                END,
                'intervention_category', CASE
                    WHEN icat.id IS NULL THEN NULL
                    ELSE jsonb_build_object(
                        'id', icat.id,
                        'code', icat.code,
                        'description', icat.description
                    )
                END
            ) ORDER BY ci.name
        ) AS interventions
        FROM ct_intervention AS ci
        LEFT JOIN vocabulary_intervention_type AS it ON it.id = ci.intervention_type_id
        LEFT JOIN vocabulary_intervention_category AS icat ON icat.id = ci.intervention_category_id
        WHERE ci.ct_id = c.id
    ) AS intervention_data ON TRUE
    LEFT JOIN LATERAL (
        SELECT jsonb_agg(
            jsonb_build_object(
                'ct_condition_id', cc.id,
                'condition_name', cc.condition_name,
                'condition_category', CASE
                    WHEN cat.id IS NULL THEN NULL
                    ELSE jsonb_build_object(
                        'id', cat.id,
                        'code', cat.code,
                        'name', cat.name,
                        'description', cat.description
                    )
                END
            ) ORDER BY cc.condition_name
        ) AS conditions
        FROM ct_condition AS cc
        LEFT JOIN vocabulary_condition_category AS cat ON cat.id = cc.condition_category_id
        WHERE cc.ct_id = c.id
    ) AS condition_data ON TRUE
    LEFT JOIN LATERAL (
        SELECT jsonb_agg(
            jsonb_build_object(
                'ct_document_id', cd.id,
                'document_type', cd.document_type,
                'url', cd.url,
                'file_name', cd.file_name,
                'uploaded_at', to_jsonb(cd.uploaded_at)
            ) ORDER BY cd.uploaded_at, cd.id
        ) AS documents
        FROM ct_document AS cd
        WHERE cd.ct_id = c.id
    ) AS document_data ON TRUE
    ORDER BY c.id;
$$;
