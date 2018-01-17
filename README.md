# MultiRainCheck
Check the job status (run + queue) on several remote servers at once using MultiRainCheck.  

## Features
1. Obtain information on how many cores are currently running and in queue on several supercomputers.
2. Easily add new users by providing their alias and username(s).
3. Designed for supercomputers with the following resource managers: Torque, BQTools, SunGridEngine, Slurm

## File Descriptions

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

### main.sh
Execute one iteration of the MultiRainCheck script. This file pulls information entered into the __users__ and __input__ files, executes them on the host servers within a given walltime of 1 minute (60 seconds). A walltime is used to allow the code to progress and ignore any connections that are unstable or offline. If the connection fails, the default value of 0 cores will be enetered for all users.

### query.sql

### run.sh

## Notes
1. 
2. Originally designed for use on the following supercomputers with their respective resource managers:

| Name         | Resource Manager |
| ------------ |:----------------:|
| Graham       | Slurm            |
| Cedar        | Slurm            |
| Guillimin    | Torque           |
| Mammouth-Mp2 | BQTools          |
| Parallel     | Torque           | 
| Placentia    | SunGridEngine    |
| SciNet       | Torque           |
