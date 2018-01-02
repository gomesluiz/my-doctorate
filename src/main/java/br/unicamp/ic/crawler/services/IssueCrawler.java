package br.unicamp.ic.crawler.services;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import br.unicamp.ic.crawler.domain.core.Dataset;
import br.unicamp.ic.crawler.domain.core.IssueEntry;
import br.unicamp.ic.crawler.domain.core.IssueEntryActivity;
import br.unicamp.ic.crawler.domain.core.IssueNode;
import br.unicamp.ic.crawler.persistence.IssueFileWriter;
import br.unicamp.ic.crawler.persistence.FileResource;
import br.unicamp.ic.crawler.persistence.URLResource;
import br.unicamp.ic.crawler.services.filters.IssueFilter;

/**
 * 
 * @author Luiz Alberto
 *
 */
public abstract class IssueCrawler {
	protected Dataset dataset;
	protected List<IssueNode> issues;

	public abstract void downloadAll();
	public abstract void download(int key);
	public abstract void search(IssueFilter filter);
	public abstract IssueEntry convert(String contents);
	public abstract List<IssueEntryActivity> extract(int key);

	/**
	 * TODO
	 * 
	 * @param source
	 */
	protected String readContentsFrom(String source) {
		String contents;

		//File file = new File(target);
		//if (!file.exists()) {
			URLResource urlResource = new URLResource(source);
			contents = urlResource.asString();
			//storeIn(target, contents);
		//}
			return contents;
	}

	/**
	 * 
	 * @return
	 */
	protected List<IssueNode> loadIssuesFromFile() {
		List<IssueNode> issues = new ArrayList<IssueNode>();
		File folder = new File(dataset.getLocalIssuePath());
		if (folder.exists()) {
			File[] files = folder.listFiles();
			for (File file : files) {
				if (file.getName().endsWith(dataset.getIssueFileFormat())) {
					FileResource fileResource = new FileResource(file);
					String contents = fileResource.asString();
					IssueEntry entry = convert(contents);
					List<IssueEntryActivity> activities = extract(entry.getKeySequential());
					for (IssueEntryActivity activity : activities) {
						entry.registerActivity(activity);
					}
					issues.add(new IssueNode(entry));
				}
			}
		}
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
	protected void writeContentsTo(String target, String contents) {
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