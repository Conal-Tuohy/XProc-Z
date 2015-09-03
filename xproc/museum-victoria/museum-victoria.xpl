<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:j="http://marklogic.com/json" 
	xmlns:mv="tag:conaltuohy.com,2015:museum-victoria" >
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<p:import href="../xproc-z-library.xpl"/>
	
	<p:declare-step type="mv:museum-victoria" name="museum-victoria" xpath-version="2.0">
		<p:input port="source" primary="true"/>
		<p:input port="parameters" kind="parameter" primary="true"/>
		<p:output port="result" primary="true" sequence="true"/>
		<p:option name="relative-uri" select=" '' "/>
		<!-- generate a public URI - this pipeline could be running behind a proxy -->
		<z:parse-request-uri name="request-uri" unproxify="true"/>
		<p:choose>
			<p:variable name="public-uri" select="
				concat(
					/c:param-set/c:param[@name='scheme']/@value,
					'//',
					/c:param-set/c:param[@name='host']/@value,
					/c:param-set/c:param[@name='port']/@value,
					/c:param-set/c:param[@name='path']/@value,
					/c:param-set/c:param[@name='query']/@value
				)
			"/>
			<!-- request for a "data" resource, i.e. a document -->
			<p:when test="starts-with($relative-uri, 'data/')">
				<!-- generate a request to the Museum Victoria API -->
				<p:template>
					<p:with-param name="api-uri" select="substring-after($relative-uri, 'data/')"/>
					<p:input port="parameters">
						<p:pipe step="request-uri" port="result"/>
					</p:input>
					<p:input port="template">
						<p:inline>
							<c:request method="GET" href="{concat('http://collections.museumvictoria.com.au/api/', $api-uri)}"/>
						</p:inline>
					</p:input>
				</p:template>
				<!-- send the request to Museum Victoria API -->
				<p:http-request/>
				<!-- convert the wrapped JSON content to XML and discard the wrapper -->
				<p:unescape-markup content-type="application/json" encoding="base64" charset="UTF-8"/>
				<p:unwrap match="/*"/>
				<!-- convert any escaped HTML into XHTML -->
				<p:viewport match="//j:content">
					<p:unescape-markup content-type="text/html"/>
				</p:viewport>
				<!-- tag the root element to match its high-level type as defined in the request URI -->
				<p:group>
					<p:variable name="type" select="substring-before(substring-after($relative-uri, 'data/'), '/')"/>
					<p:add-attribute match="/*" attribute-name="type">
						<p:with-option name="attribute-value" select="
							('article', 'item', 'species', 'specimen')[
								xs:integer($type='articles') +
								xs:integer($type='items') * 2 +
								xs:integer($type='species') * 3 +
								xs:integer($type='specimens') * 4
							]
						"/>
					</p:add-attribute>
				</p:group>
				<!-- convert the JSON into RDF/XML -->
				<mv:transform xslt="museum-victoria-json-to-rdf.xsl">
					<p:with-param name="public-uri" select="$public-uri"/>
					<p:with-param name="relative-uri" select="$relative-uri"/>
				</mv:transform>
				<!-- return the RDF/XML -->
				<z:make-http-response content-type="application/rdf+xml"/>
			</p:when>
			<p:when test="starts-with($relative-uri, 'resource/')">
				<!-- request for a generic "resource" which may or may not be an information resource -->
				<p:template>
					<p:with-param name="public-uri" select="$public-uri"/>
					<p:input port="parameters">
						<p:pipe step="request-uri" port="result"/>
					</p:input>
					<p:input port="template">
						<p:inline>
							<c:response status="303">
								<!-- redirect to a URI in which the "/resource/" component is replaced with "/data/" -->
								<c:header name="Location" value="{
									concat(
										$scheme,
										'//',
										$host,
										$port,
										substring-before($path, '/resource/'),
										'/data/',
										substring-after($path, '/resource/'),
										$query
									)
								}"/>
							</c:response>
						</p:inline>
					</p:input>
				</p:template>
			</p:when>
			<p:otherwise>
				<z:not-found/>
			</p:otherwise>
		</p:choose>
	</p:declare-step>

	
	<!-- shorthand for executing an XSLT  -->
	<p:declare-step type="mv:transform" name="transform">
		
		<p:input port="source"/>
		<p:output port="result" primary="true"/>
		<p:input port="parameters" kind="parameter"/>
		
		<p:option name="xslt" required="true"/>
		
		<p:load name="load-stylesheet">
			<p:with-option name="href" select="$xslt"/>
		</p:load>
		
		<p:xslt name="execute-xslt">
			<p:input port="source">
				<p:pipe step="transform" port="source"/>
			</p:input>
			<p:input port="stylesheet">
				<p:pipe step="load-stylesheet" port="result"/>
			</p:input>
		</p:xslt>
	</p:declare-step>
</p:library>
