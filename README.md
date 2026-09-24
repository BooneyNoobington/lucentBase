# lucentBase

The MariaDB database behind **lucentLIMS**, an open source laboratory
information management system for small environmental and academic labs, run
by people who like to tinker.

lucentBase is a complete LIMS back end on its own. All rules live in the
database, so you can work with it from a frontend, from a SQL client, or from
a spreadsheet, and the same rules hold everywhere.


## Built on ISO 19156 (Observations, Measurements and Samples)

The data model follows **ISO 19156:2023 / OGC Topic 20**, the international
standard for observations and samples. Samples, observations, observed
properties, procedures and features mean exactly what they mean there. Every
structural deviation has a documented reason:
**[docs/oms-alignment.md](docs/oms-alignment.md)**.

On top of OMS, lucentBase adds what a lab needs to organize its work:

- **A lifecycle for every sample.** Everything that happens to a sample
  (sampling, receipt, filtration, measurement, disposal) is an *action*.
  Methods declare which others must be finished first, and which others they
  bring along when they are planned. The database refuses to start an action
  too early, and it refuses to plan anything for a sample after it has been
  disposed of.
- **Results that stay honest.** Results are never overwritten; corrections
  are recorded with a reason. Values below the limit of quantification are
  kept exactly and shown as "< LOQ". Calculated results (dilutions, sums,
  water hardness) record their inputs, and are flagged as soon as an input
  changes.
- **Reports that stay what they were.** Issued reports are frozen. When a
  reported result is corrected later, the report is flagged for amendment.
- **Orders and customers, method versions, units with conversions.**

What it looks like: [docs/schema.md](docs/schema.md) (diagrams).
Why it is built this way: [docs/design.md](docs/design.md).


## Getting started

You need MariaDB 11.8 or newer and its `mariadb` command line client.

```sh
git clone https://github.com/BooneyNoobington/lucentBase.git
cd lucentBase
bin/migrate lucent
```

`bin/migrate` creates the database if needed and applies every migration not
yet applied. Run it again after pulling updates. It talks to the server
through the command in `$MARIADB_CLIENT` (default: `mariadb`), so connection
details go into a MariaDB option file:

```sh
export MARIADB_CLIENT="mariadb --defaults-extra-file=$HOME/.config/lucentLIMS/dev.cnf"
```

To look around in a database full of example data:

```sh
bin/migrate lucent_demo
$MARIADB_CLIENT lucent_demo < seed/demo_environmental_lab.sql
```

Then start with these views:

```sql
SELECT * FROM v_worklist;          -- what there is to do, and what it waits for
SELECT * FROM v_sample_overview;   -- every sample, where it came from, what is open
SELECT * FROM v_observation;       -- every result, as reported and as measured
SELECT * FROM v_stale_calculation; -- calculated results whose inputs changed
```

The seed file itself is a readable walkthrough of a lab's two weeks of work.


## Tests

```sh
bin/test                            # all tests
bin/test tests/test_lifecycle.sql   # one file
```

Each test file runs in a fresh database (`lucent_test_<name>`, so the account
needs rights on databases matching `lucent%`). Tests are plain SQL with a few
assertion procedures; see [tests/lib/assert.sql](tests/lib/assert.sql).
GitHub Actions runs them against MariaDB 11.8, 12.3 and 13.0.


## Layout

```
migrations/   the schema, as numbered migration files
bin/          migrate and test
tests/        SQL tests
seed/         fictional demo data
docs/         OMS alignment, schema diagrams, design notes
```


## License

GNU Affero General Public License v3.0, see [LICENSE](LICENSE).
