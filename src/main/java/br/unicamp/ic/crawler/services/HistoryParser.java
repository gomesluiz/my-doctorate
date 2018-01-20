package br.unicamp.ic.crawler.services;

import java.util.List;

import br.unicamp.ic.crawler.domain.core.IssueActivityEntry;

public interface HistoryParser {
	public List<IssueActivityEntry> parse(String contents);
}
