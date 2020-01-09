module CompileJS

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library
import util::Math;

str addEventListeners(AForm f, RefGraph variables) {
  str code = "window.onload = function() {";
  
  code += "
          '    updateanswer();
          '";
  
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
      /*case question(str queryText, AId id, AType varType): {
        code += "
                '    document.getElementById(\"" + id.name + "\"). addEventListener(\"change\", update" + id.name + ");";
      }*/
      case question(str queryText, AId id, AType varType, AExpr expr): {
        println("Started a computed question eventlistener analysis.");

        list[str] names = [];
        visit(expr) {
          case ref(AId id): {
            println("Found a ref id for the updateanswer lines!");
            names += id.name;
          }
        }
        println("names: " + names);
        for (str name <- names) {
          code += "
                  '    document.getElementById(\"" + name + "\").addEventListener(\"change\", update" + id.name + ");";
        }
      }
      case question(AExpr guard, list[AQuestion] ifQuestions): {
        visit(guard) {
          case ref(AId id): {
            code += "
                    '    document.getElementById(\"" + id.name + "\").addEventListener(\"change\", check" + id.name + ");";
            /*code += "
                    '    document.getElementById(\"" + id.name + "\").addEventListener(\"change\", updateanswer);";
            */
          }
        }
        for (AQuestion ifq <- ifQuestions) {
          code += addQuestionEventListener(ifq, variables);
        }
      }
      case question(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
        visit(guard) {
          case ref(AId id): {
            code += "
                    '    document.getElementById(\"" + id.name + "\").addEventListener(\"change\", check" + id.name + ");";
            code += "
                    '    document.getElementById(\"" + id.name + "\").addEventListener(\"change\", updateanswer);";
          }
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

str computeAnswer(AForm f, RefGraph vars) {
  str code = "";
  
  // Create function signature
  code += "function updateanswer() {
          '";
          
  code += "    var displayValue = -1;
          '
          '";
    
  // Add all variables in the function definition
  for (<loc use, str name> <- vars.uses) {
    code += "    var " + name + " = document.getElementById(\"" + name + "\");
            '";
  }
  
  for (/question(str queryText, AId id, AType varType, AExpr expr) := f) {
    code += "    update" + id.name + "();
            '";
  }
    
  // Call the evaluation of the if statements
  //code += "    displayValue = evaluateIfStatements();
  //        '";
          
  // Set the displayValue into the answer line
  //code += "    document.getElementById(\"" + 
  
  // Closing bracket
  code += "}
          '";
  
  return code;
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
          '    " + id.name + ".innerHTML += \":\" + " + id.name + ".value;
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