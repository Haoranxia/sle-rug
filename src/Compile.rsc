module Compile

import CompileHTML;
import CompileJS;
import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library
import util::Math;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */


void compile(AForm f) {
  RefGraph ref = resolve(f);
  loc saveLocJS = |project://QL/src| + (f.name.name + ".js");
  writeFile(saveLocJS, form2js(f, ref));
  loc saveLocHTML = |project://QL/src| + (f.name.name + ".html");
  writeFile(saveLocHTML, toString(form2html(f, ref)));
}

HTML5Node form2html(AForm f, RefGraph ref){
	HTML5Node html = 
  		html(head(
  				script(src(f.name.name + ".js"))
  			),
  			 body(
  				h1(id("title"), f.name.name),
  				div([question2html(q, ref) | AQuestion q <- f.questions])
  			 )
  		);
  
  return html;
}

str form2js(AForm f, RefGraph variables) {
  str program = "";
  program += addEventListeners(f, variables);
  for (AQuestion q <- f.questions) {
    program += question2js(q, variables);
  }
  program += "
               '" + computeAnswer(f, variables);
  return program;
}