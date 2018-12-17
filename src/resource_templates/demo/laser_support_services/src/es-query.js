const request = require('request-promise-native');

// Syncronous, HTTP-aware lambda

module.exports.handler = async (event, context, callback) => {
    try {
        const start = Date.now();

        console.log('Event: ' + event);
        console.log('Context: ' + context);

        context = JSON.parse(context);

        const options = {
            resolveWithFullResponse: true,
            // headers: context.headers
            headers: {}
        }

        options.headers = Object.assign(options.headers, {
            'Accept': 'text/plain',
            'User-Agent': 'curl/7.61.0'
        })

        const serviceUrl = 'http://gestalt-elastic.gestalt-system.svc.cluster.local:9200';
        let url = '';
        if (context.params.search) {
            url = serviceUrl + `/${context.params.search[0]}/_search`
        } else {
            url = serviceUrl + '/_cat/indices'
        }

        console.log(`Visiting ${url}...`)

        const resp = await request({ uri: url, ...options });

        const elapsed = Date.now() - start;

        console.log(`${serviceUrl} returned a ${resp.statusCode} and took ${elapsed} ms...`)

        const response = {
            statusCode: 200,
            headers: {},
            body: resp.body.startsWith('{') ? JSON.stringify(JSON.parse(resp.body), null, 2) : resp.body
        }

        callback(null, response);
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