package br.unicamp.ic.miner.domain.jira;

import java.io.BufferedWriter;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.logging.log4j.Logger;

import br.unicamp.ic.miner.domain.core.Dataset;
import br.unicamp.ic.miner.domain.core.IssueComment;
import br.unicamp.ic.miner.domain.core.IssueForest;
import br.unicamp.ic.miner.domain.core.IssueNode;
import br.unicamp.ic.miner.domain.core.IssueNodeBuilder;
import br.unicamp.ic.miner.domain.core.IssueRemoteRepository;
import br.unicamp.ic.miner.domain.core.IssueTree;
import br.unicamp.ic.miner.infrastructure.persistence.FileResource;
import br.unicamp.ic.miner.infrastructure.persistence.IssueFileReader;
import br.unicamp.ic.miner.infrastructure.persistence.URLResource;
import jdsl.core.api.Position;

/**
 * Extract information from HADOOP Jira issues.
 * 
 * @author Luiz Alberto
 * @version 1.0
 * 
 */
public class JIRAIssuesImporter extends IssueRemoteRepository {

	private IssueFileReader reader;
	private final String regex = "((\\w+)-(\\d+))$";
	private Pattern pattern;
	private Logger logger;
	private Dataset dataset;

	/**
	 * Constructs a IssueJiraExtraxtor instance.
	 * 
	 * @param reader
	 * @param dataset TODO
	 * @param logger
	 */
	public JIRAIssuesImporter(IssueFileReader reader, Dataset dataset, Logger logger) {
		this.reader = reader;
		this.pattern = Pattern.compile(regex);
		this.logger = logger;
		this.dataset = dataset;
	}

	/**
	 * <code>extractIssue</code>
	 * 
	 */
	@Override
	public void extractIssuesFrom(int start, int end) {
		issues = new ArrayList<IssueNode>();
		for (int i = start; i <= end; i++) {
			IssueNode issue = this.extractIssue(i);
			if (issue != null) {
				issues.add(issue);
			}
		}
		extractForest();
	}

	/**
	 * Extracts an issue by its number.
	 * 
	 * @param number number of issue.
	 * @return an instance of <code>Issue</code> class.
	 */
	public IssueNode extractIssue(int number) {
		return read(dataset.formatUrl(number));
	}

	/**
	 * Extracts an issue by its URL.
	 * 
	 * @param url URL of issue.
	 * @return an instance of <code>Issue</code> class.
	 */
	@Override
	public IssueNode read(String url) {
		return extractFrom(url);
	}

	
	public void extractForest() {
		forest = new IssueForest();
		for (IssueNode entry : issues) {
			IssueTree tree = new IssueTree();
			buildTree(tree, tree.root(), entry);
			forest.add(tree);
		}
		extractTopologicalData();
	}

	@Override
	public boolean urlPatternMatch(String url) {
		Matcher matcher = pattern.matcher(url);
		if (matcher.find()) {
			return true;
		}
		return false;
	}

	/**
	 * 
	 * @param tree
	 * @param position
	 * @param issue
	 */
	private void buildTree(IssueTree tree, Position position, IssueNode issue) {

		if (position == tree.root()) {
			position = tree.insert(tree.root(), issue);
		}

		for (String link : this.extractLinks(issue.getDescription())) {
			IssueNode leaf = this.read(link);
			if (leaf == null) {
				continue;
			}

			if (!tree.contains(leaf.getKey())) {
				Position newer = tree.insert(position, leaf);
				buildTree(tree, newer, leaf);
			}
		}
	}

	private IssueNode extractFrom(String link) {
		IssueNode issue = null;
		try {
			logger.trace(link);
			String key = getKeySequential(link);
			String text;
			File file = new File(reader.getPath() + key + ".xml");

			if (file.exists()) {
				FileResource fileResource = new FileResource(file);
				text = fileResource.asString();
			} else {
				String url = dataset.formatUrl(Integer.parseInt(key));
				URLResource urlResource = new URLResource(url);
				text = urlResource.asString();
				writeIssueEntry(key, text);
			}

			InputStream xml = new ByteArrayInputStream(text.getBytes());
			JIRAIssueEntry entry = (JIRAIssueEntry) reader.load(xml);

			String assignee = entry.getAssignee();
			List<IssueComment> comments = entry.getComments();
			String created = entry.getCreated();
			String description = entry.getDescription();
			String priority = entry.getSeverity();
			String resolution = entry.getResolution();
			String resolved = entry.getResolved();
			String status = entry.getStatus();
			String title = entry.getTitle();
			String type = entry.getType();
			String updated = entry.getUpdated();
			String votes = entry.getVotes();
			int daysToResolve = entry.getDaysToResolve();
			
			
			issue = new IssueNodeBuilder(key, description)
					.withAssignee(assignee)
					.withComments(comments)
					.withCreated(created)
					.withPriority(priority)
					.withResolved(resolved)
					.withResolution(resolution)
					.withStatus(status)
					.withTitle(title)
					.withType(type)
					.withUpdated(updated)
					.withVotes(votes)
					.withDaysToResolve(daysToResolve)
					.build();

		} catch (Exception e) {
			logger.error(e.getMessage());
		}
		return issue;
	}

	private String getKeySequential(String address) {

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

	//private String formatUrl(String key) {
	//	return String.format("https://issues.apache.org/jira/si/jira.issueviews:issue-xml/%s/%s.xml", key, key);
	//}

	private void writeIssueEntry(String code, String entry) {
		String name = reader.getPath() + code + ".xml";

		try {
			FileWriter file = new FileWriter(name);
			BufferedWriter writer = new BufferedWriter(file);

			writer.write(entry);

			writer.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	
	public void extractTopologicalData() {
		forest.extractTopological();
	}

}
