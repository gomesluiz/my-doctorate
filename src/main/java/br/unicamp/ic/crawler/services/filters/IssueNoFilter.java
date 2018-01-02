package br.unicamp.ic.crawler.services.filters;

import br.unicamp.ic.crawler.domain.core.IssueNode;

public class IssueNoFilter extends IssueFilter {

	@Override
	protected boolean evaluate(IssueNode issue) {
		return true;
	}

}
