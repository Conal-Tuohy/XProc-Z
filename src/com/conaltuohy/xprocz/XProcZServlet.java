package com.conaltuohy.xprocz;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.net.URLEncoder;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Collections;
import java.util.Date;
import java.util.TimeZone;
import java.util.HashMap;
import java.util.Map;
import java.util.Enumeration;
import java.util.Properties;
import com.xmlcalabash.util.XProcSystemPropertySet;
import com.xmlcalabash.core.XProcException;

import org.apache.commons.codec.binary.Base64;


import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.XMLConstants;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Templates;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.Transformer;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.sax.SAXSource;
import javax.xml.transform.sax.SAXTransformerFactory;
import javax.xml.transform.sax.TransformerHandler;
import javax.xml.transform.stream.StreamResult; 
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import net.sf.saxon.s9api.SaxonApiException;

import com.xmlcalabash.core.XProcRuntime;
import com.xmlcalabash.core.XProcConfiguration;
import com.xmlcalabash.util.Input;
import com.xmlcalabash.runtime.XPipeline;
import com.xmlcalabash.model.RuntimeValue;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.XdmNode;
import com.xmlcalabash.io.ReadablePipe;
import java.io.OutputStreamWriter;
import net.sf.saxon.s9api.Axis;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.XdmItem;
import net.sf.saxon.s9api.XdmSequenceIterator;
import java.io.UnsupportedEncodingException;
import java.io.Reader;
import java.io.InputStreamReader;
import javax.servlet.http.Part;
import javax.servlet.annotation.MultipartConfig;
import javax.xml.parsers.ParserConfigurationException;
/**
 * Servlet implementation class XProcZServlet
 * The XProcZServlet is a host for HTTP server applications written in XProc.
 */
