package br.unicamp.ic.miner.domain.core;

import java.util.List;

public interface IssueEntry {
	
	final String ISSUE_ENTRY_NA = "NA";
	
	String getAssignee();
	List<IssueComment> getComments();
	String getCreated();
	
	String getKey();
	String getKeySequential();
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
}