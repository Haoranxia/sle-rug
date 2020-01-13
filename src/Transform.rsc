module Transform

import IO;
import Set;
import ParseTree;

import Syntax;
import Resolve;
import AST;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  list[AQuestion] newQuestions = [];
  
  for (AQuestion q <- f.questions) {
      newQuestions += flattenQuestion(q, []);
  }
  
  return form(f.name, newQuestions); 
}


list[AQuestion] flattenQuestion(AQuestion q, list[AExpr] conditions) {
    list[AQuestion] flattenedQuestions = [];
    switch(q) {
        case question(str queryText, AId id, AType varType):
            flattenedQuestions += [question(concatConditions(conditions), [q])];
        case question(str queryText, AId id, AType varType, AExpr expr): 
            flattenedQuestions += [question(concatConditions(conditions), [q])];
        case question(AExpr guard, list[AQuestion] ifQuestions): {
            for (AQuestion qif <- ifQuestions) {
                flattenedQuestions += flattenQuestion(qif, conditions + [guard]);
            }
        }
        case question(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
            for (AQuestion qif <- ifQuestions) {
                flattenedQuestions += flattenQuestion(qif, conditions + [guard]);
            }
            for (AQuestion qelse <- elseQuestions) { // Else case adds the negation of the guard as a condition
                flattenedQuestions += flattenQuestion(qelse, conditions + [not(guard)]);
            }
        }
    }
    
    return flattenedQuestions;
}


AExpr concatConditions(list[AExpr] conditions) {
    AExpr condResult = boolean(true);
    
    for (AExpr condition <- conditions) {
       condResult = and(condResult, condition);
    }
    
    return condResult;
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
 start[Form] rename(start[Form] f, loc useOrDef, str newName, RefGraph refs) {
     // Get the defining occurrence associated with the indicated location
     println("Starting rename.");
     loc defLoc = useOrDef;
     println({def | <loc use, loc def> <- refs.useDef, use == useOrDef});
     if ({def | <str name, loc def> <- refs.defs, def == useOrDef} != {}) { // Case def: the rename location is a defining occurrence
         defLoc = useOrDef;
     }
     else { // Case use: search for defining occurrence associated with the use occurrence
         defLoc = getOneFrom({def | <loc use, loc def> <- refs.useDef, use == useOrDef});
     }
     
     Id newId = [Id]newName;
     
     return visit(f) {
         case (Question) `<Str query> <Id x> : <Type varType>`
           => (Question) `<Str query> <Id newId> : <Type varType>`
           when
               defLoc == x@\loc
         
         case (Question) `<Str query> <Id x> : <Type varType> = <Expr exp>`
           => (Question) `<Str query> <Id newId> : <Type varType> = <Expr exp>`
           when
               defLoc == x@\loc
         
         case (Expr) `<Id x>`
           => (Expr) `<Id newId>`
           when 
                <loc use, loc def> <- refs.useDef,
                use == x@\loc,
                def == defLoc
     } 
 } 
 
 
 

