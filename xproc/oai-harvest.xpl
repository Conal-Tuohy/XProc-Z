<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:oai="tag:conaltuohy.com,2014:oai-harvest" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z">
	
	<!-- A tool for managing OAI-PMH harvesters -->
	<!--
		Resources:
			"":
				get an overview of the harvesting system
			"transformation" - a collection of XSLT transforms
			"transformation/{x}" - an XSLT transformation
				- get a description of the transformation
				- post an updated description and/or updated XSLT
			"transformation/{x}/xslt" - the XSLT
				- get the XSLT
			"subscription" - a collection of OAI-PMH repository subscriptions
				get a list of all the subscriptions
				post a new subscription (html form encoded)
					Title
			"subscription/{x}"
				get a description of subscription x
				post an updated subscription (html form encoded)
					Title
					Base URL
					Set (optional)
					Metadata format
					Activity status (enabled="true|false")
					Schedule frequency
					Next scheduled time
					Resumption token state
					Subscriber email address
				delete harvester
			"subscription/x/record"
				collection of records harvested from repository x
			"subscription/x/record/y
				record y
	-->
	
	<p:import href="xproc-z-library.xpl"/>
	<p:declare-step type="oai:harvester" name="main">
		<p:input port="source"/>
		<p:input port="parameters" kind="parameter"/>
		<p:output port="result" sequence="true"/>
		<p:option name="relative-uri" required="true"/>
		<p:variable name="directory" select=" '../WEB-INF/oai' "/>
		<p:choose>
			<p:when test="$relative-uri = 'transformation/'">
				<!-- the collection of transformations -->
				<p:choose>
					<p:when test="/c:request/@method='GET'">
						<oai:list-transformations>
							<p:with-option name="directory" select="$directory"/>
						</oai:list-transformations>
					</p:when>
						<!-- add a new transformation -->
						<!--
					<p:when test="/c:request/@method='POST'">
						<oai:add-transformation>
							<p:with-option name="directory" select="$directory"/>
						</oai:add-tranformation>
					</p:when>
					-->
					<p:otherwise>
						<oai:method-not-allowed/>
					</p:otherwise>
				</p:choose>
			</p:when>
			<p:when test="$relative-uri = 'subscription/'">
				<!-- the collection of subscriptions -->
				<p:choose>
					<p:when test="/c:request/@method='GET'">
						<oai:list-subscriptions>
							<p:with-option name="directory" select="$directory"/>
						</oai:list-subscriptions>
					</p:when>
						<!-- add a new subscription -->
						<!--
					<p:when test="/c:request/@method='POST'">
						<oai:add-subscription>
							<p:with-option name="directory" select="$directory"/>
						</oai:add-subscription>
					</p:when>
					-->
					<p:otherwise>
						<oai:method-not-allowed/>
					</p:otherwise>
				</p:choose>
			</p:when>
			<p:when test="starts-with($relative-uri, 'transformation/')">
				<!-- an existing transformation -->
				<p:variable name="file-name" select="substring-after($relative-uri, 'subscription/')"/><!-- QAZ sanitize -->
				<oai:transformation>
					<p:with-option name="directory" select="$directory"/>
					<p:with-option name="file-name" select="$file-name"/>
				</oai:transformation>
			</p:when>
			<p:when test="starts-with($relative-uri, 'subscription/')">
				<!-- an existing subscription -->
				<p:variable name="file-name" select="substring-after($relative-uri, 'subscription/')"/><!-- QAZ sanitize -->
				<oai:subscription>
					<p:with-option name="directory" select="$directory"/>
					<p:with-option name="file-name" select="$file-name"/>
				</oai:subscription>
			</p:when>
			<p:when test="$relative-uri = ''">
				<oai:home-page/>
			</p:when>
			<p:otherwise>
				<oai:error status="400" title="Bad Request URI" message="The URI is not recognised"/>
			</p:otherwise>
		</p:choose>
	</p:declare-step>
	
	<p:declare-step type="oai:method-not-allowed" name="method-not-allowed">
		<p:input port="source"/>
		<p:output port="result"/>
		<!--
		<p:identity/>
		<oai:http-respond/>		-->
		<oai:error status="405" title="Method Not Allowed" message="The request method is not allowed"/>
	</p:declare-step>
	

	
	<p:declare-step type="oai:home-page" name="home-page">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:identity>
			<p:input port="source">
				<p:inline>
					<html xmlns="http://www.w3.org/1999/xhtml">
						<head>
							<title>OAI-PMH Harvester</title>
						</head>
						<body>
							<h1>OAI-PMH Harvester</h1>
							<p>Welcome to the XProc-Z OAI-PMH Harvester</p>
							<form method="post" action="subscription/">
								<div>
									<h2>Add a new OAI-PMH harvest</h2>
									<label for="base-url">Repository Base URL</label>
									<input type="text" id="base-url" name="base-url"/>
									<input type="submit" name="new" value="Add Repository"/>
								</div>
							</form>
						</body>
					</html>
				</p:inline>
			</p:input>
		</p:identity>
		<oai:http-respond/>
	</p:declare-step>
	
	<!-- output a response -->
	<p:declare-step type="oai:http-respond" name="http-respond">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="status" select="200"/>
		<p:option name="content-type" select="'application/xml'"/>
		<p:in-scope-names name="options"/>
		<p:template>
			<p:input port="source">
				<p:pipe step="http-respond" port="source"/>
			</p:input>
			<p:input port="parameters">
				<p:pipe step="options" port="result"/>
			</p:input>
			<p:input port="template">
				<p:inline>
					<c:response status="{$status}">
						<c:header name="X-Powered-By" value="XProc using XML Calabash"/>
						<c:header name="Server" value="XProc-Z"/>
						<c:body content-type="{$content-type}">{/*}</c:body>
					</c:response>
				</p:inline>
			</p:input>
		</p:template>
	</p:declare-step>
	
	<!-- output an HTML page containing an error message -->
	<p:declare-step type="oai:error" name="error">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option required="true" name="title"/>
		<p:option required="true" name="message"/>
		<p:option required="true" name="status"/>
		<p:in-scope-names name="options"/>
		<p:template>
			<p:input port="source">
				<p:pipe step="error" port="source"/>
			</p:input>
			<p:input port="parameters">
				<p:pipe step="options" port="result"/>
			</p:input>
			<p:input port="template">
				<p:inline>
					<html xmlns="http://www.w3.org/1999/xhtml">
						<head>
							<title>{$title} — OAI-PMH Harvester</title>
						</head>
						<body>
							<h1>{$title} — OAI-PMH Harvester</h1>
							<p>{$message}</p>
						</body>
					</html>
				</p:inline>
			</p:input>
		</p:template>
		<oai:http-respond>
			<p:with-option name="status" select="$status"/>
		</oai:http-respond>
	</p:declare-step>
	
	<p:declare-step type="oai:transformation" name="transformation">
		<p:input port="source"/>
		<p:output port="result" sequence="true"/>
		<p:option name="directory"/>
		<p:option name="file-name"/>
		<p:variable name="transformation" select="concat($directory, '/', $file-name)"/>
		<p:choose>
			<p:when test="/c:request/@method='GET'">
				<p:try name="load-existing-data">
					<p:group>
						<p:load>
							<p:with-option name="href" select="$subscription"/>
						</p:load>
						<oai:render-transformation-form/>
					</p:group>
					<p:catch>
						<z:not-found/>
					</p:catch>
				</p:try>
			</p:when>
			<p:when test="/c:request/@method='POST'">
				<!-- save transformation details -->
				
				<!-- parse the HTML form fields -->
				<!-- www-form-urldecode fails to decode spaces encoded as "+" - is this a bug in Calabash? -->
				<!-- http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4.1 -->
				<p:string-replace match="/c:request/c:body/text()" replace="replace(., '\+', '%20')"/>
				<p:www-form-urldecode name="posted-data">
					<p:with-option name="value" select="/c:request/c:body"/>
				</p:www-form-urldecode>
				
				<!-- The web client has updated the transformation, by submitting one 
				of the named "status" buttons to alter the transformation's overall state. -->
				<p:choose>
					<p:when test="/c:param-set/c:param[@name='status']='deleted'">
						<oai:delete-transformation>
							<p:with-option name="transformation" select="$transformation"/>
						</oai:delete-transformation>
					</p:when>
					<p:otherwise>
						<oai:save-transformation>
							<p:with-option name="transformation" select="$transformation"/>
						</oai:save-transformation>
					</p:otherwise>
				</p:choose>
			</p:when>
			<p:otherwise>
				<oai:method-not-allowed/>
			</p:otherwise>
		</p:choose>
	</p:declare-step>	

	<p:declare-step type="oai:subscription" name="subscription">
		<p:input port="source"/>
		<p:output port="result" sequence="true"/>
		<p:option name="directory"/>
		<p:option name="file-name"/>
		<p:variable name="subscription" select="concat($directory, '/', $file-name)"/>
		<p:choose>
			<p:when test="/c:request/@method='GET'">
				<oai:load-subscription>
					<p:with-option name="subscription" select="$subscription"/>
				</oai:load-subscription>
				<oai:render-subscription-form/>
			</p:when>
			<p:when test="/c:request/@method='POST'">
				<!-- save subscription details -->
				
				<!-- parse the HTML form fields -->
				<!-- www-form-urldecode fails to decode spaces encoded as "+" - is this a bug in Calabash? -->
				<!-- http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4.1 -->
				<p:string-replace match="/c:request/c:body/text()" replace="replace(., '\+', '%20')"/>
				<p:www-form-urldecode name="posted-data">
					<p:with-option name="value" select="/c:request/c:body"/>
				</p:www-form-urldecode>
				
				<!-- The web client has updated the subscription, by submitting one 
				of the named "status" buttons to alter the subscription's overall state. -->
				<p:choose>
					<p:when test="/c:param-set/c:param[@name='status']='deleted'">
						<oai:delete-subscription>
							<p:with-option name="subscription" select="$subscription"/>
						</oai:delete-subscription>
					</p:when>
					<p:otherwise>
						<oai:save-subscription>
							<p:with-option name="subscription" select="$subscription"/>
						</oai:save-subscription>
					</p:otherwise>
				</p:choose>
			</p:when>
			<p:otherwise>
				<oai:method-not-allowed/>
			</p:otherwise>
		</p:choose>
	</p:declare-step>
		
	<p:declare-step type="oai:save-subscription" name="save-subscription">
		<p:input port='source' primary='true'/>
		<p:output port="result" primary="true" sequence="true"/>
		<p:option name="subscription" required="true"/>
		<oai:load-subscription name="existing-subscription">
			<p:with-option name="subscription" select="$subscription"/>
		</oai:load-subscription>
		<p:xslt name="convert-posted-data-to-persistent-form">
			<p:input port="parameters">
				<p:empty/>
			</p:input>
			<p:input port="source">
				<p:pipe step="save-subscription" port="source"/>
			</p:input>
			<p:input port="stylesheet">
				<p:inline exclude-inline-prefixes="z oai fn">
					<!-- this simple stylesheet handles a flat namespace of single-valued properties -->
					<xsl:stylesheet version="2.0" 
						xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
						xmlns:c="http://www.w3.org/ns/xproc-step"
						xmlns:xs="http://www.w3.org/2001/XMLSchema" 
						exclude-result-prefixes="c xs">
						<xsl:template match="/c:param-set">
							<subscription xmlns="tag:conaltuohy.com,2014:oai-harvest">
								<xsl:apply-templates/>
							</subscription>
						</xsl:template>
						<xsl:template match="c:param">
							<xsl:element name="{@name}" namespace="tag:conaltuohy.com,2014:oai-harvest">
								<xsl:value-of select="@value"/>
							</xsl:element>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
		<!-- bundle the existing subscription with the updated subscription data -->
		<p:wrap-sequence name="subscription-and-update" wrapper="oai:subscription-and-update">
			<p:input port="source">
				<p:pipe step="existing-subscription" port="result"/>
				<p:pipe step="convert-posted-data-to-persistent-form" port="result"/>
			</p:input>
		</p:wrap-sequence>
		<!-- perform a merge, over-writing any element of existing subscription which had an update -->
		<p:xslt>
			<p:input port="parameters">
				<p:empty/>
			</p:input>
			<p:input port="source">
				<p:pipe step="subscription-and-update" port="result"/>
			</p:input>
			<p:input port="stylesheet">
				<p:inline exclude-inline-prefixes="z fn c oai">
					<xsl:stylesheet version="2.0" 
						xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
						xmlns:xs="http://www.w3.org/2001/XMLSchema" 
						xmlns="tag:conaltuohy.com,2014:oai-harvest" 
						xpath-default-namespace="tag:conaltuohy.com,2014:oai-harvest"
						exclude-result-prefixes="xs">
						<xsl:template match="/">
							<xsl:variable name="existing" select="subscription-and-update/subscription[1]/*"/>
							<xsl:variable name="update" select="subscription-and-update/subscription[2]/*"/>
							<subscription>
								<xsl:for-each select="$existing">
									<xsl:variable name="name" select="local-name()"/>
									<xsl:if test="not($update[local-name() = $name])">
										<xsl:copy-of select="."/>
									</xsl:if>
								</xsl:for-each>
								<xsl:copy-of select="$update"/>
							</subscription>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
		<!-- read from the repository -->
		<p:group name="subscription-with-repository-details">
			<p:variable name="old-url" select="string(/oai:subscription/oai:baseURL)">
				<p:pipe step="existing-subscription" port="result"/>
			</p:variable>
			<p:variable name="new-url" select="string(/oai:subscription/oai:baseURL)">
				<p:pipe step="convert-posted-data-to-persistent-form" port="result"/>
			</p:variable>			
			<p:choose>
				<p:when test="$old-url = $new-url">
					<p:identity/>
				</p:when>
				<p:otherwise>
					<p:load name="identify">
						<p:with-option name="href" select="concat($new-url, '?verb=Identify')"/>
					</p:load>
					<p:load name="list-sets">
						<p:with-option name="href" select="concat($new-url, '?verb=ListSets')"/>
					</p:load>
					<p:load name="list-metadata-formats">
						<p:with-option name="href" select="concat($new-url, '?verb=ListMetadataFormats')"/>
					</p:load>
					<!-- throw out any existing cache of OAI-PMH repository metadata -->
					<p:delete xmlns:oai-pmh="http://www.openarchives.org/OAI/2.0/" match="oai-pmh:OAI-PMH"/>
					<p:insert position="first-child">
						<p:input port="source">
							<p:pipe step="convert-posted-data-to-persistent-form" port="result"/>
						</p:input>
						<p:input port="insertion">
							<p:pipe step="identify" port="result"/>
							<p:pipe step="list-sets" port="result"/>
							<p:pipe step="list-metadata-formats" port="result"/>
						</p:input>
					</p:insert>
				</p:otherwise>
			</p:choose>
		</p:group>
		<p:identity name="updated-subscription"/>
		<p:store>
			<p:with-option name="href" select="$subscription"/>
		</p:store>
		<!-- render the data in an HTML form -->
		<oai:render-subscription-form name="subscription-form">
			<p:input port="source">
				<p:pipe step="updated-subscription" port="result"/>
			</p:input>
		</oai:render-subscription-form>
		<!-- kick off the harvest if the subscription's status is "started" -->
		<oai:do-harvest name="harvest">		
			<p:with-option name="subscription" select="$subscription"/>
			<p:input port="source">
				<p:pipe step="updated-subscription" port="result"/>
			</p:input>
		</oai:do-harvest>
		<p:identity>
			<p:input port="source">
				<p:pipe step="subscription-form" port="result"/>
				<p:pipe step="harvest" port="result"/>
			</p:input>
		</p:identity>
	</p:declare-step>
	
	<p:declare-step type="oai:delete-transformation" name="delete-transformation">
		<!-- TODO -->
		<p:identity/>
	</p:declare-step>
	<p:declare-step type="oai:save-transformation" name="save-transformation">
		<!-- TODO -->
		<p:identity/>
	</p:declare-step>
	<p:declare-step type="oai:delete-subscription" name="delete-subscription">
		<p:input port="source"/>
		<!-- QAZ sequence=true required here apparently to match the sequence output from oai:save-subscription -->
		<!-- bug in Calabash? "As a convenience to authors, it is not an error if some subpipelines declare outputs that can produce sequences and some do not. Each output of the p:choose is declared to produce a sequence if that output is declared to produce a sequence in any of its subpipelines."-->
		<p:output port="result" sequence="true"/>
		<p:option name="subscription"/>
		<pxf:delete xmlns:pxf="http://exproc.org/proposed/steps/file" fail-on-error="false">
			<p:with-option name="href" select="$subscription"/>
		</pxf:delete>
		<z:make-http-response>
			<p:input port="source">
				<p:inline>
					<html xmlns="http://www.w3.org/1999/xhtml">
						<head>
							<title>Subscription Deleted</title>
						</head>
						<body>
							<h1>Subscription Deleted</h1>
							<p><a href="..">View subscriptions</a></p>
						</body>
					</html>
				</p:inline>
			</p:input>
		</z:make-http-response>
	</p:declare-step>

	<p:declare-step type="oai:do-harvest" name="do-harvest">
		<p:input port='source' primary='true'/>
		<p:output port="result" primary="true" sequence="true"/>
		<p:option name="subscription"/>
		<!-- TODO actually kick off a harvest if status="started"-->
		<p:for-each>
			<p:iteration-source select="/oai:subscription[oai:status='started']"/>
			<p:identity>
				<p:input port="source">
					<p:inline>
						<c:request method="GET" href="/xproc-z/"/>
					</p:inline>
					<!--
					<p:empty/>
					-->
				</p:input>
			</p:identity>
		</p:for-each>
	</p:declare-step>
	
	
	<p:declare-step type="oai:load-subscription" name="load-subscription">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="subscription"/>
		<p:try name="load-existing-data">
			<p:group>
				<p:load>
					<p:with-option name="href" select="$subscription"/>
				</p:load>
			</p:group>
			<p:catch name="no-existing-data">
				<p:identity name="new-blank-subscription">
					<p:input port="source">
						<p:inline exclude-inline-prefixes="#all">
							<subscription xmlns="tag:conaltuohy.com,2014:oai-harvest">
								<name>Untitled Subscription</name>
								<status>New</status>
								<set></set>
								<metadataPrefix>oai_dc</metadataPrefix>
							</subscription>
						</p:inline>
					</p:input>
				</p:identity>
			</p:catch>
		</p:try>
	</p:declare-step>
	
	<p:declare-step type="oai:render-subscription-form" name="render-subscription-form">
		<p:input port="source"/>
		<p:output port="result"/>
		<!-- display subscription in HTML form-->
		<!-- look up OAI-PMH server and request metadata -->
		<p:xslt>
			<p:input port="parameters">
				<p:empty/>
			</p:input>
			<p:input port="stylesheet">
				<p:inline exclude-inline-prefixes="z fn c oai">
					<xsl:stylesheet version="2.0" 
						xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
						xmlns:xs="http://www.w3.org/2001/XMLSchema" 
						xmlns:oai-pmh="http://www.openarchives.org/OAI/2.0/"
						xmlns="http://www.w3.org/1999/xhtml" 
						xpath-default-namespace="tag:conaltuohy.com,2014:oai-harvest"
						exclude-result-prefixes="xs">
						<xsl:template match="/subscription">
							<html>
								<head>
									<title><xsl:value-of select="name"/></title>
									<style type="text/css">
										body {
											font-family: sans-serif;
										}
										div.repository-metadata {
											background-color: #332D00;
											color: #FFFFFF;
											border-style: none;
											padding: 0.5em;
											margin: 0.5em;
										}
										div.repository-metadata a {
											color: #FFFFFF;
										}
										th {
											font-weight: bold;
											width: 10em;
										}
										th {
											text-align: right;
										}
										th, td {
											padding: 0.5em;
										}
									</style>
								</head>
								<body>
									<h1><xsl:value-of select="name"/></h1>
									<form method="POST" action="#">
										<p>
											<label for="name">Subscription Name</label>
											<input id="name" name="name" type="text" value="{name}"/>
										</p>
										<p>
											<label for="baseURL">Repository Base URL</label>
											<input id="baseURL" name="baseURL" type="text" value="{baseURL}"/>
										</p>
										<xsl:if test="oai-pmh:OAI-PMH/oai-pmh:ListSets/oai-pmh:set">
											<!-- the repository has a set hierarchy -->
											<p>
												<label for="set">Set</label>
												<select id="set" name="set">
													<xsl:variable name="selectedSetSpec" select="set"/>
													<xsl:call-template name="render-set">
														<xsl:with-param name="setName" select="'(all records)'"/>
														<xsl:with-param name="setSpec" select="''"/>
														<xsl:with-param name="selectedSetSpec" select="$selectedSetSpec"/>
													</xsl:call-template>
													<xsl:for-each select="oai-pmh:OAI-PMH/oai-pmh:ListSets/oai-pmh:set">
														<xsl:call-template name="render-set">
															<xsl:with-param name="setName" select="oai-pmh:setName"/>
															<xsl:with-param name="setSpec" select="oai-pmh:setSpec"/>
															<xsl:with-param name="selectedSetSpec" select="$selectedSetSpec"/>
														</xsl:call-template>
													</xsl:for-each>
												</select>
											</p>
										</xsl:if>
										<p>
											<label for="metadataPrefix">Metadata Format</label>
											<select id="metadataPrefix" name="metadataPrefix">
												<xsl:variable name="selectedMetadataPrefix" select="string(metadataPrefix)"/>
												<xsl:for-each select="oai-pmh:OAI-PMH/oai-pmh:ListMetadataFormats/oai-pmh:metadataFormat">
													<option value="{oai-pmh:metadataPrefix}">
														<xsl:if test="string(oai-pmh:metadataPrefix) = $selectedMetadataPrefix">
															<xsl:attribute name="selected">selected</xsl:attribute>
														</xsl:if>
														<xsl:value-of select="oai-pmh:metadataPrefix"/>
													</option>
												</xsl:for-each>
											</select>
										</p>
										<p>
											<span>Status</span>
											<span><xsl:value-of select="status"/></span>
										</p>
										<button type="submit">Save</button>
										<button type="submit" name="status" value="deleted">Delete</button>
										<button type="submit" name="status" value="started">Run</button>
										<button type="submit" name="status" value="stopped">Stop</button>
									</form>
									<xsl:apply-templates select="oai-pmh:OAI-PMH"/>
								</body>
							</html>
						</xsl:template>
						<xsl:template name="render-set">
							<xsl:param name="setName"/>
							<xsl:param name="setSpec"/>
							<xsl:param name="selectedSetSpec"/>
							<option value="{$setSpec}">
								<xsl:if test="string($setSpec) = string($selectedSetSpec)">
									<xsl:attribute name="selected">selected</xsl:attribute>
								</xsl:if>
								<xsl:value-of select="$setName"/>
							</option>
						</xsl:template>
						<!-- Render the cached OAI-PMH Repository Metadata Records -->
						<xsl:template match="oai-pmh:OAI-PMH">
							<xsl:apply-templates select="oai-pmh:Identify"/>
							<xsl:apply-templates select="oai-pmh:ListMetadataFormats"/>
							<xsl:apply-templates select="oai-pmh:ListSets"/>
						</xsl:template>
						<xsl:template match="oai-pmh:ListMetadataFormats"/>
						<xsl:template match="oai-pmh:ListSets"/>
						<xsl:template match="oai-pmh:Identify">
							<div class="repository-metadata">
								<h2>OAI-PMH Repository</h2>
								<table>
									<tr>
										<th>Repository Name</th>
										<td><xsl:value-of select="oai-pmh:repositoryName"/></td>
									</tr>
									<tr>
										<th>Administrator</th>
										<td><a href="mailto:{oai-pmh:adminEmail}"><xsl:value-of select="oai-pmh:adminEmail"/></a></td>
									</tr>
									<tr>
										<th>Earliest Record</th>
										<td><xsl:value-of select="oai-pmh:earliestDatestamp"/></td>
									</tr>
									<tr>
										<th>Deleted Record Retention</th>
										<td><xsl:value-of select="oai-pmh:deletedRecord"/></td>
									</tr>
									<tr>
										<th>Date and Time Granularity</th>
										<td><xsl:choose>
											<xsl:when test="oai-pmh:granularity = 'YYYY-MM-DDThh:mm:ssZ'">second</xsl:when>
											<xsl:otherwise>day</xsl:otherwise>
										</xsl:choose></td>
									</tr>
									<tr>
										<th>Data Compression</th>
										<td><xsl:value-of select="oai-pmh:compression"/></td>
									</tr>
								</table>
							</div>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
		<oai:http-respond/>
	</p:declare-step>
	
	<p:declare-step type="oai:render-transformation-form" name="render-transformation-form">
		<p:input port="source"/>
		<p:output port="result"/>
		<!-- display Transformation in HTML form-->
		<p:xslt>
			<p:input port="parameters">
				<p:empty/>
			</p:input>
			<p:input port="stylesheet">
				<p:inline exclude-inline-prefixes="z fn c oai">
					<xsl:stylesheet version="2.0" 
						xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
						xmlns:xs="http://www.w3.org/2001/XMLSchema" 
						xmlns:oai-pmh="http://www.openarchives.org/OAI/2.0/"
						xmlns="http://www.w3.org/1999/xhtml" 
						xpath-default-namespace="tag:conaltuohy.com,2014:oai-harvest"
						exclude-result-prefixes="xs">
						<xsl:variable name="stylesheet" select="/*/stylesheet"/>
						<xsl:variable name="title" select="(/*/stylesheet/@title, 'Untitled Stylesheet')[1]"/>
						<xsl:template match="/">
							<html>
								<head>
									<title><xsl:value-of select="$title"/></title>
									<style type="text/css">
										body {
											font-family: sans-serif;
										}
									</style>
								</head>
								<body>
									<h1><xsl:value-of select="$title"/></h1>
									<form method="POST" action="#">
									</form>
								</body>
							</html>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
		<oai:http-respond/>
	</p:declare-step>
	
	<p:declare-step type="oai:list-transformations" name="list-transformations">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="directory" required="true"/>
		<p:directory-list include-filter="[^\.]*\.xsl">
			<p:with-option name="path" select="$directory"/>
		</p:directory-list>
		<p:viewport name="transformations" match="//c:file">
			<p:load name="transformation">
				<p:with-option name="href" select="resolve-uri(/c:file/@name, base-uri(/c:file))"/>
			</p:load>
			<p:filter name="documentation" select="/*/oai:stylesheet"/>
			<p:insert position="first-child">
				<p:input port="source">
					<p:pipe step="transformations" port="current"/>
				</p:input>
				<p:input port="insertion">
					<p:pipe step="documentation" port="result"/>
				</p:input>
			</p:insert>
		</p:viewport>
		<oai:http-respond/>
	</p:declare-step>	
	
	<p:declare-step type="oai:list-subscriptions" name="list-subscriptions">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="directory" required="true"/>
		<p:directory-list include-filter="[^\.]*\.xml">
			<p:with-option name="path" select="$directory"/>
		</p:directory-list>
		<p:viewport name="subscriptions" match="//c:file">
			<p:load name="subscription">
				<p:with-option name="href" select="resolve-uri(/c:file/@name, base-uri(/c:file))"/>
			</p:load>
			<p:insert position="first-child">
				<p:input port="source">
					<p:pipe step="subscriptions" port="current"/>
				</p:input>
				<p:input port="insertion">
					<p:pipe step="subscription" port="result"/>
				</p:input>
			</p:insert>
		</p:viewport>
		<oai:http-respond/>
	</p:declare-step>
	
</p:library>
