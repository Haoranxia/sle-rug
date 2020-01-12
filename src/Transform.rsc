module Transform

import IO;

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
  //AForm newForm = form(f.name, newQuestions);
  
  for (AQuestion q <- f.questions) {
      newQuestions += flattenQuestion(q, []);
      /*println(q);
      switch(q) {
          case question(str queryText, AId id, AType varType): {
              println("matched case 1");
              newQuestions += [question(boolean(true), [q])];
          }
          case question(str queryText, AId id, AType varType, AExpr expr): {
              println("matched case 2");
              newQuestions += [question(boolean(true), [q])];
          }
          case question(AExpr guard, list[AQuestion] ifquestions): {
              println("matched case 3");
          }
      }*/
  }
  
  return form(f.name, newQuestions); 
}


list[AQuestion] flattenQuestion(AQuestion q, list[AExpr] conditions) {
    list[AQuestion] flattenedQuestions = [];
    switch(q) {
        case question(str queryText, AId id, AType varType): {
            println("matched case 1");
            flattenedQuestions += [question(concatConditions(conditions), [q])];
        }
        case question(str queryText, AId id, AType varType, AExpr expr): {
            println("matched case 2");
            flattenedQuestions += [question(concatConditions(conditions), [q])];
        }
        case question(AExpr guard, list[AQuestion] ifQuestions): {
            for (AQuestion qif <- ifQuestions) {
                flattenedQuestions += flattenQuestion(qif, conditions + [guard]);
            }
            println("matched case 3");
        }
        case question(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
            for (AQuestion qif <- ifQuestions) {
                flattenedQuestions += flattenQuestion(qif, conditions + [guard]);
            }
            for (AQuestion qelse <- elseQuestions) { // Else case adds the negation of the guard as a condition
                flattenedQuestions += flattenQuestion(qelse, conditions + [not(guard)]);
            }
            println("matched case 4");
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
 
 start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
   return f; 
 } 
 
 
 

