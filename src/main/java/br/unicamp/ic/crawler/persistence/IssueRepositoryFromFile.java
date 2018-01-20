package br.unicamp.ic.crawler.persistence;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import br.unicamp.ic.crawler.domain.core.Dataset;
import br.unicamp.ic.crawler.domain.core.IssueEntry;
import br.unicamp.ic.crawler.domain.core.IssueActivityEntry;
import br.unicamp.ic.crawler.domain.core.IssueNode;
import br.unicamp.ic.crawler.services.HistoryParser;
import br.unicamp.ic.crawler.services.IssueParser;

public class IssueRepositoryFromFile implements IssueRepository {

	private Dataset dataset;
	private IssueParser issueParser;
	private HistoryParser historyParser;

	public IssueRepositoryFromFile(Dataset dataset, IssueParser issueParser, HistoryParser historyParser) {
		this.dataset = dataset;
		this.issueParser = issueParser;
		this.historyParser = historyParser;
	}

	@Override
	public List<IssueNode> findAll() {
		List<IssueNode> issues = new ArrayList<IssueNode>();
		File folder = new File(dataset.getLocalIssuePath());
		if (folder.exists()) {
			File[] files = folder.listFiles();
			for (File file : files) {
				if (file.getName().endsWith(dataset.getIssueFileFormat())) {
					FileResource fileResource = new FileResource(file);
					String contents = fileResource.asString();
					IssueEntry entry = (IssueEntry) issueParser.parse(contents);
					List<IssueActivityEntry> activities = extract(entry.getKeySequential());
					for (IssueActivityEntry activity : activities) {
						entry.registerActivity(activity);
					}
					issues.add(new IssueNode(entry));
				}
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
	public IssueNode findBy(String key) {
		// TODO Auto-generated method stub
		return null;
	}

}
