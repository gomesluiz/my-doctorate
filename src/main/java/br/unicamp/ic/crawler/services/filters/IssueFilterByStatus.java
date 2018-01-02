package br.unicamp.ic.crawler.services.filters;

import br.unicamp.ic.crawler.domain.core.IssueNode;

/**
 * TODO
 * @author luiz
 *
 */
public class IssueFilterByStatus extends IssueFilter {

	private String status;

	/**
	 * TODO
	 * @param status
	 */
	public IssueFilterByStatus(String status) {
		this.status = status.toLowerCase();
	}

	@Override
	public boolean evaluate(IssueNode issue) {
		return issue.getStatus().toLowerCase().equals(this.status);
	}

}
