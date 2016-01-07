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
	<p:import href="visualize-collation/visualize-collation.xpl"/>
	<p:import href="test.xpl"/>
	<p:import href="when-test.xpl"/>
	<p:import href="oai-pmh/harvest.xpl"/>
	<!--
	under development
	-->
	
	<p:variable name="relative-uri" select="substring-after(/c:request/@href, '/xproc-z/')"/>
	

	<p:choose>
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
