module Eval

import AST;
import Resolve;

import Map;
import IO;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)

VEnv initialEnv(AForm f) {
  VEnv valEnv = ();
  for (/question(str label, AId x, AType varType) := f) {
    switch(varType) {
      case integerType(): valEnv += (x.name: vint(0));
      case booleanType(): valEnv += (x.name: vbool(false));
      case stringType(): valEnv += (x.name: vstr(""));
      default: assert("Unsupported type found.");
    }
  }
  for (/question(str label, AId x, AType varType, _) := f) {
    switch(varType) {
      case integerType(): valEnv += (x.name: vint(0));
      case booleanType(): valEnv += (x.name: vbool(false));
      case stringType(): valEnv += (x.name: vstr(""));
      default: assert("Unsupported type found.");
    }
  }
  return valEnv;
}


// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  switch(f) {
    case form(_, list[AQuestion] qs): {
      for (q <- qs) {
        venv = eval(q, inp, venv);
      }
    }
  }
  return venv; 
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  switch(q) {
    case question(str queryText, AId id, AType varType): {
      if (id.name == inp.question) {
        venv[id.name] = inp.\value;
      }
    }
    case question(str queryText, AId id, AType varType, AExpr expr): {
      venv[id.name] = eval(expr, venv);
    }
    case question(AExpr guard, list[AQuestion] ifQuestions): {
      if (eval(guard, venv) == vbool(true)) {
        for (ifq <- ifQuestions) {
          venv = eval(ifq, inp, venv);
        }
      }
    }
    
    case question(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
      if (eval(guard, venv) == vbool(true)) {
        for (ifq <- ifQuestions) {
          venv = eval(ifq, inp, venv);
        }
      }
      else if (eval(guard, venv) == vbool(false)) {
        for (elseq <- elseQuestions) {
          venv = eval(elseq, inp, venv);
        }
      }
      else {
        throw("Guard is not a boolean expression.");
      }
    }
    default: assert("wrongly formatted question.");
  }
    
  return venv; 
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(id(str x)): return venv[x];
    case integer(int x): return vint(x);
    case boolean(bool x): return vbool(x);
    case string(str x): return vstr(x);
    case bracketExpr(AExpr expr): return eval(expr, venv);
    case not(AExpr expr): {
      Value vbool(bool b) = eval(expr, venv);
      return vbool(!b);
    }// return eval(expr, venv);
    case unaryPlus(AExpr expr): return eval(expr, venv);
    case unaryMinus(AExpr expr): {
      int val;
      switch(eval(left, venv)) {
        case vint(int x): val = x;
      }
      return vint(-val);
    }    
    case mult(AExpr left, AExpr right): {
      int l, r;
      switch(eval(left, venv)) {
        case vint(int x): l = x;
      }
      switch (eval(right, venv)) {
        case vint(int x): r = x;
      }
      return vint(l*r);
    }
    case div(AExpr left, AExpr right): {
      int l, r;
      switch(eval(left, venv)) {
        case vint(int x): l = x;
      }
      switch (eval(right, venv)) {
        case vint(int x): r = x;
      }
      return vint(l/r);
    }
    case plus(AExpr left, AExpr right): {
      int l, r;
      switch(eval(left, venv)) {
        case vint(int x): l = x;
      }
      switch (eval(right, venv)) {
        case vint(int x): r = x;
      }
      return vint(l+r);
    }
    case minus(AExpr left, AExpr right): {
      int l, r;
      switch(eval(left, venv)) {
        case vint(int x): l = x;
      }
      switch (eval(right, venv)) {
        case vint(int x): r = x;
      }
      return vint(l-r);
    }
    case less(AExpr left, AExpr right): {
      int l, r;
      switch(eval(left, venv)) {
        case vint(int x): l = x;
      }
      switch (eval(right, venv)) {
        case vint(int x): r = x;
      }
      return vbool(l < r);
    }
    case leq(AExpr left, AExpr right): {
      int l, r;
      switch(eval(left, venv)) {
        case vint(int x): l = x;
      }
      switch (eval(right, venv)) {
        case vint(int x): r = x;
      }
      return vbool(l <= r);
    }
    case greater(AExpr left, AExpr right): {
      int l, r;
      switch(eval(left, venv)) {
        case vint(int x): l = x;
      }
      switch (eval(right, venv)) {
        case vint(int x): r = x;
      }
      return vbool(l > r);
    }
    case geq(AExpr left, AExpr right): {
      int l, r;
      switch(eval(left, venv)) {
        case vint(int x): l = x;
      }
      switch (eval(right, venv)) {
        case vint(int x): r = x;
      }
      return vbool(l >= r);
    }
    case eq(AExpr left, AExpr right): {
      int lval, rval;
      bool isBool = false;
      bool lbool, rbool;
      switch(eval(left, venv)) {
        case vint(int x): lval = x;
        case vbool(bool x): {
          isBool = true;
          lbool = x;
        }
      }
      switch(eval(right, venv)) {
        case vint(int x): rval = x;
        case vbool(bool x): rbool = x;
      }
      
      if (isBool) {
        return vbool(lbool == rbool);
      }
      else {
        return vbool(lval == rval);
      }
    }
    case neq(AExpr left, AExpr right): {
      int lval, rval;
      bool isBool = false;
      bool lbool, rbool;
      switch(eval(left, venv)) {
        case vint(int x): lval = x;
        case vbool(bool x): {
          isBool = true;
          lbool = x;
        }
      }
      switch(eval(right, venv)) {
        case vint(int x): rval = x;
        case vbool(bool x): rbool = x;
      }
      
      if (isBool) {
        return vbool(lbool != rbool);
      }
      else {
        return vbool(lval != rval);
      }
    }
    case and(AExpr left, AExpr right): {
      bool l, r;
      switch(eval(left, venv)) {
        case vbool(bool x): l = x;
      }
      switch (eval(right, venv)) {
        case vbool(bool x): r = x;
      }
      return vbool(l && r);
    }
    case or(AExpr left, AExpr right): {
      bool l, r;
      switch(eval(left, venv)) {
        case vbool(bool x): l = x;
      }
      switch (eval(right, venv)) {
        case vbool(bool x): r = x;
      }
      return vbool(l || r);
    }
    
    // etc.
    
    default: throw "Unsupported expression <e>";
  }
  
  return vint(0);
}