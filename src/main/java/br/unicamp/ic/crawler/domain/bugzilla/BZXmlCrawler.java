package br.unicamp.ic.crawler.domain.bugzilla;

import java.util.ArrayList;

import org.apache.logging.log4j.Logger;

import br.unicamp.ic.crawler.domain.core.Dataset;
import br.unicamp.ic.crawler.domain.core.IssueNode;
import br.unicamp.ic.crawler.persistence.IssueRepository;
import br.unicamp.ic.crawler.persistence.URLResource;
import br.unicamp.ic.crawler.services.IssueCrawler;
import br.unicamp.ic.crawler.services.IssueParser;
import br.unicamp.ic.crawler.services.filters.IssueFilter;

/**
 * Extract information Bugzilla Tracking Systems.
 * 
 * @author Luiz Alberto
 * @version 1.0
 * 
 */
public class BZXmlCrawler extends IssueCrawler {

	/**
	 * Constructs a IssueJiraExtraxtor instance.
	 * 
	 * @param dataset
	 *            TODO
	 * @param converter
	 * @param logger
	 *            TODO
	 * @param repository
	 *            TODO
	 */
	public BZXmlCrawler(Dataset dataset, IssueParser converter, Logger logger, IssueRepository repository) {
		this.dataset = dataset;
		this.logger = logger;
		this.issues = new ArrayList<IssueNode>();
		this.repository = repository;
	}

	@Override
	public String downloadFrom(String url) {
		String contents = null;
		try {
			URLResource urlResource = new URLResource(url);
			contents = urlResource.asString();

			String buffer = contents.toLowerCase();
			if (buffer.contains("<bug error=\"" + "invalidbugid" + "\"" + ">")
					|| buffer.contains("<bug error=\"" + "notfound" + "\"" + ">"))
				contents = null;
		} catch (Exception e) {
			logger.trace(e);
		}

		return contents;
	}

	@Override
	public String formatRemoteIssueUrl(int key) {
		return String.format(dataset.getRemoteIssueUrl(), key);
	}

	@Override
	public String formatRemoteIssueHistoryUrl(int key) {
		return String.format(dataset.getRemoteIssueHistoryUrl(), key);
	}

	@Override
	public void search(IssueFilter filter) {
		issues = filter.filter(issues);
	}

}
