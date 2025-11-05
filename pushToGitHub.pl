#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I/home/phil/perl/cpan/GitHubCrud/lib/
#-------------------------------------------------------------------------------
# Use silicon compiler via a docker image to place one design in another
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
my $wf      = q(.github/workflows/run.yml);                                     # Work flow on Ubuntu
my $docker  = "ghcr.io/philiprbrenan/silicon_compiler_docker_image:0890fa2e60d6322611358f53bf1ff0d9b5e53926";

my $shaFile = fpe $home, q(sha);                                                # Sh256 file sums for each known file to detect changes
my @ext     = qw(.md .pl .py .sh);                                              # Extensions of files to upload to github

say STDERR timeStamp,  " Push to github $repo";

my @files = searchDirectoryTreesForMatchingFiles($home, @ext);                  # Files to upload
   @files = changedFiles $shaFile, @files;                                      # Filter out files that have not changed

if (!@files)                                                                    # No new files
 {say "Everything up to date";
  exit;
 }

if  (1)                                                                         # Upload via github crud
 {for my $s(@files)                                                             # Upload each selected file
   {my $c = readBinaryFile $s;                                                  # Load file

    $c = expandWellKnownWordsAsUrlsInMdFormat $c if $s =~ m(README);            # Expand README

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
      - '**/run.yml'

jobs:

  test:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout\@v4

    - name: Run Silicon compiler in a docker container
      run: |
        docker run --rm -v "\$(pwd):/opt/siliconcompiler" $docker bash -c "ls -la"

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
