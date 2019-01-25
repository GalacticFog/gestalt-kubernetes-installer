function fizzBuzz(n) {
  const results = [];
  
  for (let i = 1; i <= n; i++) {
    if (i % 3 === 0 && i % 5 === 0) {
      results.push('fizzBuzz');
    } else if (i % 5 === 0) {
      results.push('buzz');
    } else if (i % 3 === 0) {
      results.push('fizz');
    } else {
      results.push(i);
    }
  }
  
  return results;
}

exports.handler = (event, context) => {
  return fizzBuzz(process.env.NUM);
};
