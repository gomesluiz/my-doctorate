package br.unicamp.ic.crawler.services;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.apache.logging.log4j.Logger;

import br.unicamp.ic.crawler.domain.core.Dataset;
import br.unicamp.ic.crawler.domain.core.IssueEntry;
import br.unicamp.ic.crawler.domain.core.IssueEntryActivity;
import br.unicamp.ic.crawler.domain.core.IssueNode;
import br.unicamp.ic.crawler.persistence.IssueFileWriter;
import br.unicamp.ic.crawler.persistence.IssueRepository;
import br.unicamp.ic.crawler.persistence.FileResource;
import br.unicamp.ic.crawler.persistence.URLResource;
import br.unicamp.ic.crawler.services.filters.IssueFilter;

/**
 * The <code>IssueCrawler</code> abstract class offers template methods to down-
 * loads one or several issues from Bug Tracking System specified by an URL and 
 * stores them into disk. 
 * 
 * This software is licensed with an Apache 2 license, see
 * http://www.apache.org/licenses/LICENSE-2.0 for details.
 * 
 * @author Luiz Alberto (gomes.luiz@gmail.com)
 * 
 */
public abstract class IssueCrawler {
	protected Dataset dataset;
	protected List<IssueNode> issues;
	protected Logger logger;
	protected IssueRepository repository;

	public abstract String readFrom(String url);
	public abstract String formatRemoteIssueUrl(int key);
	public abstract String formatRemoteIssueHistoryUrl(int key);
	public abstract void search(IssueFilter filter);

	/**
	 * Reads a contents as string an URL.
	 * 
	 * @param url an URL address.
	 */
	protected final String readContents(String url) {
		String contents;

		URLResource urlResource = new URLResource(url);
		contents = urlResource.asString();
		return contents;
	}

	/**
	 * @return
	 */
	public final List<IssueNode> loadFrom() {
		List<IssueNode> issues = repository.findAll();
		return issues;
	}
	
	/**
	 * 
	 * @param out
	 */
	public void export(IssueFileWriter out) {
		out.write(issues);
	}

	/**
	 * TODO
	 * 
	 * @param target
	 * @param contents
	 */
	protected void writeTo(String target, String contents) {
		try {

			FileWriter out = new FileWriter(target);
			BufferedWriter writer = new BufferedWriter(out);
			writer.write(contents);
			writer.close();
		} catch (IOException e) {
			throw new RuntimeException(e.getMessage());
		}
	}

	public final void downloadAll() {
		try {
			File folder = new File(dataset.getLocalIssuePath());
			if (!folder.exists()) {
				folder.mkdirs();
			}

			for (int i = dataset.getFirstIssue(); i <= dataset.getLastIssue(); i++) {
				download(i);
			}
		} catch (Exception e) {
			throw new RuntimeException(e.getMessage());
		}
	}

	protected final void download(int key) {
		
		try {
			String url = this.formatRemoteIssueUrl(key);

			File localIssueFile = new File(dataset.formatLocalIssueFileName(key));
			File localHistoryFile = new File(dataset.formatLocalIssueHistoryFileName(key));

			if (localIssueFile.exists() && localHistoryFile.exists())
				return;

			String issueContents = readFrom(url);
			if (issueContents == null) return;
			logger.trace(url);
			
			url = this.formatRemoteIssueHistoryUrl(key);
			
			String issueHistoryContents = readFrom(url);
			if (issueHistoryContents == null) return;
			logger.trace(url);
			
			writeTo(dataset.formatLocalIssueFileName(key), issueContents);
			writeTo(dataset.formatLocalIssueHistoryFileName(key), issueHistoryContents);
		
		} catch (Exception e) {
			throw new RuntimeException(e.getMessage());

		}
	}

}