package br.unicamp.ic.crawler.services;

import br.unicamp.ic.crawler.domain.bugzilla.BZCrawler;
import br.unicamp.ic.crawler.domain.core.Crawler;
import br.unicamp.ic.crawler.domain.core.Dataset;
import br.unicamp.ic.crawler.domain.jira.JIRACrawler;
import br.unicamp.ic.crawler.persistence.IssueFileReader;
import br.unicamp.ic.crawler.persistence.XmlReader;

public class CrawlerFactory {
	
	public static Crawler getCrawler(Dataset dataset, String inPath) {
		Crawler crawler;
		//
		IssueFileReader reader = new XmlReader(inPath);;
		if (dataset.getName().equals("mozilla")) {
			crawler = new BZCrawler(reader);
		} else {
			crawler = new JIRACrawler(reader);
		}
		return crawler;
	}

}
