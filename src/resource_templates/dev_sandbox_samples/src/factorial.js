function run(data,ctx) {
    ctx = JSON.parse(ctx);
    if (ctx.method === "POST") {
        arg = JSON.parse(data).arg;
        return factorial(arg).toString();
    } else {
        return ux;
    }
}

function factorial(arg) {
    if ( arg === 1 ) return 1;
    if ( arg < 1 ) return "undefined";
    return arg * factorial(arg-1);
}

var MultiString = function(f) {
    return f.toString().split('\n').slice(1, -1).join('\n');
}

var ux = MultiString(function() {/**
 <!DOCTYPE html>
 <html>
 <head>
 <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
 <script>
 $(document).ready(function(){
    $("#computeFactorial").click(function(){
        var arg = $("#arg").val();
        $.ajax("#",{
            data: JSON.stringify({
                arg: parseInt(arg)
            }),
            method: "POST",
            processData: false,
            contentType: "application/json",
            dataType: "html"
         }).done(function(data){
            $("#result").html("Factorial of " + arg + " is " + data);
        });
    });
});
 </script>
 </head>
 <body>

 <h1>Simple Lambda Example</h1>

 <input type="text" name="arg" id="arg" />
 <br/>
 <button id="computeFactorial">Compute Factorial</button>

 <br/>

 <div id="result"></div>

 </body>
 </html>
 **/});
