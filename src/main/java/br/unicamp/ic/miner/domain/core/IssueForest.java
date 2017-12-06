package br.unicamp.ic.miner.domain.core;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 
 * @author luiz
 *
 */
public class IssueForest {
	private Map<String, IssueTree> trees;

	/**
	 * 
	 */
	public IssueForest() {
		trees = new HashMap<String, IssueTree>();
	}

	/**
	 * 
	 * @param tree
	 */
	public void add(IssueTree tree) {
		trees.put(tree.getKey(), tree);
	}

	/**
	 * 
	 * @return
	 */
	public Set<String> keys() {
		return trees.keySet();
	}

	/**
	 * 
	 * @param key
	 * @return
	 */
	public IssueTree get(String key) {
		return trees.get(key);
	}

	public void extractTopological() {
		for (Map.Entry<String, IssueTree> entry : trees.entrySet()) {
			IssueTree tree = (IssueTree) entry.getValue();
			tree.updateTopological();
		}
		
	}

	public List<IssueNode> getIssues() {
		List<IssueNode> issues = new ArrayList<IssueNode>();
		for (Map.Entry<String, IssueTree> entry : trees.entrySet()) {
			IssueTree tree = (IssueTree) entry.getValue();
			issues.addAll(tree.getIssues());
		}
		return issues;
	}
}
