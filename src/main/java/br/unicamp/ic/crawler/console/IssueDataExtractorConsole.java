package br.unicamp.ic.crawler.console;

import java.util.Arrays;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import br.unicamp.ic.crawler.domain.core.Crawler;
import br.unicamp.ic.crawler.domain.core.Dataset;
import br.unicamp.ic.crawler.persistence.CSVIssueFileWriter;
import br.unicamp.ic.crawler.persistence.CSVRawRecordFormatter;
import br.unicamp.ic.crawler.persistence.CSVRecordFormatter;
import br.unicamp.ic.crawler.persistence.IssueFileWriter;
import br.unicamp.ic.crawler.services.CrawlerFactory;
import br.unicamp.ic.crawler.services.IssueImporter;

/**
 * Application main class.
 *
 * @author Luiz Alberto
 * @since 2016-01-02
 */
public class IssueDataExtractorConsole {

	public static void main(final String[] args) {

		List<Dataset> datasets = Arrays.asList(
				new Dataset("mozilla" 
						, "https://bugzilla.mozilla.org/show_bug.cgi?ctype=xml&id=%d"
						//, "https://bugzilla.mozilla.org/show_activity.cgi?id=%d"
						, 283000
						, 283959));
		Logger logger = LogManager.getRootLogger();
		CSVRecordFormatter issuesDataFormatter = new CSVRawRecordFormatter();
		
		for (Dataset dataset : datasets) {
			String inPath = String.format("/home/luiz/Workspace/issue-crawler/data/%s/xml/", dataset.getName());
			String outPath = String.format("/home/luiz/Workspace/issue-crawler/data/%s/csv/", dataset.getName());
			Crawler in = CrawlerFactory.getCrawler(dataset, inPath);
			IssueFileWriter out = new CSVIssueFileWriter(outPath + "r50_issues_raw_data.csv", issuesDataFormatter);
			IssueImporter crawler = new IssueImporter(in, out, dataset, logger);
			logger.trace("Start " + dataset.getName() + " !");
			crawler.load(dataset);
			crawler.export();
			logger.trace("Finish " + dataset.getName() + " !");
		}
	}
}
