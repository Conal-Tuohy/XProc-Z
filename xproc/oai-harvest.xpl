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
	<p:pipeline type="oai:harvester" name="main">
		<p:option name="relative-uri" required="true"/>
		<p:option name="directory" required="true"/>
		<p:choose>
			<p:when test="$relative-uri = 'subscription/'">
				<!-- the collection of subscriptions -->
				<p:choose>
					<p:when test="/c:request/@method='GET'">
						<oai:list-subscriptions>
							<p:with-option name="directory" select="$directory"/>
						</oai:list-subscriptions>
					</p:when>
					<p:when test="/c:request/@method='POST'">
						<!-- add a new subscription -->
						<oai:add-subscription>
							<p:with-option name="directory" select="$directory"/>
						</oai:add-subscription>
					</p:when>
					<p:otherwise>
						<oai:method-not-allowed/>
					</p:otherwise>
				</p:choose>
			</p:when>
			<p:when test="starts-with($relative-uri, 'subscription/')">
				<!-- an existing subscription -->
				<p:variable name="file-name" select="substring-after($relative-uri, 'subscription/')"/><!-- QAZ sanitize -->
				<p:choose>
					<p:when test="/c:request/@method='GET'">
						<!-- view an existing subscription -->
						<oai:show-subscription>
							<p:with-option name="directory" select="$directory"/>
							<p:with-option name="file-name" select="$file-name"/>
						</oai:show-subscription>
					</p:when>
					<p:when test="/c:request/@method='POST'">
						<!-- update an existing subscription -->
						<oai:update-subscription>
							<p:with-option name="directory" select="$directory"/>
							<p:with-option name="file-name" select="$file-name"/>
						</oai:update-subscription>
					</p:when>
					<!-- QAZ allow DELETE and PUT -->
					<p:otherwise>
						<oai:method-not-allowed/>
					</p:otherwise>
				</p:choose>
			</p:when>
			<p:when test="$relative-uri = ''">
				<oai:home-page/>
			</p:when>
			<p:otherwise>
				<oai:error status="400" title="Bad Request URI" message="The URI is not recognised"/>
			</p:otherwise>
		</p:choose>
	</p:pipeline>
	
	<p:pipeline type="oai:method-not-allowed" name="method-not-allowed">
		<p:identity/>
		<oai:http-respond/>
		<!--
		<oai:error status="405" title="Method Not Allowed" message="The request method is not allowed"/>
		-->
	</p:pipeline>
	
	<p:pipeline type="oai:add-subscription" name="add-subscription">
		<!-- the directory in which the new subscription file will be saved -->
		<p:option name="directory" required="true"/>
		<!-- parse the posted data --><!-- TODO change to use p:www-form-urldecode -->
		<z:parse-parameters name="post"/>
		<!-- convert the HTTP POST data into the subscription format -->
		<p:template name="convert-to-subscription">
			<p:input port="template">
				<p:inline>
					<subscription>
						<name>Untitled</name>
						<metadata-prefix>oai_dc</metadata-prefix>
						<base-url>{/c:multipart/c:part[@name='base-url']}</base-url>
					</subscription>
				</p:inline>
			</p:input>
			<!--
			<p:input port="parameters">
				<p:pipe step="variables" port="result"/>
			</p:input>
			-->
		</p:template>
		<!-- generate a name for the new file -->
		<p:directory-list include-filter=".*\.xml$">
			<p:with-option name="path" select="$directory"/>
		</p:directory-list>
		<!-- insert the "sentinel" file name '0.xml' so that if there are no actual files, then the new file will be called '1.xml' -->
		<p:insert position="first-child">
			<p:input port="insertion">
				<p:inline>
					<c:file name="0.xml"/>
				</p:inline>
			</p:input>
		</p:insert>
		<p:group>
			<!-- find the highest numbered file so far and increment its name by 1 -->
			<p:variable name="last-file-name" select="
				/c:directory/c:file[
					not(
						(preceding-sibling::c:file/@name &gt; @name) or 
						(following-sibling::c:file/@name &gt; @name)
					)
				]/@name
			"/>
			<p:variable name="new-file-name" select="
				concat(
					string(
						number(
							substring-before($last-file-name, '.xml')
						) + 1
					),
					'.xml'
				)
			"/>
			<!-- save it -->
			<p:store>
				<p:with-option name="href" select="concat($directory, '/', $new-file-name)"/>
				<p:input port="source">
					<p:pipe step="convert-to-subscription" port="result"/>
				</p:input>
			</p:store>
			<!-- TODO generate and return a form representing the newly created resource -->
			<p:in-scope-names name="variables"/>
			<p:template name="new-subscription-form">
				<p:input port="template">
					<p:inline>
						<c:response status="201">
							<c:header name="X-Powered-By" value="XProc using XML Calabash"/>
							<c:header name="Server" value="XProc-Z"/>
							<c:header name="Location" value="{$new-file-name}"/>
							<c:body content-type="application/xml">
								<html xmlns="http://www.w3.org/1999/xhtml">
									<head>
										<title>New Subscription — OAI-PMH Harvester</title>
									</head>
									<body>
										<h1>New Subscription — OAI-PMH Harvester</h1>
										<p><a href="{$new-file-name}">{$new-file-name}</a></p>
									</body>
								</html>
							</c:body>
						</c:response>
					</p:inline>		
				</p:input>
				<p:input port="source">
					<p:empty/>
				</p:input>
				<p:input port="parameters">
					<p:pipe step="variables" port="result"/>
				</p:input>
			</p:template>
		</p:group>
	</p:pipeline>
	
	<p:pipeline type="oai:home-page" name="home-page">
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
	</p:pipeline>
	
	<!-- output a response -->
	<p:pipeline type="oai:http-respond" name="http-respond">
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
	</p:pipeline>
	
	<!-- output an HTML page containing an error message -->
	<p:pipeline type="oai:error" name="error">
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
	</p:pipeline>
	
	

	<p:pipeline type="oai:show-subscription" name="show-subscription">
		<p:option name="directory"/>
		<p:option name="file-name"/>
		<!-- TODO -->
		<oai:http-respond/>
	</p:pipeline>
	
	<p:pipeline type="oai:update-subscription" name="update-subscription">
		<p:option name="directory"/>
		<p:option name="file-name"/>
		<!-- TODO -->
		<oai:http-respond/>
	</p:pipeline>
	
	<p:pipeline type="oai:list-subscriptions" name="list-subscriptions">
		<p:option name="directory"/>
		<p:directory-list include-filter=".*\.xml^">
			<p:with-option name="path" select="$directory"/>
		</p:directory-list>
		<p:viewport name="subscriptions" match="//c:file">
			<p:variable name="filename" select="/c:file/@name"/>
			<p:load name="subscription">
				<p:with-option name="href" select="concat($path, '/', $filename)"/>
			</p:load>
			<p:add-attribute match="oai:subscription" attribute-name="href">
				<p:with-option name="attribute-value" select="$filename"/>
			</p:add-attribute>
		</p:viewport>
		<oai:http-respond/>
	</p:pipeline>
	
</p:library>
