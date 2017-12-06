package br.unicamp.ic.isseminer.hadoop.tests;

import static org.junit.Assert.assertEquals;

import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

import br.unicamp.ic.miner.domain.core.IssueNode;
import br.unicamp.ic.miner.domain.core.IssueNodeBuilder;
import br.unicamp.ic.miner.domain.core.IssueImporter;
import br.unicamp.ic.miner.domain.jira.hadoop.IssuesJiraImporter;
import br.unicamp.ic.miner.infrastructure.persistence.IssueFileReader;
import br.unicamp.ic.miner.infrastructure.persistence.XmlReader;

public class IssueExtractorTest {

	private static IssueFileReader reader;
	private static IssueImporter extractor;

	@BeforeClass
	public static void setUpBeforeClass() throws Exception {
		Logger logger = LogManager.getRootLogger();
		reader = new XmlReader();
		extractor = new IssuesJiraImporter(reader, logger);
	}

	@Before
	public void setUp() throws Exception {
	}

	@Test
	public void extractIssueFromRange() {
		// Arrange

		// Act
		extractor.extractIssuesFrom(1, 2);
		List<IssueNode> issues = extractor.getIssues();

		// Assert
		assertEquals(2, issues.size());
	}
	
	@Test
	public void extractLinksFromIssue() {
		// Arrange
		IssueNode issue = new IssueBuilder("HADOOP-2973", 
				"<a href=\"https://issues.apache.org/jira/browse/HADOOP-2931>HADOOP-2931\"</a>"
				+ " <a href=\"https://issues.apache.org/jira/browse/HADOOP2758>HADOOP2758\"</a> Reduce buffer copies in DataNode when data is read from HDFS, without negatively affecting read throughput.")
				.withType("BUG")
				.build();
				
		// Act
		List<String> links = extractor.extractLinks(issue.getDescription());

		// Assert
		assertEquals(1, links.size());
	}

}
