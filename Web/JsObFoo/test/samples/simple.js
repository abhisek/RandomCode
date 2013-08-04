var i = 0;
var y = "ABCD";

function func1() {
  var f1 = 100;
  var f2 = f1 + 200;

  return f2;
}

function func2() {
  var f1 = 200;
  var f2 = f1 + 500;

  return f2;
}

for(i = 22; i < 44; i += 4) {
  alert("Hello World");
}

i += 2;

alert(i);
alert(func1());
alert(func2());
