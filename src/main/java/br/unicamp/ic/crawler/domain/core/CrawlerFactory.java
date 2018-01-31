package br.unicamp.ic.crawler.domain.core;

import br.unicamp.ic.crawler.domain.bugzilla.BZHistoryParserInHtml;
import br.unicamp.ic.crawler.domain.bugzilla.BZIssueParserInXml;
import br.unicamp.ic.crawler.domain.bugzilla.BZXmlCrawler;
import br.unicamp.ic.crawler.domain.jira.JIRACrawler;
import br.unicamp.ic.crawler.persistence.ReportRepositoryFromFile;
import br.unicamp.ic.crawler.persistence.ReportRepository;

public class CrawlerFactory {

	public static final String BTS_BUGZILLA = "bugzilla";
	public static final String BTS_JIRA = "jira";

	public static ReportCrawler getInstance(Project project) {
		ReportCrawler crawler = null;
		//
		if (project.getBts().equals(BTS_BUGZILLA)) {
			ReportPasser issueParser = new BZIssueParserInXml();
			HistoryParser historyParser = new BZHistoryParserInHtml();
			ReportRepository repository = new ReportRepositoryFromFile(project, issueParser, historyParser);
			crawler = new BZXmlCrawler(project, repository);
		} else if (project.getBts().equals(BTS_JIRA)) {
			crawler = new JIRACrawler(project, null);
		}
		return crawler;
	}

}
