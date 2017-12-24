package br.unicamp.ic.crawler.persistence;

import java.util.List;

import br.unicamp.ic.crawler.domain.core.IssueNode;

/**
 *
 * @author Luiz Alberto
 *
 */
public interface CSVRecordFormatter {
	/**
	 *
	 * @param issue
	 * @return
	 */
	List<Object> format(IssueNode issue);

	/**
	 *
	 ** @return
	 */
	Object[] getHeaders();
}
