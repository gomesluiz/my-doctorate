import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.Test;

import br.unicamp.ic.crawler.domain.bugzilla.BZIssueParserInXml;
import br.unicamp.ic.crawler.domain.bugzilla.BZXmlCrawler;
import br.unicamp.ic.crawler.domain.core.Dataset;
import br.unicamp.ic.crawler.persistence.IssueRepository;
import br.unicamp.ic.crawler.persistence.IssueRepositoryFromMemory;
import br.unicamp.ic.crawler.services.CrawlerFactory;
import br.unicamp.ic.crawler.services.IssueCrawler;
import br.unicamp.ic.crawler.services.IssueParser;
import br.unicamp.ic.crawler.services.filters.IssueNoFilter;

public class Teste1 {

	@Test
	public final void testSearch() {
		Dataset dataset = new Dataset("eclipse", "https://bugs.eclipse.org/bugs/show_bug.cgi?ctype=xml&id=%d",
				"/home/luiz/Workspace/issue-crawler/data/eclipse/xml/", "xml",
				"https://bugs.eclipse.org/bugs/show_activity.cgi?id=%d",
				"/home/luiz/Workspace/issue-crawler/data/eclipse/xml/", "html", "ECLIPSE-%d", 10000, 15000,
				CrawlerFactory.BTS_BUGZILLA);
		IssueParser converter = new BZIssueParserInXml();
		Logger logger = LogManager.getRootLogger();

		IssueRepository repository = new IssueRepositoryFromMemory();
		IssueCrawler crawler = new BZXmlCrawler(dataset, converter, logger, repository);
		crawler.load();
		crawler.search(new IssueNoFilter());
	}

}
