package br.unicamp.ic.crawler.domain.bugzilla;

import br.unicamp.ic.crawler.domain.core.IssueEntryActivity;

public class BZIssueEntryActivity implements IssueEntryActivity {
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

	/* (non-Javadoc)
	 * @see br.unicamp.ic.crawler.persistence.bugzilla.IssueEntryHistory#getWho()
	 */
	@Override
	public String getWho() {
		return who;
	}

	/* (non-Javadoc)
	 * @see br.unicamp.ic.crawler.persistence.bugzilla.IssueEntryHistory#getWhen()
	 */
	@Override
	public String getWhen() {
		return when;
	}

	/* (non-Javadoc)
	 * @see br.unicamp.ic.crawler.persistence.bugzilla.IssueEntryHistory#getWhat()
	 */
	@Override
	public String getWhat() {
		return what;
	}

	/* (non-Javadoc)
	 * @see br.unicamp.ic.crawler.persistence.bugzilla.IssueEntryHistory#getRemoved()
	 */
	@Override
	public String getRemoved() {
		return removed;
	}

	/* (non-Javadoc)
	 * @see br.unicamp.ic.crawler.persistence.bugzilla.IssueEntryHistory#getAdded()
	 */
	@Override
	public String getAdded() {
		return added;
	}

}
