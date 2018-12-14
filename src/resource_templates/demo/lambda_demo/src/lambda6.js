const request = require('request-promise-native');

module.exports.handler = async (event, context, callback) => {
    try {
        event = (event && event.length > 0) ? JSON.parse(event) : {};
        context = JSON.parse(context);    

        let result = {
            context: context,
            event: event,
            env: Object.keys(process.env).filter(k => !k.startsWith('_')).sort().map(i => [i, process.env[i]])
        }

        const response = {
            statusCode: 201,
            headers: {},
            body: JSON.stringify(result, null, 2)
        }

        callback(null, JSON.stringify(response));
    } catch (err) {
        const response = {
            statusCode: 500,
            headers: {},
            body: err.stack
        }

        callback(null, JSON.stringify(response));
    }
};
