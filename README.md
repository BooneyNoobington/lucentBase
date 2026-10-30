# lucentBase

The MariaDB database that underlies lucentLIMS.


## Prerequisites

- A Linux system (other systems like macOS and Windows probably also work but aren't tested)
- MariaDB 10.11 or higher (older versions might still work but aren't tested)


## Installation

1. Clone this project:
   ```bash
   git clone https://github.com/BooneyNoobington/lucentBase.git
   ```

2. Execute this command as root user inside the project directory (using `sudo` in the example):
   ```bash
   sed "s/{linux_user}/$USER/g" DATABASE_GENERATION.SQL | sudo mysql
   ```


## Philosophy and ERD

lucentBase aims to strictly adhere to the first three normal forms in order to maximize maintainability and enable frontend building with many different frameworks.

It is also process-oriented. In a lab workflow, any object of observation—mostly samples—goes through a number of steps during its lifetime, such as sampling, registration in the lab, preprocessing, various measurements, and disposal. These steps are called **actions**. Each action can have **effects** (instances of predefined **parameters**), such as the recording of the time of sampling and the arrival time in the lab, confirmation that preprocessing is completed, measurement results, or even their total costs.

**Collections** make up the second center of lucentBase. Besides samples, a collection can be a singular measurement or a time series, with the unifying quality of holding an assortment of **values**—which are **effects** assigned to a specific collection.

A value consists of one or more **raw values** (connected to a value via its primary key `id_value`).

Unlike many other LIMSs, lucentBase has no table for end results. Instead, **effects** know functions to calculate an end result from their **values** and **raw values**. They are also self-joined by **coefficients** to get **raw values** of a different **value**.


## Logging and Comment Tables

By default, every change on a table is logged in its corresponding logging table. Without user changes, logging table names are the table name prefixed by `l_`. They are automatically generated when setting up the database via the procedure `create_all_log_tables()`.

The logging triggers take two session variables from the application that writes:

- `@current_user_id`: the `id_person` of whoever makes the change, stored as `id_editor`;
- `@change_note`: optionally, why the change was made, stored as `note` (otherwise "Inserted" or "Updated").

```sql
SET @current_user_id = 1, @change_note = 'Confirmed after re-measurement';
UPDATE raw_value SET accepted = TRUE WHERE id_raw_value = 42;
```

Not auto-generated are "comment tables." These are tables that hold textual comments for a specific record and are prefixed by `c_`.


## Further Naming Conventions

Junction tables have meaningful names wherever possible. If they don't carry intuitive information, they are prefixed by `j_`.
