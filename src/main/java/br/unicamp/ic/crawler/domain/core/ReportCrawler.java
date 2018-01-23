package br.unicamp.ic.crawler.domain.core;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.List;

import br.unicamp.ic.crawler.domain.core.filters.IssueFilter;
import br.unicamp.ic.crawler.persistence.IssueFileWriter;
import br.unicamp.ic.crawler.persistence.ReportRepository;

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
public abstract class ReportCrawler{

	protected Project project;
	protected List<Report> reports;
	protected ReportRepository repository;
	protected Subject subject;

	public abstract String downloadFrom(String url);

	public abstract String formatRemoteIssueUrl(int key);

	public abstract String formatRemoteIssueHistoryUrl(int key);

	public abstract List<Report> search(IssueFilter filter);

	public ReportCrawler() {
		subject = new Subject();
		new LoggerObserver(subject);
	}
	
	/**
	 * 
	 */
	public final void downloadAll() {
		try {
			File folder = new File(project.getLocalIssuePath());
			if (!folder.exists()) {
				folder.mkdirs();
			}

			for (int i = project.getFirstIssue(); i <= project.getLastIssue(); i++) {
				download(i);
			}
		} catch (Exception e) {
			throw new RuntimeException(e.getMessage());
		}
	}

	/**
	 * 
	 * @param key
	 */
	protected final void download(int key) {

		try {
			String url = this.formatRemoteIssueUrl(key);

			File localIssueFile = new File(project.formatLocalIssueFileName(key));
			File localHistoryFile = new File(project.formatLocalIssueHistoryFileName(key));

			if (localIssueFile.exists() && localHistoryFile.exists())
				return;

			String issueContents = downloadFrom(url);
			if (issueContents == null)
				return;
			subject.setMessage(url);

			url = this.formatRemoteIssueHistoryUrl(key);

			String issueHistoryContents = downloadFrom(url);
			if (issueHistoryContents == null)
				return;
			subject.setMessage(url);

			writeTo(project.formatLocalIssueFileName(key), issueContents);
			writeTo(project.formatLocalIssueHistoryFileName(key), issueHistoryContents);

		} catch (Exception e) {
			throw new RuntimeException(e.getMessage());

		}
	}

	/**
	 * 
	 */
	public final void load() {
		reports = repository.findAll();
	}

	/**
	 * 
	 * @param out
	 */
	public void export(IssueFileWriter out) {
		out.write(reports);
	}

	/**
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
}