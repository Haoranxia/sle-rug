module Compile

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
  //loc saveLocJS = |project://QL/src| + (f.name.name + ".js");
  //writeFile(saveLocJS, form2js(f));
  loc saveLocHTML = |project://QL/src| + (f.name.name + ".html");
  writeFile(saveLocHTML, toString(form2html(f)));
}

HTML5Node form2html(AForm f){
	HTML5Node html = 
  		html(head(
  				script(src(<f.name.name>))
  			),
  			 body(
  				h1(id("title"), <f.name.name>),
  				[question2html(q) | AQuestion q <- f.questions]
  			 )
  		);
  
  return html();
}

HTML5Node question2html(AQuestion q){
	HTML5Node html;
	switch(q){
		case question(str queryText, AId, id, AType varType): {
			html = 
				p(<queryText>,
				  getCorrectInputType(id, varType)
				);
			return html;
		}
		
		
		case question(str queryText, AId id, AType varType, AExpr expr): {
			html = p(<queryText>, p("placeholder for expressions"));
			return html;
		}
		
		case question(AExpr guard, list[AQuestion] ifQuestions): {
			html = 
				div(id("if" + "placeholder"), 
					style("display:none",
						[question2html(ifq) | AQuestion ifq <- ifQuestions]
					)		
				);
			return html;
		}
		
		case question(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
			html = 
				div(id("ifelse" + "placeholder"),
					question2html(guard, ifQuestions),				
					div(id("else" + "placeholder"),
						style("display:none"),
						[question2html(elseq) | AQuestion elseq <- elseQuestions]
					)
				);
			return html;
		}
		
		default: {
			println(q);
			assert(false);
		}

	}
	return html;
}

HTML5Node getCorrectInputType(AId id, AType t){
	HTML5Node inputfield;
	switch(t){
		case stringType(): {
			inputfield = input(\type("text"), id(<id.name>));
			return inputfield;
		}
		
		case integerType(): {
			inputfield = input(\type("number"), id(<id.name>));
			return inputfield;
		}
		
		case booleanType(): {
			inputfield = input(\type("checkbox"), id(<id.name>));
			return inputfield;
		}
		
		default: {
			println(t);
			return inputfield;
		}
	}
	
	return inputfield;
}

str form2js(AForm f) {
  str program = "";
  RefGraph variables = resolve(f);
  program += addEventListeners(f, variables);
  //println(variables);
  for (AQuestion q <- f.questions) {
    print("Analysing the following question: ");
    println(q);
    println();
    program += question2js(q, variables);
  }
  return program;
}

str addEventListeners(AForm f, RefGraph variables) {
  str code = "window.onload = function() {";
  
  for (AQuestion q <- f.questions) {
    code += addQuestionEventListener(q, variables);
  }
  
  code += "
          '}
          '
          '"; // Closing bracket and a whiteline
  return code;
}

str addQuestionEventListener(AQuestion q, RefGraph variables) {
  str code = "";
  
  switch(q) {
      case question(str queryText, AId id, AType varType, AExpr expr): {
        println("Started a computed question eventlistener analysis.");
        list[str] names = [];
        visit(expr) {
          case ref(AId id): names += id.name;
        }
        for (str name <- names) {
          code += "
                  '    document.getElementById(\"" + name + "\").addEventListener(\"change\", update" + id.name + ");";
        }
      }
      case question(AExpr guard, list[AQuestion] ifQuestions): {
        visit(guard) {
          case ref(AId id): 
            code += "
                    '    document.getElementById(\"" + id.name + "\").addEventListener(\"change\", check" + id.name + ");";
        }
        for (AQuestion ifq <- ifQuestions) {
          code += addQuestionEventListener(ifq, variables);
        }
      }
      case question(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
        visit(guard) {
          case ref(AId id): 
            code += "
                    '    document.getElementById(\"" + id.name + "\").addEventListener(\"change\", check" + id.name + ");";
        }
        for (AQuestion ifq <- ifQuestions) {
          code += addQuestionEventListener(ifq, variables);
        }
        for (AQuestion elseq <- elseQuestions) {
          code += addQuestionEventListener(elseq, variables);
        }
      }
    }
    
    return code;
}

str question2js(AQuestion q, RefGraph variables) {
  str questionCode = "";
  
  switch(q) {
    case question(str queryText, AId id, AType varType, AExpr expr): 
      questionCode += processComputedQuestion(id, expr, variables);
    case question(AExpr guard, list[AQuestion] ifQuestions): 
      questionCode += processIfStatement(guard, ifQuestions, variables);
    case question(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions):
      questionCode += processIfElseStatement(guard, ifQuestions, elseQuestions, variables);
  }
  
  return questionCode;
}

