/**
 * 
 */
package br.unicamp.ic.crawler.domain.bugzilla;

import static org.junit.Assert.assertEquals;

import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

import br.unicamp.ic.crawler.domain.core.IssueEntry;
import br.unicamp.ic.crawler.persistence.IssueParser;

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
	public final void parseAnIssueInXmlValidFormat() {
		String xml = "<bugzilla version=\"5.0.3\" urlbase=\"https://bugs.eclipse.org/bugs/\" maintainer=\"webmaster@eclipse.org\">"
				+ "<bug>"
					+ "<bug_id>14582</bug_id>"
					+ "<creation_ts>2002-04-25 06:24:21 -0400</creation_ts>"
					+ "<short_desc>rename enabled on multi-selection</short_desc>"
					+ "<delta_ts>2002-04-25 06:33:05 -0400</delta_ts>"
					+ "<reporter_accessible>1</reporter_accessible>"
					+ "<cclist_accessible>1</cclist_accessible>"
					+ "<classification_id>2</classification_id>"
					+ "<classification>Eclipse</classification>"
					+ "<product>JDT</product>"
					+ "<component>UI</component>"
					+ "<version>2.0</version>"
					+ "<rep_platform>PC</rep_platform>"
					+ "<op_sys>Windows 2000</op_sys>"
					+ "<bug_status>RESOLVED</bug_status>"
					+ "<resolution>FIXED</resolution>"
					+ "<bug_file_loc/><status_whiteboard/>"
					+ "<keywords/><priority>P3</priority>"
					+ "<bug_severity>major</bug_severity>"
					+ "<target_milestone>---</target_milestone>"
					+ "<everconfirmed>1</everconfirmed>"
					+ "<reporter name=\"Adam Kiezun\">akiezun</reporter>"
					+ "<assigned_to name=\"Adam Kiezun\">akiezun</assigned_to>"
					+ "<votes>0</votes>"
					+ "<comment_sort_order>oldest_to_newest</comment_sort_order>"
					+ "<long_desc isprivate=\"0\">"
					+ "<commentid>46391</commentid>"
					+ "<comment_count>0</comment_count>"
					+ "<who name=\"Adam Kiezun\">akiezun</who>"
					+ "<bug_when>2002-04-25 06:24:21 -0400</bug_when>"
					+ "<thetext> </thetext>"
					+ "</long_desc><long_desc isprivate=\"0\">"
					+ "<commentid>46392</commentid>"
					+ "<comment_count>1</comment_count>"
					+ "<who name=\"Adam Kiezun\">akiezun</who>"
					+ "<bug_when>2002-04-25 06:33:05 -0400</bug_when>"
					+ "<thetext>fixed</thetext>"
					+ "</long_desc>"
					+ "</bug>"
				+ "</bugzilla>";
		IssueParser parser = new BZIssueParserInXml();
		IssueEntry entry = (IssueEntry) parser.parse(xml);
		assertEquals(entry.getKey(), "14582");
		assertEquals(entry.getSeverity(), "major");
		assertEquals(entry.getStatus(), "RESOLVED");
	}

}
