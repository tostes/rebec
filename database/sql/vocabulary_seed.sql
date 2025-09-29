-- Seed data for vocabulary tables

INSERT INTO countries (iso_alpha2, iso_alpha3, name) VALUES
    ('US', 'USA', 'United States'),
    ('CA', 'CAN', 'Canada'),
    ('GB', 'GBR', 'United Kingdom'),
    ('BR', 'BRA', 'Brazil'),
    ('ZA', 'ZAF', 'South Africa')
ON CONFLICT (iso_alpha2) DO NOTHING;

INSERT INTO recruitment_statuses (status_code, description) VALUES
    ('NOT_YET_RECRUITING', 'Trial has been registered but enrollment has not yet begun.'),
    ('RECRUITING', 'Actively recruiting participants.'),
    ('ACTIVE_NOT_RECRUITING', 'Active, but not currently recruiting participants.'),
    ('COMPLETED', 'Study has reached overall completion and data collection has ended.'),
    ('TERMINATED', 'Study has stopped early and will not start again.')
ON CONFLICT (status_code) DO NOTHING;

INSERT INTO intervention_types (type_code, description) VALUES
    ('DRUG', 'Pharmaceutical or biological drug interventions.'),
    ('DEVICE', 'Medical device interventions.'),
    ('PROCEDURE', 'Surgical or procedural interventions.'),
    ('BEHAVIORAL', 'Behavioral, lifestyle, or educational interventions.'),
    ('DIETARY_SUPPLEMENT', 'Vitamins, minerals, and dietary supplements.')
ON CONFLICT (type_code) DO NOTHING;

INSERT INTO study_phases (phase_code, description) VALUES
    ('EARLY_PHASE1', 'Early Phase 1 (formerly Phase 0).'),
    ('PHASE1', 'Phase 1 safety trials.'),
    ('PHASE2', 'Phase 2 efficacy and side effects trials.'),
    ('PHASE3', 'Phase 3 effectiveness trials.'),
    ('PHASE4', 'Phase 4 post-marketing studies.')
ON CONFLICT (phase_code) DO NOTHING;

INSERT INTO condition_categories (category_code, name, description) VALUES
    ('ONCOLOGY', 'Oncology', 'Cancer-related conditions.'),
    ('CARDIO', 'Cardiology', 'Cardiovascular system disorders.'),
    ('NEURO', 'Neurology', 'Brain and nervous system conditions.'),
    ('INFECT', 'Infectious Disease', 'Viral and bacterial infections.'),
    ('ENDO', 'Endocrinology', 'Hormonal and metabolic disorders.')
ON CONFLICT (category_code) DO NOTHING;

