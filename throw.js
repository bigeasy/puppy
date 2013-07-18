var AWS = require('aws-sdk')

AWS.config.loadFromPath(process.env.HOME + '/.aws')
AWS.config.update({region: 'us-east-1'})

// This fails without reporting the exception.
// see: https://github.com/aws/aws-sdk-js/issues/74
new AWS.EC2().describeInstances(function () { throw new Error })
