package br.unicamp.ic.miner.domain.core;

import br.unicamp.ic.miner.infrastructure.persistence.IssueFileWriter;

/**
 * The <code>IsseMiner</code> class mines several information from issues
 * repository.
 * 
 * @author Luiz Alberto
 * @version 1.0
 * @since 2016-02-01
 *
 */
public class IssueCrawler {

	private IssueRemoteRepository		from;
	private IssueFileWriter	to;

	/**
	 * Constructs a new IssueMiner instance.
	 * 
	 * @param from
	 *          The mechanism to extract issues.
	 * @param to
	 *          The mechanism to export information.
	 */
	public IssueCrawler(IssueRemoteRepository from, IssueFileWriter to) {
		this.from = from;
		this.to = to;
	}

	/**
	 * Load issues from source.
	 * 
	 * @param start
	 *          the starting issue number
	 * @param end
	 *          the ending issue number
	 */
	public void load(int start, int end) {
		from.extractIssuesFrom(start, end);
	}

	/**
	 * 
	 */

	public void export() {
		to.write(from.getIssues());
	}

	public void export(IssueFileWriter writer) {
		this.to = writer;
		this.export();
	}

}
