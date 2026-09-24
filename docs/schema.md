# Schema diagrams

The first diagram is the big picture. The three after it show every table and
every foreign key, one area at a time, with their most important columns.
The full definitions, with comments, are in [migrations/](../migrations/).

Reading the lines: `||` exactly one, `|o` zero or one, `o{` zero or more,
`|{` one or more. Every table also has a key `id_<table>` (shown as PK).
`schema_migration`, the bookkeeping table of `bin/migrate`, is left out.


## Overview

What is investigated (a *feature*) is represented by *samples*. Everything
that happens to a sample is an *action*: a version of a *method* applied to
it. Actions produce *observations* of *observed properties*. Orders ask for
actions; reports freeze what was told to the customer.

```mermaid
erDiagram
    feature |o--o{ sample : "is represented by"
    sample }o--o{ sample : "is obtained from"
    sample ||--o{ action : "undergoes"
    method ||--|{ method_version : "has"
    method }o--o{ method : "requires, implies"
    method_version ||--o{ action : "is applied in"
    method_version ||--o{ method_property : "determines"
    observed_property ||--o{ method_property : "is determined by"
    action ||--o{ observation : "produces"
    observed_property ||--o{ observation : "is observed in"
    observation }o--o{ observation : "is calculated from"
    lab_order |o--o{ action : "requests"
    lab_order ||--o{ report : "is answered by"
    report ||--o{ reported_result : "contains"
    observation ||--o{ reported_result : "is reported as"
```

In OMS terms (see [oms-alignment.md](oms-alignment.md)): feature = ultimate
feature of interest, sample = Sample, method = Procedure, action = Sampling,
PreparationStep or the shared context of Observations, observation =
Observation, observed_property = ObservableProperty.


## Samples and their lifecycle

```mermaid
erDiagram
    feature |o--o{ sample : "is represented by"
    sample ||--o{ sample_source : "is obtained from"
    sample ||--o{ sample_source : "is the source in"
    matrix |o--o{ sample : "is the material of"
    storage_location |o--o{ sample : "keeps"
    unit |o--o{ sample : "measures the size of"
    sample ||--o{ action : "undergoes"
    method_version ||--o{ action : "is applied in"
    lab_order |o--o{ action : "requests"
    action |o--o{ action : "implies"
    person |o--o{ action : "is assigned to, performs"
    action ||--o{ action_device : "uses"
    device ||--o{ action_device : "is used in"
    action ||--o{ action_link : "produced"
    link ||--o{ action_link : "documents"

    feature {
        int id_feature PK
        varchar name
        geometry shape "with EPSG code as SRID"
        int id_address FK
    }
    sample {
        int id_sample PK
        varchar code UK "the label"
        varchar sample_kind "spatial or material"
        int id_sampled_feature FK "empty: inherited from sources"
        int id_matrix FK
        geometry location
        varchar location_description
        decimal size
        int id_size_unit FK
        int id_storage_location FK
    }
    sample_source {
        int id_sample_source PK
        int id_sample FK "the obtained sample"
        int id_source_sample FK "what it was obtained from"
    }
    action {
        int id_action PK
        int id_sample FK
        int id_method_version FK
        int id_lab_order FK
        int id_implied_by_action FK
        int id_assignee FK
        int id_performer FK
        timestamp due_at
        timestamp planned_at
        timestamp started_at
        timestamp finished_at
        timestamp cancelled_at
        varchar note
        varchar status "generated: planned, started, finished, cancelled"
    }
    device {
        int id_device PK
        varchar name
        varchar inventory_number UK
        int id_manufacturer FK
        timestamp retired_at
    }
    link {
        int id_link PK
        varchar name
        varchar uri
        varchar file_path
        char sha256
    }
```


## Methods and results

