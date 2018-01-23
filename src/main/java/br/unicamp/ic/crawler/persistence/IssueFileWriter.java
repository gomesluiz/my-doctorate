package br.unicamp.ic.crawler.persistence;

import java.util.List;

import br.unicamp.ic.crawler.domain.core.Report;

/**
 * <code>IssueFileWriter</code> is the interface for all file issues writers.
 * 
 * @author Luiz Alberto
 * @version %I%, %G%
 * @since 1.0
 */
public interface IssueFileWriter {
	/**
	 * Writes a list of <code>IssueNode</code> into file on disk.
	 * 
	 * @param issues	issues to write
	 * @see 	Report
	 * @since	1.0
	 */
	void write(final List<Report> issues);
}
