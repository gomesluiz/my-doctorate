/**
 * 
 */
package br.unicamp.ic.crawler.domain.bugzilla;

import static org.junit.Assert.assertEquals;

import java.util.List;

import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

import br.unicamp.ic.crawler.domain.bugzilla.BZHistoryParserInHtml;
import br.unicamp.ic.crawler.domain.bugzilla.BZIssueParserInXml;
import br.unicamp.ic.crawler.domain.core.IssueActivityEntry;
import br.unicamp.ic.crawler.domain.core.IssueEntry;
import br.unicamp.ic.crawler.domain.core.Report;
import br.unicamp.ic.crawler.domain.core.IssueParser;
import br.unicamp.ic.crawler.persistence.ReportRepository;
import br.unicamp.ic.crawler.persistence.ReportRepositoryFromMemory;

/**
 * @author luiz
 *
 */
public class ParseIssueAndHistoryTest {

	@BeforeClass
	public static void setUpBeforeClass() throws Exception {
	}

	/**
	 * @throws java.lang.Exception
	 */
	@AfterClass
	public static void tearDownAfterClass() throws Exception {
	}

	/**
	 * @throws java.lang.Exception
	 */
	@Before
	public void setUp() throws Exception {
	}

	/**
	 * @throws java.lang.Exception
	 */
	@After
	public void tearDown() throws Exception {
	}

	@Test
	public final void parseAnIssueFromBugzillaXmlValidFormat() {
		String xml = ReportRepositoryFromMemory.reports.get(0);	
		IssueParser parser = new BZIssueParserInXml();
		IssueEntry entry = (IssueEntry) parser.parse(xml);
		assertEquals("JDT-14582", entry.getKey());
		assertEquals("2002-04-25", entry.getCreated());
		assertEquals("major", entry.getSeverity());
		assertEquals("RESOLVED", entry.getStatus());
	}
	
	@Test
	public final void parseAnIssueHistoryFromBugzillaHtmlValidFormat() {
		String html = ReportRepositoryFromMemory.histories.get(0);
		BZHistoryParserInHtml parser = new BZHistoryParserInHtml();
		List<IssueActivityEntry> activities = parser.parse(html);
		assertEquals(2, activities.size());
		
		IssueActivityEntry anActivity = activities.get(0);
		assertEquals("akiezun", anActivity.getWho());
		assertEquals("2002-04-25", anActivity.getWhen());
		assertEquals("status", anActivity.getWhat());
		assertEquals("new", anActivity.getRemoved());
		assertEquals("resolved", anActivity.getAdded());
		
		anActivity = activities.get(1);
		assertEquals("akiezun", anActivity.getWho());
		assertEquals("2002-04-25", anActivity.getWhen());
		assertEquals("resolution", anActivity.getWhat());
		assertEquals("---", anActivity.getRemoved());
		assertEquals("fixed", anActivity.getAdded());
		
	}
	
	/**
	 * TODO: move to approriate class.
	 */
	
	@Test
	public final void createIssueNode() {
		ReportRepository repository = new ReportRepositoryFromMemory();
		Report issue = repository.findBy("CORE_GRAVEYARD-13271");
		
		assertEquals("1999-09-07", issue.getCreated());
		assertEquals("2000-02-09", issue.getResolved());
		assertEquals("normal", issue.getSeverity());
		assertEquals("5", issue.getSeverityCode());
		
		assertEquals(155, issue.getDaysToResolve());
	}

}
