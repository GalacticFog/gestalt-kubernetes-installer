const request = require('request-promise-native');

module.exports.handler = async (event, context, callback) => {

    try {

        console.log('Event: ' + event);
        console.log('Context: ' + context);

        context = JSON.parse(context);

        const urls = [];

        let serviceUrl = process.env.LASER_SERVICE_URL;
        if (!serviceUrl) throw Error(`LASER_SERVICE_URL is not defined`);

        console.log(`LASER_SERVICE_URL = ${serviceUrl}`);

        console.log(`Collecting all lambda IDs from environment...`);
        let i = 0;
        while (true) {
            i++;

            const lambdaId = process.env[`LAMBDA_${i}`];
            if (!lambdaId) break;

            const url = `${serviceUrl}/lambdas/${lambdaId}/invokeSync`;
            urls.push(url);

            console.log(`Found LAMBDA_${i}: ${lambdaId} --> ${url}`);
        }

        const summary = [];

        const options = {
            method: 'POST',
            resolveWithFullResponse: true,
            headers: context.headers || {},
            timeout: 10000,
            body: ''
        }

        let step = 0;

        const t0 = Date.now();

        console.log(`Will process ${urls.length} urls...`);
        for (let url of urls) {

            const start = Date.now();

            // Set and increment step
            step++;
            options.headers = Object.assign(options.headers, { 'step': String(step) }); // Must be string

            console.log(`Invoking ${url}...`)

            try {

                const resp = await request({ uri: url, ...options });

                const elapsed = Date.now() - start;

                console.log('resp.body: ' + resp.body);
                console.log('typeof resp.body: ' + (typeof resp.body));
                console.log(`${url} returned a ${resp.statusCode} and took ${elapsed} ms...`)

                summary.push({
                    step: step,
                    timestamp: start,
                    elapsed: elapsed,
                    downstream_url: url,
                    downstream_statusCode: resp.statusCode,
                    downstream_headers: resp.headers,
                    downstream_response: JSON.parse(resp.body)
                });

                // Collect headers
                options.headers = Object.assign(options.headers, JSON.parse(resp.body).headers);
                options.body = resp.body; // Use response from this call for the next downstream call
            } catch (err) {

                console.log(`Enountered an error: ${err.message}`);

                const elapsed = Date.now() - start;

                summary.push({
                    step: step,
                    error: err.message,
                    timestamp: start,
                    elapsed: elapsed,
                    downstream_url: url,
                });
            }
        }

        const elapsed = Date.now() - t0;

        console.log(`Wrapping up, got ${summary.length} results after ${elapsed} ms`);

        const body = {
            summary: summary,
            elapsed: elapsed
        };

        const response = {
            statusCode: 200,
            headers: options.headers,
            body: JSON.stringify(body, null, 2)
        };

        callback(null, response);
    } catch (err) {

        console.error(`Encountered error: ${err.message}`);

        const response = {
            statusCode: 500,
            headers: {},
            body: err.stack
        }

        callback(null, JSON.stringify(response));
    }
};
