package br.unicamp.ic.crawler.domain.bugzilla;

import java.io.BufferedWriter;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import br.unicamp.ic.crawler.domain.core.Crawler;
import br.unicamp.ic.crawler.domain.core.IssueEntry;
import br.unicamp.ic.crawler.domain.core.IssueNode;
import br.unicamp.ic.crawler.persistence.FileResource;
import br.unicamp.ic.crawler.persistence.IssueFileReader;
import br.unicamp.ic.crawler.persistence.URLResource;

/**
 * Extract information Bugzilla Tracking Systems.
 * 
 * @author Luiz Alberto
 * @version 1.0
 * 
 */
public class BZCrawler implements Crawler {

	private IssueFileReader reader;
	private final String regex = "((\\d+){6})$";
	private Pattern pattern;

	/**
	 * Constructs a IssueJiraExtraxtor instance.
	 * 
	 * @param reader
	 */
	public BZCrawler(IssueFileReader reader) {
		this.reader = reader;
		this.pattern = Pattern.compile(regex);
	}
	
	@Override
	public IssueNode extractFrom(String url) {
		IssueNode issue = null;
		try {
			String text = extract(url);
			InputStream xml = new ByteArrayInputStream(text.getBytes());
			issue = new IssueNode(this.load(xml));
		} catch (Exception e) {
			throw new RuntimeException(e.getMessage());
		}
		return issue;
	}

	@Override
	public boolean urlPatternMatch(String url) {
		Matcher matcher = pattern.matcher(url);
		if (matcher.find()) {
			return true;
		}
		return false;
	}

	private String getKey(String url) {
		int ini = url.lastIndexOf("=");
		if (ini == -1) {
			return "-1";
		}

		int end = url.length();
		if (url.endsWith(".xml")) {
			end = url.lastIndexOf(".");
			if (end == -1) {
				return "-1";
			}
		}

		return url.substring(ini + 1, end);
	}

	private String getPath() {
		return reader.getPath();
	}

	private IssueEntry load(InputStream file) {
		return (BZIssueEntry) reader.load(file, BZIssueEntry.class);
	}
	
	private String extract(String url) {
		String text;
		String key = this.getKey(url);

		File issueFile = new File(this.getPath() + key + ".xml");
		if (issueFile.exists()) {
			FileResource fileResource = new FileResource(issueFile);
			text = fileResource.asString();
			
		} else {
			//String url = dataset.formatUrl(Integer.valueOf(key));
			URLResource urlResource = new URLResource(url);
			text = urlResource.asString();
			writeIssueEntry(key, text);
		}
		return text;
	}
	
	private void writeIssueEntry(String key, String text) {
		String name = this.getPath() + key + ".xml";

		try {
			FileWriter file = new FileWriter(name);
			BufferedWriter writer = new BufferedWriter(file);
			writer.write(text);
			writer.close();
		} catch (IOException e) {
			throw new RuntimeException(e.getMessage());
		}
	}

}
