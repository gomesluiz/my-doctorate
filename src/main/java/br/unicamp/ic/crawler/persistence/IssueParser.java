package br.unicamp.ic.crawler.persistence;

/**
 * 
 * @author 	Luiz Alberto
 * @version %I%, %G%
 *
 */
public interface IssueParser {
	Object parse(String contents);
}