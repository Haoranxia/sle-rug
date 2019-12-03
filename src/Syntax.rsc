module Syntax

import ParseTree;
import vis::ParseTree;
import vis::Render;
import vis::Figure;

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = Str Id ":" Type ("=" Expr)? // Question and computed question
  | "if" Expr "{" Question* "}" ("else" "{" Question* "}")?
  ; 

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr
  = Id \ "true" \"false" // true/false are reserved keywords.
  | Int
  | Bool
  | Str
  | "(" Expr ")"
  | "!" Expr
  | "+" Expr
  | "-" Expr
  > left (Expr "*" Expr | Expr "/" Expr)
  > left (Expr "+" Expr | Expr "-" Expr)
  > non-assoc (Expr "\<" Expr | Expr "\<=" Expr | Expr "\>=" Expr | Expr "\>" Expr)
  > left (Expr "==" Expr | Expr "!=" Expr)
  > left Expr "&&" Expr
  > left Expr "||" Expr
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



