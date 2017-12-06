package br.unicamp.ic.miner.domain.core;

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
	private int children;
	private int parents;
	private double peso;
	private int depthOfTree;

	private IssueEntry entry;

	public IssueNode(IssueEntry entry) {
		this.entry = entry;
		this.comments = new ArrayList<IssueComment>();
		this.depthOfTree = 0;
		this.children = 0;
		this.parents = 0;
		this.peso = 0.0;
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
	 * @param c
	 *            issue comment
	 */
	public void addComment(IssueComment c) {
		this.comments.add(c);

	}

	public List<IssueComment> getComments() {
		return this.comments;
	}

	/**
	 * Return issue weight();
	 * 
	 * @return
	 */
	public int getWeight() {
		int weight = 0;
		switch (this.getType()) {
		case "Bug":
			weight = 6;
			break;
		case "Improvement":
			weight = 5;
			break;
		case "New Feature":
			weight = 4;
			break;
		case "Task":
			weight = 3;
			break;
		case "Custom Issue":
			weight = 2;
			break;
		}
		return weight;
	}

	public String getTypeCode() {
		return entry.convertTypeToCode();
	}

	public String getSeverityCode() {
		return entry.convertSeverityToCode();
	}

	public int getDaysToResolve() {

		return entry.getDaysToResolve();
	}

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

	public int getQuantityOfCharactersInDescription() {
		return getDescription().length();
	}

	public int getQuantityOfWordsInTitle() {
		return getTitle().split("\\w+").length;
	}

	public int getQuantityOfCharactersInTitle() {
		return getTitle().length();
	}

	public int getParents() {
		return this.parents;
	}

	public void updateParents(int parents) {
		if (parents > this.parents)
			this.parents = parents;
	}

	public int getChildren() {
		return this.children;
	}

	public void updateChildren(int children) {
		if (children > this.children)
			this.children = children;
	}

	public int getWeightedAveragePriority() {
		return (int) (Math.random() * 15 + 1);
	}

	public int getParentsWeightedAveragePriority() {
		return (int) (Math.random() * 15 + 1);
	}

	public int ChildrenWeightedAveragePriority() {
		return (int) (Math.random() * 15 + 1);
	}

	public int getRelatedNodes() {
		return (int) (Math.random() * 15 + 1);
	}

	public void updateWeigth(double d) {
		if (d > this.peso)
			this.peso = d;

	}

	public double getPeso() {
		return this.peso;
	}

	public void updateDepthOfTree(int depth) {
		this.depthOfTree = depth;

	}

	public int getDepthOfTree() {
		return this.depthOfTree;
	}

	public String toString() {
		return "Issue [key=" + getKey() + ", title=" + getTitle() + "]";
	}

}
