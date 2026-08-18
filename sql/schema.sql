CREATE TABLE study_types (
    study_type_id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE trials (
    nct_id VARCHAR(20) PRIMARY KEY,
    study_type_id INT NOT NULL,
    brief_title TEXT,
    official_title TEXT,
    status VARCHAR(30),
    start_date DATE,
    start_date_type VARCHAR(30),
    primary_completion_date DATE,
    primary_completion_date_type VARCHAR(30),
    completion_date DATE,
    completion_date_type VARCHAR(30),
    enrollment_count INT,
    enrollment_type VARCHAR(30),

    FOREIGN KEY (study_type_id)
        REFERENCES study_types(study_type_id)
);

CREATE TABLE phases (
    phase_id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE trial_phases (
    nct_id VARCHAR(20),
    phase_id INT,

    PRIMARY KEY (nct_id, phase_id),

    FOREIGN KEY (nct_id)
        REFERENCES trials(nct_id),

    FOREIGN KEY (phase_id)
        REFERENCES phases(phase_id)
);

CREATE TABLE conditions (
    condition_id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE trial_conditions (
    nct_id VARCHAR(20),
    condition_id INT,

    PRIMARY KEY (nct_id, condition_id),

    FOREIGN KEY (nct_id)
        REFERENCES trials(nct_id),

    FOREIGN KEY (condition_id)
        REFERENCES conditions(condition_id)
);

CREATE TABLE sponsors (
    sponsor_id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    sponsor_class VARCHAR(50)
);

CREATE TABLE trial_sponsors (
    nct_id VARCHAR(20),
    sponsor_id INT,
    role VARCHAR(30),

    PRIMARY KEY (nct_id, sponsor_id),

    FOREIGN KEY (nct_id)
        REFERENCES trials(nct_id),

    FOREIGN KEY (sponsor_id)
        REFERENCES sponsors(sponsor_id)
);

CREATE TABLE interventions (
    intervention_id SERIAL PRIMARY KEY,
    nct_id VARCHAR(20) NOT NULL,
    name VARCHAR(255),
    type VARCHAR(50),
    description TEXT,

    FOREIGN KEY (nct_id)
        REFERENCES trials(nct_id)
);

CREATE TABLE arm_groups (
    arm_group_id SERIAL PRIMARY KEY,
    nct_id VARCHAR(20) NOT NULL,
    label VARCHAR(255),
    type VARCHAR(50),
    description TEXT,

    FOREIGN KEY (nct_id)
        REFERENCES trials(nct_id)
);

CREATE TABLE arm_group_interventions (
    arm_group_id INT,
    intervention_id INT,

    PRIMARY KEY (arm_group_id, intervention_id),

    FOREIGN KEY (arm_group_id)
        REFERENCES arm_groups(arm_group_id),

    FOREIGN KEY (intervention_id)
        REFERENCES interventions(intervention_id)
);

CREATE TABLE eligibility (
    nct_id VARCHAR(20) PRIMARY KEY,
    minimum_age NUMERIC,
    maximum_age NUMERIC,
    age_unit VARCHAR(20),
    sex VARCHAR(20),
    healthy_volunteers BOOLEAN,
    eligibility_criteria TEXT,

    FOREIGN KEY (nct_id)
        REFERENCES trials(nct_id)
);

CREATE TABLE locations (
    location_id SERIAL PRIMARY KEY,
    nct_id VARCHAR(20) NOT NULL,
    facility VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),

    FOREIGN KEY (nct_id)
        REFERENCES trials(nct_id)
);

CREATE TABLE outcomes (
    outcome_id SERIAL PRIMARY KEY,
    nct_id VARCHAR(20) NOT NULL,
    outcome_type VARCHAR(20),
    measure TEXT,
    description TEXT,
    time_frame TEXT,

    FOREIGN KEY (nct_id)
        REFERENCES trials(nct_id)
);