package br.unicamp.ic.crawler.domain.bugzilla;

import com.thoughtworks.xstream.annotations.XStreamAsAttribute;
import com.thoughtworks.xstream.annotations.XStreamOmitField;

import br.unicamp.ic.crawler.domain.core.IssueComment;

//@XStreamAlias("comment")
//@XStreamConverter(value=ToAttributedValueConverter.class, strings={"message"})
public class BZIssueComment implements IssueComment{
	
	@XStreamAsAttribute 
	private String commentid;
	
	@XStreamAsAttribute 
	private String who;
	
	@XStreamAsAttribute 
	private String bug_when;
	
	@XStreamOmitField
	private String thetext;
	
	public String getId() {
		return commentid;
	}
	public String getAuthor() {
		return who;
	}
	public String getCreated() {
		return bug_when;
	}
	public String getMessage() {
		return thetext;
	}
}
