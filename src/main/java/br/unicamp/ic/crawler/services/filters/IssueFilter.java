package br.unicamp.ic.crawler.services.filters;

import java.util.ArrayList;
import java.util.List;

import br.unicamp.ic.crawler.domain.core.IssueNode;

/**
 * TODO
 * @author luiz
 *
 */
public abstract class IssueFilter {
	/**
	 * TODO
	 * @param issue
	 * @return
	 */
	protected abstract boolean evaluate(IssueNode issue);
	
	/**
	 * TODO
	 * @param issues
	 * @return
	 */
	public List<IssueNode> filter(List<IssueNode> issues) {
		List<IssueNode> result = new ArrayList<IssueNode>();
		for(IssueNode issue: issues) {
			if (evaluate(issue) == true) {
				result.add(issue);
			}
		}
		return result;
	}
}
