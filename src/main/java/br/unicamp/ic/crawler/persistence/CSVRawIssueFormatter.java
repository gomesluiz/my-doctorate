package br.unicamp.ic.crawler.persistence;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import br.unicamp.ic.crawler.domain.core.IssueActivityEntry;
import br.unicamp.ic.crawler.domain.core.Report;

/**
 * 
 * @author luiz
 *
 */
public class CSVRawIssueFormatter implements CSVOutputFormatter {
	@Override
	public Object[] getHeaders(int header) {
		ArrayList<String> headers;

		if (header == ISSUE_HEADER_TYPE) {
			headers = new ArrayList<String>(Arrays.asList(
					"IssueKey"
					, "Assignee"
					, "Created"
					, "Resolution"
					, "ResolutionCode"
					, "Resolved"
					, "Severity"
					, "SeverityCode"
					, "Status"
					, "StatusCode"
					, "Type"
					, "TypeCode"
					, "Updated"
					, "Votes"
					, "DaysToResolve"
					, "QuantityOfComments"
					));
		} else {
			headers = new ArrayList<String>(Arrays.asList("IssueKey", "Who", "When", "What", "Removed", "Added"));
		}

		return headers.toArray();
	}

	/**
	 * 
	 */
	@Override
	public List<Object> format(Report issue) {

		List<Object> record = new ArrayList<Object>();

		String description = issue.getDescription();
		description = description.replaceAll("\\&.*?\\;", "").replaceAll("<.*?>", " ");

		record.add(issue.getKey());
		record.add(issue.getAssignee());
		record.add(issue.getCreated());
		record.add(issue.getResolution());
		record.add(issue.getResolutionCode());
		record.add(issue.getResolved());
		record.add(issue.getSeverity());
		record.add(issue.getSeverityCode());
		record.add(issue.getStatus());
		record.add(issue.getStatusCode());
		record.add(issue.getType());
		record.add(issue.getTypeCode());
		record.add(issue.getUpdated());
		record.add(issue.getVotes());
		record.add(issue.getDaysToResolve());
		record.add(issue.getQuantityOfComments());

		return record;
	}

	@Override
	public Iterable<?> format(String key, IssueActivityEntry activity) {
		List<Object> record = new ArrayList<Object>();

		record.add(key);
		record.add(activity.getWho());
		record.add(activity.getWhen());
		record.add(activity.getWhat());
		record.add(activity.getRemoved());
		record.add(activity.getAdded());

		return record;

	}
}
