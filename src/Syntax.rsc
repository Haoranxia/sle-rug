module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = Str Id ":" TypeDefinition // Question and computed question
  | "if" BoolExpr "{" Question* "}" OptionalElse?
  ; 

syntax OptionalElse
  = "else" "{" Question* "}"
  ;
  
syntax TypeDefinition
  = "integer" ("= " IntExpr)?
  | "boolean" ("= " BoolExpr)?
  | "string" ("= " StrExpr)?
  ;

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | BoolExpr 
  | IntExpr
  | StrExpr
  ;
  
syntax BoolExpr
  //= Id \ "true" \ "false"
  //| Bool
  //> "(" BoolExpr ")"
  = "!" BoolExpr
  > left IntExpr "\>=" IntExpr
  | left IntExpr "\<=" IntExpr
  | left IntExpr "\>" IntExpr
  | left IntExpr "\<" IntExpr
  | BoolTerm OptionalBoolExpr?
  //> left BoolExpr "==" BoolExpr 
 // | left BoolExpr "!=" BoolExpr
  | left IntExpr "==" IntExpr
  | left IntExpr "!=" IntExpr
  | left StrExpr "==" StrExpr
  | left StrExpr "!=" StrExpr
  //> left BoolExpr "&&" BoolExpr
  //| left BoolExpr "||" BoolExpr
  ;
  
syntax OptionalBoolExpr
  = "!=" BoolExpr
  | "==" BoolExpr
  ;
  
syntax BoolTerm
  = BoolFactor OptionalBoolTerm?;
  
syntax OptionalBoolTerm
  = "&&" BoolTerm
  | "||" Boolterm
  ;
  
syntax BoolFactor
  =  Id \ "true" \ "false"
  | Bool
  | "(" BoolExpr ")"
  ;
  
syntax IntExpr
  //= Id \ "true" \ "false"
  //| Int
  //> "(" IntExpr ")"
  //> "+" IntExpr
  = Term OptionalIntExpr?
  //> left IntExpr "*" IntExpr
  //| left IntExpr "/" IntExpr
 // > left IntExpr "+" IntExpr
  //| left IntExpr "-" IntExpr
 // > left IntExpr "\>=" IntExpr
 // | right IntExpr "\<=" IntExpr
 // | left IntExpr "\>" IntExpr
 // | right IntExpr "\<" IntExpr
 // > left IntExpr "==" IntExpr
 // | right IntExpr "!=" IntExpr
  ;
  
syntax OptionalIntExpr
  = "+" IntExpr
  | "-" IntExpr
  ;
  
syntax Term
  = Factor OptionalTerm? ;
  
syntax OptionalTerm
  = "*" Term
  | "/" Term
  ;
  
syntax Factor
  = "(" IntExpr ")"
  | Int
  | Id \ "true" \ "false"  
  ;
  
syntax StrExpr
  = Id \"true" \"false"
  | Str
  > "(" StrExpr ")"
 // | left StrExpr "==" StrExpr
 // | left StrExpr "!=" StrExpr
  ;
  
syntax Type
  = "boolean"
  | "integer"
  | "string"
  ;  
  
lexical Str = [\"] ![\"]* [\"];

lexical Int 
  = [0-9]+;

lexical Bool 
= "true"
| "false"
;



