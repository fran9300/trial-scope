# TrialScope — Data Dictionary

**Version:** 1.0  
**Source:** ClinicalTrials.gov API v2  
**Status:** Initial data model specification

## 1. Purpose

This document defines the initial data dictionary for TrialScope.

It specifies the entities TrialScope will store, their source API fields, expected types, required transformations, and intended analytical use.

The model intentionally does **not** reproduce the ClinicalTrials.gov JSON structure one-to-one. It is designed around TrialScope's relational and analytical requirements.

## 2. Modeling principles

TrialScope follows a hybrid relational approach:

- Reusable entities are represented by dedicated tables.
- One-to-many relationships use foreign keys.
- Many-to-many relationships use bridge tables.
- Simple categorical attributes remain fields where a separate lookup table would add unnecessary complexity.
- Structured analytical fields are separated from large free-text fields where appropriate.
- ClinicalTrials.gov identifiers are preserved for source traceability.

## 3. Entity overview

| Entity | Purpose |
|---|---|
| `trials` | Central clinical trial record |
| `study_types` | Reusable study type categories |
| `phases` | Reusable clinical trial phase categories |
| `conditions` | Medical conditions associated with trials |
| `sponsors` | Organizations sponsoring or collaborating on trials |
| `interventions` | Drugs, devices, procedures, or other interventions |
| `arm_groups` | Treatment/control groups within a trial |
| `eligibility` | Participant eligibility information |
| `locations` | Research sites associated with trials |
| `outcomes` | Primary and secondary trial outcomes |

### Relationship / bridge tables

| Entity | Purpose |
|---|---|
| `trial_phases` | Links trials and phases |
| `trial_conditions` | Links trials and conditions |
| `trial_sponsors` | Links trials and sponsors |
| `trial_interventions` | Links trials and interventions |
| `arm_group_interventions` | Links arm groups and interventions |

## 4. `trials`

Central entity containing the main study-level information.

| Column | Type | Key | ClinicalTrials.gov source | Transformation | Purpose |
|---|---|---|---|---|---|
| `nct_id` | VARCHAR | PK | `identificationModule.nctId` | None | Unique trial identifier |
| `brief_title` | TEXT | | `identificationModule.briefTitle` | None | Short study title |
| `official_title` | TEXT | | `identificationModule.officialTitle` | None | Official study title |
| `study_type_id` | INTEGER | FK | `designModule.studyType` | Map to `study_types` | Study type |
| `status` | VARCHAR | | `statusModule.overallStatus` | Normalize value | Current study status |
| `start_date` | DATE | | `statusModule.startDateStruct.date` | Parse date | Study start |
| `start_date_type` | VARCHAR | | `statusModule.startDateStruct.type` | Normalize value | Actual/estimated |
| `primary_completion_date` | DATE | | `statusModule.primaryCompletionDateStruct.date` | Parse date | Primary completion |
| `primary_completion_date_type` | VARCHAR | | `statusModule.primaryCompletionDateStruct.type` | Normalize value | Actual/estimated |
| `completion_date` | DATE | | `statusModule.completionDateStruct.date` | Parse date | Study completion |
| `completion_date_type` | VARCHAR | | `statusModule.completionDateStruct.type` | Normalize value | Actual/estimated |
| `enrollment_count` | INTEGER | | `designModule.enrollmentInfo.count` | None | Number of participants |
| `enrollment_type` | VARCHAR | | `designModule.enrollmentInfo.type` | Normalize value | Actual/estimated enrollment |

**Relationships:** a trial can have many phases, conditions, sponsors, interventions, arm groups, locations, and outcomes; the initial model has one eligibility record per trial.

## 5. `study_types`

| Column | Type | Key | Source | Purpose |
|---|---|---|---|---|
| `study_type_id` | INTEGER | PK | Generated | Internal identifier |
| `name` | VARCHAR | UNIQUE | `designModule.studyType` | Study type name |

## 6. `phases`

| Column | Type | Key | Source | Purpose |
|---|---|---|---|---|
| `phase_id` | INTEGER | PK | Generated | Internal identifier |
| `name` | VARCHAR | UNIQUE | `designModule.phases[]` | Phase name |

A trial may contain more than one phase value, so phases use a many-to-many relationship.

## 7. `trial_phases`

| Column | Type | Key | Source | Purpose |
|---|---|---|---|---|
| `nct_id` | VARCHAR | PK/FK | `identificationModule.nctId` | Trial reference |
| `phase_id` | INTEGER | PK/FK | `designModule.phases[]` | Phase reference |

