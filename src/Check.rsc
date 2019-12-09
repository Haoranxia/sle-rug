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
  set[Message] msgs = {};
  
  switch (q) {
    case question(str queryText, AId id, AType varType): {
      msgs += createIncompTypeErrors(id, tenv, useDef);
      msgs += createDupLabelWarnings(queryText, id, tenv, useDef);
      msgs += createMultipleLabelsWarnings(id, tenv, useDef);
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
  set[Message] msgs = {};
  
  switch (e) {
    case ref(str x, src = loc u):
      msgs += { error("Undeclared question", u) | useDef[u] == {} };

    // etc.
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(str x, src = loc u):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    // etc.
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
 
 

