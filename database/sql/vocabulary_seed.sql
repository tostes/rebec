-- Seed data for vocabulary tables aligned with ct schema naming

INSERT INTO vocabulary_country (iso_alpha2, iso_alpha3, name) VALUES
    ('US', 'USA', 'United States'),
    ('CA', 'CAN', 'Canada'),
    ('GB', 'GBR', 'United Kingdom'),
    ('BR', 'BRA', 'Brazil'),
    ('ZA', 'ZAF', 'South Africa')
ON CONFLICT (iso_alpha2) DO NOTHING;

INSERT INTO vocabulary_intervention_category (code, name, description) VALUES
    ('MEDICINAL_PRODUCT', 'Medicinal Product', 'Drug, biologic, or vaccine based interventions.'),
    ('MEDICAL_DEVICE', 'Medical Device', 'Devices, equipment, or diagnostic tools used in interventions.'),
    ('NON_MEDICAL', 'Non-medical', 'Behavioral, dietary, educational, or procedural interventions.')
ON CONFLICT (code) DO NOTHING;

INSERT INTO vocabulary_intervention_type (intervention_category_id, code, name, description)
SELECT category.id, seed.code, seed.name, seed.description
FROM (
    VALUES
        ('MEDICINAL_PRODUCT', 'DRUG', 'Drug', 'Pharmaceutical or biological drug interventions.'),
        ('MEDICINAL_PRODUCT', 'BIOLOGIC', 'Biologic', 'Vaccines and other biologic interventions.'),
        ('MEDICAL_DEVICE', 'DEVICE', 'Device', 'Medical device interventions.'),
        ('NON_MEDICAL', 'PROCEDURE', 'Procedure', 'Surgical or procedural interventions.'),
        ('NON_MEDICAL', 'BEHAVIORAL', 'Behavioral', 'Behavioral, lifestyle, or educational interventions.'),
        ('NON_MEDICAL', 'DIETARY_SUPPLEMENT', 'Dietary Supplement', 'Vitamins, minerals, and dietary supplements.')
) AS seed(category_code, code, name, description)
JOIN vocabulary_intervention_category AS category ON category.code = seed.category_code
ON CONFLICT (code) DO NOTHING;

INSERT INTO vocabulary_intervention_subtype (intervention_type_id, code, name, description)
SELECT type.id, seed.code, seed.name, seed.description
FROM (
    VALUES
        ('DRUG', 'SMALL_MOLECULE', 'Small Molecule', 'Chemically synthesised small molecule drug.'),
        ('DRUG', 'BIOEQUIVALENCE', 'Bioequivalence', 'Studies comparing formulations of the same drug.'),
        ('DEVICE', 'IMPLANTABLE', 'Implantable Device', 'Device implanted within the body.'),
        ('BEHAVIORAL', 'COUNSELLING', 'Counselling', 'Structured behavioural counselling sessions.'),
        ('DIETARY_SUPPLEMENT', 'VITAMIN', 'Vitamin Supplement', 'Vitamin-based dietary supplement.'),
        ('PROCEDURE', 'SURGICAL', 'Surgical Procedure', 'Operative or invasive procedure.')
) AS seed(type_code, code, name, description)
JOIN vocabulary_intervention_type AS type ON type.code = seed.type_code
ON CONFLICT (intervention_type_id, code) DO NOTHING;

INSERT INTO vocabulary_intervention (intervention_type_id, intervention_subtype_id, code, name, description)
SELECT type.id, subtype.id, seed.code, seed.name, seed.description
FROM (
    VALUES
        ('DRUG', 'SMALL_MOLECULE', 'DRUG_PARACETAMOL', 'Paracetamol 500mg Tablet', 'Analgesic and antipyretic small molecule drug.'),
        ('BIOLOGIC', NULL, 'BIO_VACCINE_MRNA', 'mRNA COVID-19 Vaccine', 'Messenger RNA vaccine targeting SARS-CoV-2.'),
        ('DEVICE', 'IMPLANTABLE', 'DEV_PACEMAKER', 'Cardiac Pacemaker', 'Implantable cardiac rhythm management device.'),
        ('BEHAVIORAL', 'COUNSELLING', 'BEH_CBT', 'Cognitive Behavioural Therapy', 'Structured CBT session programme.'),
        ('DIETARY_SUPPLEMENT', 'VITAMIN', 'SUP_VITD', 'Vitamin D Supplement', 'Oral vitamin D3 supplement capsules.')
) AS seed(type_code, subtype_code, code, name, description)
JOIN vocabulary_intervention_type AS type ON type.code = seed.type_code
LEFT JOIN vocabulary_intervention_subtype AS subtype ON subtype.code = seed.subtype_code AND subtype.intervention_type_id = type.id
ON CONFLICT (code) DO NOTHING;

INSERT INTO vocabulary_recruitment_status (code, description) VALUES
    ('NOT_YET_RECRUITING', 'Trial has been registered but enrollment has not yet begun.'),
    ('RECRUITING', 'Actively recruiting participants.'),
    ('ACTIVE_NOT_RECRUITING', 'Active, but not currently recruiting participants.'),
    ('COMPLETED', 'Study has reached overall completion and data collection has ended.'),
    ('TERMINATED', 'Study has stopped early and will not start again.')
ON CONFLICT (code) DO NOTHING;

INSERT INTO vocabulary_study_phase (code, description) VALUES
    ('EARLY_PHASE1', 'Early Phase 1 (formerly Phase 0).'),
    ('PHASE1', 'Phase 1 safety trials.'),
    ('PHASE2', 'Phase 2 efficacy and side effects trials.'),
    ('PHASE3', 'Phase 3 effectiveness trials.'),
    ('PHASE4', 'Phase 4 post-marketing studies.')
ON CONFLICT (code) DO NOTHING;

INSERT INTO vocabulary_condition_category (code, name, description) VALUES
    ('ONCOLOGY', 'Oncology', 'Cancer-related conditions.'),
    ('CARDIO', 'Cardiology', 'Cardiovascular system disorders.'),
    ('NEURO', 'Neurology', 'Brain and nervous system conditions.'),
    ('INFECT', 'Infectious Disease', 'Viral and bacterial infections.'),
    ('ENDO', 'Endocrinology', 'Hormonal and metabolic disorders.')
ON CONFLICT (code) DO NOTHING;

INSERT INTO vocabulary_secondary_identify_type (code, name, description) VALUES
    ('EUCTR', 'EU Clinical Trials Register', 'Identifier issued by the EU Clinical Trials Register.'),
    ('ISRCTN', 'ISRCTN Registry', 'Identifier assigned by the ISRCTN registry.'),
    ('WHO', 'WHO Universal Trial Number', 'World Health Organization universal trial identifier.'),
    ('ANVISA', 'ANVISA Register', 'Registration number assigned by ANVISA.'),
    ('LOCAL', 'Local Registry', 'Identifier provided by a local or institutional registry.')
ON CONFLICT (code) DO NOTHING;

