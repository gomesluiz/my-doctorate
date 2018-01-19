import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.Test;

import br.unicamp.ic.crawler.domain.bugzilla.BZHistoryParserInHtml;
import br.unicamp.ic.crawler.domain.bugzilla.BZIssueParserInXml;
import br.unicamp.ic.crawler.domain.bugzilla.BZXmlCrawler;
import br.unicamp.ic.crawler.domain.core.Dataset;
import br.unicamp.ic.crawler.domain.core.IssueNode;
import br.unicamp.ic.crawler.persistence.IssueParser;
import br.unicamp.ic.crawler.persistence.IssueRepository;
import br.unicamp.ic.crawler.persistence.IssueRepositoryFromFile;
import br.unicamp.ic.crawler.services.CrawlerFactory;
import br.unicamp.ic.crawler.services.IssueCrawler;

public class Teste1 {

	@Test
	public final void testSearch() {
		Dataset dataset = new Dataset("mozilla", "https://bugzilla.mozilla.org/show_bug.cgi?ctype=xml&id=%d",
				"/home/luiz/Workspace/issue-crawler/data/mozilla/xml/", "xml",
				"https://bugzilla.mozilla.org/show_activity.cgi?id=%d",
				"/home/luiz/Workspace/issue-crawler/data/mozilla/xml/", "html", "MOZILLA-%d", 10000, 15000,
				CrawlerFactory.BTS_BUGZILLA);
		IssueParser converter = new BZIssueParserInXml();
		Logger logger = LogManager.getRootLogger();

		// List<IssueNode> issues = new ArrayList<IssueNode>();
		IssueRepository repository1 = new IssueRepositoryFromMemory();
		IssueRepository repository2 = new IssueRepositoryFromFile(dataset, new BZIssueParserInXml(),
				new BZHistoryParserInHtml());
		IssueCrawler crawler = new BZXmlCrawler(dataset, converter, logger, repository1);
		List<IssueNode> issues = crawler.loadFrom();

	}

}
