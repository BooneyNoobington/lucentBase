# Design notes

Why lucentBase looks the way it does. For how it relates to ISO 19156, see
[oms-alignment.md](oms-alignment.md).


## Principles

- **Modularity.** The database is usable on its own, without any frontend.
  So the rules live in the database: constraints and triggers enforce them for
  everyone who writes, procedures do what triggers cannot, views make the data
  readable. A frontend is one client among others.
- **Normalization.** The first three normal forms are mandatory. Values that
  can be derived are derived (in views and functions), not stored twice.
- **Readability over elegance**, and over performance unless performance
  really suffers. Small labs have thousands of samples, not billions.
- **Interoperability.** lucentLIMS does not store documents, send mail or
  manage invoices. It links to the systems that do.


## Conventions

- Tables are singular nouns in `snake_case`. Every table has a surrogate key
  `id_<table>`; that uniformity makes generic tooling (export, audit trail,
  frontends) simple. Natural keys are enforced with `UNIQUE` constraints.
- A foreign key column is called `id_<table>`, or `id_<role>` when the role
  matters or a table is referenced twice (`id_sampled_feature`,
  `id_customer_person`).
- Junction tables have meaningful names (`sample_source`,
  `method_prerequisite`) and a `UNIQUE` constraint on the pair they join.
- **Fixed choices vs. lookup tables.** A value the database logic depends on
  is a `CHECK (... IN (...))` list, because adding a value means changing the
  logic anyway (`method.kind`, `observed_property.result_type`). A
  classification users extend is a lookup table (`matrix`, `unit`).
- **No visibility flags.** The old `vis` column mixed "hide from lists" with
  "no longer in use", and a hidden row still blocked its name in `UNIQUE`
  constraints. Where retirement is a real-world fact, the table has
  `retired_at` (`method`, `device`). Results are never hidden; they are
  invalidated with a reason.
- **History is not edited.** Actions, observations, sample sources and issued
  reports are not updated or deleted beyond what their lifecycle allows;
  triggers refuse it. Mistakes are corrected by invalidating and recording
  anew, so the correction itself is on record.
- **Times** are `TIMESTAMP`: stored in UTC, shown in the session's time zone.
  Since MariaDB 11.5 the range reaches 2106; data from before 1970 would need
  a `DATETIME` column.
- **Numbers** are `DECIMAL(38,12)`: exact, so 0.1 stays 0.1. How many
  decimals a result is *reported* with is a property of the method
  (`method_property.decimal_places`), so significant zeros ("7.20") are kept
  in reports.
- In procedures, parameters start with `p_`, local variables with `v_`.
- Error messages are sentences a lab worker can act on, because they reach
  the frontend as they are.


## The lifecycle

Everything that happens to a sample is an **action**: one method applied to
one sample. An action is `planned`, then `started`, then `finished` or
`cancelled`. The status is a generated column computed from the timestamps,
so it cannot contradict them.

Methods relate to each other in two ways, each with its own table, because
they mean different things and are checked at different moments:

- `method_prerequisite`: **"B may only start after A has finished."**
  Checked by a trigger when an action starts. A finished action on the sample
  *or on one of its ancestors* counts: an aliquot does not need its own
  receipt when the bottle it came from was received. Circular prerequisites
  are refused, since nothing could ever start.
- `method_implication`: **"Planning A also plans B."** Applied by
  `plan_action()`, transitively, and only if the sample has no uncancelled
  action of B yet. Receipt implies disposal; nitrate by IC implies filtration.
  Implied actions remember what caused them (`id_implied_by_action`) and are
  cancelled with it if they have not started.

The old draft had a third kind, `possibility`, for "B may follow A". Without
a constraint, anything may follow anything, so it would not change what the
database allows. It is left out until there is a rule it should enforce.

A **final** method (`method.is_final`, e.g. disposal) closes a sample. It
only starts when nothing else is open on the sample, and afterwards nothing
new can be planned for it.

