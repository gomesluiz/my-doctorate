package br.unicamp.ic.crawler.services;

import org.apache.logging.log4j.Logger;

import br.unicamp.ic.crawler.domain.bugzilla.BZXmlCrawler;
import br.unicamp.ic.crawler.domain.bugzilla.BZIssueParserInXml;
import br.unicamp.ic.crawler.domain.core.Dataset;
import br.unicamp.ic.crawler.domain.jira.JIRACrawler;

public class CrawlerFactory {
	
	public static final String BTS_BUGZILLA = "bugzilla";
	public static final String BTS_JIRA = "jira";
	
	public static IssueCrawler getInstance(Dataset dataset, Logger logger) {
		IssueCrawler crawler = null;
		//
		IssueParser converter = new BZIssueParserInXml();
		if (dataset.getBts().equals(BTS_BUGZILLA)) {
			crawler = new BZXmlCrawler(dataset, converter, logger, null);
		} else if (dataset.getBts().equals(BTS_JIRA)) {
			crawler = new JIRACrawler(dataset, converter, logger);
		}
		return crawler;
	}

}
