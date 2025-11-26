#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I/home/phil/perl/cpan/GitHubCrud/lib/
#-------------------------------------------------------------------------------
# Use silicon compiler via a docker image previously built on github
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2025
#-------------------------------------------------------------------------------
use v5.38;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use GitHub::Crud qw(:all);

my $repo    = q(silicon_compiler_mod_A_in_mod_B);                               # Repo
my $user    = q(philiprbrenan);                                                 # User
my $home    = fpd q(/home/phil/sc/), $repo;                                     # Home folder
my $wf      = q(.github/workflows/mod_A_in_mod_B.yml);                          # Work flow on Ubuntu
my $upload  = q(../siliconcompiler/examples/mod_A_in_mod_B/);                   # This folder will be loaded with the read me and python code ready for a manual push o siliconCompiler

my $docker  = "ghcr.io/philiprbrenan/silicon_compiler_docker_image_asic:latest";# Docker image built on github by me
   $docker  = "ghcr.io/siliconcompiler/sc_runner:v0.35.3";                      # Docker image built on Silicon Compiler

my $dockerPath = "/app";                                                        # Path to working directory in my version
   $dockerPath = "/sc_work";                                                    # Path to working directory in docker image provided by silicon compiler

my $shaFile = fpe $home, q(sha);                                                # Sh256 file sums for each known file to detect changes
my @ext     = qw(.md .pl .py .sh);                                              # Extensions of files to upload to github

say STDERR timeStamp,  " Push to github $repo";

if (1)                                                                          # Create read me from python code
 {my @p = readFile fpe $home, $repo, q(py);                                     # Read python
  shift @p;                                                                     # Remove shebang

  my $lc = 1;                                                                   # Was the last line a comment
  my @q;
  for my $p(@p)                                                                 # Each line
   {if ($p =~ m(\A#)is)                                                         # A comment line
     {$p =~ s(\A# ?) ()igs;                                                     # Remove comment to reveal documentation
      if (!$lc)                                                                 # Last line was not a comment
       {push @q, qq(```\n\n);                                                   # End last code block
       }
      push @q, $p;                                                              # Add comment line
      $lc = 1;                                                                  # Last line was a comment
     }
    else                                                                        # Not a comment
     {if ($lc)                                                                  # Last line was a comment
       {push @q, qq(\n```\n);                                                   # Start new code block
       }
      push @q, $p;                                                              # Push code line
      $lc = 0;                                                                  # Last line was code
     }
   }

  my $q = expandWellKnownWordsAsUrlsInMdFormat join "", @q;                     # Expand README
  owf(fpe($home, qw(README md)), $q);                                           # Write extracted mark down to read me file
 }

my @files = searchDirectoryTreesForMatchingFiles($home, @ext);                  # Files to upload
   @files = grep {!m(/(build|z)/)} @files;                                      # Filter out generated files
   @files = changedFiles $shaFile, @files;                                      # Filter out files that have not changed

if (!@files)                                                                    # No new files
 {say "Everything up to date";
  exit;
 }

if  (1)                                                                         # Upload via github crud
 {for my $s(@files)                                                             # Upload each selected file
   {my $c = readBinaryFile $s;                                                  # Load file
    my $t = swapFilePrefix $s, $home;                                           # File on github
    my $w = writeFileUsingSavedToken($user, $repo, $t, $c);                     # Write file into github
    lll "$w  $t";
   }
 }

my $dt    = dateTimeStamp;
my $yml   = <<"END";                                                            # Create workflow
# Test $dt

name: Test
run-name: $repo

on:
  push:
    paths:
      - $wf

jobs:

  test:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout\@v4

    - name: Run Silicon compiler in a docker container
      run: |
        pwd
        ls -la
        docker run --rm -v "\$(pwd):$dockerPath" $docker python3 $repo.py

    - name: Upload all files as artifact
      uses: actions/upload-artifact\@v4
      if: always()
      with:
        name: results
        path: .
        retention-days: 32
END

my $f = writeFileUsingSavedToken $user, $repo, $wf, $yml;                       # Upload workflow
lll "$f  Ubuntu work flow for $repo";

sub upload($file)                                                               # Position a file for pushing to silicon compiler
 {my $s = $file;
  my $t = fpf $upload, $file;
  copyFile($s, $t);
  say STDERR "Copied $s to $t";
 }

upload(q(README.md));
upload(q(silicon_compiler_mod_A_in_mod_B.py));
