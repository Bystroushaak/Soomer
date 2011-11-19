/**
 * soomer.d
 *
 * Program ktery sleduje zadana vlakna na soomu a pokud v nich nastane zmena,
 * upozorni na ni emailem uzivatele.
 * 
 * Author:  Bystroushaak (bystrousak@kitakitsune.org)
 * Date:    19.11.2011
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



struct Comment{
	string nickname;
	string backlink;
	string text;
	
	string toString(){
		return "Nickname: " ~ this.nickname ~ "\n" ~
		       "Backlink: " ~ this.backlink ~ "\n" ~
		       "Text:\n" ~ this.text ~ "\n";
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


/// Returns title of given url.
string getTitle(string url){
	auto dom = parseString(win1250ShitToUTF8(cl.get(url)));
	return dom.find("title")[0].getContent().strip().replace("\n", " ");
}


/// Comments for articles
Comment[] getArticleComments(string url){
	Comment comment;
	Comment[] comments;
	
	auto dom = parseString(win1250ShitToUTF8(cl.get(url)));
	
	foreach(e; dom.find("table", ["class":"obsahprisp"])){
		// parse nickname
		auto tmp = e.find("strong");
		if (tmp.length >= 1)
			comment.nickname = tmp[0].getContent();
		
		// no baclinks in articles/usertexts, so using url..
		comment.backlink = url;
		
		tmp = e.findB("tr");
		if (tmp.length >= 2)
			comment.text = tmp[1].childs[0].getContent();
		
		// remove user sign
		int io;
		if ((io = comment.text.indexOf("----------")) > 0)
			comment.text = comment.text[0 .. io];
		
		comment.text = comment.text.replace("<br />\n", "").strip(); //mg..
		comments ~= comment;
	}
	
	// remove garbage (first <td> is crap)
	if (comments.length >= 1)
		comments = comments[1 .. $];
	
	return comments;
}


/// Comments for webforum
Comment[] getWebforumComments(string url){
	Comment comment;
	Comment[] comments;
	
	auto dom = parseString(win1250ShitToUTF8(cl.get(url)));
	
	foreach(e; dom.find("table", ["class":"obsahprisp"])[0 .. $ - 1]){ // last is new comment form
		// parse nickname
		auto tmp = e.find("td", ["class":"descr"]);
		if (tmp.length >= 1)
			comment.nickname = tmp[0].find("strong")[0].getContent();
		
		// parse baclink
		tmp = e.find("a", ["title":"Link"]);
		if (tmp.length >= 1)
			comment.backlink = "http://soom.cz/" ~ tmp[0].params["href"];
		
		// parse text
		int io;
		comment.text = e.findB("tr")[1].find("td")[0].getContent();
		if ((io = comment.text.indexOf("<br>")) > 0 && comment.text.length > 2)
			comment.text = comment.text[0 .. io - 1];
		
		// remove user sign
		if ((io = comment.text.indexOf("----------")) > 0)
			comment.text = comment.text[0 .. io];
		
		comment.text = comment.text.replace("<br />\n", "").strip();
		
		comments ~= comment;
	}
	return comments;
}


/// wrapper for getWebforumComments && getArticleComments
Comment[] getComments(string url){
	string url_l = url.toLower();
	if (url_l.indexOf("webforum/show") > 0 || url_l.indexOf("bugtrack/show") > 0)
		return getWebforumComments(url);
	else if (url_l.indexOf("discussion/main") > 0 || url_l.indexOf("comments") > 0)
		return getArticleComments(url);
	
	throw new Exception("Unknown type of URL!");
}


int main(string[] args){
	cl = new HTTPClient();
	
//	writeln(getTitle("http://www.soom.cz/index.php?name=articles/show&aid=566"));

	writeln(getComments("http://www.soom.cz/index.php?name=user/profile/comments&aid=118"));
	
	return 0;
}





















