module Check

import AST;
import Resolve;
import Message; // see standard library
import IO;
import Set;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  // Append the sets of possible types over the two constructs (so 2*3 = 6 separate sets) into a single rel 
  return {<x.src, x.name, label, tint()> | /question(str label, AId x, integerType()) := f} +
         {<x.src, x.name, label, tint()> | /question(str label, AId x, integerType(), _) := f} +
         {<x.src, x.name, label, tbool()> | /question(str label, AId x, booleanType()) := f} + 
         {<x.src, x.name, label, tbool()> | /question(str label, AId x, booleanType(), _) := f} +
         {<x.src, x.name, label, tstr()> | /question(str label, AId x, stringType()) := f} + 
         {<x.src, x.name, label, tstr()> | /question(str label, AId x, stringType(), _) := f}; 
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  println("starting the check function.");
  set[Message] msgs = {};
  switch(f) {
    case form(_, list[AQuestion] qs):
        msgs += union({check(q, tenv, useDef) | q <- qs});
    default: throw "Not a form.";    
  }
  //println("Final msgs set:");
  //println(msgs);
  return msgs; 
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  println("Checking a question");
  println(q);
  set[Message] msgs = {};
  
  switch (q) {
    case question(str queryText, AId id, AType varType): {
      println("Testing first case");
      msgs += createIncompTypeErrors(id, tenv, useDef);
      msgs += createDupLabelWarnings(queryText, id, tenv, useDef);
      msgs += createMultipleLabelsWarnings(id, tenv, useDef);
    }
    case question(str queryText, AId id, AType varType, AExpr expr): {
      println("Testing second case");
      msgs += createIncompTypeErrors(id, tenv, useDef);
      msgs += createDupLabelWarnings(queryText, id, tenv, useDef);
      msgs += createMultipleLabelsWarnings(id, tenv, useDef);
      println("Expression:");
      println(expr);
      msgs += check(expr, tenv, useDef);
      if (typeOf(expr, tenv, useDef) != varType) { // Test whether the assigned expression is of the correct type
        msgs += { error("Type of expression does not match type of variable.", expr.src) };
      }
    }
    case question(AExpr guard, list[AQuestion] ifqs): {
      println("Testing third case.");
      msgs += check(guard, tenv, useDef);
      msgs += union({check(ifq, tenv, useDef) | (AQuestion) ifq <- ifqs});
    }
    case question (AExpr guard, list[AQuestion] ifqs, list[AQuestion] elseqs): {
      println("Testing fourth case.");
      msgs += check(guard, tenv, useDef);
      msgs += union({check(ifq, tenv, useDef) | ifq <- ifqs});
      msgs += union({check(elseq, tenv, useDef) | elseq <- elseqs});
    }
  }
  
  return msgs; 
}

set[Message] createIncompTypeErrors(AId id, TEnv tenv, UseDef useDef) {
  TEnv q = { elem | elem <- tenv, elem.def == id.src };
  set[loc] mismatchLocs = { mismatch.def | mismatch <- tenv, mismatch.name == getOneFrom(q).name, mismatch.\type != getOneFrom(q).\type};
  return { error("Variable type declaration conflicts with previous declaration.", mismatch) | mismatch <- mismatchLocs };
}

set[Message] createDupLabelWarnings(str queryText, AId id, TEnv tenv, UseDef useDef) {
  TEnv q = {elem | elem <- tenv, elem.label == queryText};
  set[loc]DupLabelLocs = {dup.def | dup <- tenv, dup.label == getOneFrom(q).label, dup.name != getOneFrom(q).name};
  return { warning("Same label associated with multiple questions.", duplicate) | duplicate <- DupLabelLocs };
}

