module CompileHTML

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library
import util::Math;

HTML5Node question2html(AQuestion q, RefGraph ref){
	HTML5Node html;
	switch(q){
		case question(str queryText, AId id, AType varType): {
			html = 
				p(<queryText>,
				  getCorrectInputType(id, varType)
				);
			return html;
		}
		
		
		case question(str queryText, AId id, AType varType, AExpr expr): {
			html = p(<queryText>, html5attr("id", id.name));
			return html;
		}
		
		case question(AExpr guard, list[AQuestion] ifQuestions): {
			html = 
				div(id("if" + getCorrectId(guard, ref)), 
					html5attr("style", "display:none"),
					div([question2html(ifq, ref) | AQuestion ifq <- ifQuestions])
				);
			return html;
		}
		
		case question(AExpr guard, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
			html = 
				div(id("if" + getCorrectId(guard, ref)),
					question2html(guard, ifQuestions),				
					div(id("else" + getCorrectId(guard, ref)),
						html5attr("style", "display:none"),
						div([question2html(elseq, ref) | AQuestion elseq <- elseQuestions])
					)
				);
			return html;
		}
		
		default: {
			println(q);
			assert(false);
		}

	}
	return html;
}

// Right now were just printing the variables used
HTML5Node getComputedQuestion(AId id, AType t, AExpr e, RefGraph ref){
	HTML5Node html = p(expr2html(e));
	return html;
}

HTML5Node expr2html(AExpr e){
	HTML5Node html;
	switch(e) {
		case ref(AId id): return p(id.name);
		case integer(int intValue): return p(intValue);
		case string(str strValue): return p(strValue);
		case bracketExpr(AExpr singleArg): return expr2html(singleArg);
		case not(AExpr singleArg): return expr2html(singleArg);
		case unaryPLus(AExpr singleArg): return expr2html(singleArg);
		case unaryMinus(AExpr singleArg): return expr2html(singleArg);
		case mult(AExpr leftArg, AExpr rightArg): return div(expr2html(leftArg), (expr2html(rightArg)));
		case div(AExpr leftARg, AExpr rightArg): return div(expr2html(leftArg), (expr2html(rightArg)));
		case plus(AExpr leftARg, AExpr rightARg): return div(expr2html(leftArg), (expr2html(rightArg)));
		case minus(AExpr leftArg, AExpr rightArg): return div(expr2html(leftArg), (expr2html(rightArg)));
		case less(AExpr leftARg, AExpr rightArg): return div(expr2html(leftArg), (expr2html(rightArg)));
		case leq(AExpr leftARg, AExpr rightArg): return div(expr2html(leftArg), (expr2html(rightArg)));
		case greater(AExpr leftARg, AExpr rightArg): return p(expr2html(leftArg), p(expr2html(rightArg)));
		case geq(AExpr leftARg, AExpr rightArg): return div(expr2html(leftArg), (expr2html(rightArg)));
		case eq(AExpr leftARg, AExpr rightArg): return div(expr2html(leftArg), (expr2html(rightArg)));
		case neq(AExpr leftARg, AExpr rightArg): return div(expr2html(leftArg), (expr2html(rightArg)));
		case and(AExpr leftARg, AExpr rightArg): return div(expr2html(leftArg), (expr2html(rightArg)));
		case or(AExpr leftARg, AExpr rightArg): return div(expr2html(leftArg), (expr2html(rightArg)));
		default: return p();
	}
	return html;
}

HTML5Node getCorrectInputType(AId aid, AType t){
	HTML5Node inputfield;
	//println(aid);
	//println(t);
	switch(t){
		case stringType(): {
			inputfield = input(\type("text"), id(aid.name));
			return inputfield;
		}
		
		case integerType(): {
			inputfield = input(\type("number"), id(aid.name));
			return inputfield;
		}
		
		case booleanType(): {
			inputfield = input(\type("checkbox"), id(aid.name));
			return inputfield;
		}
		
		default: {
			println(t);
			return inputfield;
		}
	}
	
	return inputfield;
}

str getCorrectId(AExpr guard, RefGraph varibles){
	str name = "";
	println(guard);
	visit(guard) {
		case ref(AId id): name += id.name;
	}
	return name;
}