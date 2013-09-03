// This file belongs in your project's repository as /_simplecd/karma.e2e.conf.js

// See http://karma-runner.github.io/0.10/config/configuration-file.html for a
// comprehensive explanation of this file

module.exports = function(config) {
  config.set({

    basePath: '',

    urlRoot: '/karma/',

    frameworks: ['jasmine'],

    files: [
      '../node_modules/karma-ng-scenario/lib/angular-scenario.js',
      '../node_modules/karma-ng-scenario/lib/adapter.js',
      '../test/e2e/**/*Spec.js',
    ],

    exclude: [
    ],

    reporters: ['progress'],

    port: 9876,

    // This should point to your staging environment
    proxies:  {
      '/': 'http://staging.example.com/myproject/'
    },

    colors: true,

    logLevel: config.LOG_INFO,

    autoWatch: false,

    browsers: ['Chrome'],

    captureTimeout: 60000,

    // This one is critical. If set to false, Karma simply would not end, infinitely stalling the delivery
    singleRun: true
  });
};
