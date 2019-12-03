module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return form("", [], src=f@\loc); 
}

AQuestion cst2ast(Question q) {
  switch (q) {
  	case (Question) `<Str q> <Id i> ":" <Type t>`:
  	 	return question(q, id("<i>", src=i@\loc), cst2ast(t), src=q@\loc);
  		
  	case (Question) `<Str q> <Id i> ":" <Type t> "=" <Expr e>`:
  		return question(q, id("<i>", src=i@\loc), cst2ast(t), cst2ast(e), src=q@\loc);
  		
  	case (Question) `"if" <Expr ifexpr> "{" <Question* qif> "}" "else" "{" <Question* qelse> "}"`:
  		return question(cst2ast(ifexpr), cst2ast(qif), cst2ast(qelse));
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr) `<Id x>`: return ref("<x>", src=x@\loc);
    case (Expr) `<Int x>`: return integer("<x>", src=x@\loc);
    case (Expr) `<Bool x>`: return boolean("<x>", src=x@\loc);
    case (Expr) `<Str x>`: return string("<x>", src=x@\loc);
    case (Expr) `"(" <Expr e> ")"`: return bracketExpr(cst2ast(e), src=e@\loc);
    case (Expr) `"!" <Expr e>`: return not(cst2ast(e), src=e@\loc);
    case (Expr) `"+" <Expr e>`: return unaryPlus(cst2ast(e), src=e@\loc);
    case (Expr) `"-" <Expr e>`: return unaryMinus(cst2ast(e), src=e@\loc);
    
    
    // etc.
  }
}

AType cst2ast(Type t) {
  switch(t){
  	case (Type) `"string"`:
  		return stringType();
  		
  	case (Type) `"integer"`:
  		return integerType();
  		
  	case (Type) `"boolean"`:
  		return booleanType();
  }
}
