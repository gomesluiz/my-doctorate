package br.unicamp.ic.crawler.domain.jira;

import java.util.List;
import java.util.regex.Pattern;

import org.apache.logging.log4j.Logger;

import br.unicamp.ic.crawler.domain.core.Dataset;
import br.unicamp.ic.crawler.domain.core.IssueEntry;
import br.unicamp.ic.crawler.domain.core.IssueEntryActivity;
import br.unicamp.ic.crawler.persistence.FormatConverter;
import br.unicamp.ic.crawler.services.IssueCrawler;
import br.unicamp.ic.crawler.services.filters.IssueFilter;

/**
 * Extract information from Jira issues.
 * 
 * @author Luiz Alberto
 * @version 1.0
 * 
 */
public class JIRACrawler extends IssueCrawler {

	private FormatConverter reader;
	private final String regex = "((\\w+)-(\\d+))$";
	private Pattern pattern;

	/**
	 * Constructs a IssueJiraExtraxtor instance.
	 * @param dataset TODO
	 * @param dataset
	 *            TODO
	 * @param converter
	 * @param logger TODO
	 * @param logger
	 */
	public JIRACrawler(Dataset dataset, FormatConverter converter, Logger logger) {
		this.reader = converter;
		this.pattern = Pattern.compile(regex);
	}

//	@Override
//	public boolean urlPatternMatch(String url) {
//		Matcher matcher = pattern.matcher(url);
//		if (matcher.find()) {
//			return true;
//		}
//		return false;
//	}

	public String getKey(String address) {

		int ini = address.lastIndexOf("/");
		if (ini == -1) {
			return "-1";
		}

		int end = address.length();
		if (address.endsWith(".xml")) {
			end = address.lastIndexOf(".");
			if (end == -1) {
				return "-1";
			}
		}

		return address.substring(ini + 1, end);
	}


	public IssueEntry load(String contents) {
		return (JIRAIssueEntry) reader.load(contents, JIRAIssueEntry.class);
	}

	@Override
	public void downloadAll() {
		// TODO Auto-generated method stub
	}

	@Override
	public void download(int key) {
		// TODO Auto-generated method stub
	}

	@Override
	public void search(IssueFilter filter) {
		// TODO Auto-generated method stub
		
	}

	@Override
	public IssueEntry convert(String contents) {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public List<IssueEntryActivity> extract(int key) {
		// TODO Auto-generated method stub
		return null;
	}

}
