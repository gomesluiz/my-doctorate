package br.unicamp.ic.miner.console;

import java.util.Arrays;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import br.unicamp.ic.miner.domain.bugzilla.BZIssueEntry;
import br.unicamp.ic.miner.domain.bugzilla.BZIssuesImporter;
import br.unicamp.ic.miner.domain.core.IssueExtractor;
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

		List<String> datasets = Arrays.asList(new String[] { "ooo"});

		for (String dataset : datasets) {

			Logger logger = LogManager.getRootLogger();

			String inPath = String.format("/home/luiz/Workspace/maintenance-assistant/data/%s/xml/",
					dataset.toLowerCase());
			IssueFileReader reader;
			IssueRemoteRepository in;
			if (dataset.equals("ooo")) {
				reader = new XmlReader(inPath, BZIssueEntry.class);
				in = new BZIssuesImporter(reader, dataset, logger);
			} else {
				reader = new XmlReader(inPath, JIRAIssueEntry.class);
				in = new JIRAIssuesImporter(reader, dataset, logger);
			}
			CSVRecordFormatter issuesDataFormatter = new CSVRawRecordFormatter();
			String outPath = String.format("/home/luiz/Workspace/maintenance-assistant/data/%s/csv/",
					dataset.toLowerCase());

			IssueFileWriter out = new CSVIssueFileWriter(outPath + "r49_issues_raw_data.csv", issuesDataFormatter);
			IssueExtractor miner = new IssueExtractor(in, out);

			logger.trace("Start " + dataset + " !");
			miner.load(117725, 117726);
			miner.export();
			logger.trace("Finish " + dataset + " !");
		}
	}
}
