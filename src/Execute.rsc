module Execute

import Syntax;
import AST;
import CST2AST;
import Resolve;
import Check;
import Eval;
import Compile;
import Transform;

import Eval::Value;

import IO;
import ParseTree;
import vis::ParseTree;
import Message;


void executeStatic(loc file) {
    println("DEMO START");
    
    println("Creating concrete syntax tree...");
    
    start[Form] concreteTree = parse(#start[Form], file);
    
    println(concreteTree);
    renderParsetree(concreteTree);
    
    println("Create abstract syntax tree...");
    
    AForm abstractTree = cst2ast(concreteTree);
    
    println(abstractTree);
    
    println("Performing name resolution...");
    
    RefGraph refs = resolve(abstractTree);
    
    println("Defs:");
    for (<str name, loc def> <- refs.defs) {
        print("name: " + name + ", loc: ");
        println(def);
    }
    println();
    
    println("Uses:");
    for (<loc use, str name> <- refs.uses) {
        print("name: " + name + ", loc: ");
        println(use);
    }
    println();
    
    println("UseDefs:");
    for (<loc use, loc def> <- refs.useDef) {
        print(use);
        
        print(", ");
        println(def);
    }
    println();
    
    println("Performing type checking...");
    
    set[Message] errors = check(abstractTree, collect(abstractTree), refs.useDef);
    if (errors == {}) {
        println("No errors found!");
    }
    else {  
        println("Errors detected:");  
        println(errors);
        for (Message error <- errors) {
           switch (error) {
               case error(_, _): return; // Terminate if error is found, rather than only warnings
           }
        }
    }
    println();
}

void executeEval(loc file, rel[str var, Value \value] inputs) { // str var, Value \value)
    println("Evaluating program...");
    
    start[Form] concreteTree = parse(#start[Form], file);
    AForm abstractTree = cst2ast(concreteTree);
    
    VEnv venv = initialEnv(abstractTree);
    
    for (<var, \value> <- inputs) {
      venv = eval(abstractTree, input(var, \value), venv);
    }
    
    println(venv);
    println();
}

void executeCompile(loc file) {
    println("Compiling MyQL program...");
    start[Form] concreteTree = parse(#start[Form], file);
    AForm abstractTree = cst2ast(concreteTree);
    
    compile(abstractTree);
}

void executeTransform(loc file, <loc renameLocation, str newName>) {
    start[Form] concreteTree = parse(#start[Form], file);
    AForm abstractTree = cst2ast(concreteTree);
    RefGraph refs = resolve(abstractTree);

    println("Normalising program...");
    println(flatten(abstractTree));
    
    println("Renaming indicated question...");
    
    println(rename(concreteTree, renameLocation, newName, refs));
    
}