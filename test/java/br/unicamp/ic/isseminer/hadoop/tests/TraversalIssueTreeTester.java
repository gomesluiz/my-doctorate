package br.unicamp.ic.isseminer.hadoop.tests;

import static org.junit.Assert.assertEquals;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

import br.unicamp.ic.miner.domain.core.IssueNode;
import br.unicamp.ic.miner.domain.core.IssueNodeBuilder;
import br.unicamp.ic.miner.domain.core.IssueTree;
import jdsl.core.api.Position;

public class TraversalIssueTreeTester {

	private static IssueNode issue1;
	private static IssueNode issue2;
	private static IssueNode issue3;
	private static IssueNode issue4;

	private IssueTree tree;

	@BeforeClass
	public static void setupBeforeClass() {
		issue1 = new IssueBuilder("hadoop-01", "issue 01").withType("BUG").build();
		issue2 = new IssueBuilder("hadoop-02", "issue 02").withType("BUG").build();
		issue3 = new IssueBuilder("hadoop-03", "issue 03").withType("BUG").build();
		issue4 = new IssueBuilder("hadoop-04", "issue 04").withType("BUG").build();
	}

	@Before
	public void setup() {
		tree = new IssueTree();
	}

	@Test
	public void transversalTreeWithZeroNodes() {
		List<IssueNode> empty = new ArrayList<IssueNode>();
		assertEquals(empty, tree.transversalInPost());
	}

	@Test
	public void transversalTreeWithOnlyRoot() {
		List<IssueNode> withOne = Arrays.asList(issue1);
		tree.insert(tree.root(), issue1);
		assertEquals(withOne, tree.transversalInPost());
	}

	@Test
	public void transversalTreeWithRootWithOneChildren() {
		List<IssueNode> withTwo = Arrays.asList(issue1, issue2);
		Position position = tree.insert(tree.root(), issue1);
		tree.insert(position, issue2);

		assertEquals(withTwo, tree.transversalInPost());

	}

	@Test
	public void transversalTreeWithRootWithTwoChildren() {
		List<IssueNode> withThree = Arrays.asList(issue1, issue3, issue2);
		Position position = tree.insert(tree.root(), issue1);
		tree.insert(position, issue2);
		tree.insert(position, issue3);
		assertEquals(withThree, tree.transversalInPost());
	}

	@Test
	public void transversalTreeWithRootWithThreeChildren() {
		List<IssueNode> withThree = Arrays.asList(issue1, issue3, issue4, issue2);
		Position position = tree.insert(tree.root(), issue1);
		tree.insert(position, issue2);
		position = tree.insert(position, issue3);
		tree.insert(position, issue4);

		assertEquals(withThree, tree.transversalInPost());
	}
}
