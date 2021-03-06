/**
 * soomer_api.d
 *
 * Soom.cz API.
 * 
 * Author:  Bystroushaak (bystrousak@kitakitsune.org)
 * Date:    30.07.2013
 * 
 * Copyright: 
 *     This work is licensed under a CC BY.
 *     http://creativecommons.org/licenses/by/3.0/
*/
import std.array;
import std.string;


/// See https://github.com/Bystroushaak for details
import dhttpclient;
import dhtmlparser;
import utf_conv;



private HTTPClient cl; // global variable used for http interaction



static this(){ // module constructor, fuck yea
	cl = new HTTPClient();
}



///
struct Comment{
	string nickname;
	string backlink;
	string text;
	
	/// returns xml string
	string toString(){
		auto dom = new HTMLElement([ // container
			new HTMLElement("comment", [
				new HTMLElement("nickname", [new HTMLElement(nickname)]),
				new HTMLElement("backlink", [new HTMLElement(backlink.replace("&amp;", "&"))]),
				new HTMLElement("text", [new HTMLElement(text)])
			])
		]);
		
		return dom.toString();
	}
	
	static Comment[] readComments(string filename){
		Comment comment;
		Comment[] comments;

		// deserialize comments from XML
		foreach(c; parseString(std.file.readText(filename)).find("comment")){
			comment.nickname = c.find("nickname")[0].getContent();
			comment.backlink = c.find("backlink")[0].getContent().replace("&amp;", "&");
			comment.text     = c.find("text")[0].getContent();
			
			comments ~= comment;
		}
		
		return comments;
	}
	
	static void writeComments(string filename, Comment[] comments){
		string o;
		foreach(c; comments)
			o ~= c.toString();
		
		std.file.write(filename, o);
	}
	
	const bool opEquals(ref const(Comment) rhs) {
		return (this.nickname == rhs.nickname && this.backlink == rhs.backlink && this.text.replace("\n", "") == rhs.text.replace("\n", ""));
	}
}



/// Returns title of given url.
string getTitle(string url){
	// parse link to real title
	if (url.indexOf("/comments") > 0){
		foreach(k; ["articles", "recenze", "usertexts"]){
			if (url.indexOf(k ~ "/") > 0){
				url = url.replace("/comments", "/show");
				break;
			}
		}
	}
	
	auto dom = parseString(win1250ShitToUTF8(cl.get(url)));
	return dom.find("title")[0].getContent().strip().replace("\n", " ").replace("SOOM.cz - ", "");
}


/// Comments from articles
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
		if ((io = cast(int) comment.text.indexOf("----------")) > 0)
			comment.text = comment.text[0 .. io].replace("&amp;", "&");
		
		comment.text = comment.text.replace("<br />\r\n", "").replace("<br />\n\r", "").replace("<br />\n", "").strip(); //mg..
		comments ~= comment;
	}
	
	// remove garbage (first <td> is crap)
	if (comments.length >= 1)
		comments = comments[1 .. $];
	
	return comments;
}


/// Comments from webforum
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
			comment.backlink = "http://soom.cz/" ~ tmp[0].params["href"].replace("&amp;", "&");
		
		// parse text
		int io;
		comment.text = e.findB("tr")[1].find("td")[0].getContent();
		if ((io = cast(int) comment.text.indexOf("<br>")) > 0 && comment.text.length > 2)
			comment.text = comment.text[0 .. io - 1].replace("&amp;", "&");
		
		// remove user sign
		if ((io = cast(int) comment.text.indexOf("----------")) > 0)
			comment.text = comment.text[0 .. io].replace("&amp;", "&");
		
		comment.text = comment.text.replace("<br />\n", "").strip();
		
		comments ~= comment;
	}
	return comments;
}


/// wrapper for getWebforumComments && getArticleComments
Comment[] getComments(string url){
	string url_l = url.toLower();
	if (url_l.indexOf("webforum/show") > 0 || url_l.indexOf("bugtrack/show") > 0 || url_l.indexOf("hardware/show") > 0)
		return getWebforumComments(url);
	else if (url_l.indexOf("discussion/main") > 0 || url_l.indexOf("/comments") > 0)
		return getArticleComments(url);
	
	throw new Exception("Unknown type of URL!");
}
