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
*/
import std.stdio;
import std.array;
import std.string;
import std.getopt;
import std.algorithm : remove;


/// See https://github.com/Bystroushaak for details
import fakemailer_api;
import conf_parser;

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



int main(string[] args){
	bool help, ver, multiple, list;
	string add, remove;
	string config_path = CONF_PATH;
	string[string] configuration;
	
	// parse options
	try{
		getopt(
			args,
			std.getopt.config.bundling, // onechar shortcuts
			"help|h", &help,
			"version|v", &ver,
			"multiple|m", &multiple,
			"list|l", &list,
			"add|a", &add,
			"remove|r", &remove,
			"config|c", &config_path
		);
	}catch(Exception e){
		stderr.writeln(HELP_STR);
		return 1;
	}
	if (help){
		writeln(HELP_STR);
		return 0;
	}else if (ver){
		write(VERSION_STR);
		return 0;
	}
	
	// read configuration
	try{
		config_path = std.path.expandTilde(config_path);
		configuration = parseConfiguration(std.file.readText(config_path), parseConfiguration(EXAMPLE_CONF));
	}catch(Exception e){
		stderr.writeln(e.msg);
		stderr.write("Writing example configuration to '" ~ config_path ~ "' .. ");
		
		try{
			std.file.mkdirRecurse(config_path[0 .. config_path.lastIndexOf("/")]);
			std.file.write(config_path, EXAMPLE_CONF);
		
			stderr.writeln("ok");
		}catch(Exception e){
			stderr.writeln(e.msg);
			return -1;
		}
		
		configuration = parseConfiguration(std.file.readText(config_path), parseConfiguration(EXAMPLE_CONF));
	}
	// get absolute path based on just readed configuration
	configuration["CONF_DIR"] = config_path[0 .. config_path.lastIndexOf("/")];
	configuration["LINKS_FILE"] = configuration["CONF_DIR"] ~ "/" ~ configuration["LINKS_FILE"];
	
	// show all saved links
	if (list){
		URL[] urls;
		try{
			urls = URL.readURLs(configuration["LINKS_FILE"]);
		}catch(Exception){ // handled in next if
		}
		
		if (urls.length == 0){
			stderr.writeln("There are no links in '" ~ configuration["LINKS_FILE"] ~ "'. Try add some with '--add' parameter.");
			return 1;
		}
		
		// list all stored urls
		foreach(int i, URL u; urls){
			writeln(i, "; ", u.title, " (", u.url, ")");
		}
		
		return 0;;
	}
	
	// read links from stdin if --multiple option selected
	if (multiple){
		add ~= "\n";
		
		foreach(string l; lines(stdin))
			add ~= l ~ "\n";
	}
	// write links to configuration["LINKS_FILE"]
	if (add != ""){
		URL url;
		URL[] urls;
		try{
			urls = URL.readURLs(configuration["LINKS_FILE"]);
		}catch(Exception){ // handled in next if
		}
		
		foreach(l; add.splitLines()){
			l = l.strip();
			
			// skip crap
			if (! l.toLower().startsWith("http://") || l.toLower().indexOf("soom.cz") <= 0)
				continue;
			
			url.url = l;
			
			// try download title
			try{
				url.title = getTitle(l);
			}catch(Exception e){
				stderr.writeln(e.msg);
				return 1;
			}
			
			urls ~= url;
		}
		
		URL.writeURLs(configuration["LINKS_FILE"], urls);
	}
	
	// remove link(s) from file
	if (remove != ""){
		URL[] urls;
		try{
			urls = URL.readURLs(configuration["LINKS_FILE"]);
		}catch(Exception){ // handled in next if
		}
		if (urls.length == 0){
			stderr.writeln("There are no links in '" ~ configuration["LINKS_FILE"] ~ "'. Try add some with '--add' parameter.");
			return 1;
		}
		
		// parse range
		int[2] range;
		string[] s_range;
		if (remove.indexOf("..") > 0)
			s_range = remove.split("..");
		else if (remove.indexOf("-") > 0)
			s_range = remove.split("..");
		else{
			try{
				range[0] = std.conv.to!int(remove);
			}catch(Exception e){
				stderr.writeln(e.msg);
				return 2;
			}
			
			// check number range
			if (range[0] < 0 || range[0] > urls.length - 1){
				stderr.writeln("Bad index in '--remove' parameter. Run --list for indexes.");
				return 2;
			}
			
			urls = urls.remove(range[0]);
			URL.writeURLs(configuration["LINKS_FILE"], urls);
			
			return 0;
		}
		
		s_range[0] = s_range[0].strip();
		s_range[1] = s_range[1].strip();
		
		// convert range to int
		try{
			range[0] = std.conv.to!int(s_range[0]);
			range[1] = std.conv.to!int(s_range[1]);
		}catch(Exception e){
			stderr.writeln(e.msg);
			return 2;
		}
		
		// check given range
		if (range[0] >= range[1] || range[0] < 0 || range[1] > urls.length - 1){
			stderr.writeln("Bad range!");
			return 2;
		}
		
		// remove elements from url
		for(int i = range[0]; i <= range[1]; i++){
			urls = urls.remove(i);
		}
		
		URL.writeURLs(configuration["LINKS_FILE"], urls);
		return 0;
	}
	
	// TODO check and send to mail


//	writeln(getTitle("http://www.soom.cz/index.php?name=articles/show&aid=566"));
//	Comment.writeComments("test", getComments("http://www.soom.cz/index.php?name=user/profile/comments&aid=118"));
//	writeln(Comment.readComments("test")[0].text);
	
//	writeln(URL.readURLs("test")[0].title);
	
	return 0;
}





















