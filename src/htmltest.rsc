module htmltest

import lang::html5::DOM;
import IO;
import List;



str testhtml(){
	list[int] testlist = [1,2,3,4,5];

	HTML5Node html = div(id("1"), div(id("2"), div(id("2"))));	

	return toString(html);
}

str runtest() {
	return testhtml();
}

