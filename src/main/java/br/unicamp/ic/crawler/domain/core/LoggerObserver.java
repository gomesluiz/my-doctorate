package br.unicamp.ic.crawler.domain.core;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class LoggerObserver extends CrawlerObserver {

	private Subject subject;
	private Logger logger;
	public LoggerObserver(Subject subject) {
		this.logger = LogManager.getRootLogger();
		this.subject = subject;
		this.subject.add(this);
	}
	@Override
	public void update() {
		logger.trace(subject.getMessage());
	}

}
