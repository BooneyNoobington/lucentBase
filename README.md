# lucentBase
The MariaDB database that underlies lucentLIMS.


# Prerequisites
- A Linux system
- MariaDB 10.11 or higher (older versions might still work, but aren't tested)


# Installation
Execute this command as root user inside the project directory. In the example, sudo is used to achieve that.
`sed "s/$USER/$linux_user/g" DATABASE_GENERATION.SQL | sudo mysql`