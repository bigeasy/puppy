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

      ec2('DescribeKeyPairs', {}, cadence());

    }, function (response, createKeyPair) {

      // TODO: Not quite the query I imagined.
      if (!$q('/keySet/keyName[$ == $1]')(response, imageId).length) {
        cadence(createKeyPair)();
      }

    }, function () {

      ec2('DeleteKeyPair', { KeyName: imageId }, cadence());

    }, function createKeyPair () {

      ec2('CreateKeyPair', { KeyName: imageId }, cadence());

    }, function (response) {

      var out = fs.createWriteStream(keyFile, { encoding: 'utf8', mode: 0600 });
      out.end(response.keyMaterial);
      out.on('close', cadence());

    }, function () {

      ec2('RunInstances',
      { ImageId: 'ami-08d97e61'
      , MinCount: 1
      , MaxCount: 1
      , KeyName: 'ami-08d97e61'
      , 'SecurityGroup.1': 'puppy-image'
      , InstanceType: 'm1.small'
      }, cadence());

    }, function (response) {

      instanceId = $q('/i*Set/instanceId')(response).pop();

    }, function checkInstance () {

      setTimeout(cadence(), 1000);

    }, function () {

      ec2('DescribeInstances', { 'InstanceId.1': instanceId }, cadence());

    }, function (instance, checkInstance) {

      var state = $q('/reservationSet/instancesSet/instanceState/name')(instance).pop();
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
