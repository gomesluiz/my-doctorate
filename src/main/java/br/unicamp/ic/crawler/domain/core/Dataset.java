package br.unicamp.ic.crawler.domain.core;

public class Dataset {
	private String name;
	private String url;
	private int first;
	private int last;
	
	/**
	 * Class constructor.
	 * 
	 * @param name 	dataset name.
	 * @param url	dataset url.	
	 * @param first	str
	 * @param last
	 */
	public Dataset(String name, String url, int first, int last) {
		this.name 	= name;
		this.url  	= url;
		this.first 	= first;
		this.last	= last;
	}

	/**
	 * 
	 * @return name
	 */
	public String getName() {
		return name;
	}

	/**
	 * 
	 * @return url
	 */
	public String getUrl() {
		return url;
	}

	/**
	 * 
	 * @return first
	 */
	public int getFirst() {
		return first;
	}

	/**
	 * 
	 * @return last
	 */
	public int getLast() {
		return last;
	}

	public String formatUrl(int key) {
		return String.format(getUrl(), key);
	}
	
}
