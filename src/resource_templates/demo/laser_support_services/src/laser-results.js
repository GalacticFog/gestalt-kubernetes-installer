const request = require('request-promise-native');

// Syncronous, HTTP-aware lambda

module.exports.handler = async (event, context, callback) => {
    try {
        const start = Date.now();

        console.log('Event: ' + event);
        console.log('Context: ' + context);

        context = JSON.parse(context);

        const id = context.params.id[0];

        const options = {
            resolveWithFullResponse: true,
            headers: context.headers
        }

        let serviceUrl = process.env.SERVICE_URL;

        if (!serviceUrl) throw Error(`serviceUrl is not defined`);

        serviceUrl += '/' + id;

        console.log(`Visiting ${serviceUrl}...`)

        const resp = await request({ uri: serviceUrl, ...options });

        const elapsed = Date.now() - start;

        console.log(`${serviceUrl} returned a ${resp.statusCode} and took ${elapsed} ms...`)

        // const result = {
        //     url: serviceUrl,
        //     elapsed: elapsed,
        //     statusCode: resp.statusCode,
        //     timestamp: start,
        //     response: resp
        // };

        // const response = {
        //     statusCode: resp.statusCode,
        //     headers: { 'Content-Type': 'application/json' },
        //     body: JSON.stringify(result, null, 2)
        // }

        callback(null, resp);
    } catch (err) {

        console.error('An exception occurred: ' + err);

        if (err.response) {
            const response = {
                statusCode: err.response.statusCode,
                headers: err.response.headers,
                body: JSON.stringify(err, null, 2)
            }

            callback(null, response);
        } else {
            const response = {
                statusCode: 500,
                headers: {},
                body: JSON.stringify(err.stack || err, null, 2)
            }

            callback(null, response);
            // callback(err, null);
        }
    }
};