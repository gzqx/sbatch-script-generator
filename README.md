# SBATCH Script Generator

sbatchGenerator.pl - Generate script for running with sbatch

# SYNOPSIS

Generate script with a configuration file _config.yaml_:

    sbatchGenerator.pl --config=config.yaml

Start interactive configuration:

    sbatchGenerator.pl 

Start interactive configuration with some default parameter changed (will be overridden if **--config** is also used)

    sbatchGenerator.pl --[job-name|account|partition|time|ntasks|output|error]=[ultimate-question|earth|ape|10my|1|42|Vogons]

Start interactive configuration with a module file:

    sbatchGenerator.pl --module_file=module.sh

# DESCRIPTION

This script helps you config environment, find modules, and generate a sbatch script.

# OPTIONS

- **--config**=_path-to-file_

    Specifies the configuration file (yaml format) to be used. If no file is provided, the script will start with prompting questions and generate one in the end.

    Note: It will always override  parameters provided as flag **--\[sbatch options\]** when running the script.

- **--\[sbatch options\]**=_value_

    It accepts _job-name_, _account_, _partition_, _time_, _ntasks_, _output_, _error_

- **--module\_file**=_path-to-file_

    Allows you to specify a module file that could contain modules and other commands (e.g. activating virtualenv). If not provided, the script will ask you if you want to interactively create one.

# BINARY

If you access this code from github, there is compiled version for Linux and MacOS in Action page.
