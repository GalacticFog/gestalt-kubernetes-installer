const request = require('request-promise-native');

module.exports.handler = async (event, context, callback) => {

    console.log(`context: ${context}`);
    console.log(`event: ${event}`);

    event = (event && event.length > 0) ? JSON.parse(event) : {};
    context = (context && context.length > 0) ? JSON.parse(context) : {};

    if (context.method == 'GET') {
        const response = {
            statusCode: 200,
            headers: {},
            body: getHtml()
        };

        return callback(null, response);
    }

    if (context.method == 'POST') {
        return callback(null, await doPost(context, event));
    }

    const response = {
        statusCode: 500,
        headers: {},
        body: Error().stack
    }

    callback(null, response);
};


async function doPost(context, event) {

    // return {
    //     statusCode: 200,
    //     headers: {},
    //     body: JSON.stringify({
    //         event: event
    //     })
    // };

    const url = process.env.DOWNSTREAM_URL;
    const options = {
        method: process.env.DOWNSTREAM_HTTP_METHOD,
        resolveWithFullResponse: true,
        headers: { 'Accept': 'text/plain' }, //context.headers || {},
        timeout: 10000,
        // body: JSON.stringify({
        //     context: context,
        //     event: event
        // })
    }

    if (options.method != 'GET') {
        options.body = event;
    }

    const start = Date.now();

    console.log(`Invoking ${url}...`)

    const summary = [];

    try {

        const resp = await request({ uri: url, ...options });

        const elapsed = Date.now() - start;

        console.log('resp.body: ' + resp.body);
        console.log('typeof resp.body: ' + (typeof resp.body));
        console.log(`${url} returned a ${resp.statusCode} and took ${elapsed} ms...`)

        summary.push({
            timestamp: start,
            elapsed: elapsed,
            downstream_url: url,
            downstream_statusCode: resp.statusCode,
            downstream_headers: resp.headers,
            downstream_response: resp.body
        });

        return {
            statusCode: 200,
            headers: {},
            body: JSON.stringify(summary, null, 2)
        };

    } catch (err) {
        return {
            statusCode: 500,
            headers: {},
            body: JSON.stringify({
                error: err.stack
            })
        };
    }
}


function getHtml() {
    return `
    <html>
    <head>
        <title>${process.env.TITLE || 'Request to Provision new VM'}</title>
        <script src="https://code.jquery.com/jquery-3.3.1.min.js"></script>
        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" />
    </head>
    <body class="bg-light">
        <div class="container">
                <div class="row" style="margin:100px;">
                    <form id="form1">
                        <h2>${process.env.FORM_TITLE || 'Default title (replace using FORM_TITLE variable)'}</h2>
                        <input id="name" name="name" type="text" placeholder="Name" class="form-control"  style="margin-bottom:16px; min-width:150px;"></input>
                        <input id="num_instances" name="num_instances" type="number" placeholder="Number of Instances" class="form-control"  style="margin-bottom:16px; min-width:150px;"></input>
                        <input id="cpus" name="cpus" type="number" placeholder="CPUs" class="form-control"  style="margin-bottom:16px; min-width:150px;"></input>
                        <input id="memory" name="memory" type="number" placeholder="Memory (GiB)" class="form-control"  style="margin-bottom:16px; min-width:150px;"></input>

                        <div class="radio">
                            <label><input type="radio" name="os_type" value="RHEL" checked>RHEL 7.x</label>
                        </div>
                        <div class="radio">
                            <label><input type="radio" name="os_type" value="WINDOWS">Windows 10 Professional</label>
                        </div>

                        <label class="checkbox-inline"><input name="ssd_storage" type="checkbox" value="">SSD Storage</label>

                        <textarea id="user_data" name="user_data" placeholder="User Data" autofocus="autofocus" onblur="messageBlur()" onfocus="messageFocused()" class="form-control" style="margin-bottom:16px; min-width:150px;"></textarea>
                        </form>

                    <button onclick="sendClick()" class="btn btn-primary" style="width:200px;">Initiate VM Provisioning</button>

                    <div id="status" style="margin-left:32px;"></div>
                </div>
        </div>
    
        <script>
            
            function messageFocused() {
                $('#status').text('');
            }
    
            function sendClick() {
                var msg = {};
                $.each($('#form1').serializeArray(), function() {
                  msg[this.name] = this.value;
                });
            
    
                $('#status').text('Sending...');
                var url = './lambda1';
                $.post(url, JSON.stringify(msg), function (data, error) {
                    $('#status').text(data);
                }).fail(
                    function (error) {                    
                        $('#status').text('Error code: ' + error.status);
                    });
            }


        </script>
    </body>
    </html>    
    `
}

