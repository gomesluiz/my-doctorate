package br.unicamp.ic.crawler.domain.jira;

import java.util.ArrayList;
import java.util.List;

import br.unicamp.ic.crawler.domain.core.ReportCrawler;
import br.unicamp.ic.crawler.domain.core.IssueParser;
import br.unicamp.ic.crawler.domain.core.Project;
import br.unicamp.ic.crawler.domain.core.Report;
import br.unicamp.ic.crawler.domain.core.filters.IssueFilter;
import br.unicamp.ic.crawler.persistence.URLResource;

/**
 * Extract information from Jira issues.
 * 
 * @author Luiz Alberto
 * @version 1.0
 * 
 */
public class JIRACrawler extends ReportCrawler {

	private IssueParser converter;

	/**
	 * Constructs a IssueJiraExtraxtor instance.
	 * 
	 * @param dataset
	 *            TODO
	 * @param dataset
	 *            TODO
	 * @param converter
	 */
	public JIRACrawler(Project dataset, IssueParser converter) {
		this.converter = converter;
		this.project = dataset;
		this.converter = converter;
	}

	@Override
	public String formatRemoteIssueUrl(int key) {
		String name = project.getNameWithKey(key).toUpperCase();
		return String.format(project.getRemoteIssueUrl(), name, name);
	}

	@Override
	public String formatRemoteIssueHistoryUrl(int key) {
		String name = project.getNameWithKey(key).toUpperCase();
		return String.format(project.getRemoteIssueHistoryUrl(), name);
	}

	@Override
	public List<Report> search(IssueFilter filter) {
		return new ArrayList<Report>();

	}

	@Override
	public String downloadFrom(String url) {
		String contents = null;
		try {
			URLResource urlResource = new URLResource(url);
			contents = urlResource.asString();
		} catch (Exception e) {
			subject.setMessage(e.getMessage());
		}
		return contents;
	}

}
