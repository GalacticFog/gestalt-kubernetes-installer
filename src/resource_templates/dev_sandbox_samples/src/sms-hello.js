function run(e, c) {

    var context = JSON.parse(c);


    if (context.method == 'GET')
        return getHtml();

    if (context.method == 'POST') {
        var event = JSON.parse(e);
        return sendSms(context, event);
    }

    return "Method not found";
}


function sendSms(context, event) {

    var phone = event.phone ? event.phone : java.lang.System.getenv("phone");

    if (!phone)
        return "Error: phone is not defined";

    var msg = event.msg;
    if (!msg)
        return "Error: message is empty";

    var eventData =
        {
            to: phone,
            from: "REPLACE",
            user: "REPLACE",
            pwd: "REPLACE",
            body: msg
        };

    //add auth	
    var userpass = eventData.user + ":" + eventData.pwd;
    var basicAuth = "Basic " + java.util.Base64.getEncoder().encodeToString(userpass.getBytes());

    var u = "https://api.twilio.com/2010-04-01/Accounts/" + eventData.user + "/Messages/?To=%2B" + eventData.to + "&From=%2B" + eventData.from;

    var AsyncHttpClient = Java.type('org.asynchttpclient.DefaultAsyncHttpClient');
    var CompletableFuture = Java.type('java.util.concurrent.CompletableFuture');
    var client = new AsyncHttpClient();
    var pc = client.preparePost(u)
        .addHeader("Authorization", basicAuth)
        .addFormParam("To", eventData.to)
        .addFormParam("From", eventData.from)
        .addFormParam("Body", eventData.body);

    var response = pc.execute().get();
    var code = response.getStatusCode();
    if (code == 200 || code == 201 || code == 202)
        return "Sent";
    else {
        console.log(response);
        return "Error: " + code;
    }

}

function getHtml() {

    var MultiString = function (f) {
        return f.toString().split('\n').slice(1, -1).join('\n');
    };

    var ux = MultiString(function () {/**<html>
<head>
    <title>Send message</title>
    <script src="https://code.jquery.com/jquery-3.3.1.min.js"></script>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" />
</head>
<body class="bg-light">
    <div class="container">
        <div class="row" style="margin:100px;">
            <h2>Send message</h2>
            <textarea id="message" placeholder="Message" autofocus="autofocus" onblur="messageBlur()" onfocus="messageFocused()" class="form-control" style="margin-bottom:16px; min-width:150px;"></textarea>
            <button onclick="sendClick()" class="btn btn-primary" style="width:150px;">Send</button>

            <div id="status" style="margin-left:32px;"></div>
        </div>
    </div>

    <script>
        
        function messageFocused() {
            $('#status').text('');
        }

        function sendClick() {
            var msg = $('#message').val();

            if (!msg) {
                $('#status').text('Write some text');
                return;
            }

            $('#status').text('Sending...');
            var url = '';
            $.post(url, JSON.stringify({ msg: msg }), function (data, error) {
                $('#status').text(data);
            }).fail(
                function (error) {                    
                    $('#status').text('Error code: ' + error.status);
                });
        }

    </script>
</body>
</html>
 **/});

    return ux;

}
