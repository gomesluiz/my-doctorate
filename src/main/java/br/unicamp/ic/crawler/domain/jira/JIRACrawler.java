package br.unicamp.ic.crawler.domain.jira;

import java.util.List;

import org.apache.logging.log4j.Logger;

import br.unicamp.ic.crawler.domain.core.Dataset;
import br.unicamp.ic.crawler.domain.core.IssueEntry;
import br.unicamp.ic.crawler.domain.core.IssueEntryActivity;
import br.unicamp.ic.crawler.persistence.IssueParser;
import br.unicamp.ic.crawler.services.IssueCrawler;
import br.unicamp.ic.crawler.services.filters.IssueFilter;

/**
 * Extract information from Jira issues.
 * 
 * @author Luiz Alberto
 * @version 1.0
 * 
 */
public class JIRACrawler extends IssueCrawler {

	private IssueParser converter;

	/**
	 * Constructs a IssueJiraExtraxtor instance.
	 * 
	 * @param dataset
	 *            TODO
	 * @param dataset
	 *            TODO
	 * @param converter
	 * @param logger
	 *            TODO
	 * @param logger
	 */
	public JIRACrawler(Dataset dataset, IssueParser converter, Logger logger) {
		this.converter = converter;
		this.dataset = dataset;
		this.converter = converter;
		this.logger = logger;
	}

	@Override
	public String formatRemoteIssueUrl(int key) {
		String name = dataset.getNameWithKey(key).toUpperCase();
		return String.format(dataset.getRemoteIssueUrl(), name, name);
	}

	@Override
	public String formatRemoteIssueHistoryUrl(int key) {
		String name = dataset.getNameWithKey(key).toUpperCase();
		return String.format(dataset.getRemoteIssueHistoryUrl(), name);
	}

	@Override
	public void search(IssueFilter filter) {
		// TODO Auto-generated method stub

	}

	@Override
	public String readFrom(String url) {
		String contents = null;
		try {
			 contents = readContents(url);
		} catch (Exception e) {
			logger.trace(e.getMessage());
		}
		return contents;
	}

}
