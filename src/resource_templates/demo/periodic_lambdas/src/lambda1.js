const request = require('request-promise-native');

module.exports.handler = async (event, context, callback) => {

    const data = {
        event: JSON.parse(event),
        context: JSON.parse(context)
    }


    // const response = {
    //     statusCode: 201,
    //     headers: {},
    //     body: JSON.stringify(data)
    // }

    callback(null, data);
};