module AST



/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(AId name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = question(str queryText, AId id, AType varType)
  | question(str queryText, AId id, AType varType, AExpr expr)
  | question(AExpr guard, list[AQuestion] ifQuestions)
  | question(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | integer(int intValue)
  | boolean(bool boolValue)
  | string(str strValue)
  | bracketExpr(AExpr singleArg)
  | not(AExpr singleArg)
  | unaryPlus(AExpr singleArg)
  | unaryMinus(AExpr singleArg)
  | mult(AExpr leftArg, AExpr rightArg)
  | div(AExpr leftArg, AExpr rightArg)
  | plus(AExpr leftArg, AExpr rightArg)
  | minus(AExpr leftArg, AExpr rightArg)
  | less(AExpr leftArg, AExpr rightArg)
  | leq(AExpr leftArg, AExpr rightArg)
  | greater(AExpr leftArg, AExpr rightArg)
  | geq(AExpr leftArg, AExpr rightArg)
  | eq(AExpr leftArg, AExpr rightArg)
  | neq(AExpr leftArg, AExpr rightArg)
  | and(AExpr leftArg, AExpr rightArg)
  | or(AExpr leftArg, AExpr rightArg)
  ;

data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
  = stringType()
  | integerType()
  | booleanType()
  ;
  
	
  

