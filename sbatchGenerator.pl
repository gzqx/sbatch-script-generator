#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use YAML::Tiny;
use Tie::IxHash;

# Define SBATCH parameters with default values and prompt messages.
# Tie assures the hash will be outputted as exactly following order
tie my %params, 'Tie::IxHash', (
    'job-name'  => { default => 'my_job',         prompt => "Enter job name" },
    account     => { default => 'my_account',         prompt => "Enter account name" },
    partition     => { default => 'vera',         prompt => "Enter partition (system) used" },
    time      => { default => '01:00:00',         prompt => "Enter time limit (hh:mm:ss/d-hh:mm:ss)" },
    ntasks    => { default => 32,                prompt => "Enter number of tasks to be run in parallel" },
    output    => { default => 'job_output.out',   prompt => "Enter output file name" },
    error     => { default => 'job_error.err',    prompt => "Enter error file name" },
    module_file => { default => '',               prompt => "Enter module file path (optional)" },
);

# Variables for command-line options.
my %cli_options;
my $config_file;

# Dynamically build GetOptions specification.
my @getopt_spec;
foreach my $key (keys %params) {
    # Numeric defaults are treated as integers, others as strings.
    if ($params{$key}->{default} =~ /^\d+$/) {
        push @getopt_spec, "$key=i" => \$cli_options{$key};
    } else {
        push @getopt_spec, "$key=s" => \$cli_options{$key};
    }
}
push @getopt_spec, 'config=s' => \$config_file;

# Parse command-line options.
GetOptions(@getopt_spec) or die "Error in command line arguments.\n";

# Override defaults with any command-line provided options.
foreach my $key (keys %params) {
    if (defined $cli_options{$key}) {
        $params{$key}->{default} = $cli_options{$key};
    }
}

# If a YAML config file is provided, read and update parameters from it.
if ($config_file) {
    my $yaml = YAML::Tiny->read($config_file)
      or die "Failed to read YAML config file '$config_file': $!";
    my $config = $yaml->[0];
    foreach my $key (keys %$config) {
        if (exists $params{$key}) {
            $params{$key}->{default} = $config->{$key};
        } else {
            warn "Unknown configuration key '$key' in YAML config file.\n";
        }
    }
} else {
    # No config file provided: prompt the user interactively for each parameter.
    foreach my $key (sort keys %params) {
        my $default = $params{$key}->{default};
        print "$params{$key}->{prompt} [$default]: ";
        my $input = <STDIN>;
        chomp($input);
        $params{$key}->{default} = $input if $input ne '';
    }
}

# Use the job name to define the output script file.
my $job_name        = $params{"job-name"}->{default};
my $script_filename = "$job_name.sh";

open(my $fh, '>', $script_filename)
  or die "Cannot open file '$script_filename' for writing: $!";

# Write the shebang.
print $fh "#!/bin/bash\n";

# Write SBATCH directives for all parameters except module_file.
foreach my $key (sort keys %params) {
    next if $key eq 'module_file';
    my $flag  = "--" . (join '-', split /_/, $key);
    my $value = $params{$key}->{default};
    print $fh "#SBATCH $flag=$value\n";
}

# Insert the module file's content, if specified.
my $module_file = $params{module_file}->{default};
if ($module_file ne '') {
    print $fh "\n# Begin module file content from: $module_file\n";
    if (-e $module_file) {
        open(my $mf, '<', $module_file)
          or warn "Cannot open module file '$module_file': $!";
        while (my $line = <$mf>) {
            print $fh $line;
        }
        close($mf);
    } else {
        print $fh "# Module file not found: $module_file\n";
    }
    print $fh "# End module file content\n";
}

# Append additional job commands as needed.
print $fh "\n# Load additional modules if required\n";
print $fh "# module load your_module\n\n";
print $fh "# Execute your application\n";
print $fh "# srun your_application\n";

close($fh) or warn "Could not close file '$script_filename': $!";

# Make the generated script executable.
chmod 0755, $script_filename or warn "Could not set executable permission on '$script_filename': $!";

print "Job script '$script_filename' generated successfully.\n";

# Prepare configuration data for saving.
my %config_data = map { $_ => $params{$_}->{default} } keys %params;

# If no config file was originally provided, ask the user whether to save the configuration.
unless ($config_file) {
    print "Would you like to save these settings to a YAML config file? [y/N]: ";
    chomp(my $answer = <STDIN>);
    if ($answer =~ /^y(es)?$/i) {
        print "Enter YAML file name [job_config.yaml]: ";
        chomp(my $fname = <STDIN>);
        $config_file = $fname ne '' ? $fname : 'job_config.yaml';
    }
}

# Write (or update) the YAML configuration file.
if ($config_file) {
    my $yaml_out = YAML::Tiny->new(\%config_data);
    $yaml_out->write($config_file)
      or warn "Could not write to YAML file '$config_file': $!";
    print "Configuration saved to '$config_file'.\n";
}


__END__

=head1 SBATCH Script Generator

sbatchGenerator.pl - Generate script for running with sbatch

=head1 SYNOPSIS

Generate script with a configuration file I<config.yaml>:

    sbatchGenerator.pl --config=config.yaml

Start interactive configuration:

    sbatchGenerator.pl 

Start interactive configuration with some default parameter changed (will be overridden if B<--config> is also used)

    sbatchGenerator.pl --[job-name|account|partition|time|ntasks|output|error]==[ultimate-question|earth|ape|10my|1|42|Vogons]

Start interactive configuration with a module file:
    
    sbatchGenerator.pl --module_file=module.sh

=head1 DESCRIPTION

This script helps you config environment, find modules, and generate a sbatch script.

=head1 OPTIONS

=over

=item B<--config>=I<path-to-file>

Specifies the configuration file (yaml format) to be used. If no file is provided, the script will start with prompting questions and generate one in the end.

Note: It will always override  parameters provided as flag B<--[sbatch options]> when running the script.

=item B<--[sbatch options]>=I<value>

It accepts I<job-name>, I<account>, I<partition>, I<time>, I<ntasks>, I<output>, I<error>

=item B<--module_file>=I<path-to-file>

Allows you to specify a module file that could contain modules and other commands (e.g. activating virtualenv). If not provided, the script will ask you if you want to interactively create one.

=back

=head1 BINARY

If you access this code from github, there is compiled version for Linux and MacOS in Action page.

=cut
