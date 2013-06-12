var AWS = require('aws-sdk');
var arguable = require('arguable');
var cadence = require('cadence');

var key = '__puppy_temporary_key_pair_$$$_' + process.pid + '__';

AWS.config.loadFromPath(process.env.HOME + '/.aws');
AWS.config.update({region: 'us-east-1'});

var ec2 = new AWS.EC2;
cadence(function (step, ec2) {
  step(function () {
    ec2.createKeyPair({ KeyName: key }, step());
  }, function (results) {
    console.log(results);
    ec2.describeKeyPairs(step());
  }, function (results) {
    results.KeyPairs.filter(function (pair) {
      return (/^__puppy_temporary_key_pair_\$\$\$_\d+__/.test(pair.KeyName))
    }).forEach(step([], function (pair) {
      console.log(pair.KeyName);
      ec2.deleteKeyPair({ KeyName: pair.KeyName }, step());
    }));
  });
})((new AWS.EC2), function () {});
