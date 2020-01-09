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
				p(queryText,
				  getCorrectInputType(id, varType)
				);
			return html;
		}
		
		
		case question(str queryText, AId id, AType varType, AExpr expr): {
			html = p(queryText, html5attr("id", id.name));
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
			/*html = 
				div(div(id("if" + getCorrectId(guard, ref))),//,
				       // html5attr("style", "display:none")),
					div([question2html(ifq, ref) | AQuestion ifq <- ifQuestions],
					    html5attr("style", "display:none")),		
					div(id("else" + getCorrectId(guard, ref)),
						html5attr("style", "display:block"),
						div([question2html(elseq, ref) | AQuestion elseq <- elseQuestions])
					)
				);*/
			return html;
		}

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
	visit(guard) {
		case ref(AId id): return id.name;
	}
}