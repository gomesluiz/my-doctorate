package br.unicamp.ic.crawler.persistence;

import java.io.InputStream;

import com.thoughtworks.xstream.XStream;
import com.thoughtworks.xstream.io.xml.DomDriver;

/**
 * The <code>XmlReader</code> class implements XML reading files.
 * 
 * @author Luiz Alberto
 * @version %I%, %G%
 * @since 1.0
 */
public class XmlReader implements IssueFileReader {

	private XStream	stream;
	private String	path;

	/**
	 * Instantiates a <code>XmlReader</code> object.
	 * 
	 * @param path of file to be read.
	 */
	public XmlReader(String path) {
		stream = new XStream(new DomDriver());
		stream.autodetectAnnotations(true);
		stream.ignoreUnknownElements();
		this.path = path;
	}

	/**
	 * Load an XML file.
	 * 
	 * @param inputStream
	 */
	@SuppressWarnings("rawtypes")
	@Override
	public Object load(InputStream inputStream, Class type) {
		stream.processAnnotations(type);
		return stream.fromXML(inputStream);
	}

	/**
	 * 
	 */
	@Override
	public String getPath() {
		return this.path;
	}
	

}
