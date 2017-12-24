package br.unicamp.ic.crawler.domain.jira;

import java.io.InputStream;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import br.unicamp.ic.crawler.domain.core.Crawler;
import br.unicamp.ic.crawler.domain.core.IssueEntry;
import br.unicamp.ic.crawler.domain.core.IssueNode;
import br.unicamp.ic.crawler.persistence.IssueFileReader;

/**
 * Extract information from Jira issues.
 * 
 * @author Luiz Alberto
 * @version 1.0
 * 
 */
public class JIRACrawler implements Crawler {

	private IssueFileReader reader;
	private final String regex = "((\\w+)-(\\d+))$";
	private Pattern pattern;

	/**
	 * Constructs a IssueJiraExtraxtor instance.
	 * 
	 * @param reader
	 * @param dataset
	 *            TODO
	 * @param logger
	 */
	public JIRACrawler(IssueFileReader reader) {
		this.reader = reader;
		this.pattern = Pattern.compile(regex);
	}

	@Override
	public boolean urlPatternMatch(String url) {
		Matcher matcher = pattern.matcher(url);
		if (matcher.find()) {
			return true;
		}
		return false;
	}

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

	public String getPath() {
		return reader.getPath();
	}

	public IssueEntry load(InputStream file) {
		return (JIRAIssueEntry) reader.load(file, JIRAIssueEntry.class);
	}

	@Override
	public IssueNode extractFrom(String url) {
		// TODO Auto-generated method stub
		return null;
	}

}