Relationship: `TRIAL N : M PHASE`. Composite PK: `(nct_id, phase_id)`.

## 8. `conditions`

| Column | Type | Key | Source | Transformation | Purpose |
|---|---|---|---|---|---|
| `condition_id` | INTEGER | PK | Generated | None | Internal identifier |
| `name` | VARCHAR | UNIQUE | `conditionsModule.conditions[]` | Normalize text | Condition name |

## 9. `trial_conditions`

| Column | Type | Key | Source | Purpose |
|---|---|---|---|---|
| `nct_id` | VARCHAR | PK/FK | `identificationModule.nctId` | Trial reference |
| `condition_id` | INTEGER | PK/FK | `conditionsModule.conditions[]` | Condition reference |

Relationship: `TRIAL N : M CONDITION`. Composite PK: `(nct_id, condition_id)`.

## 10. `sponsors`

| Column | Type | Key | Source | Transformation | Purpose |
|---|---|---|---|---|---|
| `sponsor_id` | INTEGER | PK | Generated | None | Internal identifier |
| `name` | VARCHAR | | `sponsorCollaboratorsModule.leadSponsor.name` | Normalize text | Organization name |
| `sponsor_class` | VARCHAR | | `leadSponsor.class` | Normalize value | Sponsor category |

## 11. `trial_sponsors`

| Column | Type | Key | Source | Purpose |
|---|---|---|---|---|
| `nct_id` | VARCHAR | PK/FK | `identificationModule.nctId` | Trial reference |
| `sponsor_id` | INTEGER | PK/FK | Sponsor module | Sponsor reference |
| `role` | VARCHAR | | Sponsor/collaborator context | Relationship role |

The `role` field allows lead sponsors and collaborators to be represented in the same relationship table.

## 12. `interventions`

| Column | Type | Key | Source | Purpose |
|---|---|---|---|---|
| `intervention_id` | INTEGER | PK | Generated | Internal identifier |
| `name` | VARCHAR | | `interventions[].name` | Intervention name |
| `type` | VARCHAR | | `interventions[].type` | Intervention category |
| `description` | TEXT | | `interventions[].description` | Intervention description |

## 13. `trial_interventions`

| Column | Type | Key | Source | Purpose |
|---|---|---|---|---|
| `nct_id` | VARCHAR | PK/FK | `identificationModule.nctId` | Trial reference |
| `intervention_id` | INTEGER | PK/FK | `interventions[]` | Intervention reference |

Relationship: `TRIAL N : M INTERVENTION`. Composite PK: `(nct_id, intervention_id)`.

## 14. `arm_groups`

| Column | Type | Key | Source | Purpose |
|---|---|---|---|---|
| `arm_group_id` | INTEGER | PK | Generated | Internal identifier |
| `nct_id` | VARCHAR | FK | `identificationModule.nctId` | Trial reference |
| `label` | VARCHAR | | `armGroups[].label` | Arm name |
| `type` | VARCHAR | | `armGroups[].type` | Arm category |
| `description` | TEXT | | `armGroups[].description` | Arm description |

Relationship: `TRIAL 1 : N ARM_GROUP`.

## 15. `arm_group_interventions`

| Column | Type | Key | Source | Purpose |
|---|---|---|---|---|
| `arm_group_id` | INTEGER | PK/FK | `armGroups[]` | Arm reference |
| `intervention_id` | INTEGER | PK/FK | `armGroups[].interventionNames` / `interventions[]` | Intervention reference |

Relationship: `ARM_GROUP N : M INTERVENTION`. Composite PK: `(arm_group_id, intervention_id)`.

## 16. `eligibility`

| Column | Type | Key | Source | Transformation | Purpose |
|---|---|---|---|---|---|
| `nct_id` | VARCHAR | PK/FK | `identificationModule.nctId` | None | Trial reference |
| `minimum_age` | NUMERIC | | `eligibilityModule.minimumAge` | Extract numeric value | Minimum participant age |
| `maximum_age` | NUMERIC | | `eligibilityModule.maximumAge` | Extract numeric value | Maximum participant age |
| `age_unit` | VARCHAR | | Age fields | Normalize unit | Age unit |
| `sex` | VARCHAR | | `eligibilityModule.sex` | Normalize value | Eligible sex |
| `healthy_volunteers` | BOOLEAN | | `eligibilityModule.healthyVolunteers` | None | Healthy volunteers allowed |
| `eligibility_criteria` | TEXT | | `eligibilityModule.eligibilityCriteria` | Preserve source text | Inclusion/exclusion criteria |

