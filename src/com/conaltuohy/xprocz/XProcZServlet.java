package com.conaltuohy.xprocz;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.net.URLEncoder;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Collections;
import java.util.Date;
import java.util.TimeZone;

import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
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

import net.sf.saxon.s9api.SaxonApiException;

import com.xmlcalabash.core.XProcRuntime;
import com.xmlcalabash.core.XProcConfiguration;
import com.xmlcalabash.util.Input;
import com.xmlcalabash.runtime.XPipeline;
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
/**
 * Servlet implementation class XProcZServlet
 * The RetailerServlet is a host for HTTP server applications written in XProc.
 */
@MultipartConfig
public class XProcZServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	
	private static final String XPROC_STEP_NS = "http://www.w3.org/ns/xproc-step";
	
	private final static SAXTransformerFactory transformerFactory = (SAXTransformerFactory) TransformerFactory.newInstance();
	private final static DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
       
    /**
     * @see HttpServlet#HttpServlet()
     */
     public XProcZServlet() {
        super();
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
		
		// Create a stream to send response XML to the HTTP client
		OutputStream os = resp.getOutputStream();

		// Create a document describing the HTTP request,
		// from request parameters, headers, etc.
		// to be the input document for the XProc pipeline.
		Document requestXML = null;
		try {
			requestXML = factory.newDocumentBuilder().newDocument();
		} catch (ParserConfigurationException documentCreationFailed) {
			fail(documentCreationFailed, "Error creating DOM Document");
		}
		
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
		try {
			Element request = requestXML.createElementNS(XPROC_STEP_NS, "request");
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
			if (req.getRemoteUser() != null) {
				request.setAttribute("username", req.getRemoteUser()); 
				// NB password not available; pipeline would need to process the Authorization header
			};
			if (req.getAuthType() != null) {
				request.setAttribute("auth-method", req.getAuthType()); 
			};
			
			// the HTTP request headers
			for (String name : Collections.list(req.getHeaderNames())) {	
				Element header = requestXML.createElementNS(XPROC_STEP_NS, "header");
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
				Element multipart = requestXML.createElementNS(XPROC_STEP_NS, "multipart");
				multipart.setAttribute("content-type", req.getContentType());
				request.appendChild(multipart);
				multipart.setAttribute("boundary", boundary); 
				// for each part, create a c:body
				for (Part part: req.getParts()) {
					Element body = requestXML.createElementNS(XPROC_STEP_NS, "body");
					multipart.appendChild(body);			
					String partContentType = part.getContentType();
					if (partContentType == null) {
						partContentType = "text/plain";
					}
					body.setAttribute("content-type", partContentType);
					body.setAttribute("id", part.getName()); // CHECK: is part.getName() really = c:body/@id?
					// TODO insert the actual content of the part - as in the case of simple content, below
				}
			} else {
				// content is simple
				// TODO create c:body element
				Element body = requestXML.createElementNS(XPROC_STEP_NS, "body");
				request.appendChild(body);
				body.setAttribute("content-type", req.getContentType());
				// TODO if it's XML then parse it and place root element inside
				// <c:body content-type="application/rdf+xml"><rdf:RDF etc.../></c:body>
				// otherwise if text then copy it unparsed
				// <c:body content-type="text/plain">This &amp; that</c:body>
				if (req.getContentType().startsWith("text/") || req.getContentType().equals("application/x-www-form-urlencoded")) {
						InputStream inputStream = req.getInputStream();
						body.appendChild(
							requestXML.createTextNode(
								readText(inputStream, getCharacterEncoding(req))
							/*
							getCharacterEncoding(req)
							*/
							)
						);
						inputStream.close();
				}
				// TODO or if binary then base64 encode it 
				// <c:body content-type="application/pdf" encoding = "base64">...</c:body>
			}
			
			// Process the XML document which describes the HTTP request, 
			// sending the result to the HTTP client
			XProcConfiguration config = new XProcConfiguration();
			XProcRuntime runtime = new XProcRuntime(config);
			Input input = new Input("xproc/xproc-z.xpl");
			XPipeline pipeline = runtime.load(input);
			// wrap request DOM in Saxon XdmNode
			XdmNode inputDocument = runtime.getProcessor().newDocumentBuilder().wrap(requestXML);
			pipeline.writeTo("source", inputDocument);
			pipeline.run();
			ReadablePipe result = pipeline.readFrom("result");
			XdmNode outputDocument = result.read();
			/*
			// quick and dirty serialization
			DOMSource domSource = new DOMSource(requestXML);
			transformer.transform(domSource, result);
			*/
			OutputStreamWriter writer = new OutputStreamWriter(os);
			QName responseName = new QName(XPROC_STEP_NS, "response");
			XdmNode rootElement = (XdmNode) outputDocument.axisIterator(Axis.CHILD, responseName).next();
			String statusAttribute = rootElement.getAttributeValue( new QName("status"));
			QName bodyName = new QName(XPROC_STEP_NS, "body");
			XdmNode bodyElement = (XdmNode) rootElement.axisIterator(Axis.CHILD, bodyName).next();
			String contentType = bodyElement.getAttributeValue( new QName ("content-type") );
			XdmSequenceIterator content = bodyElement.axisIterator(Axis.CHILD);
			resp.setStatus(Integer.valueOf(statusAttribute));
			resp.setContentType(contentType);
			QName headerName = new QName(XPROC_STEP_NS, "header");
			XdmSequenceIterator headers = rootElement.axisIterator(Axis.CHILD, headerName);
			QName nameName = new QName("name");
			QName valueName = new QName("value");
			while (headers.hasNext()) {
				XdmNode headerNode = (XdmNode) headers.next();
				resp.setHeader(headerNode.getAttributeValue(nameName), headerNode.getAttributeValue(valueName));
			}
			while (content.hasNext()) {
				XdmItem contentItem = content.next();
				writer.write(contentItem.toString());
			}
			writer.flush();
		} catch (Exception pipelineFailed) {
			getServletContext().log("Pipeline failed", pipelineFailed);
			resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
			resp.setContentType("text/plain");
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
			//writer.println(pipelineFailed.getMessage());
			pipelineFailed.printStackTrace(writer);
			writer.flush();
		}
		os.close();		
	}
	
	// logs an exception and re-throws it as a servlet exception
	private void fail(Exception e, String message) throws ServletException {
			getServletContext().log(message, e);
			throw new ServletException(message, e);
	}
	
	private String getCharacterEncoding(HttpServletRequest req) {
		String encoding = req.getCharacterEncoding();
		if (encoding == null) {
			return "ISO-8859-1";
		} else {
			return encoding;
		}
	}
	
	// Read text from the input stream
	public String readText(InputStream inputStream, String characterEncoding) 
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

}
