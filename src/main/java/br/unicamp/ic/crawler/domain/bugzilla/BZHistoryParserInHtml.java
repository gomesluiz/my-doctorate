package br.unicamp.ic.crawler.domain.bugzilla;

import java.util.ArrayList;
import java.util.List;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

import br.unicamp.ic.crawler.domain.core.IssueEntryActivity;
import br.unicamp.ic.crawler.persistence.HistoryParser;

public class BZHistoryParserInHtml implements HistoryParser {

	@Override
	public List<IssueEntryActivity> parse(String contents) {
		List<IssueEntryActivity> activities = new ArrayList<IssueEntryActivity>();
		Document doc = Jsoup.parse(contents);
		Element table = doc.select("table").get(0);
		Elements rows = table.select("tr");
		String who = "", when = "", what = "", removed = "", added = "";
		for (int j = 1; j < rows.size(); j++) {
			int columns = rows.get(j).select("td").size();
			int shift = columns - 3;
			if (columns == 5) {
				who = rows.get(j).select("td").get(0).text();
				when = rows.get(j).select("td").get(1).text();
			}
			what = rows.get(j).select("td").get(shift).text();
			removed = rows.get(j).select("td").get(shift + 1).text();
			added = rows.get(j).select("td").get(shift + 2).text();
			BZIssueEntryActivity activity = new BZIssueEntryActivity(who, when, what, removed, added);
			activities.add(activity);
		}
		return activities;
	}

}