Triggers cannot insert into the table they belong to, so planning implied
actions happens in a procedure. Everything else is enforced by triggers and
holds for direct `INSERT`/`UPDATE` statements as well. If someone inserts
actions directly, `v_missing_implied_action` shows implications that were
skipped.


## Results and calculations

Results are observations. A wrong result is invalidated with a reason, never
overwritten.

**Displaying is computed on the fly.** `format_result()` converts into the
method's unit, rounds to its decimal places, and writes values below the LOQ
as "< LOQ". The raw value is kept exactly as measured, so a later change of
presentation can never lose data.

**Censored values.** When a device reports only a limit ("< 0.002",
"> 300 colonies"), the limit goes into `result_numeric` and the direction into
`censoring`. A value the device measured exactly stays exact, even below the
LOQ.

**Calculations are stored, with their inputs.** The original idea was to
calculate end results only when they are shown, so they can never be stale.
Two things speak against it:

1. MariaDB cannot evaluate a formula stored as data inside a view or a
   function. That needs dynamic SQL, which only procedures may run. Results
   computed in the frontend would leave everyone using the database directly
   without them, against the modularity principle.
2. A result that changes silently after it was reported is worse than a stale
   one. A lab must be able to say which inputs and which formula version
   produced a number.

So `calculate_action()` evaluates each formula, stores the result as an
observation and records its inputs in `observation_input`.
`v_stale_calculation` lists every calculated result whose inputs have changed
since, and a stale result can be neither reviewed nor reported until it is
recalculated. The goal of the original idea, never showing a stale result as
valid, is kept, and results also stay traceable.

Formulas are MariaDB expressions over named inputs (`reading * dilution`).
Each input says which property it reads, which unit it expects, whether it
reads from the same action or from the sample's lineage, how replicates are
combined (mean, min, max, sum, latest, count), and how values below the LOQ
are treated (as measured, zero, half the LOQ, the LOQ). Whoever may edit
formulas must be trusted like someone who may write SQL; they are executed
with the rights of the person calculating.


## Reports

A report is a document that has left the lab, so what it said is frozen in
`reported_result` when it is issued. Unlike a stored result, that is a fact of
its own ("on 18 September we reported 48.2 mg/L"). A report is only issued when
all its results are reviewed and none is stale. If a reported result is later
invalidated or goes stale, `v_report_needing_amendment` lists the report until
an amending report that replaces it has been issued. The PDF lives in a
document system and is referenced with a checksum.


## Addresses

Addresses are normalized down to the street, but not further than reality
allows. City names are not unique. The postal code belongs to a street segment
(`street` is "a street name within one postal code of one city"), which also
tells apart the several streets of the same name a big city can have. House
numbers are text ("12a", "12-14"). Districts are left out: they are not part
of a postal address in most countries, and streets cross district borders.


## Migrations and tests

- `bin/migrate <database>` applies the files in `migrations/` in order, once
  each, and records them with a checksum in `schema_migration`.
- Once a migration has been released, it is never edited; changes go into a
  new migration. (Before the first release, the files may still be reshaped.)
- `bin/test` builds a fresh database per test file, loads the assertion
  helpers from `tests/lib/assert.sql`, and runs the file. Tests are plain SQL:
  `assert_true`, `assert_equal`, `assert_number` and `assert_fails`, which
  proves that a rule refuses what it should.
- `seed/demo_environmental_lab.sql` is a fictional lab's two weeks of work,
  replayed through the procedures. Tests starting with `-- uses: seed` run on
  top of it.


## Deliberately postponed

- **Audit trail.** Planned once the schema has settled: MariaDB's system
  versioning (`WITH SYSTEM VERSIONING`) keeps every earlier version of every
  row, a `changed_by` column filled from `current_person()` records who, and
  roles and grants make sure the history cannot be edited.
- **Roles and permissions** (together with the audit trail).
- **Device calibration and maintenance**, **storage history**, **method
  packages** ("drinking water basic" as one plannable unit).
- **A SensorThings API** view layer (see oms-alignment.md).
