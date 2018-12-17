var exports = module.exports = {};
exports.run = function(event, context, callback) {
  const https = require('https');
  const eventData = event && JSON.parse(event);
  const message = (eventData && eventData.payload) || 'a payload was not provided to the message';

  const slackHost = process.env.SLACK_API_BASEPATH;
  const slackPath = process.env.SLACK_PATH;
  const slackOptions = { host: slackHost, path: slackPath };
  const slackPayload = JSON.stringify({ text: message.slackMessage });
  
  const sfHost = process.env.SF_API_BASEPATH;
  const sfPath = process.env.SF_PATH;
  const sfOID = process.env.SF_OID;
  const sfOptions = { host: sfHost, path: sfPath };
  const name = message.name.split(' ');
  const sfPayload = `oid=${sfOID}&lead_source=Website&first_name=${name[0]}&last_name=${name[1]}&company=${message.company}&email=${message.email}&title=${message.title}&phone=${message.phone}&employees=${message.size}&00N1I00000KJ0Id=${message.message}`;
  
  
  // https request POST method
  const request = (options, payload, contentType = 'application/json') => {
     const postOptions = Object.assign({
      method: 'POST',
      headers: {
        'Content-Type': contentType,    
        'Content-Length': Buffer.byteLength(payload),
      },
      json: true,
     }, options);

    const req = https.request(postOptions, (res) => {
      res.on('data', (chunk) => {
        console.log(`BODY: ${chunk}`);
      });
      res.on('end', () => {
        callback(null, 'SUCCESS');
      });
    });
  
    req.on('error', (e) => {
      console.error(`problem with request: ${e.message}`);
      callback(e.message, 'ERROR');
    });
    
    // write data to request body
    req.write(payload);
    req.end();       
  };
  
  request(slackOptions, slackPayload);
  request(sfOptions, sfPayload, 'application/x-www-form-urlencoded');
};