const request = require('request-promise-native');

module.exports.handler = async (event, context, callback) => {


    const urls = [
        'http://www.galacticfog.com',
        'http://www.google.com',
        'http://www.cnn.com',
        'http://www.osnews.com',
        'http://www.arstechnica.com',
    ];

    const options = {
        resolveWithFullResponse: true
    }

    const summary = [];

    for (let url of urls) {

        const start = Date.now();

        console.log(`Visiting ${url}...`)

        const response = await request({ uri: url, ...options });

        const elapsed = Date.now() - start;

        console.log(`${url} returned a ${response.statusCode} and took ${elapsed} ms...`)

        summary.push({
            url: url,
            elapsed: elapsed,
            statusCode: response.statusCode,
            timestamp: start
        });
    }

    console.log(`Wrapping up, got ${summary.length} results`);

    const response = {
        statusCode: 201,
        headers: { 'test-header': 'test123' },
        body: JSON.stringify(summary, null, 2)
    }

    callback(null, response);
};