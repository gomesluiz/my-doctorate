package br.unicamp.ic.miner.infrastructure.persistence;

import java.io.InputStream;

/**
 * 
 * @author 	Luiz Alberto
 * @version %I%, %G%
 *
 */
public interface IssueFileReader {
	/**
	 * 
	 * @param inputStream
	 * @return
	 */
	Object load(InputStream inputStream);
	
	/**
	 * 
	 * @return
	 */
	String getPath();
}