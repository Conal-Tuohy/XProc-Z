
<p:library version="1.0" xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" xmlns:j="http://marklogic.com/json" xmlns:mv="tag:conaltuohy.com,2015:museum-victoria">
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<p:import href="../xproc-z-library.xpl"/>
	
	<p:declare-step type="mv:museum-victoria" name="museum-victoria" xpath-version="2.0">
		<p:input port="source" primary="true"/>
		<p:input port="parameters" kind="parameter" primary="true"/>
		<p:output port="result" primary="true" sequence="true"/>
		<p:option name="relative-uri" select=" '' "/>
					
		<!-- generate a public URI - this pipeline could be running behind a proxy -->
		<z:parse-request-uri name="request-uri" unproxify="true"/>
		<p:group>
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
			<p:choose>
				<!-- request for a "data" resource, i.e. a document -->
				<p:when test="starts-with($relative-uri, 'data/')">
					<p:choose>
						<p:when test="starts-with($relative-uri, 'data/taxon/')">
							<!-- make a request to the Museum Victoria "search" API to find species
								by taxon name
							-->
							<mv:make-api-call name="species-by-taxon">
								<p:with-option name="uri" select="
									concat(
										'search?recordtype=species&amp;limit=100&amp;taxon=',
										substring-after(substring-after($relative-uri, 'data/taxon/'), '-')
									)
								"/>
								<p:input port="parameters">
									<p:pipe step="request-uri" port="result"/>
								</p:input>
							</mv:make-api-call>
							<!-- now make a request for the first one of those species -->
							<mv:make-api-call name="representative-species-for-taxon">
								<p:with-option name="uri" select="/j:json/j:results/j:item[1]/j:id"/>
							</mv:make-api-call>
							<!-- insert the "species" result document into the "search" result document -->
							<p:insert position="first-child">
								<p:input port="source">
									<p:pipe step="species-by-taxon" port="result"/>
								</p:input>
								<p:input port="insertion">
									<p:pipe step="representative-species-for-taxon" port="result"/>
								</p:input>
							</p:insert>
						</p:when>
						<p:otherwise>
							<!-- make a request to the Museum Victoria API -->
							<mv:make-api-call>
								<p:with-option name="uri" select="substring-after($relative-uri, 'data/')"/>
								<p:input port="parameters">
									<p:pipe step="request-uri" port="result"/>
								</p:input>
							</mv:make-api-call>
						</p:otherwise>
					</p:choose>
					<!-- tag the root element to match its high-level type as defined in the request URI -->
					<p:group>
						<p:variable name="type" select="substring-before(substring-after($relative-uri, 'data/'), '/')"/>
						<p:add-attribute match="/*" attribute-name="type">
							<p:with-option name="attribute-value" select="
							('article', 'item', 'species', 'specimen', 'taxon')[
								xs:integer($type='articles') +
								xs:integer($type='items') * 2 +
								xs:integer($type='species') * 3 +
								xs:integer($type='specimens') * 4 +
								xs:integer($type='taxon') * 5
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
				<!-- request for a generic "resource" which we redirect to an information ("data") resource -->
					<mv:redirect-to-information-resource>
						<p:input port="parameters">
							<p:pipe step="request-uri" port="result"/>
						</p:input>
					</mv:redirect-to-information-resource>
				</p:when>
				<p:otherwise>
					<z:not-found/>
				</p:otherwise>
			</p:choose>
		</p:group>
	</p:declare-step>
	
	<p:declare-step type="mv:make-api-call">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:input port="parameters" kind="parameter"/>
		<p:option name="uri"/>
		<p:template>
			<p:with-param name="uri" select="$uri"/>
			<p:input port="template">
				<p:inline>
					<c:request method="GET" href="{concat('http://collections.museumvictoria.com.au/api/', $uri)}"/>
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
	</p:declare-step>
	
	<p:declare-step type="mv:redirect-to-information-resource">
		<!-- request for a generic "resource" must redirect to an information resource -->
		<p:input port="source"/>
		<p:output port="result"/>
		<p:input port="parameters" kind="parameter"/>
		<p:template>
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
