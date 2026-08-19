Sí. Ahora que el SQL ya está cerrado para este alcance, yo actualizaría el documento para que **no queden decisiones abiertas que ya resolvimos** y para que `responsibleParty` refleje lo que realmente encontramos.

Hay un detalle importante: en la revisión vimos que `responsibleParty` **no es solamente `SPONSOR`**. Aparecieron también `SPONSOR_INVESTIGATOR`, `PRINCIPAL_INVESTIGATOR` y estructuras antiguas con `oldNameTitle` / `oldOrganization`.

Además, ya confirmamos que no vamos a modelar esos campos por ahora.

Te lo dejaría así:

# Data Model Notes

## Purpose

This document records observations, edge cases, and modeling decisions
discovered during the ClinicalTrials.gov data extraction process.

These notes are used to validate and refine the relational data model
before implementing the final ingestion pipeline.

---

## Observations

### 1. Partial dates

ClinicalTrials.gov may provide dates with different levels of precision.

Examples:

- `2022-11-05`
- `2023-11`

Observed precision levels:

- DAY
- MONTH

The PostgreSQL model will use a `DATE` field together with a
precision field for each relevant date.

For example:

- `2022-11-05` → date = `2022-11-05`, precision = `DAY`
- `2023-11` → date = `2023-11-01`, precision = `MONTH`

When the precision is MONTH, the day `01` is only a technical
representation and must not be interpreted as the actual day.

ClinicalTrials.gov also provides a separate type field, which may
contain:

- ACTUAL
- ESTIMATED

The type field may be missing even when a date is present.
Missing type values should therefore be stored as NULL.

The relevant fields in the relational model are:

- `start_date`
- `start_date_precision`
- `start_date_type`
- `primary_completion_date`
- `primary_completion_date_precision`
- `primary_completion_date_type`
- `completion_date`
- `completion_date_precision`
- `completion_date_type`

**Status:** Confirmed.

---

### 2. Missing / non-applicable phases

Some trials contain:

- `phases = [NA]`

In the observed data, NA always appeared alone and was never
combined with a real clinical phase.

NA will not be treated as a real clinical phase.

During ingestion:

- `['NA']` → no record inserted into `trial_phases`
- `['PHASE1']` → insert PHASE1
- `['PHASE1', 'PHASE2']` → insert both phases
- missing phases → no records inserted

No additional database field is required.

**Status:** Confirmed.

---

### 3. Multiple phases per trial

ClinicalTrials.gov may represent a trial with multiple phases.

Examples observed during extraction:

- PHASE1 + PHASE2
- PHASE2 + PHASE3

This confirms that the relationship between trials and phases
must be modeled as many-to-many.

The bridge table `trial_phases` is therefore required.

**Status:** Confirmed.

---

### 4. Multiple conditions per trial

ClinicalTrials.gov commonly provides multiple conditions for a single trial.

Examples observed during extraction include:

- Diabetes + Diabetes Mellitus, Type 2
- Pain + Depression
- Infertility + Psychological Distress + Infertility, Female + Depression, Anxiety + Nurse's Role

Some trials contain many conditions.

This confirms that the relationship between trials and conditions
must be modeled as many-to-many using the `trial_conditions`
bridge table.

**Status:** Confirmed.

---

### 5. Condition terminology

Condition names may contain related, overlapping, specific,
or synonymous terms.

Examples observed include:

- Diabetes / Diabetes Mellitus, Type 2
- Periodontitis / Periodontal Disease
- Schistosoma Mansoni / Schistosomiasis
- Hydrocephalus / Normal Pressure Hydrocephalus

The ingestion process should preserve the condition names
provided by ClinicalTrials.gov rather than attempting semantic
deduplication or normalization.

**Status:** Confirmed for ingestion; semantic normalization is out of scope for now.

---

### 6. Responsible party

The `sponsorCollaboratorsModule` may contain `responsibleParty`
information.

Multiple structures were observed, including:

- `SPONSOR`
- `SPONSOR_INVESTIGATOR`
- `PRINCIPAL_INVESTIGATOR`
- historical records containing `oldNameTitle` and `oldOrganization`

The responsible party information is not currently represented
in the relational model.

The existing sponsor model represents the lead sponsor relationship
through `trial_sponsors.role`, but this is not considered equivalent
to all possible `responsibleParty` structures.

Responsible party information will therefore remain outside the
relational model for now.

**Status:** Not modeled for now.

---

### 7. Multiple sponsors per trial

ClinicalTrials.gov may provide one lead sponsor and multiple
collaborating sponsors for the same trial.

Collaborators were observed with varying counts, including trials
with several collaborating organizations.

This confirms the many-to-many relationship between trials and sponsors,
implemented through the `trial_sponsors` bridge table.

The role attribute distinguishes the relationship:

- LEAD
- COLLABORATOR

Sponsor information (name and class) is shared between lead sponsors
and collaborators.

**Status:** Confirmed.

---

### 8. Intervention to arm group relationship

Intervention records may contain `armGroupLabels` identifying
the study arms associated with the intervention.

This relationship is represented in the relational model through
the `arm_group_interventions` bridge table.

**Status:** Confirmed.

---

### 9. Optional API modules

Some clinical trial records may not contain certain API modules.

Observed missing modules include:

- `armsInterventionsModule`
- `contactsLocationsModule`
- `outcomesModule`

The ingestion process must therefore treat API modules as optional
and handle missing modules without failing.

**Status:** Confirmed.

---

### 10. Multiple interventions per arm

ClinicalTrials.gov may associate multiple interventions with a single
arm group.

Examples observed include arms containing two, three, and several
interventions.

