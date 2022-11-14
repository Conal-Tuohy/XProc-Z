<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" xmlns:ex="https://github.com/Conal-Tuohy/XProc-Z/tree/master/xproc/examples" 
xmlns:corbicula="tag:conaltuohy.com,2015:corbicula"
xmlns:mv="tag:conaltuohy.com,2015:museum-victoria" version="1.0" name="main">


	<p:input port='source' primary='true'/>
	<!-- e.g.
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
	-->
	
	<p:input port='parameters' kind='parameter' primary='true'/>
	<p:output port="result" primary="true" sequence="true"/>
	<p:import href="xproc-z-library.xpl"/>	
	<p:import href="museum-victoria/museum-victoria.xpl"/>
	<p:import href="visualize-distribution.xpl"/>
	<p:import href="examples/echo.xpl"/>
	<p:import href="examples/menu.xpl"/>
	<p:import href="examples/file.xpl"/>
	<p:import href="examples/feed-reader.xpl"/>
	<p:import href="examples/xproc-system-properties.xpl"/>
	<p:import href="visualize-collation/visualize-collation.xpl"/>
	<p:import href="test.xpl"/>
	<p:import href="oai-pmh/harvest.xpl"/>
	<!--
	under development
	-->
	
	<p:variable name="relative-uri" select="substring-after(/c:request/@href, '/xproc-z/')"/>
	
<!--
			<z:route uri-template="{protocol}://{hostname}/xproc-z/route-test/{value}" name="route-test"/>
			-->

	<p:choose>
		<p:when test=" starts-with($relative-uri, 'route-test') ">
			<z:route name="route-a" uri-template="{scheme}://{origin}/{path}route-test/A/{A-value}/?{query}"/>
			<z:route name="route-b" uri-template="{scheme}://{origin}/{path}route-test/B/{B-value}/?{query}"/>
			<z:route name="route-c" uri-template="{scheme}://{origin}/{path}route-test/C/{C-value}/?{query}"/>
			<p:identity name="no-routes-matched"/>
			
			<p:for-each name="pipeline-not-found">
				<p:output port="result"/>
				<p:iteration-source>
					<p:pipe step="no-routes-matched" port="result"/>
				</p:iteration-source>
				<z:not-found/>
			</p:for-each>
			
			<p:for-each name="pipeline-a">
				<p:output port="result"/>
				<p:iteration-source>
					<p:pipe step="route-a" port="matched"/>
				</p:iteration-source>
				<z:make-http-response>
					<p:input port="source">
						<p:pipe step="route-a" port="variables"/>
					</p:input>
				</z:make-http-response>
			</p:for-each>
			
			<p:for-each name="pipeline-b">
				<p:output port="result"/>
				<p:iteration-source>
					<p:pipe step="route-b" port="matched"/>
				</p:iteration-source>
				<z:make-http-response>
					<p:input port="source">
						<p:pipe step="route-b" port="variables"/>
					</p:input>
				</z:make-http-response>
			</p:for-each>
			
			<p:for-each name="pipeline-c">
				<p:output port="result"/>
				<p:iteration-source>
					<p:pipe step="route-c" port="matched"/>
				</p:iteration-source>
				<z:make-http-response>
					<p:input port="source">
						<p:pipe step="route-c" port="variables"/>
					</p:input>
				</z:make-http-response>
			</p:for-each>
			
			<p:identity name="gather-pipeline-responses">
				<p:input port="source">
					<p:pipe step="pipeline-not-found" port="result"/>
					<p:pipe step="pipeline-a" port="result"/>
					<p:pipe step="pipeline-b" port="result"/>
					<p:pipe step="pipeline-c" port="result"/>
				</p:input>
			</p:identity>
		</p:when>
		<p:when test=" $relative-uri = '' ">
			<ex:menu/>
		</p:when>
		<!-- testing the use of pipeline bifurcation steps as boolean control constructs
		<p:when test="starts-with($relative-uri, 'choice')">
			<z:choice-test/>
		</p:when>-->
		<p:when test="starts-with($relative-uri, 'oai-harvest/')">
			<corbicula:handle-harvest-request>
				<p:with-option name="relative-uri" select="substring-after($relative-uri, 'oai-harvest/')"/>
			</corbicula:handle-harvest-request>
		</p:when>
		<p:when test="starts-with($relative-uri, 'museum-victoria/')">
			<mv:museum-victoria>
				<p:with-option name="relative-uri" select="substring-after($relative-uri, 'museum-victoria/')"/>
			</mv:museum-victoria>
		</p:when>
		<p:when test="starts-with($relative-uri, 'static/')">
			<z:static/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'echo/')">
			<ex:echo/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'system-properties/')">
			<ex:system-properties/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'tei-viz/')">
			<v:visualize-distribution xmlns:v="https://github.com/leoba/distributionVis"/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'visualize-collation/')">
			<vc:visualize-collation xmlns:vc="https://github.com/leoba/VisColl"/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'upload-download/')">
			<ex:file-upload-and-download>
				<p:with-option name="relative-uri" select="substring-after($relative-uri, 'upload-download/')"/>
			</ex:file-upload-and-download>
		</p:when>
		<p:when test="starts-with($relative-uri, 'trampoline-test/')">
			<z:trampoline-test/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'xslt-safety-test/')">
			<z:xslt-safety-test/>
		</p:when>
		<!--
		<p:when test="starts-with($relative-uri, 'form-test/')">
			<z:form-test/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'data/')">
			<ex:data>
				<p:with-option name="relative-uri" select="substring-after($relative-uri, 'data/')"/>
			</ex:data>
		</p:when>-->
		<p:when test="starts-with($relative-uri, 'request/')">
			<z:parse-request-uri unproxify="true"/>
			<z:make-http-response/>
		</p:when>
		<p:otherwise>
			<z:not-found/>
		</p:otherwise>
	</p:choose>

</p:declare-step>
