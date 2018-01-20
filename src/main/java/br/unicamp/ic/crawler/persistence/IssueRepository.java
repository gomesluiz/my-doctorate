package br.unicamp.ic.crawler.persistence;

import java.util.List;

import br.unicamp.ic.crawler.domain.core.IssueNode;

public interface IssueRepository {

	List<IssueNode> findAll();

	IssueNode findBy(String key);

}
