package br.unicamp.ic.crawler.persistence;

import java.util.List;

import br.unicamp.ic.crawler.domain.core.Report;

public interface ReportRepository {

	List<Report> findAll();

	Report findBy(String key);

}