The same intervention may also appear in multiple arm groups.

This confirms the many-to-many relationship between arm_groups and
interventions.

The relationship is represented through the
`arm_group_interventions` bridge table.

**Status:** Confirmed.

---

### 11. Standardized age categories

ClinicalTrials.gov may provide standardized age categories
through the `stdAges` field.

The field is represented as a list and may contain multiple values.

Observed values:

- ADULT
- CHILD
- OLDER_ADULT

Observed cardinality:

- 1 category: 43 studies
- 2 categories: 136 studies
- 3 categories: 21 studies

This confirms that a trial may be associated with multiple
standardized age categories.

The relationship is therefore modeled as many-to-many through
the `trial_standard_ages` bridge table, using the `standard_ages`
lookup table.

The standardized age categories are distinct from
`minimumAge` and `maximumAge`.

**Status:** Confirmed.

---

### 12. Minimum and maximum age may use different units

ClinicalTrials.gov represents `minimumAge` and `maximumAge` as strings
containing both a numeric value and a unit.

Observed units include:

- Hours
- Days
- Weeks
- Months
- Years

The minimum and maximum age values may use different units.

Examples:

- NCT07305935: minimumAge = 1 Hour, maximumAge = 6 Hours
- NCT00000750: minimumAge = 1 Day, maximumAge = 9 Months

Therefore, `minimum_age` and `maximum_age` require separate unit fields.

The eligibility model uses:

- `minimum_age`
- `minimum_age_unit`
- `maximum_age`
- `maximum_age_unit`

**Status:** Confirmed.

---

### 13. Eligibility field values

Observed sex values:

- MALE
- FEMALE
- ALL

Observed `healthyVolunteers` values:

- true
- false
- missing

Missing `healthyVolunteers` values should be stored as NULL,
not interpreted as false.

**Status:** Confirmed.

---

### 14. Locations

ClinicalTrials.gov may provide multiple locations for a single trial.

In the observed dataset:

- 1,126 total locations were found.
- `city` and `country` were present for all locations.
- `facility` was present for 711 locations.
- `state` was present for 718 locations.
- `zip` was present for 826 locations.
- geographic coordinates were present for 1,110 locations.

This confirms a one-to-many relationship between trials and locations.

The relational model therefore represents locations using the
`locations` table, with nullable fields for optional location data.

**Status:** Confirmed.

---

### 15. Outcomes

ClinicalTrials.gov may provide multiple outcomes for a single trial.

In the observed dataset:

- 1,181 total outcomes were found.
- `measure` was present for all outcomes.
- `description` was present for 952 outcomes.
- `timeFrame` was present for 1,171 outcomes.

This confirms a one-to-many relationship between trials and outcomes.

The relational model represents outcomes using the `outcomes` table.

Primary and secondary outcomes are distinguished through the
`outcome_type` field.

**Status:** Confirmed.

---

### 16. Study type

The observed `studyType` values were:

- INTERVENTIONAL
- OBSERVATIONAL

All 200 studies contained this field.

The relational model therefore represents study types through the
`study_types` lookup table and the `study_type_id` foreign key in
`trials`.

**Status:** Confirmed.

---

### 17. Optional and missing fields

Several fields were observed to be missing in some studies.

Examples include:

- `officialTitle`
- `primaryCompletionDateStruct`
- `completionDateStruct`
- `phases`
- `collaborators`
- `responsibleParty`
- `armGroups`
- `interventions`
- `minimumAge`
- `maximumAge`
- `healthyVolunteers`
- `locations`
- `primaryOutcomes`
- `secondaryOutcomes`

The relational model should therefore allow NULL values for optional
scalar fields and simply omit child or bridge records when the
corresponding API data is absent.

**Status:** Confirmed.

---

## Fields identified but not currently modeled

The extraction review identified additional ClinicalTrials.gov fields
that are currently outside the scope of the relational model.

Examples include:

### identificationModule

- `orgStudyIdInfo`
- `organization`
- `acronym`
- `secondaryIdInfos`

### statusModule

- `statusVerifiedDate`
- `studyFirstSubmitDate`
- `studyFirstSubmitQcDate`
- `studyFirstPostDateStruct`
- `lastUpdateSubmitDate`
- `lastUpdatePostDateStruct`
- `expandedAccessInfo`
- `lastKnownStatus`
- `resultsFirstSubmitDate`
- `resultsFirstSubmitQcDate`
- `resultsFirstPostDateStruct`
- `whyStopped`
- `dispFirstSubmitDate`
- `dispFirstSubmitQcDate`
- `dispFirstPostDateStruct`

### designModule

- `designInfo`
- `patientRegistry`
- `bioSpec`
- `targetDuration`

### conditionsModule

- `keywords`

### contactsLocationsModule

- `overallOfficials`
- `centralContacts`

### eligibilityModule

- `studyPopulation`
- `samplingMethod`
- `genderBased`
- `genderDescription`

### outcomesModule

- `otherOutcomes`

These fields were identified during the extraction review but will not
be added to the current relational model unless the project scope
requires them later.

**Status:** Out of scope for the current model.

---

## Modeling decisions

- [x] Define handling of partial dates
- [x] Define handling of NA phase values
- [x] Review optional fields and missing values
- [x] Review whether all currently selected API fields are represented
- [x] Validate cardinalities against real data
- [x] Validate standardized age categories
- [x] Validate minimum and maximum age units
- [x] Validate locations as one-to-many
- [x] Validate outcomes as one-to-many

The current relational model is considered complete for the
defined project scope.

Additional ClinicalTrials.gov fields may be incorporated in a
future model revision if project requirements change.