str processComputedQuestion(AId id, AExpr expr, RefGraph variables) {
  str code = "";
  println("Processing the expression: ");
  println(expr);
  println();
  list[str] names = [];
  visit(expr) {
    case ref(AId id): {
      println("Found a ref ID!");
      names += id.name;
    }
  }
  println(names);
  
  // Compose an update function for this variable
  code += "function update" + id.name + "() {
          '    var " + id.name + " = document.getElementById(\"" + id.name + "\");
          '    <for (str name <- names) {>
          '    var <name> = document.getElementById(\"<name>\");
          '    <}>
          '    " + id.name + ".value = " + expr2js(expr) + ";
          '    " + id.name + ".innerHTML = " + id.name + ".value;
          '}
          '
          '";
  
  return code;
}

str expr2js(AExpr expr) {
  str code = "";
  
  switch (expr) {
    case ref(AId id): code += (id.name + ".value");
    case integer(int intValue): code += toString(intValue);
    case boolean(bool boolValue): code += toString(boolValue);
    case string(str strValue): code += strValue;
    case bracketExpr(AExpr singleArg): code += "(" + expr2js(singleArg) + ")";
    case not(AExpr singleArg): code += "!" + expr2js(singleArg);
    case unaryPlus(AExpr singleArg): code += "+" + expr2js(singleArg);
    case unaryMinus(AExpr singleArg): code += "-" + expr2js(singleArg);
    case mult(AExpr leftArg, AExpr rightArg): code += expr2js(leftArg) + "*" + expr2js(rightArg);
    case div(AExpr leftArg, AExpr rightArg): code += expr2js(leftArg) + "/" + expr2js(rightArg);
    case plus(AExpr leftArg, AExpr rightArg): code += expr2js(leftArg) + " + " + expr2js(rightArg);
    case minus(AExpr leftArg, AExpr rightArg): code += expr2js(leftArg) + " - " + expr2js(rightArg);
    case less(AExpr leftArg, AExpr rightArg): code += expr2js(leftArg) + " \< " + expr2js(rightArg);
    case leq(AExpr leftArg, AExpr rightArg): code += expr2js(leftArg) + " \<= " + expr2js(rightArg);
    case greater(AExpr leftArg, AExpr rightArg): code += expr2js(leftArg) + " \> " + expr2js(rightArg);
    case geq(AExpr leftArg, AExpr rightArg): code += expr2js(leftArg) + " \>= " + expr2js(rightArg);
    case eq(AExpr leftArg, AExpr rightArg): code += expr2js(leftArg) + " == " + expr2js(rightArg);
    case neq(AExpr leftArg, AExpr rightArg): code += expr2js(leftArg) + " != " + expr2js(rightArg);
    case and(AExpr leftArg, AExpr rightArg): code += expr2js(leftArg) + " && " + expr2js(rightArg);
    case or(AExpr leftArg, AExpr rightArg): code += expr2js(leftArg) + " || " + expr2js(rightArg);
  }
  
  return code;
}

str processIfStatement(AExpr guard, list[AQuestion] ifQuestions, RefGraph variables) {
  str code = "";
  
  visit(guard) {
    case ref(AId id): 
      code += "function check" + id.name + "() {
              '    var " + id.name + " = document.getElementById(\"" + id.name + "\");
              '    var if" + id.name + " = document.getElementById(\"if" + id.name + "\");
              '
              '    if (" + id.name + ".checked == true) {
              '         if" + id.name + ".style.display = \"block\";
              '    }
              '    else {
              '         if" + id.name + ".style.display = \"none\"; 
              '    }
              '}
              '
              '"
              ;
  }
  
  for (AQuestion q <- ifQuestions) {
    code += question2js(q, variables);
  }
  
  return code;
}

str processIfElseStatement(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions, RefGraph variables) {
  str code = "";
  
  visit(guard) {
    case ref(AId id): 
      code += "function check" + id.name + "() {
              '    var " + id.name + " = document.getElementById(\"" + id.name + "\");
              '    var if" + id.name + " = document.getElementById(\"if" + id.name + "\");
              '
              '    if (" + id.name + ".checked == true) {
              '         if" + id.name + ".style.display = \"block\";
              '         else" + id.name + ".style.display = \"none\";
              '    }
              '    else {
              '         if" + id.name + ".style.display = \"none\"; 
              '         else" + id.name + ".style.display = \"block\";
              '    }
              '}
              '
              '"
              ;
  }
  
  for (AQuestion q <- ifQuestions) {
    code += question2js(q, variables);
  }
  
  for (AQuestion q <- elseQuestions) {
    code += question2js(q, variables);
  }
  
  return code;
}