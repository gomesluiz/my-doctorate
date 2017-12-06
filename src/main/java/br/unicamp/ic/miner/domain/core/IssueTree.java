package br.unicamp.ic.miner.domain.core;

import java.util.ArrayList;
import java.util.List;

import jdsl.core.api.Position;
import jdsl.core.api.PositionIterator;
import jdsl.core.api.Tree;
import jdsl.core.ref.NodeTree;
import jdsl.core.ref.PreOrderIterator;

public class IssueTree {
	private Tree tree;
	private List<String> keys;

	public IssueTree() {
		tree = new NodeTree();
		keys = new ArrayList<String>();
	}

	public String getKey() {
		IssueNode issue = (IssueNode) tree.root().element();
		return issue.getKey();
	}

	/**
	 * 
	 * @return
	 */
	public Position root() {
		return tree.root();
	}

	/**
	 * 
	 * @param key
	 * @return
	 */
	public boolean contains(String key) {
		return keys.contains(key);
	}

	/**
	 * Insert new <code>Issue</code> node in the tree.
	 * 
	 * @param position the position where node should be insert.
	 * @param issue the issue to be insert in the tree.
	 * @return the current position where issue node was inserted.
	 */
	public Position insert(Position position, IssueNode issue) {

		Position current;
		if (tree.isRoot(position)) {
			current = tree.insertFirstChild(tree.root(), null);
			tree.replaceElement(tree.root(), issue);
		} else {
			current = tree.insertFirstChild(position, issue);
		}

		keys.add(issue.getKey());
		return current;
	}

	/**
	 * 
	 * @return
	 */
	public int depth() {
		return depth(tree, tree.root());
	}

	/**
	 * 
	 * @param tree
	 * @param pos
	 * @return
	 */
	private int depth(Tree tree, Position pos) {
		if (tree.isExternal(pos)) {
			return 0;
		} else {
			return 1 + Math.max(depth(tree, tree.firstChild(pos)), depth(tree, tree.lastChild(pos)));
		}
	}

	public List<IssueNode> transversalInPost() {
		List<IssueNode> issues = new ArrayList<IssueNode>();
		PreOrderIterator iterator = new PreOrderIterator(tree);
		while (iterator.hasNext()) {
			Position position = iterator.nextPosition();
			IssueNode issue = (IssueNode) position.element();
			if (issue != null) {
				issues.add(issue);
			}
		}
		return issues;

	}

	public Position findPosition(String key) {
		PreOrderIterator iterator = new PreOrderIterator(tree);
		while (iterator.hasNext()) {
			Position position = iterator.nextPosition();
			IssueNode issue = (IssueNode) position.element();
			if (issue != null) {
				if (issue.getKey().equals(key)) {
					return position;
				}
			}
		}
		return null;

	}

	public void updateTopological() {
		List<IssueNode> issues = transversalInPost();
		for (IssueNode issue : issues) {
			Position position = findPosition(issue.getKey());
			if (position != null) {
				int children = tree.numChildren(position);
				IssueNode e = (IssueNode) position.element();
				e.updateDepthOfTree(depth());
				if (children > 1) {
					children = children - 1;
					e.updateChildren(children);
					PositionIterator iterator = tree.children(position);
					double total = 0.0;
					while (iterator.hasNext()) {
						Position p = iterator.nextPosition();
						IssueNode n = (IssueNode) p.element();
						if (n != null)
							total += n.getWeight();
					}
					e.updateWeigth(total / children);
				}

			}
		}

	}

	public int getChildren(IssueNode issue) {
		int children = 0;
		Position position = findPosition(issue.getKey());
		if (position != null) {
			children = tree.numChildren(position);
			children = children > 0 ? children - 1 : 0;
		}
		return children;
	}

	public List<IssueNode> getIssues() {
		// TODO Auto-generated method stub
		return transversalInPost();
	}

}
