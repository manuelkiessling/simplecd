# Simple Continuous Delivery

## About

SimpleCD is a Continuous Delivery system written for the Bash shell.

It provides a very simple environment which allows you to continuously deliver
your software to a staging and/or production environment while also running
your end-to-end and/or unit tests in advance, deploying only those deliverables
to your environments that don't have failing tests.

SimpleCD is completely agnostic in regards to unit- and e2e-test frameworks and
doesn't know itself how to deploy deliverables. These steps are defined and
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
subfolder of you project's repository named `_simplecd`, and must be set to
executable.

SimpleCD will try to execute each step by executing these scripts in the order
shown above. If a script is missing, this step is simply skipped. If executing
a script results in a status code > 0, the delivery is aborted.


## Usage

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
