package br.unicamp.ic.crawler.domain.core;

/**
 * 
 * @author luiz
 *
 */
public class Dataset {
	private String name;
	private String remoteIssueUrl;
	private String localIssuePath;
	private String issueFileFormat;
	private String remoteIssueHistoryUrl;
	private String localIssueHistoryPath;
	private String issueHistoryFileFormat;
	private String localNameMask;
	private int firstIssue;
	private int lastIssue;
	private String bts;

	/**
	 * 
	 * @param name
	 * @param remoteIssueUrl
	 * @param localIssuePath
	 * @param issueFileFormat
	 * @param remoteIssueHistoryUrl
	 * @param localIssueHistoryPath
	 * @param issueHistoryFileFormat
	 * @param localNameMask
	 * @param firstIssue
	 * @param lastIssue
	 * @param bts TODO
	 */
	public Dataset(String name, String remoteIssueUrl, String localIssuePath, String issueFileFormat,
			String remoteIssueHistoryUrl, String localIssueHistoryPath, String issueHistoryFileFormat,
			String localNameMask, int firstIssue, int lastIssue, String bts) {
		super();
		this.name = name;
		this.remoteIssueUrl = remoteIssueUrl;
		this.localIssuePath = localIssuePath;
		this.issueFileFormat = issueFileFormat;
		this.remoteIssueHistoryUrl = remoteIssueHistoryUrl;
		this.localIssueHistoryPath = localIssueHistoryPath;
		this.issueHistoryFileFormat = issueHistoryFileFormat;
		this.localNameMask = localNameMask;
		this.firstIssue = firstIssue;
		this.lastIssue = lastIssue;
		this.bts = bts;
	}

	/**
	 * @return the name
	 */
	public String getName() {
		return name;
	}

	/**
	 * @return the remoteIssueUrl
	 */
	public String getRemoteIssueUrl() {
		return remoteIssueUrl;
	}

	/**
	 * @return the localIssuePath
	 */
	public String getLocalIssuePath() {
		return localIssuePath;
	}

	/**
	 * @return the issueFileFormat
	 */
	public String getIssueFileFormat() {
		return issueFileFormat;
	}

	/**
	 * @return the remoteIssueHistoryUrl
	 */
	public String getRemoteIssueHistoryUrl() {
		return remoteIssueHistoryUrl;
	}

	/**
	 * @return the localIssueHistoryPath
	 */
	public String getLocalIssueHistoryPath() {
		return localIssueHistoryPath;
	}

	/**
	 * @return the issueHistoryFileFormat
	 */
	public String getIssueHistoryFileFormat() {
		return issueHistoryFileFormat;
	}

	/**
	 * @return the localNameMask
	 */
	public String getLocalNameMask() {
		return localNameMask;
	}

	/**
	 * @return the firstIssue
	 */
	public int getFirstIssue() {
		return firstIssue;
	}

	/**
	 * @return the lastIssue
	 */
	public int getLastIssue() {
		return lastIssue;
	}

	/**
	 * 
	 * @param key
	 * @return
	 */
	public String formatRemoteIssueUrl(int key) {
		return String.format(remoteIssueUrl, key);
	}

	/**
	 * 
	 * @param key
	 * @return the local file name formatted.
	 */
	public String formatLocalIssueFileName(int key) {
		StringBuilder fileName = new StringBuilder(localIssuePath);
		fileName.append(localNameMask);
		fileName.append(".");
		fileName.append(issueFileFormat);
		return String.format(fileName.toString(), key);
	}
	
	/**
	 * 
	 * @param key
	 * @return
	 */
	public String formatRemoteIssueHistoryUrl(int key) {
		return String.format(remoteIssueHistoryUrl, key);
	}

	/**
	 * 
	 * @param key
	 * @return the local file name formatted.
	 */
	public String formatLocalIssueHistoryFileName(int key) {
		StringBuilder fileName = new StringBuilder(localIssueHistoryPath);
		fileName.append(localNameMask);
		fileName.append(".");
		fileName.append(issueHistoryFileFormat);
		return String.format(fileName.toString(), key);
	}
	@Override
	public String toString() {
		return super.toString();
	}

	public String getBts() {
		// TODO Auto-generated method stub
		return this.bts;
	}

	

}
