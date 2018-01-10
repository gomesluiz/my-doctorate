package br.unicamp.ic.crawler.domain.bugzilla;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.apache.logging.log4j.Logger;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

import br.unicamp.ic.crawler.domain.core.Dataset;
import br.unicamp.ic.crawler.domain.core.IssueEntry;
import br.unicamp.ic.crawler.domain.core.IssueEntryActivity;
import br.unicamp.ic.crawler.domain.core.IssueNode;
import br.unicamp.ic.crawler.persistence.FileResource;
import br.unicamp.ic.crawler.persistence.FormatConverter;
import br.unicamp.ic.crawler.services.IssueCrawler;
import br.unicamp.ic.crawler.services.filters.IssueFilter;

/**
 * Extract information Bugzilla Tracking Systems.
 * 
 * @author Luiz Alberto
 * @version 1.0
 * 
 */
public class BZXmlCrawler extends IssueCrawler {
	private FormatConverter xmlConverter;
	
	/**
	 * Constructs a IssueJiraExtraxtor instance.
	 * 
	 * @param dataset
	 *            TODO
	 * @param converter
	 * @param logger
	 *            TODO
	 */
	public BZXmlCrawler(Dataset dataset, FormatConverter converter, Logger logger) {
		this.dataset = dataset;
		this.xmlConverter = converter;
		this.logger = logger;
		this.issues = new ArrayList<IssueNode>();
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
		if (issues.size() == 0) {
			issues = loadIssuesFromFile();
		}
		issues = filter.filter(issues);
	}

	@Override
	public String readFrom(String url) {
		String contents = null;
		try {
			contents = readContents(url);
			
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
	public IssueEntry parse(String contents) {
		return (BZIssueEntry) xmlConverter.load(contents, BZIssueEntry.class);
	}

	@Override
	public List<IssueEntryActivity> extract(int key) {
		List<IssueEntryActivity> activities = new ArrayList<IssueEntryActivity>();
		if (key == -1)
			return activities;

		File file = new File(dataset.formatLocalIssueHistoryFileName(key));
		logger.trace(file.getName());
		FileResource fileResource = new FileResource(file);
		String contents = fileResource.asString();
		Document doc = Jsoup.parse(contents);
		Element table = doc.select("table").get(0);
		Elements rows = table.select("tr");
		String who = "", when = "", what = "", removed = "", added = "";
		for (int j = 1; j < rows.size(); j++) {
			int columns = rows.get(j).select("td").size();
			int shift = columns - 3;
			if (columns == 5) {
				who = rows.get(j).select("td").get(0).text();
				when = rows.get(j).select("td").get(1).text();
			}
			what = rows.get(j).select("td").get(shift).text();
			removed = rows.get(j).select("td").get(shift + 1).text();
			added = rows.get(j).select("td").get(shift + 2).text();
			BZIssueEntryActivity activity = new BZIssueEntryActivity(who, when, what, removed, added);
			activities.add(activity);
		}
		return activities;
	}
}
