package br.unicamp.ic.crawler.persistence;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import br.unicamp.ic.crawler.domain.bugzilla.BZHistoryParserInHtml;
import br.unicamp.ic.crawler.domain.bugzilla.BZIssueParserInXml;
import br.unicamp.ic.crawler.domain.core.IssueActivityEntry;
import br.unicamp.ic.crawler.domain.core.IssueEntry;
import br.unicamp.ic.crawler.domain.core.IssueNode;
import br.unicamp.ic.crawler.persistence.IssueRepository;
import br.unicamp.ic.crawler.services.HistoryParser;
import br.unicamp.ic.crawler.services.IssueParser;

public class IssueRepositoryFromMemory implements IssueRepository {

	public static List<String> reports = Arrays.asList(
			"<bugzilla version=\"5.0.3\" urlbase=\"https://bugs.eclipse.org/bugs/\" maintainer=\"webmaster@eclipse.org\">"
					+ "<bug>" + "<bug_id>14582</bug_id>" + "<creation_ts>2002-04-25 06:24:21 -0400</creation_ts>"
					+ "<short_desc>rename enabled on multi-selection</short_desc>"
					+ "<delta_ts>2002-04-25 06:33:05 -0400</delta_ts>" + "<reporter_accessible>1</reporter_accessible>"
					+ "<cclist_accessible>1</cclist_accessible>" + "<classification_id>2</classification_id>"
					+ "<classification>Eclipse</classification>" + "<product>JDT</product>"
					+ "<component>UI</component>" + "<version>2.0</version>" + "<rep_platform>PC</rep_platform>"
					+ "<op_sys>Windows 2000</op_sys>" + "<bug_status>RESOLVED</bug_status>"
					+ "<resolution>FIXED</resolution>" + "<bug_file_loc/><status_whiteboard/>"
					+ "<keywords/><priority>P3</priority>" + "<bug_severity>major</bug_severity>"
					+ "<target_milestone>---</target_milestone>" + "<everconfirmed>1</everconfirmed>"
					+ "<reporter name=\"Adam Kiezun\">akiezun</reporter>"
					+ "<assigned_to name=\"Adam Kiezun\">akiezun</assigned_to>" + "<votes>0</votes>"
					+ "<comment_sort_order>oldest_to_newest</comment_sort_order>" + "<long_desc isprivate=\"0\">"
					+ "<commentid>46391</commentid>" + "<comment_count>0</comment_count>"
					+ "<who name=\"Adam Kiezun\">akiezun</who>" + "<bug_when>2002-04-25 06:24:21 -0400</bug_when>"
					+ "<thetext> </thetext>" + "</long_desc><long_desc isprivate=\"0\">"
					+ "<commentid>46392</commentid>" + "<comment_count>1</comment_count>"
					+ "<who name=\"Adam Kiezun\">akiezun</who>" + "<bug_when>2002-04-25 06:33:05 -0400</bug_when>"
					+ "<thetext>fixed</thetext>" + "</long_desc>" + "</bug>" + "</bugzilla>");
	public static  List<String> histories = Arrays.asList("<!DOCTYPE html>\n" + "<html lang=\"en\">\n" + "  <head>\n"
			+ "    <title>Changes made to bug 14582</title>\n" + "\n"
			+ "      <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n" + "\n"
			+ "<link href=\"data/assets/fe6bc1a55c6a92f0fa05c7b94e8ccf3e.css?1511975182\" rel=\"stylesheet\" type=\"text/css\">\n"
			+ "\n" + "\n" + "\n" + "    \n"
			+ "<script type=\"text/javascript\" src=\"data/assets/1b4e898422a669ab82b604a2c23edce5.js?1511975189\"></script>\n"
			+ "\n" + "    <script type=\"text/javascript\">\n" + "    <!--\n" + "        YAHOO.namespace('bugzilla');\n"
			+ "        YAHOO.util.Event.addListener = function (el, sType, fn, obj, overrideContext) {\n"
			+ "               if ( (\"onpagehide\" in window || YAHOO.env.ua.gecko) && sType === \"unload\") { sType = \"pagehide\"; };\n"
			+ "               var capture = ((sType == \"focusin\" || sType == \"focusout\") && !YAHOO.env.ua.ie) ? true : false;\n"
			+ "               return this._addListener(el, this._getType(sType), fn, obj, overrideContext, capture);\n"
			+ "         };\n" + "        if ( \"onpagehide\" in window || YAHOO.env.ua.gecko) {\n"
			+ "            YAHOO.util.Event._simpleRemove(window, \"unload\", \n"
			+ "                                           YAHOO.util.Event._unload);\n" + "        }\n" + "        \n"
			+ "        function unhide_language_selector() { \n" + "            YAHOO.util.Dom.removeClass(\n"
			+ "                'lang_links_container', 'bz_default_hidden'\n" + "            ); \n" + "        } \n"
			+ "        YAHOO.util.Event.onDOMReady(unhide_language_selector);\n" + "\n" + "        \n"
			+ "        var BUGZILLA = {\n" + "            param: {\n" + "                cookiepath: '\\/bugs',\n"
			+ "                maxusermatches: 10\n" + "            },\n" + "            constant: {\n"
			+ "                COMMENT_COLS: 80\n" + "            },\n" + "            string: {\n"
			+ "                \n" + "\n" + "                attach_desc_required:\n"
			+ "                    \"You must enter a Description for this attachment.\",\n"
			+ "                component_required:\n"
			+ "                    \"You must select a Component for this bug.\",\n"
			+ "                description_required:\n"
			+ "                    \"You must enter a Description for this bug.\",\n"
			+ "                short_desc_required:\n"
			+ "                    \"You must enter a Summary for this bug.\",\n"
			+ "                version_required:\n"
			+ "                    \"You must select a Version for this bug.\"\n" + "            }\n" + "        };\n"
			+ "\n" + "    // -->\n" + "    </script>\n"
			+ "<script type=\"text/javascript\" src=\"data/assets/d41d8cd98f00b204e9800998ecf8427e.js?1511975189\"></script>\n"
			+ "\n" + "    \n" + "\n" + "    \n"
			+ "    <link rel=\"search\" type=\"application/opensearchdescription+xml\"\n"
			+ "                       title=\"Bugzilla\" href=\"./search_plugin.cgi\">\n"
			+ "    <link rel=\"shortcut icon\" href=\"images/favicon.ico\">\n" + "  </head>\n" + "\n" + "  <body \n"
			+ "        class=\"bugs-eclipse-org-bugs yui-skin-sam\">\n" + "\n"
			+ "  <div id=\"header\"><!-- 1.0@bugzilla.org -->\n" + "\n" + "\n" + "\n" + "\n" + "\n"
			+ "<!--  START OF SOLSTICE HEADER -->\n" + " <style type=\"text/css\">\n"
			+ "    @import url('https://www.eclipse.org/eclipse.org-common/themes/solstice/public/stylesheets/barebone.min.css')\n"
			+ "    </style>\n" + "    <script\n"
			+ "      src=\"https://www.eclipse.org/eclipse.org-common/themes/solstice/public/javascript/barebone.min.js\">\n"
			+ "    </script><header role=\"banner\" class=\"barebone-layout thin-header padding-top-5 padding-bottom-5\"  id=\"header-wrapper\">\n"
			+ "  <div class=\"container-fluid reset\">\n" + "    <div class=\"row-fluid\" id=\"header-row\">\n"
			+ "            <div class=\"col-sm-8 col-md-6 col-lg-4\" id=\"header-left\">\n"
			+ "        <div class=\"wrapper-logo-default\"><a href=\"https://www.eclipse.org/\"><img class=\"logo-eclipse-default img-responsive hidden-xs\" alt=\"logo\" src=\"/eclipse.org-common/themes/solstice/public/images/logo/eclipse-426x100.png\"/></a></div>\n"
			+ "      </div>            <div class=\"col-sm-16 col-md-18 col-lg-20\" id=\"main-menu-wrapper\">\n"
			+ "  <div class=\"navbar yamm\" id=\"main-menu\">\n"
			+ "    <div id=\"navbar-collapse-1\" class=\"navbar-collapse collapse\">\n"
			+ "      <ul class=\"nav navbar-nav navbar-right\">\n"
			+ "        <li class=\"visible-thin\"><a href=\"https://www.eclipse.org/downloads/\" target=\"_self\">Download</a></li><li><a href=\"https://www.eclipse.org/users/\" target=\"_self\">Getting Started</a></li><li><a href=\"https://www.eclipse.org/membership/\" target=\"_self\">Members</a></li><li><a href=\"https://www.eclipse.org/projects/\" target=\"_self\">Projects</a></li>                  <li class=\"dropdown visible-xs\"><a href=\"#\" data-toggle=\"dropdown\" class=\"dropdown-toggle\">Community <b class=\"caret\"></b></a><ul class=\"dropdown-menu\"><li><a href=\"http://marketplace.eclipse.org\">Marketplace</a></li><li><a href=\"http://events.eclipse.org\">Events</a></li><li><a href=\"http://www.planeteclipse.org/\">Planet Eclipse</a></li><li><a href=\"https://www.eclipse.org/community/eclipse_newsletter/\">Newsletter</a></li><li><a href=\"https://www.youtube.com/user/EclipseFdn\">Videos</a></li></ul></li><li class=\"dropdown visible-xs\"><a href=\"#\" data-toggle=\"dropdown\" class=\"dropdown-toggle\">Participate <b class=\"caret\"></b></a><ul class=\"dropdown-menu\"><li><a href=\"https://bugs.eclipse.org/bugs/\">Report a Bug</a></li><li><a href=\"https://www.eclipse.org/forums/\">Forums</a></li><li><a href=\"https://www.eclipse.org/mail/\">Mailing Lists</a></li><li><a href=\"https://wiki.eclipse.org/\">Wiki</a></li><li><a href=\"https://wiki.eclipse.org/IRC\">IRC</a></li><li><a href=\"https://www.eclipse.org/contribute/\">How to Contribute</a></li></ul></li><li class=\"dropdown visible-xs\"><a href=\"#\" data-toggle=\"dropdown\" class=\"dropdown-toggle\">Working Groups <b class=\"caret\"></b></a><ul class=\"dropdown-menu\"><li><a href=\"http://wiki.eclipse.org/Auto_IWG\">Automotive</a></li><li><a href=\"http://iot.eclipse.org\">Internet of Things</a></li><li><a href=\"http://locationtech.org\">LocationTech</a></li><li><a href=\"http://lts.eclipse.org\">Long-Term Support</a></li><li><a href=\"http://polarsys.org\">PolarSys</a></li><li><a href=\"http://science.eclipse.org\">Science</a></li><li><a href=\"http://www.openmdm.org\">OpenMDM</a></li></ul></li>          <!-- More -->\n"
			+ "          <li class=\"dropdown eclipse-more hidden-xs\">\n"
			+ "            <a data-toggle=\"dropdown\" class=\"dropdown-toggle\">More<b class=\"caret\"></b></a>\n"
			+ "            <ul class=\"dropdown-menu\">\n" + "              <li>\n"
			+ "                <!-- Content container to add padding -->\n"
			+ "                <div class=\"yamm-content\">\n" + "                  <div class=\"row\">\n"
			+ "                    <ul class=\"col-sm-8 list-unstyled\"><li><p><strong>Community</strong></p></li><li><a href=\"http://marketplace.eclipse.org\">Marketplace</a></li><li><a href=\"http://events.eclipse.org\">Events</a></li><li><a href=\"http://www.planeteclipse.org/\">Planet Eclipse</a></li><li><a href=\"https://www.eclipse.org/community/eclipse_newsletter/\">Newsletter</a></li><li><a href=\"https://www.youtube.com/user/EclipseFdn\">Videos</a></li></ul><ul class=\"col-sm-8 list-unstyled\"><li><p><strong>Participate</strong></p></li><li><a href=\"https://bugs.eclipse.org/bugs/\">Report a Bug</a></li><li><a href=\"https://www.eclipse.org/forums/\">Forums</a></li><li><a href=\"https://www.eclipse.org/mail/\">Mailing Lists</a></li><li><a href=\"https://wiki.eclipse.org/\">Wiki</a></li><li><a href=\"https://wiki.eclipse.org/IRC\">IRC</a></li><li><a href=\"https://www.eclipse.org/contribute/\">How to Contribute</a></li></ul><ul class=\"col-sm-8 list-unstyled\"><li><p><strong>Working Groups</strong></p></li><li><a href=\"http://wiki.eclipse.org/Auto_IWG\">Automotive</a></li><li><a href=\"http://iot.eclipse.org\">Internet of Things</a></li><li><a href=\"http://locationtech.org\">LocationTech</a></li><li><a href=\"http://lts.eclipse.org\">Long-Term Support</a></li><li><a href=\"http://polarsys.org\">PolarSys</a></li><li><a href=\"http://science.eclipse.org\">Science</a></li><li><a href=\"http://www.openmdm.org\">OpenMDM</a></li></ul>                  </div>\n"
			+ "                </div>\n" + "              </li>\n" + "            </ul>\n" + "          </li>\n"
			+ "              </ul>\n" + "    </div>\n" + "    <div class=\"navbar-header\">\n"
			+ "      <button type=\"button\" class=\"navbar-toggle\" data-toggle=\"collapse\" data-target=\"#navbar-collapse-1\">\n"
			+ "      <span class=\"sr-only\">Toggle navigation</span>\n" + "      <span class=\"icon-bar\"></span>\n"
			+ "      <span class=\"icon-bar\"></span>\n" + "      <span class=\"icon-bar\"></span>\n"
			+ "      <span class=\"icon-bar\"></span>\n" + "      </button>\n"
			+ "      <div class=\"wrapper-logo-mobile\"><a class=\"navbar-brand visible-xs\" href=\"https://www.eclipse.org/\"><img class=\"logo-eclipse-default-mobile img-responsive\" alt=\"logo\" src=\"/eclipse.org-common/themes/solstice/public/images/logo/eclipse-800x188.png\"/></a></div>    </div>\n"
			+ "  </div>\n" + "</div>\n" + "    </div>\n" + "  </div>\n" + "</header>\n"
			+ "<!--  END OF SOLSTICE HEADER -->\n" + "\n" + "    <div id=\"titles\">\n"
			+ "      <span id=\"title\">Bugzilla &ndash; Activity log for bug 14582: rename enabled on multi-selection</span>\n"
			+ "\n" + "\n" + "    </div>\n" + "\n" + "\n" + "    <div id=\"common_links\"><ul class=\"links\">\n"
			+ "  <li><a href=\"./\">Home</a></li>\n"
			+ "  <li><span class=\"separator\">| </span><a href=\"enter_bug.cgi\">New</a></li>\n"
			+ "  <li><span class=\"separator\">| </span><a href=\"describecomponents.cgi\">Browse</a></li>\n"
			+ "  <li><span class=\"separator\">| </span><a href=\"query.cgi\">Search</a></li>\n" + "\n"
			+ "  <li class=\"form\">\n" + "    <span class=\"separator\">| </span>\n"
			+ "    <form action=\"buglist.cgi\" method=\"get\"\n"
			+ "        onsubmit=\"if (this.quicksearch.value == '')\n"
			+ "                  { alert('Please enter one or more search terms first.');\n"
			+ "                    return false; } return true;\">\n"
			+ "    <input type=\"hidden\" id=\"no_redirect_top\" name=\"no_redirect\" value=\"0\">\n"
			+ "    <script type=\"text/javascript\">\n" + "      if (history && history.replaceState) {\n"
			+ "        var no_redirect = document.getElementById(\"no_redirect_top\");\n"
			+ "        no_redirect.value = 1;\n" + "      }\n" + "    </script>\n"
			+ "    <input class=\"txt\" type=\"text\" id=\"quicksearch_top\" name=\"quicksearch\" \n"
			+ "           title=\"Quick Search\" value=\"\">\n"
			+ "    <input class=\"btn\" type=\"submit\" value=\"Search\" \n" + "           id=\"find_top\"></form>\n"
			+ "  <a href=\"page.cgi?id=quicksearch.html\" title=\"Quicksearch Help\">[?]</a></li>\n" + "\n"
			+ "  <li><span class=\"separator\">| </span><a href=\"report.cgi\">Reports</a></li>\n" + "\n" + "  <li>\n"
			+ "      <span class=\"separator\">| </span>\n" + "        <a href=\"request.cgi\">Requests</a></li>\n"
			+ "\n" + "\n" + "  \n" + "    \n" + "\n" + "    <li id=\"mini_login_container_top\">\n"
			+ "  <span class=\"separator\">| </span>\n"
			+ "  <a id=\"login_link_top\" href=\"show_activity.cgi?id=14582&amp;GoAheadAndLogIn=1\"\n"
			+ "     onclick=\"return show_mini_login_form('_top')\">Log In</a>\n" + "\n"
			+ "  <form action=\"show_activity.cgi?id=14582\" method=\"POST\"\n"
			+ "        class=\"mini_login bz_default_hidden\"\n" + "        id=\"mini_login_top\">\n"
			+ "    <input id=\"Bugzilla_login_top\" required\n"
			+ "           name=\"Bugzilla_login\" class=\"bz_login\"\n" + "        placeholder=\"Login\">\n"
			+ "    <input class=\"bz_password\" name=\"Bugzilla_password\" type=\"password\"\n"
			+ "           id=\"Bugzilla_password_top\" required\n" + "           placeholder=\"Password\">\n"
			+ "    <input type=\"hidden\" name=\"Bugzilla_login_token\"\n" + "           value=\"\">\n"
			+ "    <input type=\"submit\" name=\"GoAheadAndLogIn\" value=\"Log in\"\n"
			+ "            id=\"log_in_top\">\n"
			+ "    <a href=\"#\" onclick=\"return hide_mini_login_form('_top')\">[x]</a>\n" + "  </form>\n" + "</li>\n"
			+ "  <span class=\"separator\">| </span>\n"
			+ "  <li><a href=\"http://www.eclipse.org/legal/termsofuse.php\">Terms of Use</a></li>\n"
			+ "  <span class=\"separator\">| </span>\n"
			+ "  <li><a href=\"http://www.eclipse.org/legal/copyright.php\">Copyright Agent</a></li>\n" + "</ul>\n"
			+ "    </div>\n" + "  </div>\n" + "\n" + "  <div id=\"bugzilla-body\">\n" + "\n" + "<p>\n"
			+ "  Back to <a class=\"bz_bug_link \n" + "          bz_status_RESOLVED  bz_closed\"\n"
			+ "   title=\"RESOLVED FIXED - rename enabled on multi-selection\"\n"
			+ "   href=\"show_bug.cgi?id=14582\">bug 14582</a>\n" + "</p>\n" + "<table id=\"bug_activity\">\n"
			+ "    <tr class=\"column_header\">\n" + "      <th>Who</th>\n" + "      <th>When</th>\n"
			+ "      <th>What</th>\n" + "      <th>Removed</th>\n" + "      <th>Added</th>\n" + "    </tr>\n" + "\n"
			+ "      <tr>\n" + "        <td rowspan=\"2\">akiezun\n" + "        </td>\n"
			+ "        <td rowspan=\"2\">2002-04-25 06:33:05 EDT\n" + "        </td>\n" + "            <td>\n"
			+ "                Status\n" + "            </td><td>NEW\n" + "  </td><td>RESOLVED\n" + "  </td></tr><tr>\n"
			+ "            <td>\n" + "                Resolution\n" + "            </td><td>---\n"
			+ "  </td><td>FIXED\n" + "  </td>\n" + "      </tr>\n" + "  </table>\n" + "\n" + "  <p>\n"
			+ "    Back to <a class=\"bz_bug_link \n" + "          bz_status_RESOLVED  bz_closed\"\n"
			+ "   title=\"RESOLVED FIXED - rename enabled on multi-selection\"\n"
			+ "   href=\"show_bug.cgi?id=14582\">bug 14582</a>\n" + "  </p>\n" + "</div>\n" + "\n"
			+ "    <div id=\"footer\">\n" + "      <div class=\"intro\"></div>\n" + "<ul id=\"useful-links\">\n"
			+ "  <li id=\"links-actions\"><ul class=\"links\">\n" + "  <li><a href=\"./\">Home</a></li>\n"
			+ "  <li><span class=\"separator\">| </span><a href=\"enter_bug.cgi\">New</a></li>\n"
			+ "  <li><span class=\"separator\">| </span><a href=\"describecomponents.cgi\">Browse</a></li>\n"
			+ "  <li><span class=\"separator\">| </span><a href=\"query.cgi\">Search</a></li>\n" + "\n"
			+ "  <li class=\"form\">\n" + "    <span class=\"separator\">| </span>\n"
			+ "    <form action=\"buglist.cgi\" method=\"get\"\n"
			+ "        onsubmit=\"if (this.quicksearch.value == '')\n"
			+ "                  { alert('Please enter one or more search terms first.');\n"
			+ "                    return false; } return true;\">\n"
			+ "    <input type=\"hidden\" id=\"no_redirect_bottom\" name=\"no_redirect\" value=\"0\">\n"
			+ "    <script type=\"text/javascript\">\n" + "      if (history && history.replaceState) {\n"
			+ "        var no_redirect = document.getElementById(\"no_redirect_bottom\");\n"
			+ "        no_redirect.value = 1;\n" + "      }\n" + "    </script>\n"
			+ "    <input class=\"txt\" type=\"text\" id=\"quicksearch_bottom\" name=\"quicksearch\" \n"
			+ "           title=\"Quick Search\" value=\"\">\n"
			+ "    <input class=\"btn\" type=\"submit\" value=\"Search\" \n" + "           id=\"find_bottom\"></form>\n"
			+ "  <a href=\"page.cgi?id=quicksearch.html\" title=\"Quicksearch Help\">[?]</a></li>\n" + "\n"
			+ "  <li><span class=\"separator\">| </span><a href=\"report.cgi\">Reports</a></li>\n" + "\n" + "  <li>\n"
			+ "      <span class=\"separator\">| </span>\n" + "        <a href=\"request.cgi\">Requests</a></li>\n"
			+ "\n" + "\n" + "  \n" + "    \n" + "\n" + "    <li id=\"mini_login_container_bottom\">\n"
			+ "  <span class=\"separator\">| </span>\n"
			+ "  <a id=\"login_link_bottom\" href=\"show_activity.cgi?id=14582&amp;GoAheadAndLogIn=1\"\n"
			+ "     onclick=\"return show_mini_login_form('_bottom')\">Log In</a>\n" + "\n"
			+ "  <form action=\"show_activity.cgi?id=14582\" method=\"POST\"\n"
			+ "        class=\"mini_login bz_default_hidden\"\n" + "        id=\"mini_login_bottom\">\n"
			+ "    <input id=\"Bugzilla_login_bottom\" required\n"
			+ "           name=\"Bugzilla_login\" class=\"bz_login\"\n" + "        placeholder=\"Login\">\n"
			+ "    <input class=\"bz_password\" name=\"Bugzilla_password\" type=\"password\"\n"
			+ "           id=\"Bugzilla_password_bottom\" required\n" + "           placeholder=\"Password\">\n"
			+ "    <input type=\"hidden\" name=\"Bugzilla_login_token\"\n" + "           value=\"\">\n"
			+ "    <input type=\"submit\" name=\"GoAheadAndLogIn\" value=\"Log in\"\n"
			+ "            id=\"log_in_bottom\">\n"
			+ "    <a href=\"#\" onclick=\"return hide_mini_login_form('_bottom')\">[x]</a>\n" + "  </form>\n"
			+ "</li>\n" + "  <span class=\"separator\">| </span>\n"
			+ "  <li><a href=\"http://www.eclipse.org/legal/termsofuse.php\">Terms of Use</a></li>\n"
			+ "  <span class=\"separator\">| </span>\n"
			+ "  <li><a href=\"http://www.eclipse.org/legal/copyright.php\">Copyright Agent</a></li>\n" + "</ul>\n"
			+ "  </li>\n" + "\n" + "  \n" + "\n" + "\n" + "\n" + "\n" + "  \n" + "</ul>\n" + "\n"
			+ "      <div class=\"outro\"></div>\n" + "    </div>\n" + "\n" + "  </body>\n" + "</html>\n" + "");

	private static ArrayList<IssueNode> issues = new ArrayList<IssueNode>();

	public IssueRepositoryFromMemory() {

		IssueParser issueParser = new BZIssueParserInXml();
		HistoryParser historyParser = new BZHistoryParserInHtml();

		for (int i = 0; i < reports.size(); i++) {
			IssueEntry entry = (IssueEntry) issueParser.parse(reports.get(i));
			List<IssueActivityEntry> activities = historyParser.parse(histories.get(i));

			for (IssueActivityEntry activitiy : activities) {
				entry.registerActivity(activitiy);
			}

			issues.add(new IssueNode(entry));
		}
	}

	@Override
	public List<IssueNode> findAll() {
		return issues;
	}
	
	@Override
	public IssueNode findBy(String key) {
		IssueNode result = null;
		
		for (IssueNode issue:issues) {
			if (issue.getKey().equals(key)) {
				result = issue;
				break;
			}
		}
		
		return result;
	}

}
