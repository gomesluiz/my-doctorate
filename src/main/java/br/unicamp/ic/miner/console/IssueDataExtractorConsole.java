package br.unicamp.ic.miner.console;

import java.util.Arrays;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import br.unicamp.ic.miner.domain.bugzilla.BZIssueEntry;
import br.unicamp.ic.miner.domain.bugzilla.BZIssuesImporter;
import br.unicamp.ic.miner.domain.core.Dataset;
import br.unicamp.ic.miner.domain.core.IssueCrawler;
import br.unicamp.ic.miner.domain.core.IssueRemoteRepository;
import br.unicamp.ic.miner.domain.jira.JIRAIssueEntry;
import br.unicamp.ic.miner.domain.jira.JIRAIssuesImporter;
import br.unicamp.ic.miner.infrastructure.persistence.CSVIssueFileWriter;
import br.unicamp.ic.miner.infrastructure.persistence.CSVRawRecordFormatter;
import br.unicamp.ic.miner.infrastructure.persistence.CSVRecordFormatter;
import br.unicamp.ic.miner.infrastructure.persistence.IssueFileReader;
import br.unicamp.ic.miner.infrastructure.persistence.IssueFileWriter;
import br.unicamp.ic.miner.infrastructure.persistence.XmlReader;

/**
 * Application main class.
 *
 * @author Luiz Alberto
 * @since 2016-01-02
 */
public class IssueDataExtractorConsole {

	public static void main(final String[] args) {

		List<Dataset> datasets = Arrays.asList(new Dataset("mozilla", "https://bugzilla.mozilla.org/show_bug.cgi?ctype=xml&id=%d", 283949, 283959));

		for (Dataset dataset : datasets) {

			Logger logger = LogManager.getRootLogger();

			String inPath = String.format("/home/luiz/Workspace/issue-crawler/data/%s/xml/",dataset.getName());
			IssueFileReader reader;
			IssueRemoteRepository in;
			if (dataset.getName().equals("mozilla")) {
				reader = new XmlReader(inPath, BZIssueEntry.class);
				in = new BZIssuesImporter(reader, dataset, logger);
			} else {
				reader = new XmlReader(inPath, JIRAIssueEntry.class);
				in = new JIRAIssuesImporter(reader, dataset, logger);
			}
			CSVRecordFormatter issuesDataFormatter = new CSVRawRecordFormatter();
			String outPath = String.format("/home/luiz/Workspace/issue-crawler/data/%s/csv/",
					dataset.getName());

			IssueFileWriter out = new CSVIssueFileWriter(outPath + "r50_issues_raw_data.csv", issuesDataFormatter);
			IssueCrawler crawler = new IssueCrawler(in, out);

			logger.trace("Start " + dataset.getName() + " !");
			crawler.load(dataset.getFirst(), dataset.getLast());
			//miner.export();
			logger.trace("Finish " + dataset.getName() + " !");
		}
	}
}
