#!/usr/bin/env node

/* 
 
  usage: bootstrap [options]

  options:

  -z, --zone              [name]  AWS availability zone
  -a, --architecture      [name]  instance architecture, i386 or x86_64
  -s, --size              [name]  instance size, default t1.micro
  -h, --help                      display this help message

  :usage
 
 */

var cadence = require('cadence')()
  , ec2 = require('ec2')
  , fs = require('fs')
  , $q = require('inquiry')
  , configuration = JSON.parse(fs.readFileSync(process.env.HOME + '/.aws', 'utf8'))
  , name = "alvar.image.south.virginia.runpup.com"
  , options
  ;

run(main);

function run (main) {
  try {
    main();
  } catch (error) {
    if (error.usage) {
      if (error.message) console.error('error: ' + error.message);
      console.error(error.usage);
      process.on('exit', function () { process.exit(error.code) });
    } else {
      throw error;
    }
  }
}

function raise (options, message, code) {
  var error  = new Error(message);
  error.usage = options.$usage;
  error.code  = code == null ? 1 : code;
  throw error;
}

function main () {
  options = require('arguable').parse(__filename, process.argv.slice(2));

  var imageId = 'ami-08d97e61', keyFile = './' + imageId + '.pem'
    , instanceId
    ;

  if (options.help) {
    raise(options, '', 0);
  }

  cadence(function (cadence) {

    ec2 = ec2(configuration);  

    cadence(function () {

      ec2('DescribeInstances', {}, cadence());

    }, function (instance, checkInstance) {

      console.log(require('util').inspect(instance, false, 12));

      var instance = $q('/reservationSet/instancesSet[tagSet{$.key == "Name" && $.value == $1}]')(instance, name).pop();
      console.log(instance);
      process.exit(1);
      if (state == 'pending') cadence(checkInstance)();

    }, function () {

      ec2('CreateTags',
      { 'ResourceId.1': instanceId
      , 'Tag.1.Key': 'Name'
      , 'Tag.1.Value': 'alvar.image.south.virginia.runpup.com'
      }, cadence());

    // TODO: That underbar is handy for this common case.
    }, function (ignore, instance) {

      // TODO: Add a test to match the correct device.
      var volumeId = $q('/reservationSet/instancesSet/blockDeviceMapping/ebs/volumeId')(instance).pop();

      ec2('CreateTags',
      { 'ResourceId.1': volumeId
      , 'Tag.1.Key': 'Name'
      , 'Tag.1.Value': 'alvar.image.south.virginia.runpup.com'
      }, cadence());

    }/*, function checkConsole () {

      ec2('GetConsoleOutput', { 'InstanceId.1': instanceId }, cadence());

    }, function (response, checkConsole) {

      if (!response.output) setTimeout(cadence(checkConsole), 1000);
      else console.log(response); 

    }*/);
  })();
}
