/**
 * 
 */
package br.unicamp.ic.miner.domain.core;

import static org.junit.Assert.*;

import java.nio.file.attribute.AclEntry.Builder;

import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

/**
 * @author luiz
 *
 */
public class IssueNodeTest {

	private static IssueBuilder builder;
	private static IssueNode issue1, issue2;

	/**
	 * @throws java.lang.Exception
	 */
	@BeforeClass
	public static void setUpBeforeClass() throws Exception {
		builder = new IssueBuilder("HADOOP-2973", "Test issue").withType("Bug")
				.withCreationDate("Fri, 9 Mar 2007 23:09:37 +0000")
				.withResolutionDate("Wed, 16 May 2007 18:37:18 +0000");

		issue1 = builder.build();

		builder = new IssueBuilder("HADOOP-2973", "Test issue").withType("Bug")
				.withCreationDate("Fri, 9 Mar 2007 23:09:37 +0000").withResolutionDate("");

		issue2 = builder.build();

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
	public void GetKeyNumber_ReturnsAKeyNumber_ForAnIssueNode() {
		// cenário;
		IssueNode issue = builder.build();
		// System.out.println(issue);

		// ação
		String resultado = issue.getKeyNumber();

		// asserção
		assertEquals("2973", resultado);

	}

	@Test
	public void GetTypeCode_ReturnsATypeCode_ForAnIssueNode() {
		// cenário;
		IssueNode issue = builder.build();
		// System.out.println(issue);

		// ação
		String resultado = issue.getTypeCode();

		// asserção
		assertEquals("5", resultado);

	}

	@Test
	public void GetDaysToResolve_ReturnsDaysToResolve_ForAnIssueNode() {
		// cenário;

		// ação
		int resultado = issue1.getDaysToResolve();

		// asserção
		assertEquals(68, resultado);

	}

	@Test
	public void GetDaysToResolve_ReturnsDaysToResolve_ForAnIssueNodeUnresolved() {
		// cenário;

		// ação
		int resultado = issue2.getDaysToResolve();

		// asserção
		assertEquals(3503, resultado);

	}

}
