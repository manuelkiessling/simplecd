# Simple Continuous Delivery

## About

SimpleCD is a Continuous Delivery system written for the Bash shell.

It provides a very simple environment which allows you to continuously deliver
your software to a staging or production environment while also running your
end-to-end and unit tests in advance, deploying only those deliverables to your
environments that don't have failing tests.

SimpleCD currently utilizes Karma for end-to-end browser tests, and PHPUnit for
unit tests.


## Installation

SimpleCD depends on Karma, and therefore needs Node.js and a setup
where Karma can start one of its supported browsers
(see http://karma-runner.github.io/0.10/config/browsers.html).

Install the latest version of Node.js from http://nodejs.org/download/

Install Karma: `sudo npm install -g karma`

Clone this repository. You will only need the file `simplecd.sh` in order
to start deliveries.


## Preparing your application

SimpleCD depends on some special files being present in your application's
Git repository. These are:

* `_simplecd/deploy-staging.sh` - a bash-executable script that copies the
  delivery to your staging system
* `_simplecd/karma.e2e.conf.js` - a Karma configuration file which allows
  SimpleCD to run your end-to-end tests
* `package.json` - a NPM package file which describes the Karma dependencies
  for your end-to-end tests. SimpleCD will install them before running Karma

See `example-configs` in this repository for some example files.


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
