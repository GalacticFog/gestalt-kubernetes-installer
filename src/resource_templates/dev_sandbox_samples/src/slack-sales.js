var exports = module.exports = {};
exports.run = function(event, context, callback) {
  const https = require('https');
  const host = process.env.SLACK_API_BASEPATH;
  const path = process.env.SLACK_PATH;
  const options = { host, path };
  const eventData = event && JSON.parse(event);
  const message = (eventData && eventData.payload) || 'a payload was not provided to the message';
  const body = JSON.stringify({ text: message.slackMessage });

  // https request POST method
  const requestPOST = (options, payload) => {
     const postOptions = Object.assign({
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',      
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
  
  requestPOST(options, body);
};