@MultipartConfig
public class XProcZServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private static final String SERVLET_INIT_PARAMETERS_NS = "tag:conaltuohy.com,2015:servlet-init-parameters";
	private static final String APPLICATION_INIT_PARAMETERS_NS = "tag:conaltuohy.com,2015:webapp-init-parameters";
	private static final String SERVLET_CONTEXT_NS = "tag:conaltuohy.com,2015:servlet-context";
	private static final String OS_ENVIRONMENT_VARIABLES_NS = "tag:conaltuohy.com,2015:os-environment-variables";
	private static final String JAVA_SYSTEM_PROPERTIES_NS = "tag:conaltuohy.com,2015:java-system-properties";
	private static final String XPROC_Z_SYSTEM_PROPERTIES_NS = "tag:conaltuohy.com,2019:xproc-z-system-properties";
	
	private static final String XPROC_STEP_NS = "http://www.w3.org/ns/xproc-step";
	
	private final static SAXTransformerFactory transformerFactory = (SAXTransformerFactory) TransformerFactory.newInstance();
	private final static DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
	private DocumentBuilder builder;
	
	//private XProcRuntime runtime = new XProcRuntime(new XProcConfiguration());
	private Map<QName, String> parameters = new HashMap<QName, String>();
	private XProcZSystemPropertySet xproczSystemPropertySet = new XProcZSystemPropertySet();
	
	/**
	 * @see HttpServlet#HttpServlet()
	 */
	 public XProcZServlet() {
		super();
	}
    
	private class XProcZSystemPropertySet implements XProcSystemPropertySet {
		private Properties properties = new Properties();
		private XProcZSystemPropertySet() {
			try {
				InputStream inputStream = this.getClass().getClassLoader().getResourceAsStream("/xproc-z-build.properties");
				properties.load(inputStream);
			} catch(Exception e){
				System.out.println("xproc-z-build.properties not found in classpath");
			}
		};
		public String systemProperty(XProcRuntime runtime, QName propertyName) throws XProcException {
			String uri = propertyName.getNamespaceURI();
			String local = propertyName.getLocalName();

			if (uri.equals(XPROC_Z_SYSTEM_PROPERTIES_NS)) {
				return properties.getProperty(local);
			} else {
				return null;
			}
		}
	};

    
	private class RunnablePipeline implements Runnable {
		Exception e = null; 
		XdmNode inputDocument = null;
		HttpServletResponse httpResponse = null;
		XProcRuntime runtime = null;
		RunnablePipeline(XProcRuntime runtime, XdmNode inputDocument) { 
			this.runtime = runtime;
			this.inputDocument = inputDocument; 	
		}
		RunnablePipeline(XProcRuntime runtime, XdmNode inputDocument, HttpServletResponse httpResponse) { 
			this.runtime = runtime;	
			this.inputDocument = inputDocument; 	
			this.httpResponse = httpResponse;
		} 
		public void run() { 	
			try { 	
				//getServletContext().log("Running pipeline...");
				
				//getServletContext().log("Initializing pipeline...");
				Input input = getMainPipelineInput();
				XPipeline pipeline = runtime.load(input);
				//getServletContext().log("Passing parameters to pipeline...");
				// attach parameters from the application's environment
				for (QName name : parameters.keySet()) {
					pipeline.setParameter(name, new RuntimeValue(parameters.get(name)));
				}
				//getServletContext().log("Passing input document (http request) to pipeline...");
				//  TODO for debug logging only
	//			getServletContext().log(inputDocument.toString());
				pipeline.writeTo("source", inputDocument);
				//getServletContext().log("Actually executing the pipeline...");
				pipeline.run(); 	
	
				// TODO read multiple result documents
				// The first is a c:response - use it make http response to client.
				// Remaining documents are inputs for subsequent executions - spawn separate threads to execute
				// the pipeline to handle each of these documents, and discarding any results.
				// This allows XProc-Z to execute multiple asynchronous long-running processes.
				
				//getServletContext().log("Reading results from pipeline...");
				ReadablePipe result = pipeline.readFrom("result");
				//getServletContext().log("Reading first result from pipeline...");
				XdmNode outputDocument = result.read();
				
				// generate HTTP Response from pipeline output
				if (httpResponse != null) {
					// an HTTP client is waiting on a response - the pipelines's first output document is asssumed to specify that response
					//getServletContext().log("Sending pipeline result as HTTP response");
					respond(httpResponse, outputDocument);
				}
				//if (httpResponse == null) {
				//	getServletContext().log("Pipeline first response ignored");
				//}
				if (result.moreDocuments()) {
					while (result.moreDocuments()) {
						// subsequent documents are callbacks to the pipeline
						//getServletContext().log("Reading subsequent results from pipeline...");
						outputDocument = result.read();
						//getServletContext().log("Pipeline produced extra document: " + outputDocument.toString());
						//XdmNode rootElement = (XdmNode) outputDocument.axisIterator(Axis.CHILD).next();
						//while (! (rootElement.getNodeKind().equals(net.sf.saxon.s9api.XdmNodeKind.ELEMENT))) {
						//rootElement = (XdmNode) outputDocument.axisIterator(Axis.CHILD).next();
							//getServletContext().log("Launching asynchronous pipeline...");
							// TODO handle threading issue; need new runtime instances for these pipelines, after the first
							// (since the main pipeline has now finished, and its runtime can be safely reused
							new Thread(new RunnablePipeline(runtime, outputDocument)).start();
							//getServletContext().log("Pipeline launched.");
						//}
					}
				} else {
					// no more pipelines to run
					runtime.close();
					this.runtime = null;
				}
			} catch (Exception e) { 	
				this.e = e; 
			} 	
		} 	
	};    

	private void addParameter(String prefix, String xmlns, String localName, String value) {
		QName name = new QName(prefix, xmlns, purifyForXML(localName));
		getServletContext().log("XProc-Z parameter <c:param name='" + name + "' value='" + value + "'/>");
		parameters.put(name, purifyForXML(value));
	};
	
	/**
	* Remove characters which are invalid or discouraged in XML
	*/
	private String purifyForXML(String text) {
		return text.replaceAll("[^\\u0009\\u000a\\u000d\\u0020-\\ud7ff\\ue000-\\ufffd]", "");
	}
	
    public void init() throws ServletException {
	getServletContext().log("XProc-Z initializing ...");
    	 try {
    	 	 factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
    	 	 builder = factory.newDocumentBuilder();
    	 	 // initialize the set of parameters from the servlet's environment
		// The Servlet initialization parameters
		for (String name : Collections.list(getServletConfig().getInitParameterNames())) {
			addParameter("servlet", SERVLET_INIT_PARAMETERS_NS, name, getServletConfig().getInitParameter(name));
		}
		
		// The web application's initialization parameters, 
		// from WEB.xml or provided by the Servlet container
		// e.g. parameters listed in a Tomcat 'context.xml' file
		for (String name : Collections.list(getServletContext().getInitParameterNames())) {
			addParameter("webapp", APPLICATION_INIT_PARAMETERS_NS, name, getServletContext().getInitParameter(name));
		}
		
		// The Operating System's environment variables, 
		for (Map.Entry<String, String> entry: System.getenv().entrySet()) {
			addParameter("os", OS_ENVIRONMENT_VARIABLES_NS, entry.getKey(), entry.getValue());
		}	

		// Java System Properties
		Properties systemProperties = System.getProperties();
		Enumeration systemPropertyNames = systemProperties.propertyNames();
		while (systemPropertyNames.hasMoreElements()) {
			String key = (String) systemPropertyNames.nextElement();
			addParameter("jvm", JAVA_SYSTEM_PROPERTIES_NS, key, systemProperties.getProperty(key));
		}
		
		// Servlet Context properties
		addParameter("sc", SERVLET_CONTEXT_NS, "contextPath", getServletContext().getContextPath());
		addParameter("sc", SERVLET_CONTEXT_NS, "realPath", getServletContext().getRealPath(""));
		
		getServletContext().log("XProc-Z initialization completed successfully.");
    	 } catch (ParserConfigurationException pce) {
    	 	 // should not happen as support for FEATURE_SECURE_PROCESSING is mandatory
		getServletContext().log("XProc-Z initialization failed!");
    	 	throw new ServletException(pce);
    	 }
    }
    
    private Document parseXML(InputStream inputStream) throws SAXException, IOException {
    	 // TODO should a parse failure trigger re-processing as plain text?
    	 Document document = builder.parse(inputStream);
    	 inputStream.close();
    	 return document;
    }
    
    private void setNonNullAttribute(Element element, String attributeName, String attributeValue) {
	if (attributeValue != null) {
		element.setAttribute(attributeName, attributeValue); 
	}
    }
    
    private XdmNode getRequestDocument(XProcRuntime runtime, HttpServletRequest req) 
    	throws ParserConfigurationException, SAXException, IOException, ServletException {
    		// TODO finish migrating from W3 DOM to Saxon XDM
    	 	// Create a document describing the HTTP request,
		// from request parameters, headers, etc.
		// to be the input document for the XProc pipeline.
		Document requestXML = null;
		requestXML = factory.newDocumentBuilder().newDocument();
		
		// Populate the XML document from the HTTP request data
		/*
		<request xmlns="http://www.w3.org/ns/xproc-step"
		  method = NCName
		  href? = anyURI
		  detailed? = boolean
		  status-only? = boolean
		  username? = string
		  password? = string
		  auth-method? = string
		  send-authorization? = boolean
		  override-content-type? = string>
			 (c:header*,
			  (c:multipart |
				c:body)?)
		</request>
		*/
			Element request = requestXML.createElementNS(XPROC_STEP_NS, "c:request");
			requestXML.appendChild(request);
			String queryString = req.getQueryString();
			String requestURI = req.getRequestURL().toString();
			if (queryString != null) {
				requestURI += "?" + queryString;
			};
			request.setAttribute("method", req.getMethod());
			request.setAttribute("href", requestURI);
			request.setAttribute("detailed", "true");
			request.setAttribute("status-only", "false");
			setNonNullAttribute(request, "username", req.getRemoteUser());
			// NB password not available; pipeline would need to process the Authorization header
			
			setNonNullAttribute(request, "auth-method", req.getAuthType()); 
			
			// the HTTP request headers
			for (String name : Collections.list(req.getHeaderNames())) {	
				Element header = requestXML.createElementNS(XPROC_STEP_NS, "c:header");
				request.appendChild(header);
				header.setAttribute("name", name);
				header.setAttribute("value", req.getHeader(name));
			}
			
			// the request body or parts
			if (req.getContentType() == null || req.getContentLength() == 0) {
				// no HTTP message body ⇒ no c:body or c:multipart elements
			} else if (req.getContentType().startsWith("multipart/form-data;")) {
				// content is multipart
				// create c:multipart
				String boundary = req.getContentType().substring("multipart/form-data; boundary=".length());
				Element multipart = requestXML.createElementNS(XPROC_STEP_NS, "c:multipart");
				multipart.setAttribute("content-type", req.getContentType());
				request.appendChild(multipart);
				multipart.setAttribute("boundary", boundary); 
				// for each part, create a c:body
				for (Part part: req.getParts()) {
					Element body = requestXML.createElementNS(XPROC_STEP_NS, "c:body");
					multipart.appendChild(body);			
					String partContentType = part.getContentType();
					// The http client may legitimately not send part headers, but for politeness we
					// supply the XProc pipeline with an explicit Content-Type, because 
					// rfc1341 says that absent headers imply "plain US-ASCII text"
					// https://www.w3.org/Protocols/rfc1341/7_2_Multipart.html
					if (partContentType == null) {
						partContentType = "text/plain; charset=US-ASCII";
					}
					body.setAttribute("content-type", partContentType);
					setNonNullAttribute(body, "disposition", part.getHeader("Content-Disposition"));
					setNonNullAttribute(body, "id", part.getHeader("Content-ID"));
					setNonNullAttribute(body, "description", part.getHeader("Content-Description"));
						
					// TODO allow badly formed XML content to fall back to being processed as text
					// insert the actual content of the part
					if (isXMLMediaType(partContentType)) {
						// parse XML
						Document uploadedDocument = parseXML(part.getInputStream());
						// TODO also import top-level comments, processing instructions, etc?
						body.appendChild(
							body.getOwnerDocument().adoptNode(
								uploadedDocument.getDocumentElement()
							)
						);
					} else if (isTextMediaType(partContentType)) {
						// otherwise if text then copy it unparsed
						// <c:body content-type="text/plain">This &amp; that</c:body>
						InputStream inputStream = part.getInputStream();
						body.appendChild(
							requestXML.createTextNode(
								readText(inputStream, getCharacterEncoding(req))
							)
						);
						inputStream.close();
					} else {
						// Base64 encode binary data
						body.setAttribute("encoding", "base64");
						InputStream inputStream = part.getInputStream();
						body.appendChild(
							requestXML.createTextNode(
								readBinary(inputStream)
							)
						);
						inputStream.close();
					}
				}
			} else {
				// content is simple
				// create c:body element
				Element body = requestXML.createElementNS(XPROC_STEP_NS, "c:body");
				request.appendChild(body);
				body.setAttribute("content-type", req.getContentType());
				String contentType = req.getContentType();
				if (isXMLMediaType(contentType)) {
					// if it's XML then parse it and place root element inside
					// <c:body content-type="application/rdf+xml"><rdf:RDF etc.../></c:body>
					Document uploadedDocument = parseXML(req.getInputStream());
					// TODO also import top-level comments, processing instructions, etc?
					body.appendChild(
						body.getOwnerDocument().adoptNode(
							uploadedDocument.getDocumentElement()
						)
					);
				} else if (isTextMediaType(contentType)) {
					// otherwise if text then copy it unparsed
					// <c:body content-type="text/plain">This &amp; that</c:body>
					InputStream inputStream = req.getInputStream();
					body.appendChild(
						requestXML.createTextNode(
							readText(inputStream, getCharacterEncoding(req))
						)
					);
					inputStream.close();
				} else {
					// ... or if binary then base64 encode it 
					// <c:body content-type="application/pdf" encoding = "base64">...</c:body>
					body.setAttribute("encoding", "base64");
					InputStream inputStream = req.getInputStream();
					body.appendChild(
						requestXML.createTextNode(
							readBinary(inputStream)
						)
					);
					inputStream.close();
				}
			}
			// wrap request DOM in Saxon XdmNode
			XdmNode inputDocument = runtime.getProcessor().newDocumentBuilder().wrap(requestXML);
			return inputDocument;
    }

    private void respond(HttpServletResponse resp, XdmNode outputDocument) throws IOException {
			// Create a stream to send response XML to the HTTP client
			OutputStream os = resp.getOutputStream();
			QName responseName = new QName(XPROC_STEP_NS, "response");
			XdmNode rootElement = (XdmNode) outputDocument.axisIterator(Axis.CHILD, responseName).next();
			String statusAttribute = rootElement.getAttributeValue( new QName("status"));
			resp.setStatus(Integer.valueOf(statusAttribute));
			QName headerName = new QName(XPROC_STEP_NS, "header");
			XdmSequenceIterator headers = rootElement.axisIterator(Axis.CHILD, headerName);
			QName nameName = new QName("name");
			QName valueName = new QName("value");
			while (headers.hasNext()) {
				XdmNode headerNode = (XdmNode) headers.next();
				resp.addHeader(headerNode.getAttributeValue(nameName), headerNode.getAttributeValue(valueName));
			}
			QName bodyName = new QName(XPROC_STEP_NS, "body");
			XdmSequenceIterator bodyIterator = rootElement.axisIterator(Axis.CHILD, bodyName);
			if (bodyIterator.hasNext()) {
				// there is an entity body to return
				XdmNode bodyElement = (XdmNode) bodyIterator.next();
				String encoding = bodyElement.getAttributeValue( new QName("encoding") );
				String contentType = bodyElement.getAttributeValue( new QName ("content-type") );
				String contentDisposition = bodyElement.getAttributeValue( new QName ("disposition") );
				if (contentDisposition != null) {
					resp.addHeader("Content-Disposition", contentDisposition);
				}
				XdmSequenceIterator content = bodyElement.axisIterator(Axis.CHILD);
				resp.setContentType(contentType);
				if ("base64".equals(encoding)) {
					// decode base64 encoded binary data and stream to http client
					os.write(
						Base64.decodeBase64(
							content.next().toString()
						)
					);
				} else if (isXMLMediaType(contentType)) {
					// output the sequence of XML nodes within the c:body element using toString to
					// produce an XML serialization of each one
					OutputStreamWriter writer = new OutputStreamWriter(os);
					while (content.hasNext()) {
						XdmItem contentItem = content.next();
						writer.write(contentItem.toString());
					}
					writer.flush();
				} else {
					// output plain text content within the c:body element by writing its string value
					OutputStreamWriter writer = new OutputStreamWriter(os);
					while (content.hasNext()) {
						XdmItem contentItem = content.next();
						writer.write(contentItem.getStringValue());
					}
					writer.flush();
				}
			}
	}
	
    /** Respond to an HTTP request using an XProc pipeline.
	* • Create an XML document representing the HTTP request
	* • Transform the document using the XProc pipeline, returning the 
	* result to the HTTP client.
	 * @see javax.servlet.http.HttpServlet#service(javax.servlet.http.HttpServletRequest, javax.servlet.http.HttpServletResponse)
	 */
	@Override
	public void service(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		try {
			XProcRuntime runtime = new XProcRuntime(new XProcConfiguration());
			runtime.addSystemPropertySet(xproczSystemPropertySet);

			// marshal the HTTP request into an XdmNode as a c:request document
			XdmNode inputDocument = getRequestDocument(runtime, req);
			// Process the XML document which describes the HTTP request, 
			// sending the result to the HTTP client
			
			RunnablePipeline pipeline = new RunnablePipeline(runtime, inputDocument, resp);
			pipeline.run();
			// this is clunky ... TODO replace with a call to pipeline.runReportingAnyErrors() throws Exception. Pipeline.run() should call 
			// that same method and swallow (log) errors
			if (pipeline.e != null) {throw pipeline.e;};

		} catch (Exception pipelineFailed) {
			getServletContext().log("Pipeline failed", pipelineFailed);
			resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
			resp.setContentType("text/plain");
			OutputStream os = resp.getOutputStream();
			PrintWriter writer = new PrintWriter(os);
			if (pipelineFailed instanceof SaxonApiException) {
				SaxonApiException e = (SaxonApiException) pipelineFailed;
				writer.print("Error ");
				writer.print(e.getErrorCode());
				/*
				writer.print(" in module ");
				writer.print(e.getSystemId());
				writer.print(" on line ");
				writer.print(e.getLineNumber());
				*/
			}
			pipelineFailed.printStackTrace(writer);
			writer.flush();
			os.close();	
		}	
	}
	
	// logs an exception and re-throws it as a servlet exception
	private void fail(Exception e, String message) throws ServletException {
			getServletContext().log(message, e);
			throw new ServletException(message, e);
	}
	
	private String getCharacterEncoding(HttpServletRequest req) {
		// The HTTP 1.1 spec says that the default is "ISO-8859-1"
		// http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.7.1
		String encoding = req.getCharacterEncoding();
		if (encoding == null) {
			return "ISO-8859-1";
		} else {
			return encoding;
		}
	}
	
	/**
	* Determine whether content is, or can be treated as, plain text
	*/
	private boolean isTextMediaType(String mediaType) {
		if (mediaType == null) {
			return false;
		}
		return (
			mediaType.startsWith("text/") ||
			mediaType.equals("application/x-www-form-urlencoded") ||
			mediaType.equals("application/json") ||
			(
				mediaType.startsWith("application/") && 
				mediaType.endsWith("+json")
			)
		);
	}
	
	
	/**
	* Determine whether content is already XML, or alternatively, will need to be encoded as XML
	* See <a href="https://tools.ietf.org/html/rfc7303">RFC7303</a>
	*/
	private boolean isXMLMediaType(String mediaType) {
		if (mediaType == null) {
			return false;
		}
		return (
			mediaType.equals("application/xml") ||
			mediaType.equals("application/xml-external-parsed-entity") ||
			mediaType.equals("text/xml") ||
			mediaType.equals("text/xml-external-parsed-entity") ||
			(
				mediaType.startsWith("application/") && 
				mediaType.endsWith("+xml")
			)
		);
	}
	
	private Input getMainPipelineInput() throws SecurityException, FileNotFoundException {
		try {
			return getPipelineInput(getServletContext().getInitParameter("xproc-z.main"));
		} catch (Exception e) {
			return getPipelineInput(getServletContext().getRealPath("/xproc/xproc-z.xpl"));
		}
	}
	
	private Input getPipelineInput(String filename) throws SecurityException, FileNotFoundException {
		File file = new File(filename);
		if (file.isFile() && file.canRead()) {
			getServletContext().log("Loading main pipeline from " + file);
			return new Input(filename);
		} else {
			throw new FileNotFoundException("Pipeline " + file + " not found");
		}
	}
	
	// Read text from the input stream
	private String readText(InputStream inputStream, String characterEncoding) 
		throws IOException, UnsupportedEncodingException {
		char[] buffer = new char[1024];
		StringBuilder builder = new StringBuilder();
		Reader reader = new InputStreamReader(inputStream, characterEncoding);
		int charactersRead = reader.read(buffer, 0, buffer.length);
		while (charactersRead > -1) {
			builder.append(buffer, 0, charactersRead);
			charactersRead = reader.read(buffer, 0, buffer.length);
		}
		return builder.toString();
	}
	
	// Read binary data from the input stream and return Base64 encoded text
	// NB if base64-encoding is performed on successive chunks of binary data,
	// those chunks must be multiples of 3 bytes long (except the last chunk which
	// may be any length), otherwise a chunk whose size is not divisible by 3 will
	// produce one or more "=" padding characters and prematurely terminate
	// the stream of base64 digits.
	private String readBinary(InputStream inputStream) 
		throws IOException {
		StringBuilder builder = new StringBuilder(2048);
		byte[] buffer = new byte[3]; // buffer for 3 bytes of binary data 
		byte[] readBuffer;
		int bytesRead = 0;
		do {
			int firstByteRead = inputStream.read(buffer, 0, 1);
			int secondByteRead = inputStream.read(buffer, 1, 1);
			int thirdByteRead = inputStream.read(buffer, 2, 1);
			if (thirdByteRead == 1) {
				bytesRead = 3;
			} else if (secondByteRead == 1) {
				bytesRead = 2;
			} else if (firstByteRead == 1) {
				bytesRead = 1;
			} else {
				bytesRead = 0;
			}
			if (bytesRead == 3) {
				readBuffer = buffer;
			} else {
				readBuffer = Arrays.copyOfRange(buffer, 0, bytesRead);
			}
			if (bytesRead > 0) {
				builder.append(Base64.encodeBase64String(readBuffer));
			}
		} while (bytesRead == 3);
		return builder.toString();
	}

}
