package br.unicamp.ic.miner.infrastructure.persistence;

import java.io.FileWriter;
import java.io.IOException;
import java.util.List;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;

import br.unicamp.ic.miner.domain.core.IssueNode;

/**
 * The <code>CSVIssueFileWriter</code> class implements a file writer which uses
 * csv format to store a List of <code>IssueNode</code>  instances in a specific 
 * format.
 * 
 * <PRE>
 * CSVIssueFileWriter writer = new CSVFileWritter("file.csv", formatter);
 * writer.write(issues);
 * </PRE>
 * 
 * @author Luiz Alberto
 * @version 1.0
 * @see IssueFileWriter
 *
 */
public class CSVIssueFileWriter implements IssueFileWriter {

	private String							file;
	private CSVRecordFormatter	formatter;

	/**
	 * CSVIssueFileWriter constructor
	 * 
	 * @param file file 
	 * @param formatter
	 */
	public CSVIssueFileWriter(String file, CSVRecordFormatter formatter) {
		this.file = file;
		this.formatter = formatter;
	}

	/**
	 * Writes issues into csv file.
	 * 
	 * @param issues to write.
	 */
	public void write(final List<IssueNode> issues) {
		FileWriter writer = null;
		CSVPrinter printer = null;
		CSVFormat format = CSVFormat.DEFAULT;
		Object[] headers = formatter.getHeaders();

		try {
			writer = new FileWriter(this.file);
			printer = new CSVPrinter(writer, format);
			printer.printRecord(headers);
			for (IssueNode issue : issues) {
				printer.printRecord(formatter.format(issue));
			}

		} catch (IOException e) {
			throw new RuntimeException("Erro: " + e.getMessage());
		} finally {
			try {
				if (writer != null) {
					writer.flush();
					writer.close();
				}
				if (printer != null) {
					printer.close();
				}
			} catch (IOException e) {
				throw new RuntimeException("Erro: " + e.getMessage());
			}
		}
	}
}
