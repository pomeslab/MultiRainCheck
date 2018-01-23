# MultiRainCheck
Check the job status (run + queue) on several remote servers at once using MultiRainCheck.  

## Features
1. Obtain information on how many cores are currently running and in queue on several supercomputers.
2. Easily add new users by providing their alias and username(s).
3. Designed for supercomputers with the following resource managers: Torque, BQTools, SunGridEngine, Slurm

## Recommendations
1. It helps if you have an auto SSH login setup for all host servers. Search online on how to setup auto-logins to servers via SSH.
2. If you want to run this program continuously in the backgroud on a remote Linux computer (e.g. Raspberry Pi), then I recommend you use a program called "screen" to help you run this program via SSH and leave it on after exiting.

## File Descriptions

### main.sh
Execute one iteration of the MultiRainCheck script. This file pulls information entered into the __users__ and __input__ files, executes them on the host servers within a given walltime of 1 minute (60 seconds). A walltime is used to allow the code to progress and ignore any connections that are unstable or offline. If the connection fails, the default value of 0 cores will be enetered for all users.

### input
The list of input host server addresses. You must entered your own username associated with that server, a name for the host (no spaces), the host address, and the job check script you wish to run on that server. To prevent entering your password for each host, it is recommended that you have authorized SSH keys uploaded to each server. You can search for tutorials online on how to do this. 

Format: 

```username hostalias(given name) hostaddress jobcheckscript(inside the /script directory)```

Example: 

```wilsonjohn Cedar cedar.computecanada.ca Slurm```

### users
The list of users you want to check job statuses for. Equal signs are important for the program to distinguish between the name of the user, their usernames and the following user. Underscores are important (don't use spaces) to distinguish between segments of a name. The end of the list is followed by "=end="

Format: 
```
=FirstName_LastName=
username1
username2
=end=
```

Example:
```
=John_Smith=
smithjohn1
smithjohn2
=end=
```

### run.sh (desigend for personal use)
Iteratively run main.sh. This script creates tables in the a PostgreSQL database if they don't already exist and runs main.sh to collect data from the requested host addresses. The default sleep time between iterations is 30 minutes. Some servers may limit the number of times you can login within a set time. Adjusting the iteration time may be useful. You can do it in two ways:

You can provide one argument when executing run.sh to change the iteration time. Just provide an integer in minutes.

```
./run.sh 60 # 60 minutes of sleep between interations
```

You can change the default sleep time in the script.
```
# Set Time Interval (First Argument or default of 30 mins)
# min_interval=${1:-30} # old default of 30 minutes
min_interval=${1:-60} # new 60 minute sleep time
echo "Collecting Data at an interval of $min_interval minutes"
```

### query.sql (desigend for personal use)
PostgreSQL code for handling data inserted into a temporary log table in the database. The log60m table currently isn't functioning as intended. 


## Notes
1. Originally designed for use on the following supercomputers with their respective resource managers:

| Name         | Resource Manager |
| ------------ |:----------------:|
| Graham       | Slurm            |
| Cedar        | Slurm            |
| Guillimin    | Torque           |
| Mammouth-Mp2 | BQTools          |
| Parallel     | Torque           | 
| Placentia    | SunGridEngine    |
| SciNet       | Torque           |
