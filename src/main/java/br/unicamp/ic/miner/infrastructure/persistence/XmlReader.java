package br.unicamp.ic.miner.infrastructure.persistence;

import java.io.InputStream;

import com.thoughtworks.xstream.XStream;
import com.thoughtworks.xstream.io.xml.DomDriver;

import br.unicamp.ic.miner.domain.bugzilla.BZIssueEntry;
import br.unicamp.ic.miner.domain.core.IssueEntry;

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
	@SuppressWarnings("rawtypes")
	public XmlReader(String path, Class type) {
		stream = new XStream(new DomDriver());
		stream.autodetectAnnotations(true);
		stream.processAnnotations(type);
		stream.ignoreUnknownElements();
		this.path = path;
	}

	/**
	 * Load an XML file.
	 * 
	 * @param inputStream
	 */
	@Override
	public Object load(InputStream inputStream) {
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
