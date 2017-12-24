package br.unicamp.ic.crawler.services;

import java.util.ArrayList;
import java.util.List;

import org.apache.logging.log4j.Logger;

import br.unicamp.ic.crawler.domain.core.Crawler;
import br.unicamp.ic.crawler.domain.core.Dataset;
import br.unicamp.ic.crawler.domain.core.IssueNode;
import br.unicamp.ic.crawler.persistence.IssueFileWriter;

/**
 * 
 * @author Luiz Alberto
 *
 */
public class IssueImporter {

	private List<IssueNode> issues;
	private Dataset dataset;
	private Logger logger;
	private Crawler from;
	private IssueFileWriter to;

	/**
	 * 
	 * @param from
	 */
	public IssueImporter(Crawler from, IssueFileWriter to, Dataset dataset, Logger logger) {
		this.from = from;
		this.to = to;
		this.logger = logger;
		this.dataset = dataset;
	}

	/**
	 * Load issues from source.
	 * @param dataset TODO
	 */
	public void load(Dataset dataset) {
		this.extractIssuesFrom(dataset.getFirst(), dataset.getLast());
	}

	/**
	 * 
	 */

	public void export() {
		to.write(this.getIssues());
	}

	public void export(IssueFileWriter writer) {
		this.to = writer;
		this.export();
	}

	/**
	 * Extracts an issue by its number.
	 * 
	 * @param number
	 *            number of issue.
	 * @return an instance of <code>Issue</code> class.
	 */
	public IssueNode extractIssue(int number) {
		return extractFrom(String.format(dataset.formatUrl(number)));
	}

	/**
	 * 
	 * @param start
	 * @param end
	 */
	public void extractIssuesFrom(int start, int end) {
		issues = new ArrayList<IssueNode>();
		for (int i = start; i <= end; i++) {
			
			try {
				IssueNode issue = this.extractIssue(i);
				if (issue != null) {
					issues.add(issue);
				} 
			} catch (Exception e) {
				logger.trace(e.getMessage());
			}
		}
	}

	/**
	 * 
	 * @param link
	 * @return
	 */
	protected IssueNode extractFrom(String link) {
		IssueNode issue = null;
		try {
			logger.trace(link);
			issue = from.extractFrom(link);
		} catch (Exception e) {
			throw new RuntimeException(e.getMessage());
		}
		return issue;
	}

	/**
	 * 
	 * @return
	 */
	public List<IssueNode> getIssues() {
		return this.issues;
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
					if (from.urlPatternMatch(link)) {
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

}