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
  set[Message] msgs = {};
  switch(f) {
    case form(_, list[AQuestion] qs):
        msgs += union({check(q, tenv, useDef) | q <- qs});
    default: throw "Not a form.";    
  }
  return msgs; 
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (q) {
    case question(str queryText, AId id, AType varType): {
      msgs += createIncompTypeErrors(id, tenv, useDef);
      msgs += createDupLabelWarnings(queryText, id, tenv, useDef);
      msgs += createMultipleLabelsWarnings(id, tenv, useDef);
    }
    case question(str queryText, AId id, AType varType, AExpr expr): {
      msgs += createIncompTypeErrors(id, tenv, useDef);
      msgs += createDupLabelWarnings(queryText, id, tenv, useDef);
      msgs += createMultipleLabelsWarnings(id, tenv, useDef);
      msgs += check(expr, tenv, useDef);
      if (typeOf(expr, tenv, useDef) != mapDefTypes(varType)) { // Test whether the assigned expression is of the correct type
        msgs += { error("Type of expression does not match type of variable.", expr.src) };
      }
    }
    case question(AExpr guard, list[AQuestion] ifqs, src = loc u): {
      msgs += check(guard, tenv, useDef);
      if (typeOf(guard, tenv, useDef) != tbool()) {
        msgs += { error("Guard of if statement is not boolean.", u) };
      }
      msgs += union({check(ifq, tenv, useDef) | (AQuestion) ifq <- ifqs});
    }
    case question (AExpr guard, list[AQuestion] ifqs, list[AQuestion] elseqs): {
      msgs += check(guard, tenv, useDef);
      if (typeOf(guard, tenv, useDef) != tbool()) {
        msgs += { error("Guard of if statement is not boolean.", u) };
      }
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
  set[loc] multLabelLocs = { mismatch.def | mismatch <- tenv, mismatch.name == getOneFrom(q).name, mismatch.label != getOneFrom(q).label}; 
  return { warning("Multiple labels associated with the same question.", duplicate) | duplicate <- multLabelLocs };
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(id(str x, src = loc u)):
      msgs += { error("Undeclared question", u) | useDef[u] == {} };
      
    case bracketExpr(AExpr singleArg, src = loc u): msgs += check(singleArg, tenv, useDef);
    
    case mult(AExpr leftArg, AExpr rightArg, src = loc u): {
      typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeLeft != typeOf(rightArg, tenv, useDef)) {
        msgs += { error("Argument types of expression do not match.", leftArg.src) };
      }
      else if (typeLeft != tint()) {
        msgs += { error("Arguments are not of type int.", leftArg.src) };
      }
    }
    
    case div(AExpr leftArg, AExpr rightArg, src = loc u): {
      typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeLeft != typeOf(rightArg, tenv, useDef)) {
        msgs += { error("Argument types of expression do not match.", leftArg.src) };
      }
      else if (typeLeft != tint()) {
        msgs += { error("Arguments are not of type int.", leftArg.src) };
      }
    }
    
    case plus(AExpr leftArg, AExpr rightArg, src = loc u): {
      typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeLeft != typeOf(rightArg, tenv, useDef)) {
        msgs += { error("Argument types of expression do not match.", leftArg.src) };
      }
      else if (typeLeft != tint()) {
        msgs += { error("Arguments are not of type int.", leftArg.src) };
      }
    }
    
    case minus(AExpr leftArg, AExpr rightArg, src = loc u): {
      typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeLeft != typeOf(rightArg, tenv, useDef)) {
        msgs += { error("Argument types of expression do not match.", leftArg.src) };
      }
      else if (typeLeft != tint()) {
        msgs += { error("Arguments are not of type int.", leftArg.src) };
      }
    }
    
    case less(AExpr leftArg, AExpr rightArg, src = loc u): {
      typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeLeft != typeOf(rightArg, tenv, useDef)) {
        msgs += { error("Argument types of expression do not match.", leftArg.src) };
      }
      else if (typeLeft != tint()) {
        msgs += { error("Arguments are not of type int.", leftArg.src) };
      }
    }
    
    case leq(AExpr leftArg, AExpr rightArg, src = loc u): {
      typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeLeft != typeOf(rightArg, tenv, useDef)) {
        msgs += { error("Argument types of expression do not match.", leftArg.src) };
      }
      else if (typeLeft != tint()) {
        msgs += { error("Arguments are not of type int.", leftArg.src) };
      }
    }
    
    case greater(AExpr leftArg, AExpr rightArg, src = loc u): {
      typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeLeft != typeOf(rightArg, tenv, useDef)) {
        msgs += { error("Argument types of expression do not match.", leftArg.src) };
      }
      else if (typeLeft != tint()) {
        msgs += { error("Arguments are not of type int.", leftArg.src) };
      }
    }
    
    case geq(AExpr leftArg, AExpr rightArg, src = loc u): {
      typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeLeft != typeOf(rightArg, tenv, useDef)) {
        msgs += { error("Argument types of expression do not match.", leftArg.src) };
      }
      else if (typeLeft != tint()) {
        msgs += { error("Arguments are not of type int.", leftArg.src) };
      }
    }
    
    case eq(AExpr leftArg, AExpr rightArg, src = loc u): {
      typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeLeft != typeOf(rightArg, tenv, useDef)) {
        msgs += { error("Argument types of expression do not match.", leftArg.src) };
      }
      else if (typeLeft != tint() && typeLeft != tbool()) {
        msgs += { error("Arguments are not of type int or bool.", leftArg.src) };
      }
    }
    
    case neq(AExpr leftArg, AExpr rightArg, src = loc u): {
      typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeLeft != typeOf(rightArg, tenv, useDef)) {
        msgs += { error("Argument types of expression do not match.", leftArg.src) };
      }
      else if (typeLeft != tint() && typeLeft != tbool()) {
        msgs += { error("Arguments are not of type int or bool.", leftArg.src) };
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
    
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
  // Base Cases
    case ref(AId x, src = loc u): { 
      loc d = |tmp:///|;
      for (<loc use, loc def> <- useDef) { // Find definition
        if (use == x.src) {
          d = def;
          break;
        }
      }
      
      if (d == |tmp:///|) { // variable not defined
        return tunknown();
      }
      
      for (<loc def, _, _, Type t> <- tenv) { // Determine type
        if (def == d) {
          return t;
        }
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
      Type typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeOf(rightArg, tenv, useDef) == typeLeft && typeLeft == tint()) {
        return typeLeft;
      } else { return tunknown(); }
    }
    case plus(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg, tenv, useDef);
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
      Type typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeOf(rightArg, tenv, useDef) == typeLeft && typeLeft == tint()) {
        return tbool();
      } else { return tunknown(); }
    }
    case leq(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeOf(rightArg, tenv, useDef) == typeLeft && typeLeft == tint()) {
        return tbool();
      } else { return tunknown(); }
    }
    case greater(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeOf(rightArg, tenv, useDef) == typeLeft && typeLeft == tint()) {
        return tbool();
      } else { return tunknown(); }
    }
    case geq(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeOf(rightArg, tenv, useDef) == typeLeft && typeLeft == tint()) {
        return tbool();
      } else { return tunknown(); }
    }
    case eq(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeOf(rightArg, tenv, useDef) == typeLeft) {
        return tbool();
      } else { return tunknown(); }
    }
    case neq(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeOf(rightArg, tenv, useDef) == typeLeft) {
        return tbool();
      } else { return tunknown(); }
    }
    case and(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeOf(rightArg, tenv, useDef) == typeLeft && typeLeft == tbool()) {
        return tbool();
      } else { return tunknown(); }
    }
    case or(AExpr leftArg, AExpr rightArg): {
      Type typeLeft = typeOf(leftArg, tenv, useDef);
      if (typeOf(rightArg, tenv, useDef) == typeLeft && typeLeft == tbool()) {
        return tbool();
      } else { return tunknown(); }
    }
  }
  return tunknown(); 
}

Type mapDefTypes(AType varType) {
  switch (varType) {
    case integerType(): return tint();
    case booleanType(): return tbool();
    case stringType(): return tstr();
    default: return tunknown();
  }
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
 
 