Relationship: `TRIAL 1 : 1 ELIGIBILITY`.

## 17. `locations`

| Column | Type | Key | Source | Purpose |
|---|---|---|---|---|
| `location_id` | INTEGER | PK | Generated | Internal identifier |
| `nct_id` | VARCHAR | FK | `identificationModule.nctId` | Trial reference |
| `facility` | VARCHAR | | `locations[].facility` | Research facility |
| `city` | VARCHAR | | `locations[].city` | City |
| `state` | VARCHAR | | `locations[].state` | State/province |
| `country` | VARCHAR | | `locations[].country` | Country |
| `latitude` | NUMERIC | | `locations[].geoPoint.lat` | Latitude |
| `longitude` | NUMERIC | | `locations[].geoPoint.lon` | Longitude |

Relationship: `TRIAL 1 : N LOCATION`.

## 18. `outcomes`

| Column | Type | Key | Source | Purpose |
|---|---|---|---|---|
| `outcome_id` | INTEGER | PK | Generated | Internal identifier |
| `nct_id` | VARCHAR | FK | `identificationModule.nctId` | Trial reference |
| `outcome_type` | VARCHAR | | `primaryOutcomes[]` / `secondaryOutcomes[]` | Primary/secondary classification |
| `measure` | TEXT | | `outcomes[].measure` | Outcome measure |
| `description` | TEXT | | `outcomes[].description` | Outcome definition |
| `time_frame` | TEXT | | `outcomes[].timeFrame` | Assessment timeframe |

Relationship: `TRIAL 1 : N OUTCOME`.

The initial model keeps measure, description, and timeframe textual. Further standardization can be considered during later transformation or NLP work.

## 19. Deliberately non-normalized categorical fields

Not every categorical value is represented by a separate lookup table.

The following remain fields in their parent tables:

- `trials.status`
- `trials.start_date_type`
- `trials.primary_completion_date_type`
- `trials.completion_date_type`
- `trials.enrollment_type`
- `sponsors.sponsor_class`
- `interventions.type`
- `arm_groups.type`
- `trial_sponsors.role`
- `eligibility.sex`
- `outcomes.outcome_type`

This is intentional. Creating a separate table for every small categorical domain would increase complexity without enough relational or analytical benefit.

Where appropriate, PostgreSQL `CHECK` constraints can later enforce valid values.

## 20. Relationships summary

| Relationship | Cardinality | Implementation |
|---|---|---|
| Study type → Trials | 1:N | Foreign key |
| Trial ↔ Phase | N:M | `trial_phases` |
| Trial ↔ Condition | N:M | `trial_conditions` |
| Trial ↔ Sponsor | N:M | `trial_sponsors` |
| Trial ↔ Intervention | N:M | `trial_interventions` |
| Trial → Arm groups | 1:N | Foreign key |
| Arm group ↔ Intervention | N:M | `arm_group_interventions` |
| Trial → Eligibility | 1:1 | PK/FK |
| Trial → Location | 1:N | Foreign key |
| Trial → Outcome | 1:N | Foreign key |

## 21. Analytical goals supported by the model

The model is designed to support questions such as:

### Clinical landscape
- How does clinical trial activity evolve over time?
- Which conditions have the largest number of trials?
- How are trials distributed across phases?

### Study design
- How does enrollment vary by study type and phase?
- What study designs are most common?
- How long do trials take from start to completion?

### Sponsors
- Which organizations sponsor the most trials?
- How does activity differ between sponsor classes?

### Geography
- Which countries host the most clinical trials?
- How is clinical research geographically distributed?

### Interventions
- Which interventions appear most frequently?
- Which conditions are associated with specific interventions?

### Outcomes
- Which outcome measures are most common?
- How do primary and secondary outcomes differ?
- How do outcome timeframes vary between studies?

### Data Science
The stored structured and textual data may later support:
- trial duration prediction;
- trial similarity analysis;
- clustering of studies;
- NLP analysis of eligibility criteria;
- NLP analysis of outcome descriptions.

## 22. Design decision

TrialScope intentionally follows a **hybrid relational model**.

The objective is not maximum normalization. The model balances:

1. normalization and data integrity;
2. meaningful entity relationships;
3. analytical usability;
4. implementation complexity;
5. future Data Science use cases.

This makes the schema suitable both for demonstrating relational database design and for building an analytical pipeline on top of the resulting data.
