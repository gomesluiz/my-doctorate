package br.unicamp.ic.miner.infrastructure.persistence;

import java.util.List;

import br.unicamp.ic.miner.domain.core.IssueNode;

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
