package br.unicamp.ic.crawler.console;

import java.util.Arrays;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import br.unicamp.ic.crawler.domain.core.CrawlerFactory;
import br.unicamp.ic.crawler.domain.core.ReportCrawler;
import br.unicamp.ic.crawler.domain.core.Project;
import br.unicamp.ic.crawler.domain.core.filters.IssueFilterByResolution;
import br.unicamp.ic.crawler.domain.core.filters.IssueFilterByStatus;
import br.unicamp.ic.crawler.domain.core.filters.IssueFilterOutBySeverity;
import br.unicamp.ic.crawler.persistence.CSVIssueFileWriter;
import br.unicamp.ic.crawler.persistence.CSVOutputFormatter;
import br.unicamp.ic.crawler.persistence.CSVRawIssueFormatter;
import br.unicamp.ic.crawler.persistence.IssueFileWriter;

/**
 * Application main class.
 *
 * @author Luiz Alberto
 * @since 2016-01-02
 */
public class IssueDataCrawlerConsole {

	public static void main(final String[] args) {

		List<Project> datasets = Arrays.asList(
				new Project("mozilla", "https://bugzilla.mozilla.org/show_bug.cgi?ctype=xml&id=%d",
						"/home/luiz/Workspace/issue-crawler/data/mozilla/xml/", "xml",
						"https://bugzilla.mozilla.org/show_activity.cgi?id=%d",
						"/home/luiz/Workspace/issue-crawler/data/mozilla/xml/", "html", "MOZILLA-%d", 10000, 15000,
						CrawlerFactory.BTS_BUGZILLA),
				new Project("eclipse", "https://bugs.eclipse.org/bugs/show_bug.cgi?ctype=xml&id=%d",
						"/home/luiz/Workspace/issue-crawler/data/eclipse/xml/", "xml",
						"https://bugs.eclipse.org/bugs/show_activity.cgi?id=%d",
						"/home/luiz/Workspace/issue-crawler/data/eclipse/xml/", "html", "ECLIPSE-%d", 10000, 15000,
						CrawlerFactory.BTS_BUGZILLA),
				new Project("netbeans", "https://netbeans.org/bugzilla/show_bug.cgi?ctype=xml&id=%d",
						"/home/luiz/Workspace/issue-crawler/data/netbeans/xml/", "xml",
						"https://netbeans.org/bugzilla/show_activity.cgi?id=%d",
						"/home/luiz/Workspace/issue-crawler/data/netbeans/xml/", "html", "NETBEANS-%d", 10000, 15000,
						CrawlerFactory.BTS_BUGZILLA),
				new Project("ooo", "https://bz.apache.org/ooo/show_bug.cgi?ctype=xml&id=%d",
						"/home/luiz/Workspace/issue-crawler/data/ooo/xml/", "xml",
						"https://bz.apache.org/ooo/show_activity.cgi?id=%d",
						"/home/luiz/Workspace/issue-crawler/data/ooo/xml/", "html", "OOO-%d", 10000, 15000,
						CrawlerFactory.BTS_BUGZILLA),
				new Project("freedesktop", "https://bugs.freedesktop.org/show_bug.cgi?ctype=xml&id=%d",
						"/home/luiz/Workspace/issue-crawler/data/freedesktop/xml/", "xml",
						"https://bugs.freedesktop.org/show_activity.cgi?id=%d",
						"/home/luiz/Workspace/issue-crawler/data/freedesktop/xml/", "html", "FREEDESKTOP-%d", 10000,
						15000, CrawlerFactory.BTS_BUGZILLA),
				new Project("gnome", "https://bugzilla.gnome.org/show_bug.cgi?ctype=xml&id=%d",
						"/home/luiz/Workspace/issue-crawler/data/gnome/xml/", "xml",
						"https://bugzilla.gnome.org/show_activity.cgi?id=%d",
						"/home/luiz/Workspace/issue-crawler/data/gnome/xml/", "html", "GNOME-%d", 10000, 15000,
						CrawlerFactory.BTS_BUGZILLA),
				new Project("winehq", "https://bugs.winehq.org/show_bug.cgi?ctype=xml&id=%d",
						"/home/luiz/Workspace/issue-crawler/data/winehq/xml/", "xml",
						"https://bugs.winehq.org/show_activity.cgi?id=%d",
						"/home/luiz/Workspace/issue-crawler/data/winehq/xml/", "html", "WINEHQ-%d", 10000, 15000,
						CrawlerFactory.BTS_BUGZILLA),
				new Project("opennlp", "https://issues.apache.org/jira/si/jira.issueviews:issue-xml/%s/%s.xml",
						"/home/luiz/Workspace/issue-crawler/data/opennlp/xml/", "xml",
						"https://issues.apache.org/jira/browse/%s?page=com.atlassian.jira.plugin.system.issuetabpanels:changehistory-tabpanel",
						"/home/luiz/Workspace/issue-crawler/data/opennlp/xml/", "html", "OPENNLP-%d", 0, 10,
						CrawlerFactory.BTS_JIRA));
		Logger logger = LogManager.getRootLogger();
		CSVOutputFormatter formatter = new CSVRawIssueFormatter();
		IssueFileWriter output = new CSVIssueFileWriter("r50", formatter);

		//for (Project dataset : datasets) {
			Project project = datasets.get(1);
			ReportCrawler crawler = CrawlerFactory.getInstance(project);
			logger.trace("Start " + project.getName() + " !");
			crawler.load();
			crawler.search(new IssueFilterByStatus("Resolved", "Closed"));
			crawler.search(new IssueFilterByResolution("Fixed"));
			crawler.search(new IssueFilterOutBySeverity("Enhancement"));
			crawler.export(output);
			logger.trace("Finish " + project.getName() + " !");
		//}
	}
}
