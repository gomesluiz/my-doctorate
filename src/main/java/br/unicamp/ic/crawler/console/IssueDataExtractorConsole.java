package br.unicamp.ic.crawler.console;

import java.util.Arrays;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import br.unicamp.ic.crawler.domain.core.Dataset;
import br.unicamp.ic.crawler.persistence.CSVIssueFileWriter;
import br.unicamp.ic.crawler.persistence.CSVOutputFormatter;
import br.unicamp.ic.crawler.persistence.CSVRawIssueFormatter;
import br.unicamp.ic.crawler.persistence.IssueFileWriter;
import br.unicamp.ic.crawler.services.CrawlerFactory;
import br.unicamp.ic.crawler.services.IssueCrawler;

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
						, "/home/luiz/Workspace/issue-crawler/data/mozilla/xml/"
						, "xml"
						, "https://bugzilla.mozilla.org/show_activity.cgi?id=%d"
						, "/home/luiz/Workspace/issue-crawler/data/mozilla/xml/"
						, "html"
						, "MOZILLA-%d"
						, 5001
						, 10000
						, CrawlerFactory.BTS_BUGZILLA)
				, new Dataset("eclipse" 
						, "https://bugs.eclipse.org/bugs/show_bug.cgi?ctype=xml&id=%d"
						, "/home/luiz/Workspace/issue-crawler/data/eclipse/xml/"
						, "xml"
						, "https://bugs.eclipse.org/bugs/show_activity.cgi?id=%d"
						, "/home/luiz/Workspace/issue-crawler/data/eclipse/xml/"
						, "html"
						, "ECLIPSE-%d"
						, 5001
						, 10000
						, CrawlerFactory.BTS_BUGZILLA)
				, new Dataset("ooo" 
						, "https://bz.apache.org/ooo/show_bug.cgi?ctype=xml&id=%d"
						, "/home/luiz/Workspace/issue-crawler/data/ooo/xml/"
						, "xml"
						, "https://bz.apache.org/ooo/show_activity.cgi?id=%d"
						, "/home/luiz/Workspace/issue-crawler/data/ooo/xml/"
						, "html"
						, "OOO-%d"
						, 1
						, 5000
						, CrawlerFactory.BTS_BUGZILLA)
				, new Dataset("netbeans" 
						, "https://netbeans.org/bugzilla/show_bug.cgi?ctype=xml&id=%d"
						, "/home/luiz/Workspace/issue-crawler/data/netbeans/xml/"
						, "xml"
						, "https://netbeans.org/bugzilla/show_activity.cgi?id=%d"
						, "/home/luiz/Workspace/issue-crawler/data/netbeans/xml/"
						, "html"
						, "NETBEANS-%d"
						, 1
						, 5000
						, CrawlerFactory.BTS_BUGZILLA));
		Logger logger = LogManager.getRootLogger();
		CSVOutputFormatter formatter = new CSVRawIssueFormatter();
		IssueFileWriter output = new CSVIssueFileWriter("r50", formatter);
		
		for (Dataset dataset : datasets) {
			IssueCrawler crawler = CrawlerFactory.getInstance(dataset, logger);
			logger.trace("Start " + dataset.getName() + " !");
			crawler.downloadAll();
			//crawler.search(new IssueNoFilter());
			//crawler.search(new IssueFilterByStatus("Resolved"));
			//crawler.export(output);
			logger.trace("Finish " + dataset.getName() + " !");
		}
	}
}
