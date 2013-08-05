# Javascript Obfuscation Tool


The idea for developing this tool came during [@prasannain](http://www.twitter.com/prasannain) session on Javascript obfuscation during [JSFoo Hacknight](https://hacknight.in/jsfoo/offense-and-defense-security-in-javascript) on Javascript security co-organized by [HasGeek](https://hasgeek.com/) and [Null](http://null.co.in/).

This is a Proof of Concept implementation of some of the techniques discussed as a part of Javascript obfuscation session at the Hacknight, particularly:

* Unicode encoded characters
* Variable Name Mangling
* Function Name Mangling
* Other Javascript weirdness

Most of the transformation is performed on Javascript AST (Abstract Syntax Tree). The [RKelly](https://github.com/tenderlove/rkelly) library is used for parsing Javascript from Ruby.

# Usage

## Command Line
```
bash-3.2$ ruby jsobfoo.rb 
Usage: jsobfoo.rb [options]
    -i, --input [FILE]               Javascript source file to obfuscate
    -o, --output [FILE]              File to write obfuscated Javascript source
    -z, --compress                   Compress generated Javascript source
    -v, --verbose                    Show verbose messages
    -C, --console                    Start IRB console
```

## Example
```
bash-3.2$ ruby jsobfoo.rb -i test/samples/simple.js
```

### Generates
```javascript
var \u0055QsId\u0063hE\u006b\u006f = 0;
var Eh1u\u0052P9ebi = String.fromCharCode(34,65,66,67,68,34);
function func1(){
  var p\u0031\u0056v\u0056\u0058ri\u004a\u0076 = 100;
  var S\u0065yb2r9\u0072tT = p\u0031\u0056v\u0056\u0058ri\u004a\u0076 + 200;
  return S\u0065yb2r9\u0072tT;
}
function func2(){
  var D3M3\u00713Q\u0053X5 = 200;
  var NjSy\u006cMs\u0075\u0057\u005a = D3M3\u00713Q\u0053X5 + 500;
  return NjSy\u006cMs\u0075\u0057\u005a;
}
for(\u0055QsId\u0063hE\u006b\u006f = 22; \u0055QsId\u0063hE\u006b\u006f < 44; \u0055QsId\u0063hE\u006b\u006f += 4) {
  alert(String.fromCharCode(34,72,101,108,108,111,32,87,111,114,108,100,34));
}
\u0055QsId\u0063hE\u006b\u006f += 2;
alert(\u0055QsId\u0063hE\u006b\u006f);
alert(func1());
alert(func2());
```

### From
```javascript
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
```

# Roadmap

* Implement/Use the esoteric [JSFuck](http://www.jsfuck.com) for string obfuscation :P
* Full script encoder (Encode with XOR or some other algorithm and eval at runtime with an obfuscated loader)
* Encoder with environment derived key (e.g key derived from user-agent?)
* Transparent browser detection (e.g --no-chrome: Do not run JS on Chrome)
* Contextual Transformation (e.g Fake Calls)
