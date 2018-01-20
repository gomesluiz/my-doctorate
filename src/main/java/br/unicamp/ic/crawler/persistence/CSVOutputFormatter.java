package br.unicamp.ic.crawler.persistence;

import br.unicamp.ic.crawler.domain.core.IssueActivityEntry;
import br.unicamp.ic.crawler.domain.core.IssueNode;

public interface CSVOutputFormatter {
	public final int ISSUE_HEADER_TYPE 		= 1;
	public final int HISTORY_HEADER_TYPE 	= 2;
	
	Object[] getHeaders(int headerType);
	
	Iterable<?> format(IssueNode issue);
	Iterable<?> format(String key, IssueActivityEntry activity);
}
