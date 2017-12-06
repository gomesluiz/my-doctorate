package br.unicamp.ic.miner.domain.core;

import java.util.ArrayList;
import java.util.List;

import org.joda.time.DateTime;
import org.joda.time.format.DateTimeFormat;
import org.joda.time.format.DateTimeFormatter;

/**
 * Issue builder class.
 * 
 * @author Luiz Alberto
 *
 */
public class IssueNodeBuilder {

	private String issueKey;
	private String description;
	private String type;
	private String priority;
	private String created;
	private String updated;
	private String resolved;
	private String resolution;
	private String status;
	private List<IssueComment> comments;
	private String assignee;
	private String title;
	private String votes;
	private int daysToResolve;

	public IssueNodeBuilder(String key, String description) {

		DateTimeFormatter fmt = DateTimeFormat.forPattern("EEE, d MMM yyyy HH:mm:ss Z");
		String today = fmt.print(new DateTime());
		this.issueKey = key;
		this.description = description;
		this.comments = new ArrayList<IssueComment>();
		this.created = today;
		this.resolved = today;
		this.updated = today;
		this.daysToResolve = 0;
	}

	public IssueNodeBuilder withType(String type) {
		this.type = type;
		return this;
	}

	public IssueNodeBuilder withPriority(String priority) {
		this.priority = priority;
		return this;
	}

	public IssueNodeBuilder withCreated(String date) {
		if ((date == null) || (date.equals("")))
			return this;
		this.created = date;
		return this;
	}

	public IssueNodeBuilder withUpdated(String date) {
		if ((date == null) || (date.equals("")))
			return this;
		this.updated = date;
		return this;
	}

	public IssueNodeBuilder withResolved(String date) {
		if ((date == null) || (date.equals("")))
			return this;

		this.resolved = date;
		return this;
	}

	public IssueNodeBuilder withResolution(String resolution) {
		this.resolution = resolution;
		return this;
	}

	public IssueNodeBuilder withStatus(String status) {
		this.status = status;
		return this;
	}
	
	public IssueNodeBuilder withComments(List<IssueComment> comments) {
		if (comments == null)
			return this;
		this.comments = comments;
		return this;
	}

	public IssueNodeBuilder withAssignee(String assignee) {
		this.assignee = assignee;
		return this;
	}

	public IssueNodeBuilder withTitle(String title) {
		this.title = title;
		return this;
	}

	public IssueNodeBuilder withVotes(String votes) {
		this.votes = votes;
		return this;
	}
	
	public IssueNodeBuilder withDaysToResolve(int daysToResolve) {
		this.daysToResolve = daysToResolve;
		return this;
	}
	
	public IssueNode build() {
		IssueNode issue = null;

		for (IssueComment c : this.comments) {
			issue.addComment(c);
		}
		return issue;
	}

}
