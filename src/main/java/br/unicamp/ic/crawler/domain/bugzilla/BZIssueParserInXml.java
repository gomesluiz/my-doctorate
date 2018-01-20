package br.unicamp.ic.crawler.domain.bugzilla;

import java.io.ByteArrayInputStream;
import java.io.InputStream;

import com.thoughtworks.xstream.XStream;
import com.thoughtworks.xstream.io.xml.DomDriver;

import br.unicamp.ic.crawler.services.IssueParser;

/**
 * The <code>FormatConverterFromXml</code> class implements XML reading files.
 * 
 * @author Luiz Alberto
 * @version %I%, %G%
 * @since 1.0
 */
public class BZIssueParserInXml implements IssueParser {

	private XStream stream;

	public BZIssueParserInXml() {
		stream = new XStream(new DomDriver());
		stream.autodetectAnnotations(true);
		stream.ignoreUnknownElements();
	}

	@Override
	public Object parse(String contents) {
		InputStream xml = new ByteArrayInputStream(contents.getBytes());
		stream.processAnnotations(BZIssueEntry.class);
		return stream.fromXML(xml);
	}

}
