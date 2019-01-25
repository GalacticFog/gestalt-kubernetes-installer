const ui = `
   <!DOCTYPE html>
   <html>
   <head>
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.9/umd/popper.min.js" integrity="sha384-ApNbgh9B+Y1QKtv3Rn7W3mgPxhU9K/ScQsAP7hUibX39j7fakFPskvXusvfa0b4Q" crossorigin="anonymous"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js" integrity="sha384-JZR6Spejh4U02d8jOt6vLEHfe/JQGiRRSQQxSfFWpi1MquVdAyjUar5+76PVCmYl" crossorigin="anonymous"></script>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
    
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
    <div class="container fluid">
    
    <div class="row justify-content-md-center">
      <div class="col-6">
        <h3>Calculate Factorial</h3>
      </div>
    </div>
  
    <div class="row justify-content-md-center">
      <div class="col-sm-6">
        <div class="form-group"><input id="arg" name="arg" class="form-control" min="0" type="number" placeholder="Enter a number" aria-describedby="factorial" /></div>
        <br /> 
        
        <button id="computeFactorial" class="btn btn-primary">Compute Factorial</button>
        
        <hr />
        
        <div id="result"></div>

      </div>
    </div>
  </div>

 </body>
 </html>
 `;
 
function factorial(arg) {
  // base case
  if (arg === 1) return 1;
  
  if (!arg || arg < 1) {
    return 'undefined';
  }
  
  return arg * factorial(arg-1);
}

function MultiString(f) {
  return f
  .toString()
  .split('\n')
  .slice(1, -1)
  .join('\n');
}

exports.handler = (data, context) => {
  const ctx = JSON.parse(context);
  
  if (ctx.method === "POST") {
    const arg = JSON.parse(data).arg;
      
    return factorial(arg).toString();
  } else {
    return ui;
  }
};