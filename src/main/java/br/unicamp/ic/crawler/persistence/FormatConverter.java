package br.unicamp.ic.crawler.persistence;

/**
 * 
 * @author 	Luiz Alberto
 * @version %I%, %G%
 *
 */
public interface FormatConverter {
	@SuppressWarnings("rawtypes")
	Object load(String contents, Class type);
}