```mermaid
erDiagram
    method ||--|{ method_version : "has"
    method ||--o{ method_prerequisite : "requires"
    method ||--o{ method_prerequisite : "is required by"
    method ||--o{ method_implication : "implies"
    method ||--o{ method_implication : "is implied by"
    method_version ||--o{ method_version_link : "is described by"
    link ||--o{ method_version_link : "describes"
    method_version ||--o{ method_property : "determines"
    observed_property ||--o{ method_property : "is determined by"
    method_property ||--o{ formula_input : "calculates from"
    observed_property ||--o{ formula_input : "is input of"
    dimension ||--o{ unit : "is measured in"
    dimension |o--o{ observed_property : "is the dimension of"
    unit ||--o{ unit_notation : "is written as"
    unit |o--o{ method_property : "reports"
    unit ||--o{ formula_input : "is expected by"
    method_version ||--o{ action : "is applied in"
    action ||--o{ observation : "produces"
    observed_property ||--o{ observation : "is observed in"
    unit |o--o{ observation : "was recorded in"
    person |o--o{ observation : "reviews"
    observation ||--o{ observation_input : "is calculated from"
    observation ||--o{ observation_input : "is input of"

    method {
        int id_method PK
        varchar name UK
        varchar kind "sampling, preparation, observation, handling"
        boolean is_final "closes the sample, e.g. disposal"
        timestamp retired_at
    }
    method_version {
        int id_method_version PK
        int id_method FK
        timestamp valid_from
        varchar change_note
    }
    method_prerequisite {
        int id_method_prerequisite PK
        int id_method FK
        int id_prerequisite_method FK "must be finished first"
    }
    method_implication {
        int id_method_implication PK
        int id_method FK
        int id_implied_method FK "is planned along"
    }
    method_property {
        int id_method_property PK
        int id_method_version FK
        int id_observed_property FK
        int id_unit FK
        tinyint decimal_places
        decimal lod
        decimal loq
        decimal uncertainty
        varchar uncertainty_kind
        boolean is_required
        boolean is_reported
        varchar formula "e.g. reading * dilution"
    }
    formula_input {
        int id_formula_input PK
        int id_method_property FK
        varchar variable_name
        int id_observed_property FK
        int id_unit FK
        varchar scope "same action or sample"
        varchar aggregation
        varchar below_loq
    }
    observed_property {
        int id_observed_property PK
        varchar name UK
        varchar result_type "numeric, text, boolean, timestamp"
        int id_dimension FK
        varchar definition_uri
    }
    unit {
        int id_unit PK
        varchar name UK
        varchar symbol
        varchar ucum_code UK
        int id_dimension FK
        decimal conversion_factor
        decimal conversion_offset
    }
    observation {
        int id_observation PK
        int id_action FK
        int id_observed_property FK
        timestamp phenomenon_time "empty: derived"
        timestamp result_time
        decimal result_numeric
        varchar result_text
        boolean result_boolean
        timestamp result_timestamp
        char censoring "less or greater than"
        int id_unit FK
        timestamp reviewed_at
        int id_reviewer FK
        timestamp invalidated_at
        varchar invalidation_reason
    }
    observation_input {
        int id_observation_input PK
        int id_observation FK "the calculated one"
        int id_input_observation FK
    }
```


## Orders, reports, people and places

```mermaid
erDiagram
    organization |o--o{ lab_order : "orders"
    person |o--o{ lab_order : "orders, is contact for"
    lab_order ||--o{ lab_order_link : "is documented by"
    link ||--o{ lab_order_link : "documents"
    lab_order ||--o{ report : "is answered by"
    report |o--o| report : "replaces"
    person |o--o{ report : "issues"
    link |o--o{ report : "is the document of"
    report ||--o{ reported_result : "contains"
    observation ||--o{ reported_result : "is reported as"
    unit |o--o{ reported_result : "is printed with"
    organization ||--o{ organization_member : "has"
    person ||--o{ organization_member : "belongs to"
    organization ||--o{ organization_address : "is reached at"
    person ||--o{ person_address : "is reached at"
    address ||--o{ organization_address : "serves"
    address ||--o{ person_address : "serves"
    address |o--o{ feature : "locates"
    organization |o--o{ device : "manufactures"
    country ||--o{ city : "contains"
    city ||--o{ street : "contains"
    street ||--o{ address : "contains"

    lab_order {
        int id_lab_order PK
        varchar order_number UK
        int id_customer_organization FK "either this"
        int id_customer_person FK "or this"
        int id_contact_person FK
        date received_on
        date due_on
    }
    report {
        int id_report PK
        int id_lab_order FK
        varchar report_number UK
        int id_replaced_report FK
        timestamp issued_at "empty: draft"
        int id_issuer FK
        int id_link FK "the PDF"
    }
    reported_result {
        int id_reported_result PK
        int id_report FK
        int id_observation FK
        varchar reported_text "as printed, e.g. less than 0.5"
        int id_unit FK
    }
    organization {
        int id_organization PK
        varchar name UK
        varchar short_name
    }
    person {
        int id_person PK
        varchar given_name
        varchar surname
        varchar email UK
        varchar db_account UK "MariaDB account"
    }
    organization_member {
        int id_organization_member PK
        int id_organization FK
        int id_person FK
        varchar position
    }
    organization_address {
        int id_organization_address PK
        int id_organization FK
        int id_address FK
        varchar purpose "postal, billing, delivery, visiting"
    }
    person_address {
        int id_person_address PK
        int id_person FK
        int id_address FK
        varchar purpose
    }
    street {
        int id_street PK
        varchar name
        varchar postal_code
        int id_city FK
    }
    address {
        int id_address PK
        int id_street FK
        varchar house_number
    }
    city {
        int id_city PK
        varchar name
        int id_country FK
    }
    country {
        int id_country PK
        char iso_code UK
        varchar name UK
    }
```
