package br.unicamp.ic.crawler.domain.core;

import java.util.List;

public interface IssueEntry {

	final String ISSUE_ENTRY_NA = "NA";

	String getAssignee();

	List<IssueComment> getComments();

	String getCreated();

	String getKey();

	int getKeySequential();

	String getDescription();

	String getSeverity();

	String convertSeverityToCode();

	String getResolution();

	String convertResolutionToCode();

	String getResolved();

	String getStatus();

	String converteStatusToCode();

	String getTitle();

	String getType();

	String convertTypeToCode();

	String getUpdated();

	String getVotes();

	int getDaysToResolve();

	void registerActivity(IssueEntryActivity activity);
	
	List<IssueEntryActivity> getActivities();
}