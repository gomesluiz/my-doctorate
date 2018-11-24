package br.unicamp.ic.crawler.persistence;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import br.unicamp.ic.crawler.domain.core.IssueActivityEntry;
import br.unicamp.ic.crawler.domain.core.Report;

/**
 * 
 * The <code>CSVRawIssueFormatter</code> class implements issue raw format.
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
					"Bug_Id"
					, "Summary"
					, "Description"
					, "Assignee"
					, "Created"
					, "Resolution"
					, "ResolutionCode"
					, "Resolved"
					, "Status"
					, "StatusCode"
					, "Type"
					, "TypeCode"
					, "Updated"
					, "Votes"
					, "QuantityOfComments"
					, "DaysToResolve"
					, "Severity"
					, "SeverityCode"
					, "Reporter"
					));
		} else {
			headers = new ArrayList<String>(Arrays.asList("Key", "Who", "When", "What", "Removed", "Added"));
		}

		return headers.toArray();
	}

	/**
	 * 
	 */
	@Override
	public List<Object> format(Report report) {

		List<Object> record = new ArrayList<Object>();

		String resolved = report.getResolved();
		int daysToResolve = report.getDaysToResolve();
		
		String description = report.getDescription();
		String summary = report.getSummary();
		
		description = description.replaceAll("\\&.*?\\;", "")
				.replaceAll("<.*?>", "")
				.replaceAll("\"", "")
				.replaceAll(",", "");
		summary = summary.replaceAll("\\&.*?\\;", "")
				.replaceAll("<.*?>", "")
				.replaceAll("\"", "")
				.replaceAll(",", "");
		
		record.add(report.getKey());
		record.add(summary);
		record.add(description);
		record.add(report.getAssignee());
		record.add(report.getResolution());
		record.add(report.getCreated());
		record.add(report.getResolution());
		record.add(report.getResolutionCode());
		record.add(resolved);
		record.add(report.getStatus());
		record.add(report.getStatusCode());
		record.add(report.getType());
		record.add(report.getTypeCode());
		record.add(report.getUpdated());
		record.add(report.getVotes());
		record.add(report.getQuantityOfComments());
		record.add(daysToResolve);
		record.add(report.getSeverity());
		record.add(report.getSeverityCode());
		record.add(report.getReporter());
		
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
