
<p:library version="1.0" xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" xmlns:j="http://marklogic.com/json" xmlns:mv="tag:conaltuohy.com,2015:museum-victoria">
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<p:import href="../xproc-z-library.xpl"/>
	
	<p:declare-step type="mv:museum-victoria" name="museum-victoria" xpath-version="2.0">
		<p:input port="source" primary="true"/>
		<p:input port="parameters" kind="parameter" primary="true"/>
		<p:output port="result" primary="true" sequence="true"/>
		<p:option name="relative-uri" select=" '' "/>
		<p:variable name="accept" select="/c:request/c:header[3]/@value"/>
					
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
				<p:when test="$relative-uri = 'ontology' ">
					<p:identity>
						<p:input port="source">
							<p:inline>
								<rdf:RDF 
									xmlns:owl="http://www.w3.org/2002/07/owl#" 
									xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
									xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
									<owl:DatatypeProperty rdf:ID="P3.1_objectSummary">
										<rdfs:subPropertyOf rdf:resource="http://erlangen-crm.org/current/P3_has_note"/>
										<rdfs:label>object summary</rdfs:label>
										<rdfs:comment>This is a sub-property of crm:P3_has_note, reflecting the JSON objectSummary field</rdfs:comment>
									</owl:DatatypeProperty>
									<owl:DatatypeProperty rdf:ID="P3.1_physicalDescription">
										<rdfs:subPropertyOf rdf:resource="http://erlangen-crm.org/current/P3_has_note"/>
										<rdfs:label>physical description</rdfs:label>
										<rdfs:comment>This is a sub-property of crm:P3_has_note, reflecting the JSON physicalDescription field</rdfs:comment>
									</owl:DatatypeProperty>
								</rdf:RDF>
							</p:inline>
						</p:input>
					</p:identity>
					<!-- return the RDF -->
					<mv:return-rdf>
						<p:with-option name="accept" select="$accept"/>
					</mv:return-rdf>
				</p:when>
				<!-- request for HTML -->
				<p:when test="starts-with($relative-uri, 'data/html/')">
					<!-- get the article from Museum Victoria's API -->
					<mv:make-api-call name="museum-api-data">
						<p:with-option name="uri" select="substring-after($relative-uri, 'data/html/')"/>
					</mv:make-api-call>
					<!-- extract the HTML from the JSON and format it nicely -->
					<mv:transform xslt="museum-victoria-json-to-html.xsl">
						<p:with-param name="public-uri" select="$public-uri"/>
						<p:with-param name="relative-uri" select="$relative-uri"/>
					</mv:transform>
					<!-- return the HTML -->
					<z:make-http-response content-type="application/xhtml+xml"/>					
				</p:when>
				<!-- request for a "data" resource, i.e. an RDF graph -->
				<p:when test="starts-with($relative-uri, 'data/')">
					<p:choose>
						<p:when test="starts-with($relative-uri, 'data/technique/')">
							<!-- make a request to the Museum Victoria "search" API to find items
								with a particular technique -->
							<p:www-form-urldecode name="decoded-component">
								<p:with-option name="value" select="
									concat(
										'component=',
										substring-after($relative-uri, 'data/technique/'
									)
								)"/>
							</p:www-form-urldecode>
							<mv:make-api-call name="items-by-technique">
								<p:with-option name="uri" select="
									concat(
										'search?limit=100&amp;technique=',
										substring-after($relative-uri, 'data/technique/')
									)
								"/>
							</mv:make-api-call>
							<p:group>
								<p:variable name="technique" select="/c:param-set/c:param[@name='component']/@value">
									<p:pipe step="decoded-component" port="result"/>
								</p:variable>
								<p:add-attribute match="/*" attribute-name="technique">
									<p:with-option name="attribute-value" select="$technique"/>
								</p:add-attribute>
							</p:group>
						</p:when>
						<p:when test="starts-with($relative-uri, 'data/taxon/')">
							<!-- make a request to the Museum Victoria "search" API to find species
								by taxon name -->
							<mv:make-api-call name="species-by-taxon">
								<p:with-option name="uri" select="
									concat(
										'search?recordtype=species&amp;limit=100&amp;taxon=',
										substring-after(substring-after($relative-uri, 'data/taxon/'), '-')
									)
								"/>
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
							<mv:make-api-call name="museum-api-data">
								<p:with-option name="uri" select="substring-after($relative-uri, 'data/')"/>
							</mv:make-api-call>
							<p:choose>
								<p:when test="starts-with($relative-uri, 'data/species/')">
									<!-- for species, look up binomial name in dbpedia, e.g.
										select distinct ?species where
										{
											?species dbp:binomial "Hapalochlaena maculosa"@en
										}
									-->
									<mv:dbpedia-sparql-query name="dbpedia-species">
										<p:with-option name="query" select="
											'select distinct ?species where {?species dbp:binomial ',
											codepoints-to-string(34),
											//j:taxonName,
											codepoints-to-string(34), '@en', 
											'}'
										"/>
									</mv:dbpedia-sparql-query>
									<!-- stick the query result into the data document to be transformed into RDF -->
									<p:insert position="first-child">
										<p:input port="source">
											<p:pipe step="museum-api-data" port="result"/>
										</p:input>
										<p:input port="insertion">
											<p:pipe step="dbpedia-species" port="result"/>
										</p:input>	
									</p:insert>
								</p:when>
								<p:otherwise>
									<!-- not a request for a species, so no enhancement required -->
									<p:identity/>
								</p:otherwise>
							</p:choose>
						</p:otherwise>
					</p:choose>
					<!-- tag the root element to match its high-level type as defined in the request URI -->
					<p:group>
						<p:variable name="type" select="substring-before(substring-after($relative-uri, 'data/'), '/')"/>
						<p:add-attribute match="/*" attribute-name="type">
							<p:with-option name="attribute-value" select="$type"/>
						</p:add-attribute>
					</p:group>
					<!-- convert the JSON (possibly including SPARQL query results) into RDF/XML -->
					<mv:transform xslt="museum-victoria-json-to-rdf.xsl">
						<p:with-param name="public-uri" select="$public-uri"/>
						<p:with-param name="relative-uri" select="$relative-uri"/>
					</mv:transform>
					<!-- set the base URI -->
					<p:add-attribute match="/*" attribute-name="xml:base">
						<p:with-option name="attribute-value" select="$public-uri"/>
					</p:add-attribute>
					<!-- return the RDF/XML -->
					<mv:return-rdf>
						<p:with-option name="accept" select="$accept"/>
					</mv:return-rdf>
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
		<!--<p:input port="parameters" kind="parameter"/>-->
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
	
	<p:declare-step type="mv:dbpedia-sparql-query" name="sparql-query">
		<p:output port="result"/>
		<p:option name="query"/>
		<p:template name="generate-http-request">
			<p:with-param name="query" select="$query"/>
			<p:input port="source"><p:empty/></p:input>
			<p:input port="template">
				<p:inline>
					<c:request method="GET" detailed="true" href="{
						concat(
							'http://dbpedia.org/sparql',
							'?default-graph-uri=http%3A%2F%2Fdbpedia.org',
							'&amp;format=application%2Fsparql-results',
							'&amp;query=', encode-for-uri($query)
						)
					}"/>
				</p:inline>
			</p:input>
		</p:template>
		<p:http-request/>
	</p:declare-step>	
	
	<p:declare-step type="mv:return-rdf">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:input port="parameters" kind="parameter" primary="true"/>
		<p:option name="accept"/>
		<p:choose>
			<p:when test="
				contains($accept, 'application/ld+json')
			">
				<mv:transform xslt="rdf-xml-to-json-ld.xsl"/>
				<z:make-http-response content-type="application/ld+json"/>
			</p:when>
			<p:when test="
				contains($accept, 'application/json') 
			">
				<mv:transform xslt="rdf-xml-to-json-ld.xsl"/>
				<z:make-http-response content-type="application/json"/>
			</p:when>
			<p:otherwise>
				<z:make-http-response content-type="application/rdf+xml"/>
				<z:add-response-header header-name="Accepted">
					<p:with-option name="header-value" select="$accept"/>
				</z:add-response-header>
			</p:otherwise>
		</p:choose>
	</p:declare-step>
	
</p:library>
