package br.unicamp.ic.miner.domain.jira;

import com.thoughtworks.xstream.annotations.XStreamAlias;
import com.thoughtworks.xstream.annotations.XStreamAsAttribute;
import com.thoughtworks.xstream.annotations.XStreamConverter;
import com.thoughtworks.xstream.annotations.XStreamOmitField;
import com.thoughtworks.xstream.converters.extended.ToAttributedValueConverter;

import br.unicamp.ic.miner.domain.core.IssueComment;

@XStreamAlias("comment")
@XStreamConverter(value=ToAttributedValueConverter.class, strings={"message"})
public class Comment implements IssueComment{
	
	@XStreamAsAttribute 
	private String id;
	
	@XStreamAsAttribute 
	private String author;
	
	@XStreamAsAttribute 
	private String created;
	
	@XStreamOmitField
	private String message;
	
	public String getId() {
		return id;
	}
	public String getAuthor() {
		return author;
	}
	public String getCreated() {
		return created;
	}
	public String getMessage() {
		return message;
	}
}
