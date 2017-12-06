package br.unicamp.ic.miner.domain.core;

import java.util.ArrayList;
import java.util.List;

/**
 * 
 * @author luiz
 *
 */
public abstract class IssueRemoteRepository {

	protected List<IssueNode> issues;
	protected IssueForest forest;

	public abstract IssueNode read(String url);

	// public abstract void extractForest();
	public abstract void extractIssuesFrom(int start, int end);

	// public abstract void extractTopologicalData();
	protected abstract boolean urlPatternMatch(String url);

	/**
	 * 
	 * @return
	 */
	public List<IssueNode> getIssues() {
		return this.issues;
	}

	/**
	 * 
	 * @return
	 */
	public IssueForest getForest() {
		return forest;
	}

	/**
	 * A template method to extract url from a string source.
	 * 
	 * @param source
	 *            string source to extract urls.
	 * @return a list of urls extracted.
	 */
	public List<String> extractLinks(String source) {
		List<String> links = new ArrayList<String>();
		int start = 0;
		try {
			while (true) {
				int index = source.indexOf("href=", start);
				if (index < 0) {
					break;
				}
				int firstQuote = index + 6;
				int endQuote = source.indexOf("\"", firstQuote);
				if (endQuote < 0) {
					break;
				}
				String link = source.substring(firstQuote, endQuote);
				if (link.startsWith("http")) {
					if (urlPatternMatch(link)) {
						links.add(link);
					}
				}
				start = endQuote + 1;
			}
		} catch (Exception e) {
			e.printStackTrace();
		}

		return links;
	}

	/**
	 * 
	 * @param issue
	 * @param children
	 */
	public void updateChildren(IssueNode issue, int children) {
		for (IssueNode e : issues) {
			if (e.getKey().equals(issue.getKey())) {
				if (issue.getKey().equals("HADOOP-1252"))
					System.out.println(" Ke= " + issue.getKey() + " Chil = " + children);

				e.updateChildren(children);
			}
		}

	}

}