# lucentBase: notes for working on this repository

lucentBase is the MariaDB back end of lucentLIMS. The frontend will live in its
own repository. Read README.md, docs/oms-alignment.md and docs/design.md before
changing the schema.

## Ground rules from the project owner

- ISO 19156 (OMS) is the structural reference. Any structural deviation needs a
  reason in docs/oms-alignment.md; names may differ. Update that file together
  with the schema.
- Third normal form is mandatory. Derive what can be derived (views,
  functions) instead of storing it twice.
- Readability beats elegance and, within reason, performance. Comment every
  table, trigger and procedure in the style of the existing files.
- Business rules belong in the database (constraints, triggers, procedures),
  so the database is usable without any frontend. No ORM may own the schema.
- lucentLIMS does not replicate document storage, mail, invoicing; it links.
- The audit trail is deliberately postponed until the schema settles (plan in
  docs/design.md).

## Working on the schema

- Schema changes are new files in `migrations/` (`NNNN_topic.sql`). Once a
  migration has been pushed, never edit it; add another one.
- Every rule gets a test in `tests/` (plain SQL, see `tests/lib/assert.sql`;
  `assert_fails` proves a rule refuses what it should). Tests that need the
  demo data start with `-- uses: seed`.
- Keep `seed/demo_environmental_lab.sql` working and `tests/test_demo_story.sql`
  in step with it. All demo names are fictional (Musterstadt etc.).
- Error messages are sentences a lab worker can act on.
- MariaDB pitfalls met so far: no `IS DISTINCT FROM` (use `NOT (a <=> b)`);
  `PROCEDURE` is reserved (hence `method`); `SIGNAL ... MESSAGE_TEXT` takes a
  variable, not an expression; `CHECK` cannot reference an AUTO_INCREMENT
  column; a temporary table cannot be used twice in one statement; inside a
  cursor loop, use `SET v = (SELECT ...)` rather than `SELECT ... INTO`, whose
  empty result would trigger the NOT FOUND handler; anonymous blocks
  (`BEGIN NOT ATOMIC`) need `DELIMITER` in the client.

## Running things

The development server is MariaDB on mensa3.internal:33306, started by hand
by the owner. The account `lucent_dev` may create databases matching
`lucent%`; its options are in `~/.config/lucentLIMS/dev.cnf` (never print or
commit it). With the Homebrew client:

```sh
export MARIADB_CLIENT="/opt/homebrew/opt/mariadb@11.8/bin/mariadb --defaults-extra-file=$HOME/.config/lucentLIMS/dev.cnf"
bin/test
```

The scripts are POSIX sh and split `$MARIADB_CLIENT` into words; zsh does not,
so call the client through a small wrapper script in interactive zsh sessions.
