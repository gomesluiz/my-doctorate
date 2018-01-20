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

import br.unicamp.ic.crawler.domain.core.IssueActivityEntry;
import br.unicamp.ic.crawler.domain.core.IssueEntry;
import br.unicamp.ic.crawler.domain.core.IssueNode;
import br.unicamp.ic.crawler.persistence.IssueRepository;
import br.unicamp.ic.crawler.persistence.IssueRepositoryFromMemory;
import br.unicamp.ic.crawler.services.IssueParser;

/**
 * @author luiz
 *
 */
public class ParseIssueAndHistoryTest {

	/**
	 * @throws java.lang.Exception
	 */
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
		String xml = IssueRepositoryFromMemory.reports.get(0);	
		IssueParser parser = new BZIssueParserInXml();
		IssueEntry entry = (IssueEntry) parser.parse(xml);
		assertEquals("14582", entry.getKey());
		assertEquals("2002-04-25", entry.getCreated());
		assertEquals("major", entry.getSeverity());
		assertEquals("RESOLVED", entry.getStatus());
	}
	
	@Test
	public final void parseAnIssueHistoryFromBugzillaHtmlValidFormat() {
		String html = IssueRepositoryFromMemory.histories.get(0);
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
		IssueRepository repository = new IssueRepositoryFromMemory();
		IssueNode issue = repository.findBy("14582");
		
		assertEquals("2002-04-25", issue.getResolved());
		assertEquals("major", issue.getSeverity());
		assertEquals("3", issue.getSeverityCode());
		
		assertEquals(0, issue.getDaysToResolve());
	}

}
