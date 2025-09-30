CREATE OR REPLACE FUNCTION get_full_trial_json_auto_multilang(p_ct_id integer DEFAULT NULL)
RETURNS SETOF jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    v_trials_table regclass;
    v_recruitment_statuses_table regclass;
    v_study_phases_table regclass;
    v_sponsors_table regclass;
    v_trial_countries_table regclass;
    v_countries_table regclass;
    v_interventions_table regclass;
    v_intervention_types_table regclass;
    v_trial_conditions_table regclass;
    v_condition_categories_table regclass;
    v_trial_documents_table regclass;
    v_sql text;
BEGIN
    v_trials_table := COALESCE(to_regclass('ct_trials'), to_regclass('trials'));
    IF v_trials_table IS NULL THEN
        RAISE EXCEPTION 'Trials table not found.';
    END IF;

    v_recruitment_statuses_table := COALESCE(
        to_regclass('ct_recruitment_statuses'),
        to_regclass('recruitment_statuses')
    );
    IF v_recruitment_statuses_table IS NULL THEN
        RAISE EXCEPTION 'Recruitment statuses table not found.';
    END IF;

    v_study_phases_table := COALESCE(to_regclass('ct_study_phases'), to_regclass('study_phases'));
    v_sponsors_table := COALESCE(to_regclass('ct_sponsors'), to_regclass('sponsors'));
    v_trial_countries_table := COALESCE(
        to_regclass('ct_trial_countries'),
        to_regclass('trial_countries')
    );
    v_countries_table := COALESCE(to_regclass('ct_countries'), to_regclass('countries'));
    v_interventions_table := COALESCE(to_regclass('ct_interventions'), to_regclass('interventions'));
    v_intervention_types_table := COALESCE(
        to_regclass('ct_intervention_types'),
        to_regclass('intervention_types')
    );
    v_trial_conditions_table := COALESCE(
        to_regclass('ct_trial_conditions'),
        to_regclass('trial_conditions')
    );
    v_condition_categories_table := COALESCE(
        to_regclass('ct_condition_categories'),
        to_regclass('condition_categories')
    );
    v_trial_documents_table := COALESCE(
        to_regclass('ct_trial_documents'),
        to_regclass('trial_documents')
    );

    v_sql := format(
        $f$
        SELECT jsonb_build_object(
            'trial_id', t.trial_id,
            'public_identifier', t.public_identifier,
            'official_title', t.official_title,
            'brief_summary', t.brief_summary,
            'recruitment_status', jsonb_build_object(
                'id', rs.recruitment_status_id,
                'code', rs.status_code,
                'description', rs.description
            ),
            'study_phase', CASE
                WHEN sp.study_phase_id IS NULL THEN NULL
                ELSE jsonb_build_object(
                    'id', sp.study_phase_id,
                    'code', sp.phase_code,
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
            'countries', COALESCE(country_data.countries, '[]'::jsonb),
            'interventions', COALESCE(intervention_data.interventions, '[]'::jsonb),
            'conditions', COALESCE(condition_data.conditions, '[]'::jsonb),
            'documents', COALESCE(document_data.documents, '[]'::jsonb),
            'created_at', to_jsonb(t.created_at),
            'updated_at', to_jsonb(t.updated_at)
        )
        FROM %1$s AS t
        JOIN %2$s AS rs ON rs.recruitment_status_id = t.recruitment_status_id
        LEFT JOIN %3$s AS sp ON sp.study_phase_id = t.study_phase_id
        LEFT JOIN %4$s AS s ON s.sponsor_id = t.lead_sponsor_id
        LEFT JOIN LATERAL (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'trial_country_id', tc.trial_country_id,
                    'country_id', tc.country_id,
                    'country_code', c.iso_alpha2,
                    'country_name', c.name,
                    'city', tc.city,
                    'site_name', tc.site_name
                ) ORDER BY c.name, tc.city, tc.site_name
            ) AS countries
            FROM %5$s AS tc
            JOIN %6$s AS c ON c.country_id = tc.country_id
            WHERE tc.trial_id = t.trial_id
        ) AS country_data ON TRUE
        LEFT JOIN LATERAL (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'intervention_id', i.intervention_id,
                    'name', i.name,
                    'description', i.description,
                    'intervention_type', jsonb_build_object(
                        'id', it.intervention_type_id,
                        'code', it.type_code,
                        'description', it.description
                    )
                ) ORDER BY i.name
            ) AS interventions
            FROM %7$s AS i
            JOIN %8$s AS it ON it.intervention_type_id = i.intervention_type_id
            WHERE i.trial_id = t.trial_id
        ) AS intervention_data ON TRUE
        LEFT JOIN LATERAL (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'trial_condition_id', tc.trial_condition_id,
                    'condition_name', tc.condition_name,
                    'condition_category', CASE
                        WHEN cc.condition_category_id IS NULL THEN NULL
                        ELSE jsonb_build_object(
                            'id', cc.condition_category_id,
                            'code', cc.category_code,
                            'name', cc.name,
                            'description', cc.description
                        )
                    END
                ) ORDER BY tc.condition_name
            ) AS conditions
            FROM %9$s AS tc
            LEFT JOIN %10$s AS cc ON cc.condition_category_id = tc.condition_category_id
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
            FROM %11$s AS td
            WHERE td.trial_id = t.trial_id
        ) AS document_data ON TRUE
        WHERE ($1 IS NULL OR t.trial_id = $1)
        ORDER BY t.trial_id
        $f$,
        v_trials_table,
        v_recruitment_statuses_table,
        v_study_phases_table,
        v_sponsors_table,
        v_trial_countries_table,
        v_countries_table,
        v_interventions_table,
        v_intervention_types_table,
        v_trial_conditions_table,
        v_condition_categories_table,
        v_trial_documents_table
    );

    RETURN QUERY EXECUTE v_sql USING p_ct_id;
END;
$$;
