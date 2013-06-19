var AWS = require('aws-sdk');
var arguable = require('arguable');
var cadence = require('cadence');

var keyName = '__puppy_temporary_key_pair_$$$_' + process.pid + '__';

AWS.config.loadFromPath(process.env.HOME + '/.aws');
AWS.config.update({region: 'us-east-1'});

var instance, pending;
cadence(function (step, ec2) {
  step(function () {
    ec2.createKeyPair({ KeyName: keyName }, step());
  }, function (results) {
    key = results;
    console.log(results);
    ec2.runInstances({
      ImageId: 'ami-6f640c06',
      MinCount: 1,
      MaxCount: 1,
      KeyName: keyName,
      SecurityGroups: [ 'Puppy Image' ],
      InstanceType: 't1.micro',
    }, step());
  }, pending = function (result) {
    instance = (result.Instances || result.Reservations[0].Instances)[0];
    if (instance.State.Name == 'pending') {
      var next = step(pending);
      step(function () {
        setTimeout(step(), 5000);
      }, function () {
        ec2.describeInstances({ InstanceIds: [ instance.InstanceId ] }, next);
      });
    } else {
      ec2.createTags({
        Resources: [ instance.InstanceId ],
        Tags: [
          { Key: "Name", Value: "Puppy Bootstrap Image" },
          { Key: "Puppified", Value: "True" }
        ]
      }, step());
    }
  }, function (result) {
    ec2.createTags({
      Resources: [ instance.BlockDeviceMappings[0].Ebs.VolumeId ],
      Tags: [
        { Key: "Name", Value: "Puppy Bootstrap Image" }
      ]
    }, step());
  }, function (result) {
    var keyMaterial = key.keyMaterial, Tags = [], count = 0;
    while (keyMaterial.length) {
      Tags.push({
        Key: "Private Key " + (count++),
        Value: keyMaterial.substring(0, 255)
      });
      keyMaterial = keyMaterial.substring(255);
    }
    ec2.createTags({
      Resources: [ instance.InstanceId ],
      Tags: Tags
    }, step());
  }, function (result) {
    console.log(result);
    ec2.describeKeyPairs(step());
  }, function (results) {
    results.KeyPairs.filter(function (pair) {
      return (/^__puppy_temporary_key_pair_\$\$\$_\d+__/.test(pair.KeyName))
    }).forEach(step([], function (pair) {
      console.log(pair.KeyName);
      ec2.deleteKeyPair({ KeyName: pair.KeyName }, step());
    }));
  });
})((new AWS.EC2), function (error) {
  if(error) throw error;
});
