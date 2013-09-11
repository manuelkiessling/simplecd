# Simple Continuous Delivery

## About

SimpleCD is a Continuous Delivery system written for the Bash shell.

It provides a very simple environment which allows you to continuously deliver
your software to a staging and/or production environment while also running
your end-to-end and/or unit tests in advance, deploying only those deliverables
to your environments that don't have failing tests.

SimpleCD is completely agnostic in regards to unit- and e2e-test frameworks and
doesn't know how to deploy deliverables itself. These steps are defined and
implemented within the projects that are to be delivered, and SimpleCD merely
executes these steps.


## Installation

Clone this repository. You will only need the file `simplecd.sh` in order
to start deliveries.


## Preparing your application

SimpleCD depends on some special files being present in your application's
Git repository, the so-called SimpleCD run scripts - one for earch step of a
continuous delivery run.

These are:

 * `run-unit-tests`
 * `deploy-to-staging`
 * `run-e2e-tests-for-staging`
 * `deploy-to-production`
 * `run-e2e-tests-for-production`

The names probably speak for themselves. These files must be placed in a
subfolder of your project's repository named `_simplecd`, and must be set to
executable.

SimpleCD will try to execute each step by executing these scripts in the order
shown above. If a script is missing, this step is simply skipped. If executing
a script results in a status code > 0, the delivery is aborted.

Additionally, you can add a file `_simplecd/logreceivers.txt` with one mail
address per line. If the file is present, a report of the run will be sent to
the listed mail addresses.


## Usage

`simplecd.sh <repo-url> <branch> [reset|<url>]`

The following steps are executed:

1. Check if an instance of the given plan is already running, exit if yes
2. Check if the remote repo is newer than what was last delivered
3. Pull the newest code from the remote repository
4. Run the scripts that are provided by the repository in subfolder `_simplecd`:
  a. `run-unit-tests`
  b. `deploy-to-staging`
  c. `run-e2e-tests-for-staging`
  d. `deploy-to-production`
  e. `run-e2e-tests-for-production`
5. Mail results to the receivers listed in `_simplecd/logreceivers.txt`

For steps a to e, the rule is that they must return exit code 0 on success
and exit code > 0 on failure. If any of these steps fail, the delivery is
aborted.

SimpleCD will call every script with the path to the local repository clone,
e.g.

`./_simplecd/run-unit-tests /var/tmp/simplecd/projects/e70081c0e267ac64454c27f5e600d214`

If the script file for a given step a to e is not found, SimpleCD simply
skips this step and continues with the next step.

If the keyword *reset* is provided as the third parameter, SimpleCD does not
start a delivery, but instead removes all working data related to the given
repo/branch combination, that is, SimpleCD resets its environment to a state
as if no previous runs for this repo/branch had occured.

If instead an HTTP URL is provided as the third parameter, SimpleCD will
prefix any commit id it outputs with this URL.

Start a delivery by running SimpleCD with a git repository URL as the first,
and a branch name as the second parameter:

    simplecd.sh git@github.com:johndoe/foobar.git master

See the inline documentation of `simplecd.sh` if you would like to know what
exactly happens during a delivery.


## License 

The MIT License (MIT)

Copyright (c) 2013 Manuel Kiessling, MeinAuto GmbH

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
