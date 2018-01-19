package br.unicamp.ic.crawler.persistence;

import java.util.List;

import br.unicamp.ic.crawler.domain.core.IssueEntryActivity;

public interface HistoryParser {
	public List<IssueEntryActivity> parse(String contents);
}
