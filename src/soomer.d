/**
 * soomer.d
 *
 * Program ktery sleduje zadana vlakna na soomu a pokud v nich nastane zmena
 * upozorni na ni emailem uzivatele.
 * 
 * Author:  Bystroushaak (bystrousak@kitakitsune.org)
 * Date:    17.11.2011
 * 
 * Copyright: 
 *     This work is licensed under a CC BY.
 *     http://creativecommons.org/licenses/by/3.0/
*/
import std.stdio;
import std.array;
import std.string;
import std.encoding;


/// See https://github.com/Bystroushaak for details
import dhttpclient;
import dhtmlparser;
import fakemailer_api;
import utf_conv;



const string EXAMPLE_CONF = import("example.conf");
const string HELP_STR     = import("help.txt");
const string VERSION_STR  = import("version.txt");

const string CONF_PATH    = "~/.soomer/soomer.conf";

HTTPClient cl;


/// Return associative array with configuration parsed from string
string[string] processConf(string conf){
	string[string] parsed_conf;
	
	foreach(line; conf.splitLines()){
		if (line.indexOf("=") <= 0)
			continue;
		
		// comments
		if (line.indexOf("#") >= 0){
			if (line.indexOf("#") == 0)
				continue; 
				
			line = line[0 .. line.indexOf("#")];
			
			if (line.strip().length == 0)
				continue;
		}
		
		string[] tmp = line.split("=");
		
		// remove whitespaces from key & val
		tmp[0] = tmp[0].strip();
		tmp[1] = tmp[1].strip();
		
		parsed_conf[tmp[0].toUpper()] = tmp[1];
	}
	
	return parsed_conf;
}


/// Returns title of given url.
string getTitle(string url){
	auto dom = parseString(win1250ShitToUTF8(cl.get(url)));
	return dom.find("title")[0].getContent().strip().replace("\n", " ");
}


int main(string[] args){
	cl = new HTTPClient();
	
	writeln(getTitle("http://www.soom.cz/index.php?name=articles/show&aid=566"));
	
	return 0;
}





















