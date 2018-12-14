const request = require('request-promise-native');

module.exports.handler = async (event, context, callback) => {

    console.log('Event: ' + event);
    console.log('Context: ' + context);

    event = (event && event.length > 0) ? JSON.parse(event) : {};
    context = JSON.parse(context);

    // Headers have to be strings
    const step = parseInt(context.headers.step);

    // Append to the body
    const body = event.body ? JSON.parse(event.body) : {};

    console.log('body: ' + JSON.stringify(body));

    body[`Step ${step}`] = `This is ${step}`;

    console.log('body: ' + JSON.stringify(body));

    const timeout = ms => new Promise(res => setTimeout(res, ms))

    console.log("Waiting a time...")

    await timeout(200);

    const headers = {};
    headers[`step-${step}`] = `200 Success`

    const response = {
        statusCode: 201,
        headers: headers,
        body: JSON.stringify(body)
    }

    callback(null, response);
};
