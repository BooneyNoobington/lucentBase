# lucentBase
The MariaDB database that underlies lucentLIMS.


# Prerequisites
- A Linux system (other systems like macOS and Windows probably also work, but aren't tested)
- MariaDB 10.11 or higher (older versions might still work, but aren't tested)


# Installation
1. Clone this project, e.g. by `git clone https://github.com/BooneyNoobington/lucentBase.git`

2. Execute this command as root user inside the project directory. In the example, sudo is used to achieve that.
`sed "s/{linux_user}/$USER/g" DATABASE_GENERATION.SQL | sudo mysql`


# Philosophie and ERD
lucentBase aims to strictly adhere to the first three normal forms in order to maximaze maintainability and enable frontend building with many different frameworks.

It is also process oriented. In a lab workflow, any object of observation -- mostly samples -- go through a number of steps during their lifetime. Such as sampling, registration in the lab, preprocessing, various measurements as well as disposal. These steps are called _actions_. Each action can have _effects_, such as the recording of the time of sampling and the arrival time in the lab, confirmation that preprocessing is completed, measurement results or even their total costs.