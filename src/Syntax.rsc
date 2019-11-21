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
  | "if" "(" Expr ")" "{" Question* "}" OptionalElse?
  ; 

syntax OptionalElse
  = "else" "{" Question* "}"
  ;
  
syntax TypeDefinition
  = Type ("= " Expr)?;

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | Expr "==" Expr 
  | Expr "\>=" Expr
  | Expr "\<=" Expr
  | Expr "!=" Expr
  | Expr "\>" Expr
  | Expr "\<" Expr
  ;
  
syntax Type
  = "boolean"
  | "integer"
  ;  
  
lexical Str = [\"] ![\"]* [\"];

lexical Int 
  = [0-9]+;

lexical Bool 
= "true"
| "false"
;



