package br.unicamp.ic.crawler.domain.core.filters;

import br.unicamp.ic.crawler.domain.core.Report;

public class IssueNoFilter extends IssueFilter {

	@Override
	protected boolean evaluate(Report issue) {
		return true;
	}

}
