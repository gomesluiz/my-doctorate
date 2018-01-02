package br.unicamp.ic.crawler.persistence;

import java.io.ByteArrayInputStream;
import java.io.InputStream;

import com.thoughtworks.xstream.XStream;
import com.thoughtworks.xstream.io.xml.DomDriver;

/**
 * The <code>FormatConverterFromXml</code> class implements XML reading files.
 * 
 * @author Luiz Alberto
 * @version %I%, %G%
 * @since 1.0
 */
public class FormatConverterFromXml implements FormatConverter {

	private XStream stream;

	/**
	 * Instantiates a <code>FormatConverterFromXml</code> object.
	 */
	public FormatConverterFromXml() {
		stream = new XStream(new DomDriver());
		stream.autodetectAnnotations(true);
		stream.ignoreUnknownElements();
	}

	/**
	 * Load an XML file.
	 * 
	 * @param inputStream
	 */
	@SuppressWarnings("rawtypes")
	@Override
	public Object load(String contents, Class type) {
		InputStream xml = new ByteArrayInputStream(contents.getBytes());
		stream.processAnnotations(type);
		return stream.fromXML(xml);
	}

}
