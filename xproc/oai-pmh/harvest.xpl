<?xml version="1.0"?>
<p:library 
	version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:corbicula="tag:conaltuohy.com,2015:corbicula"
	xmlns:oai="http://www.openarchives.org/OAI/2.0/"
	xmlns:pxf="http://exproc.org/proposed/steps/file"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
>
	<!-- import calabash extension library to enable use of delete-file step -->
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	
	<!-- the harvest step should have "delete" and "update" sequence output ports,
	and also a "high-water-mark" output port that emits either zero or one document
	(the latter at the end of the harvest) -->
	<!-- this would be called by a step that contained the harvest step with update and
	delete ports connected to a file-store step, and via a crosswalk to a graph-store step
	The high-water-mark port would be connected to a file store step, and via
	a (OAI-to-VOID) crosswalk to a graph store step. -->
	
	<p:declare-step type="corbicula:handle-harvest-request" name="handle-request">
		<p:input port='source' primary='true'/>
		<p:input port='parameters' kind='parameter' primary='true'/>
		<p:output port="result" primary="true" sequence="true"/>
		<p:option name="relative-uri"/>
		<p:variable name="request-uri" select="/c:request/@href"/>
		<!-- read post parameters -->
		<p:www-form-urldecode name="posted-data">
			<p:with-option name="value" select="/c:request/c:body"/>
		</p:www-form-urldecode>
		<!-- merge the XProc-Z parameters (configuration settings) with the POSTed parameters -->
		<p:parameters name="merge-configuration-parameters">
			<p:input port="parameters">
				<p:pipe step="handle-request" port="parameters"/>
				<p:pipe step="posted-data" port="result"/>
			</p:input>
		</p:parameters>
		<p:delete name="exclude-empty-parameters" match="/c:param-set/c:param[@value='']">
			<p:input port="source">
				<p:pipe step="merge-configuration-parameters" port="result"/>
			</p:input>
		</p:delete>
		<p:group name="handle-parameters">
			<p:variable name="resource-base-uri" select="/c:param-set/c:param[@name='resourceBaseURI']/@value"/>
			<p:variable name="graph-store" select="/c:param-set/c:param[@name='graphStore']/@value"/>
			<p:variable name="repository-base-uri" select="/c:param-set/c:param[@name='baseURI']/@value"/>
			<p:variable name="metadata-prefix" select="/c:param-set/c:param[@name='metadataPrefix']/@value"/>
			<p:variable name="set" select="/c:param-set/c:param[@name='set']/@value"/>
			<p:variable name="resumption-token" select="/c:param-set/c:param[@name='resumptionToken']/@value"/>
			<p:variable name="cache" select="
				concat(
					/c:param-set/c:param
						[@name='realPath']
						[@namespace='tag:conaltuohy.com,2015:servlet-context']
						/@value,
					'/WEB-INF/cache/',
					encode-for-uri(encode-for-uri($repository-base-uri)),
					'/',
					if ($set) then concat(encode-for-uri(encode-for-uri($set)), '/') else '',
					encode-for-uri(encode-for-uri($metadata-prefix)),
					'/'
				)			
			"/>
			<p:choose>
				<p:when test="$resumption-token or $metadata-prefix">
					<p:choose>
						<p:when test="$resumption-token">
							<!-- resume a harvest -->
							<!-- send off the OAI-PMH ListRecords request -->
							<p:load name="http-request">
								<p:with-option name="href" select="
									concat(
										$repository-base-uri,
										'?verb=ListRecords',
										'&amp;resumptionToken=', $resumption-token
									)
								"/>
							</p:load>
						</p:when>
						<p:when test="$metadata-prefix">
							<!-- begin a harvest -->
							<!-- read previous harvest date from disk cache to begin query -->
							<corbicula:load-last-harvest-information>
								<p:with-option name="cache" select="$cache"/>
								<p:with-option name="repository" select="$repository-base-uri"/>
								<p:with-option name="metadata-prefix" select="$metadata-prefix"/>
								<p:with-option name="set" select="$set"/>
							</corbicula:load-last-harvest-information>
							
							<!-- send off the OAI-PMH ListRecords request -->
							<p:group>
								<!-- if set is missing, produces nothing; if set is present, prefixes it with "&amp;set=" -->
								<p:variable name="set-parameter" select="if ($set) then concat('&amp;set=', $set) else '' "/>
								<!-- if from is missing, produces nothing; if from is present, prefixes it with "&amp;from=" -->
								<p:variable name="from-parameter" select="if (/oai:datestamp) then concat('&amp;from=', /oai:datestamp) else '' "/>
						
								<p:load name="http-request">
									<p:with-option name="href" select="
										concat(
											$repository-base-uri,
											'?verb=ListRecords',
											'&amp;metadataPrefix=', $metadata-prefix, 
											$from-parameter,
											$set-parameter
										)
									"/>
								</p:load>
							</p:group>							
						</p:when>
					</p:choose>		
					<!-- process all the harvested records -->
					<corbicula:handle-list-records-response name="records">
						<p:with-option name="request-uri" select="$request-uri"/>
						<p:with-option name="base-uri" select="$repository-base-uri"/>
						<p:with-option name="metadata-prefix" select="$metadata-prefix"/>
						<p:with-option name="set" select="$set"/>
						<p:with-option name="cache" select="$cache"/>
						<p:with-option name="graph-store" select="$graph-store"/>
						<p:with-option name="resource-base-uri" select="$resource-base-uri"/>
					</corbicula:handle-list-records-response>
					<!--
					<p:wrap-sequence wrapper="oai-pmh-response-and-trampoline"/>
					<z:make-http-response xmlns:z="https://github.com/Conal-Tuohy/XProc-Z"/>
					-->

				</p:when>
				<p:otherwise>
					<corbicula:respond-with-harvest-form/>
				</p:otherwise>
			</p:choose>
		</p:group>
	</p:declare-step>
	
	<p:declare-step type="corbicula:load-last-harvest-information" name="load-last-harvest-information">
		<p:output port="result"/>
		<p:option name="cache" required="true"/>
		<p:option name="repository" required="true"/>
		<p:option name="metadata-prefix" required="true"/>
		<p:option name="set"/>
		<p:try>
			<p:group>
				<p:load name="last-harvest-information">
					<p:with-option name="href" select="concat(
						$cache, '/', 
						$repository, '/', 
						$metadata-prefix, '-', $set, '/',
						'.last-harvest.xml'
					"/>
				</p:load>
			</p:group>
			<p:catch>
				<p:identity>
					<p:input port="source">
						<p:inline>
							<nothing/>
						</p:inline>
					</p:input>
				</p:identity>
			</p:catch>
		</p:try>
	</p:declare-step>
	
	<p:declare-step type="corbicula:handle-list-records-response" name="handle-list-records-response">
		<!-- a harvested batch of records -->
		<p:input port="source"/>
		<!-- a report on the processing of the batch of records -->
		<!-- followed by a resumption of the harvest -->
		<p:output port="result" primary="true" sequence="true">
			<p:pipe step="report" port="result"/>
			<p:pipe step="resume-request" port="result"/>
		</p:output>		
		<p:option name="request-uri" required="true"/>
		<p:option name="base-uri" required="true"/>
		<p:option name="metadata-prefix" required="true"/>
		<p:option name="set" required="true"/>
		<p:option name="cache" required="true"/>
		<p:option name="graph-store" required="true"/>	
		<p:option name="resource-base-uri" required="true"/>
		<p:for-each name="deletion">
			<p:iteration-source select="/oai:OAI-PMH/oai:ListRecords/oai:record[oai:header/@status='deleted']">
				<p:pipe step="handle-list-records-response" port="source"/>
			</p:iteration-source>
			<!-- delete the record from the cache -->
			<!-- ignore errors because the record may not be in the cache -->
			<!--
			<pxf:delete fail-on-error="false">
				<p:with-option name="href" select="$file-uri"/>
			</pxf:delete>
			-->
			<corbicula:delete-graph>
				<p:with-option name="graph-store" select="$graph-store"/>
				<p:with-option name="graph-uri" select="/oai:record/oai:header/oai:identifier"/>
			</corbicula:delete-graph>
		</p:for-each>
		
		<p:for-each name="update">
			<p:iteration-source select="/oai:OAI-PMH/oai:ListRecords/oai:record[not(oai:header/@status='deleted')]">
				<p:pipe step="handle-list-records-response" port="source"/>
			</p:iteration-source>
			<p:variable name="identifier" select="encode-for-uri(/oai:record/oai:header/oai:identifier)"/>
			<!-- cache the harvested record -->
			<p:store name="save-record">
				<p:with-option name="href" select="concat($cache, '/', encode-for-uri($identifier), '.xml')"/>
			</p:store>
			<p:xslt name="rdf">
				<p:with-param name="resource-base-uri" select="$resource-base-uri"/>
				<p:input port="source">
					<p:pipe step="update" port="current"/>
				</p:input>
				<p:input port="stylesheet">
					<p:document href="rif-cs-to-rdf.xsl"/>
				</p:input>
			</p:xslt>
			<!-- cache the graph as a local file (for debugging cross-walk) -->
			<p:store name="save-graph">
				<p:with-option name="href" select="concat($cache, '/', encode-for-uri($identifier), '.rdf')"/>
			</p:store>
			<corbicula:store-graph>
				<p:with-option name="graph-store" select="$graph-store"/>
				<p:with-option name="graph-uri" select="$identifier"/>
				<p:input port="source">
					<p:pipe step="rdf" port="result"/>
				</p:input>
			</corbicula:store-graph>
		</p:for-each>			

		<!-- Compute and save latest datestamp from the sequence of headers-->
		<!-- but only if the sequence is not empty - otherwise leave the log file unchanged -->
		<!--
		<corbicula:save-last-harvest-information>
			<p:pipe step="records" port="headers"/>
		</corbicula:save-last-harvest-information>
		-->			
		<!--		
		<p:count name="update-count">
			<p:input port="source" select="/oai:OAI-PMH/oai:ListRecords/oai:record[not(oai:header/@status='deleted')]">
				<p:pipe step="handle-list-records-response" port="source"/>
			</p:input>
		</p:count>
		-->
		<z:make-http-response  name="report" xmlns:z="https://github.com/Conal-Tuohy/XProc-Z">
			<p:input port="source">
				<p:pipe step="handle-list-records-response" port="source"/>
			</p:input>
		</z:make-http-response>

		<!--
		<corbicula:respond-with-harvest-initiation-report name="report"/>
		-->
		
		<!-- query again (recursively) if a resumptionToken was returned in the query results -->
		<corbicula:handle-resumption-token name="resume-request">
			<p:input port="source">
				<p:pipe step="handle-list-records-response" port="source"/>
			</p:input>
			<p:with-option name="request-uri" select="$request-uri"/>
			<p:with-option name="base-uri" select="$base-uri"/>
			<p:with-option name="metadata-prefix" select="$metadata-prefix"/>
			<p:with-option name="set" select="$set"/>
			<p:with-option name="graph-store" select="$graph-store"/>
			<p:with-option name="resource-base-uri" select="$resource-base-uri"/>
		</corbicula:handle-resumption-token>
	</p:declare-step>

	<p:declare-step type="corbicula:handle-resumption-token" name="handle-resumption-token">
		<p:input port="source"/>
		<p:output port="result" sequence="true"/>
		<p:option name="request-uri" required="true"/>
		<p:option name="base-uri" required="true"/>
		<p:option name="metadata-prefix" required="true"/>
		<p:option name="graph-store" required="true"/>
		<p:option name="resource-base-uri" required="true"/>
		<p:option name="set" required="true"/>
		
		<p:for-each>
			<p:iteration-source select="/oai:OAI-PMH[oai:ListRecords/oai:resumptionToken]"/>
			<p:template name="resumption-request">
				<p:with-param name="request-uri" select="$request-uri"/>
				<p:with-param name="base-uri" select="$base-uri"/>
				<p:with-param name="metadata-prefix" select="$metadata-prefix"/>
				<p:with-param name="set" select="$set"/>
				<p:with-param name="graph-store" select="$graph-store"/>
				<p:with-param name="resource-base-uri" select="$resource-base-uri"/>
				<p:with-param name="resumption-token" select="normalize-space(/oai:OAI-PMH/oai:ListRecords/oai:resumptionToken)"/>
				<p:input port="template">
					<p:inline>
						<c:request href="{$request-uri}" method="POST">
							<c:body content-type="application/x-www-form-urlencoded">{
								concat(
									"baseURI=", encode-for-uri($base-uri),
									"&amp;metadataPrefix=", encode-for-uri($metadata-prefix),
									"&amp;set=", encode-for-uri($set),
									"&amp;resumptionToken=", encode-for-uri($resumption-token),
									"&amp;graphStore=", encode-for-uri($graph-store),
									"&amp;resourceBaseURI=", encode-for-uri($resource-base-uri)
								)
							}</c:body>
						</c:request>
					</p:inline>
				</p:input>
			</p:template>
		</p:for-each>
	</p:declare-step>
	
	<p:declare-step type="corbicula:begin-list-records" name="begin-list-records">
		<p:output port="result" primary="true"/>
		<p:option name="repository-base-uri" required="true"/>
		<p:option name="metadata-prefix" required="true"/>
		<p:option name="set"/>
		<p:option name="from"/>
		<!-- if set is missing, produces nothing; if set is present, prefixes it with "&amp;set=" -->
		<p:variable name="set-parameter" select="if ($set) then concat('&amp;set=', $set) else '' "/>
		<!-- if from is missing, produces nothing; if from is present, prefixes it with "&amp;from=" -->
		<p:variable name="from-parameter" select="if ($from) then concat('&amp;from=', $from) else '' "/>

		<p:load name="http-request">
			<p:with-option name="href" select="
				concat(
					$repository-base-uri,
					'?verb=ListRecords',
					'&amp;metadataPrefix=', $metadata-prefix, 
					$from-parameter,
					$set-parameter
				)
			"/>
		</p:load>
	</p:declare-step>

	
	<p:declare-step type="corbicula:respond-with-harvest-initiation-report">
		<p:output port="result"/>
		<p:identity>
			<p:input port="source">
				<p:inline>
					<c:response status="200">
						<c:header name="X-Powered-By" value="XProc using XML Calabash"/>
						<c:header name="Server" value="XProc-Z"/>
						<c:body content-type="application/xhtml+xml">
							<html xmlns="http://www.w3.org/1999/xhtml">
								<head>
									<title>Harvest started</title>
								</head>
								<body>
									<h1>Harvest started</h1>
								</body>
							</html>
						</c:body>
					</c:response>
				</p:inline>
			</p:input>
		</p:identity>
		<!--
		<p:xslt name="harvest-initiation-report">
			<p:input port="parameters">
				<p:empty/>
			</p:input>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet version="2.0" 
						xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
						xmlns:xs="http://www.w3.org/2001/XMLSchema"
						xmlns="http://www.w3.org/1999/xhtml">
						<xsl:template match="/">
							<c:response status="200">
								<c:header name="X-Powered-By" value="XProc using XML Calabash"/>
								<c:header name="Server" value="XProc-Z"/>
								<c:body content-type="application/xhtml+xml">
									<html xmlns="http://www.w3.org/1999/xhtml">
										<head>
											<title>Harvest started</title>
										</head>
										<body>
											<h1>Harvest started</h1>
											<xsl:for-each select="/c:param-set/c:param">
												<p><xsl:value-of select="concat(@name, '=', @value)"/></p>
											</xsl:for-each>
											<xsl:if test="not(/c:param-set)">
												<xsl:for-each select="//*">
													<p><xsl:value-of select="local-name()"/></p>
												</xsl:for-each>
											</xsl:if>
										</body>
									</html>
								</c:body>
							</c:response>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
		-->
	</p:declare-step>
	
	<p:declare-step type="corbicula:save-last-harvest-information">
		<p:input port="source" sequence="true"/>
		<p:wrap-sequence wrapper="headers" name="assemble-headers-log-file">
			<p:input port="source">
				<p:pipe step="records" port="headers"/>
			</p:input>
		</p:wrap-sequence>
		<p:choose>
			<p:when test="//oai:datestamp">
				<p:xslt name="compute-latest-datestamp">
					<p:input port="parameters">
						<p:empty/>
					</p:input>
					<p:input port="stylesheet">
						<p:inline exclude-inline-prefixes="c fn corbicula pxf">
							<xsl:stylesheet version="1.0"  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
								<xsl:template match="/">
									<xsl:for-each select="//oai:datestamp">
										<xsl:sort order="descending"/>
										<xsl:if test="position() = 1">
											<xsl:copy-of select="."/>
										</xsl:if>
									</xsl:for-each>
								</xsl:template>
							</xsl:stylesheet>
						</p:inline>
					</p:input>
				</p:xslt>
				<p:store name="save-latest-datestamp">
					<p:with-option name="href" select="concat($cache-location, '.last-harvest.xml')"/>
				</p:store>
			</p:when>
			<p:otherwise>
				<p:sink/>
			</p:otherwise>
		</p:choose>
	</p:declare-step>
	

	
	<p:pipeline type="corbicula:respond-with-harvest-form" name="harvest-form">
		<p:identity name="harvest-request-form">
			<p:input port="source">
				<p:inline>
					<c:response status="200">
						<c:header name="X-Powered-By" value="XProc using XML Calabash"/>
						<c:header name="Server" value="XProc-Z"/>
						<c:body content-type="application/xhtml+xml">
							<html xmlns="http://www.w3.org/1999/xhtml">
								<head>
									<title>Initiate Harvest</title>
								</head>
								<body>
									<h1>Initiate or Resume Harvest</h1>
									<form method="POST" action="#">
										<table>
											<tr>
												<td><label>Repository Base URI</label></td>
												<td><input type="text" name="baseURI"/></td>
											</tr>
											<tr>
												<td><label>Metadata Prefix</label></td>
												<td><input type="text" name="metadataPrefix"/></td>
											</tr>
											<tr>
												<td><label>Set</label></td>
												<td><input type="text" name="set"/></td>
											</tr>
											<tr>
												<td><label>Resumption Token</label></td>
												<td><input type="text" name="resumptionToken"/></td>
											</tr>
											<tr>
												<td><label>Graph Store</label></td>
												<td><input type="text" name="graphStore"/></td>
											</tr>
											<tr>
												<td><label>RDF Resource Base URI</label></td>
												<td><input type="text" name="resourceBaseURI"/></td>
											</tr>
										</table>
										<button type="submit">Harvest</button>
									</form>
								</body>
							</html>
						</c:body>
					</c:response>
				</p:inline>
			</p:input>
		</p:identity>
	</p:pipeline>
	
	
	
	
	<p:declare-step type="corbicula:sparql-update" name="sparql-update">
		<p:option name="sparql-update-uri"/>
		<p:option name="query"/>
		<p:template name="construct-deletion-request">
			<p:with-param name="sparql-update" select="$sparql-update"/>
			<p:with-param name="query" select="$query"/>
			<p:input port="template">
				<p:inline>
					<c:request href="{$sparql-update}" method="POST">
						<c:body content-type="application/sparql-update">{$query}</c:body>
					</c:request>
				</p:inline>
			</p:input>
		</p:template>
		<p:http-request/>
	</p:declare-step>
	
	<!-- delete graph -->
	<p:declare-step type="corbicula:delete-graph" name="delete-graph">
		<p:option name="graph-store" required="true"/>
		<p:option name="graph-uri" required="true"/>
		<p:template name="construct-deletion-request">
			<p:with-param name="graph-store" select="$graph-store"/>
			<p:with-param name="graph-uri" select="$graph-uri"/>
			<p:input port="template">
				<p:inline>
					<c:request method="DELETE" href="{$graph-store}{$graph-uri}" detailed="true"/>
				</p:inline>
			</p:input>
			<p:input port="source">
				<p:empty/>
			</p:input>
		</p:template>
		<p:http-request/>
		<p:sink/>
	</p:declare-step>
	
	<!-- store graph -->
	<p:declare-step type="corbicula:store-graph" name="store-graph">
		<p:input port="source"/>
		<p:option name="graph-store" required="true"/>
		<p:option name="graph-uri" required="true"/>
		<!-- execute an HTTP PUT to store the graph in the graph store at the location specified -->
		<p:template name="generate-put-request">
			<p:with-param name="graph-store" select="$graph-store"/>
			<p:with-param name="graph-uri" select="$graph-uri"/>
			<p:input port="source">
				<p:pipe step="store-graph" port="source"/>
			  </p:input>
			<p:input port="template">
				<p:inline>
					<c:request method="PUT" href="{$graph-store}?graph={encode-for-uri($graph-uri)}" detailed="true">
						<c:body content-type="application/rdf+xml">{ /* }</c:body>
					</c:request>
				</p:inline>
			</p:input>
		</p:template>
		<p:http-request/>
		<p:sink/>
	</p:declare-step>



	

	

		
	
	
	
	

	<p:declare-step type="corbicula:send-mail" name="send-mail">
		<p:input port="message" primary="true"/>
		<p:output port="result" primary="true"/>
		<p:variable name="from" select="/*/@from"/>
		<p:variable name="to" select="/*/@to"/>
		<p:variable name="subject" select="/*/@to"/>
		<!-- 
			mail -s subject -r from-address to-address
		-->
		<!-- execute "mail" program -->
		<p:exec name="mail" command="mail" result-is-xml="false" source-is-xml="false" arg-separator="|">
			<p:with-option name="args" select="concat('-s ', $subject, '|-r ', $from, '|', $to)"/>
		</p:exec>
	</p:declare-step>
	
</p:library>
