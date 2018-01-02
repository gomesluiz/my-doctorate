package br.unicamp.ic.crawler.services.filters;

import br.unicamp.ic.crawler.domain.core.IssueNode;

public class IssueFilterByCreated extends IssueFilter {
	private String start;
	private String end;

	public IssueFilterByCreated(String start, String end) {
		this.start = start;
		this.end = end;
	}

	@Override
	public boolean evaluate(IssueNode issue) {
		return ((issue.getCreated() == start) && (issue.getCreated() == end));
	}
	
}
