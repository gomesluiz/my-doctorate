package br.unicamp.ic.crawler.domain.bugzilla;

public class BZIssueEntryActivity {
	private String who;
	private String when;
	private String what;
	private String removed;
	private String added;

	public BZIssueEntryActivity(String who, String when, String what, String removed, String added) {
		this.who = who;
		this.when = when;
		this.what = what;
		this.removed = removed;
		this.added = added;
	}

	public String getWho() {
		return who;
	}

	public String getWhen() {
		return when;
	}

	public String getWhat() {
		return what;
	}

	public String getRemoved() {
		return removed;
	}

	public String getAdded() {
		return added;
	}

}
