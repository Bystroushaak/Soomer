/**
 * soomer.d
 *
 * Program ktery sleduje zadana vlakna na soomu a pokud v nich nastane zmena,
 * upozorni na ni emailem uzivatele.
 * 
 * Author:  Bystroushaak (bystrousak@kitakitsune.org)
 * Date:    20.11.2011
 * 
 * Copyright: 
 *     This work is licensed under a CC BY.
 *     http://creativecommons.org/licenses/by/3.0/
 
 TODO:
 	Serializace komentaru do/z HTML
*/
import std.stdio;
import std.array;
import std.string;


/// See https://github.com/Bystroushaak for details
import dhttpclient;
import dhtmlparser;
import fakemailer_api;

import soom_api;



const string EXAMPLE_CONF = import("example.conf");
const string HELP_STR     = import("help.txt");
const string VERSION_STR  = import("version.txt");

const string CONF_PATH    = "~/.soomer/soomer.conf";



/// Struct used for storing URL; title pairs with some serialization methods.
struct URL{
	public string url;        ///
	public string title;      ///
	
	/// Return list of URLs parsed from filename
	static URL[] readURLs(string filename){
		int io;
		URL tmp;
		URL[] o;
		
		foreach(string l; lines(File(filename, "r"))){
			if ((io = l.indexOf(";")) > 0){
				tmp.url   = l[0 .. io];
				tmp.title = l[io + 2 .. $ - 1]; // remove \n from the end
				
				o ~= tmp;
			}
		}
		
		return o;
	}
	
	/// Save list of URLs to filename
	static void writeURLs(string filename, URL[] urls){
		string o;
		foreach(u; urls)
			o ~= u.toString();
		
		std.file.write(filename, o);
	}
	
	public string toString(){
		return this.url ~ "; " ~ this.title.strip().replace("\n", "") ~ "\n";
	}
}



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





int main(string[] args){
//	writeln(getTitle("http://www.soom.cz/index.php?name=articles/show&aid=566"));
//	writeln(getComments("http://www.soom.cz/index.php?name=user/profile/comments&aid=118"));
	
	writeln(URL.readURLs("test")[0].title);
	
	return 0;
}





















