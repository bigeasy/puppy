var AWS = require('aws-sdk');
var arguable = require('arguable');
var cadence = require('cadence');

var key = '__puppy_temporary_key_pair_$$$_' + process.pid + '__';

AWS.config.loadFromPath(process.env.HOME + '/.aws');
AWS.config.update({region: 'us-east-1'});

var ec2 = new AWS.EC2;
cadence(function (step, ec2) {
  step(function () {
    ec2.createSecurityGroup({
      GroupName: "Puppy Image", 
      Description: "Puppy bootstrap image security group."
    }, step());
  }, function (results) {
    console.log(results);
    ec2.authorizeSecurityGroupIngress({
      GroupName: "Puppy Image", 
      IpProtocol: "tcp",
      CidrIp: "0.0.0.0/0",
      FromPort: 22,
      ToPort: 22
    }, step());
  }, function (results) {
    console.log(results);
  });
})((new AWS.EC2), function (error) {
  if(error) throw error;
});
