module CompileHTML

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library
import util::Math;
import Boolean;

HTML5Node question2html(AQuestion q, RefGraph ref){
	HTML5Node html;
	switch(q){
		case question(str queryText, AId id, AType varType): {
			html = 
				p(queryText,
				  getCorrectInputType(id, varType, true)
				);
			return html;
		}
		
		
		case question(str queryText, AId id, AType varType, AExpr expr): {
			html = p(queryText, 
			         getCorrectInputType(id, varType, false)
			       );
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
			    div(div(question2html(question(guard, ifQuestions), ref)),
			        div(id("else" + getCorrectId(guard, ref)),
						html5attr("style", "display:block"),
						div([question2html(elseq, ref) | AQuestion elseq <- elseQuestions])
					)
				);
			return html;
		}

	}
	return html;
}

HTML5Node getCorrectInputType(AId aid, AType t, bool mutable){
	HTML5Node inputfield;
	switch(t){
		case stringType(): {
		    if (mutable) {
			    inputfield = input(\type("text"), id(aid.name));
			}
			else {
			    inputfield = input(\type("text"), id(aid.name), readonly("readonly"));
			}
			return inputfield;
		}
		
		case integerType(): {
			if (mutable) {
			    inputfield = input(\type("number"), id(aid.name));
			}
			else {
			    inputfield = input(\type("number"), id(aid.name), readonly("readonly"));
			}
			return inputfield;
		}
		
		case booleanType(): {
			if (mutable) {
			    inputfield = input(\type("checkbox"), id(aid.name));
			}
			else {
			    inputfield = input(\type("checkbox"), id(aid.name), readonly("readonly"));
			}
			return inputfield;
		}
		
		default: {
			return inputfield;
		}
	}
	
	return inputfield;
}

str getCorrectId(AExpr guard, RefGraph varibles){
	visit(guard) {
		case ref(AId id): return id.name;
	}
}