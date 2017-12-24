package br.unicamp.ic.crawler.persistence;

import java.io.InputStream;

/**
 * 
 * @author 	Luiz Alberto
 * @version %I%, %G%
 *
 */
public interface IssueFileReader {
	@SuppressWarnings("rawtypes")
	Object load(InputStream inputStream, Class type);
	String getPath();
}