set[Message] createMultipleLabelsWarnings(AId id, TEnv tenv, UseDef useDef) {
  TEnv q = { elem | elem <- tenv, elem.name == id.name };
  println(q);
  set[loc] multLabelLocs = { mismatch.def | mismatch <- tenv, mismatch.name == getOneFrom(q).name, mismatch.label != getOneFrom(q).label};
  
  return { warning("Multiple labels associated with the same question.", duplicate) | duplicate <- multLabelLocs };
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
println("Checking an expression");
println(e);
  set[Message] msgs = {};
  
  switch (e) {
    case ref(id(str x, src = loc u)): {
      println(useDef[u]);
      msgs += { error("Undeclared question", u) | useDef[u] == {} };
    }
      
    case bracketExpr(AExpr singleArg, src = loc u): msgs += check(singleArg, tenv, useDef);
    
    case mult(AExpr leftArg, AExpr rightArg, src = loc u): {
      typeLeft = typeOf(leftArg, tenv, useDef);
      println(typeLeft);
      println(typeOf(rightArg, tenv, useDef));
      if (typeLeft != typeOf(rightArg, tenv, useDef)) {
        msgs += { error("Argument types of expression do not match.", leftArg.src) };
      }
      else if (typeLeft != tint()) {
        msgs += { error("Arguments are not of type int.", leftArg.src) };
      }
    }
    
    case and(AExpr leftArg, AExpr rightArg, src = loc u): {
      typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeLeft != typeOf(rightArg, tenv, useDef)) {
        msgs += { error("Argument types of expression do not match.", leftArg.src) };
      }
      else if (typeLeft != tbool()) {
        msgs += { error("Arguments are not of type bool.", leftArg.src) };
      }
    }
    
    case or(AExpr leftArg, AExpr rightArg, src = loc u): {
      typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeLeft != typeOf(rightArg, tenv, useDef)) {
        msgs += { error("Argument types of expression do not match.", leftArg.src) };
      }
      else if (typeLeft != tbool()) {
        msgs += { error("Arguments are not of type bool.", leftArg.src) };
      }
    }
    
    case _(AExpr leftArg, AExpr rightArg, src = loc u): {
    Type typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeLeft != typeOf(rightArg, tenv, useDef)) {
        msgs += { error("Arguments of expression do not match.", leftArg.src) };
      }
      else if (typeLeft != tint()) {
        msgs += { error ("Arguments must be of type int.", leftArg.src) };
      }
    }
    
    // etc.
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
  // Base Cases
    case ref(str x, src = loc u): { 
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    }
    case integer(int intValue): return tint();
    case boolean(bool boolValue): return tbool();
    case string(str strValue): return tstr();
    
    // Unary Recursive Cases
    case bracketExpr(AExpr singleArg): return typeOf(singleArg, tenv, useDef);
    case not(AExpr singleArg): return typeOf(singleArg, tenv, useDef);
    case unaryPlus(AExpr singleArg): return typeOf(singleArg, tenv, useDef);
    case unaryMinus(AExpr singleArg): return typeOf(singleArg, tenv, useDef);
    
    // Binary Recursive Cases
    case mult(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeOf(rightArg, tenv, useDef) == typeLeft && typeLeft == tint()) {
        return typeLeft;
      } else { return tunknown(); }
    }
    case div(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg);
      if (typeOf(rightArg, tenv, useDef) == typeLeft && typeLeft == tint()) {
        return typeLeft;
      } else { return tunknown(); }
    }
    case plus(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg);
      if (typeOf(rightArg, tenv, useDef) == typeLeft && typeLeft == tint()) {
        return typeLeft;
      } else { return tunknown(); }
    }
    case minus(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeOf(rightArg, tenv, useDef) == typeLeft && typeLeft == tint()) {
        return typeLeft;
      } else { return tunknown(); }
    }
    case less(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg);
      if (typeOf(rightArg, tenv, useDef) == typeLeft && typeLeft == tint()) {
        return tbool();
      } else { return tunknown(); }
    }
    case leq(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg);
      if (typeOf(rightArg, tenv, useDef) == typeLeft && typeLeft == tint()) {
        return tbool();
      } else { return tunknown(); }
    }
    case greater(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg);
      if (typeOf(rightArg, tenv, useDef) == typeLeft && typeLeft == tint()) {
        return tbool();
      } else { return tunknown(); }
    }
    case geq(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg);
      if (typeOf(rightArg, tenv, useDef) == typeLeft && typeLeft == tint()) {
        return tbool();
      } else { return tunknown(); }
    }
    case eq(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg);
      if (typeOf(rightArg, tenv, useDef) == typeLeft) {
        return tbool();
      } else { return tunknown(); }
    }
    case neq(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg);
      if (typeOf(rightArg, tenv, useDef) == typeLeft) {
        return tbool();
      } else { return tunknown(); }
    }
    case and(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg);
      if (typeOf(rightArg, tenv, useDef) == typeLeft && typeLeft == tbool()) {
        return tbool();
      } else { return tunknown(); }
    }
    case or(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg);
      if (typeOf(rightArg, tenv, useDef) == typeLeft && typeLeft == tbool()) {
        return tbool();
      } else { return tunknown(); }
    }
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(str x, src = loc u), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

