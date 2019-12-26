module htmltest

import lang::html5::DOM;
import IO;
import List;



str testhtml(){
	HTML5Node html = div(id("id1"), html5attr("style", "style1"));
	return toString(html);
}

str runtest() {
	return testhtml();
}

