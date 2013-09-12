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
Git repository, the so-called SimpleCD step scripts - one for earch step of a
continuous delivery run.

You can create up to 100 step scripts, each with a unique leading number between
00 and 99 followed by a dash (-).

Here are some examples:

* `00-run-unit-tests`
* `10-deploy-to-staging`
* `20-run-migrations-on-staging`
* `30-run-e2e-tests-for-staging`

and so on. Hint: If you start by numbering your initial step scripts with
00, 10, 20... instead of 00, 01, 02..., then later it's much easier to add
new steps between existing steps.

These files must be placed in a subfolder of your project's repository named
`_simplecd`, and they must be set to executable.

SimpleCD will try to execute each step by executing these scripts in the order
shown above. If executing a script results in a status code > 0, then the
delivery is aborted.

Additionally, you can add a file `_simplecd/logreceivers.txt` with one mail
address per line. If the file is present, a report of the run will be sent to
the listed mail addresses.


## Usage

`simplecd.sh <repo-url> <branch> [reset|<url>]`

The following steps are executed:

1. Check if an instance of the given plan is already running, exit if yes
2. Check if the remote repo is newer than what was last delivered
3. Pull the newest code from the remote repository
4. Run the step scripts that are provided by the repository in subfolder
   `_simplecd`.
5. Mail results to the receivers listed in `_simplecd/logreceivers.txt`

SimpleCD will call every script with the path to the local repository clone
as the first parameter, and with the name of the branch as the second parameter,
like this:

`./_simplecd/00-run-unit-tests /var/tmp/simplecd/projects/e70081c0e267ac64454c27f5e600d214 master`

If the keyword *reset* is provided as the third parameter, SimpleCD does not
start a delivery, but instead removes all working data related to the given
repo/branch combination, that is, SimpleCD resets its environment to a state
as if no previous runs for this repo/branch had occured.

If instead an HTTP URL is provided as the third parameter, SimpleCD will
prefix any commit id it outputs with this URL.

Start a delivery by running SimpleCD with a git repository URL as the first,
and a branch name as the second parameter:

    simplecd.sh git@github.com:johndoe/foobar.git master


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
