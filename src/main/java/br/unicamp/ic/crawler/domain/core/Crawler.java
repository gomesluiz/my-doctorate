package br.unicamp.ic.crawler.domain.core;

/**
 * 
 * @author Luiz Alberto
 *
 */
public interface Crawler {
	//public String getKey(String url);
	//public String getPath();
	public IssueNode extractFrom(String url);
	//public IssueEntry load(InputStream file); 
	public boolean urlPatternMatch(String url);
	
}