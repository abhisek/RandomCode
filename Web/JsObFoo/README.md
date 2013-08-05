# Javascript Obfuscation Tool


The idea for developing this tool came during [@prasannain](http://www.twitter.com/prasannain) session on Javascript obfuscation during [JSFoo Hacknight](https://hacknight.in/jsfoo/offense-and-defense-security-in-javascript) on Javascript security co-ornigzed by [HasGeek](https://hasgeek.com/) and [Null](http://null.co.in/).

This is a Proof of Concept implementation of some of the techniques discussed as a part of Javascript obfuscation session at the Hacknight, particularly:

* Unicode encoded characters
* Variable Name Mangling
* Function Name Mangling
* Other Javascript weirdness

Most of the transformation is performed on Javascript AST (Abstract Syntax Tree). The [RKelly](https://github.com/tenderlove/rkelly) library is used for parsing Javascript from Ruby.

# Usage


