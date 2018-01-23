package br.unicamp.ic.crawler.persistence;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import br.unicamp.ic.crawler.domain.core.HistoryParser;
import br.unicamp.ic.crawler.domain.core.IssueActivityEntry;
import br.unicamp.ic.crawler.domain.core.IssueEntry;
import br.unicamp.ic.crawler.domain.core.IssueParser;
import br.unicamp.ic.crawler.domain.core.LoggerObserver;
import br.unicamp.ic.crawler.domain.core.Project;
import br.unicamp.ic.crawler.domain.core.Report;
import br.unicamp.ic.crawler.domain.core.Subject;

public class ReportRepositoryFromFile implements ReportRepository {

	private Project dataset;
	private IssueParser issueParser;
	private HistoryParser historyParser;
	private Subject subject;

	public ReportRepositoryFromFile(Project project, IssueParser issueParser, HistoryParser historyParser) {
		this.dataset = project;
		this.issueParser = issueParser;
		this.historyParser = historyParser;
		this.subject = new Subject();
		new LoggerObserver(this.subject);

	}

	@Override
	public List<Report> findAll() {
		List<Report> issues = new ArrayList<Report>();
		int count = 0, total = 0;
		File folder = new File(dataset.getLocalIssuePath());
		if (folder.exists()) {
			File[] files = folder.listFiles((dir, name) -> name.endsWith(dataset.getIssueFileFormat()));
			total = files.length;
			for (File file : files) {
				FileResource fileResource = new FileResource(file);
				String contents = fileResource.asString();
				IssueEntry entry = (IssueEntry) issueParser.parse(contents);
				List<IssueActivityEntry> activities = extract(entry.getKeySequential());
				for (IssueActivityEntry activity : activities) {
					entry.registerActivity(activity);
				}
				issues.add(new Report(entry));
				count += 1;
				if (count % 20 == 0) {
					subject.setMessage(count + " of " + total);
				}
//				if (count % 200 == 0) {
//					break;
//				}
				
			}
		}
		return issues;
	}

	private List<IssueActivityEntry> extract(int key) {
		List<IssueActivityEntry> activities = new ArrayList<IssueActivityEntry>();
		if (key == -1)
			return activities;

		File file = new File(dataset.formatLocalIssueHistoryFileName(key));
		FileResource fileResource = new FileResource(file);
		String contents = fileResource.asString();

		activities = historyParser.parse(contents);
		return activities;
	}

	@Override
	public Report findBy(String key) {
		// TODO Auto-generated method stub
		return null;
	}

}
