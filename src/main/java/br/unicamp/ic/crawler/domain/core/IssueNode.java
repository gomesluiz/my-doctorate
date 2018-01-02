package br.unicamp.ic.crawler.domain.core;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

/**
 * The <code>Issue</code> represents an maintenance software issue.
 * 
 * @author Luiz Alberto
 * @version 1.0
 * @since 2016-05-24
 * 
 */
public class IssueNode {
	static final Pattern REMOVE_TAGS = Pattern.compile("<.+?>");

	private List<IssueComment> comments;

	private IssueEntry entry;

	public IssueNode(IssueEntry entry) {
		this.entry = entry;
		this.comments = new ArrayList<IssueComment>();
	}

	/**
	 * Returns issue key.
	 * 
	 * @return Issue key.
	 */
	public String getKey() {
		return entry.getKey();
	}

	/**
	 * Returns creation date issue.
	 * 
	 * @return the creation date
	 */
	public String getCreated() {
		return entry.getCreated();
	}

	/**
	 * Returns issue description.
	 * 
	 * @return description.
	 */
	public String getDescription() {
		return entry.getDescription();
	}

	/**
	 * Returns issue priority.
	 * 
	 * @return priority
	 */
	public String getSeverity() {
		return entry.getSeverity();
	}

	/**
	 * Returns resolve date issue.
	 * 
	 * @return the resolve date.
	 */
	public String getResolved() {
		return entry.getResolved();
	}

	/**
	 * Returns resolution action.
	 * 
	 * @return the resolution action.
	 */
	public String getResolution() {
		return entry.getResolution();
	}

	/**
	 * Return issue status.
	 * 
	 * @return the issue status.
	 */
	public String getStatus() {
		return entry.getStatus();
	}

	/**
	 * Returns issue type.
	 * 
	 * @return issue type.
	 */
	public String getType() {
		return entry.getType();
	}

	/**
	 * Returns update date issue.
	 * 
	 * @return the update date.
	 */
	public String getUpdated() {
		return entry.getUpdated();
	}

	/**
	 * Adds comment to <code>comments</code> list.
	 * 
	 * @param c issue comment
	 */
	public void addComment(IssueComment c) {
		this.comments.add(c);

	}

	/**
	 * Gets a collection of issues comments.
	 * 
	 * @return collection of comments.
	 */
	public List<IssueComment> getComments() {
		return this.comments;
	}

	/**
	 * Gets the issue type code.
	 * 
	 * @return type code
	 */
	public String getTypeCode() {
		return entry.convertTypeToCode();
	}

	/**
	 * Gets the issue severity code.
	 * 
	 * @return severity code
	 */
	public String getSeverityCode() {
		return entry.convertSeverityToCode();
	}

	/**
	 * Gets days to resolve a issue.
	 * 
	 * @return days to resolve
	 */
	public int getDaysToResolve() {

		return entry.getDaysToResolve();
	}

	/**
	 * Gets the issue resolution code 
	 * @return
	 */
	public String getResolutionCode() {
		return entry.convertResolutionToCode();
	}

	public String getStatusCode() {
		return entry.converteStatusToCode();
	}

	public int getQuantityOfComments() {
		List<IssueComment> comments = this.getComments();
		return comments.size();
	}

	public String getAssignee() {
		return entry.getAssignee();
	}

	public String getTitle() {
		return entry.getTitle();
	}

	public String getVotes() {
		return entry.getVotes();
	}

	public int getQuantityOfLinesInDescription() {
		int quantityOfLines = 0;
		if (getQuantityOfCharactersInDescription() > 0) {
			quantityOfLines = getDescription().split("\r\n|\r|\n").length;
		}
		return quantityOfLines;

	}

	public int getQuantityOfWordsInDescription() {
		int quantityOfWords = 0;
		if (getQuantityOfCharactersInDescription() > 0) {
			quantityOfWords = getDescription().split("\\w+").length;
		}

		return quantityOfWords;
	}

	public List<IssueEntryActivity> getActivities(){
		return entry.getActivities();
	}
	public int getQuantityOfCharactersInDescription() {
		return getDescription().length();
	}

	public int getQuantityOfWordsInTitle() {
		return getTitle().split("\\w+").length;
	}

	public int getQuantityOfCharactersInTitle() {
		return getTitle().length();
	}

	public String toString() {
		return "Issue [key=" + getKey() + ", title=" + getTitle() + "]";
	}

}
