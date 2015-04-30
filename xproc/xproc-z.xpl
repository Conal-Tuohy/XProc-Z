<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" xmlns:ex="https://github.com/Conal-Tuohy/XProc-Z/tree/master/xproc/examples" version="1.0" name="main">


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
	<p:import href="visualize-distribution.xpl"/>
	<p:import href="examples/echo.xpl"/>
	<p:import href="examples/menu.xpl"/>
	<p:import href="examples/file.xpl"/>
	<!--
	under development
	<p:import href="test.xpl"/>
	<p:import href="oai-harvest.xpl"/>
	-->
	
	<p:variable name="relative-uri" select="substring-after(/c:request/@href, '/xproc-z/')"/>
	

	<p:choose>
		<p:when test=" $relative-uri = '' ">
			<ex:menu/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'echo/')">
			<ex:echo/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'tei-viz/')">
			<v:visualize-distribution xmlns:v="https://github.com/leoba/distributionVis"/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'upload-download/')">
			<ex:file-upload-and-download>
				<p:with-option name="relative-uri" select="substring-after($relative-uri, 'file/')"/>
			</ex:file-upload-and-download>
		</p:when>
		<!--
		<p:when test="starts-with($relative-uri, 'form-test/')">
			<z:form-test/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'data/')">
			<ex:data>
				<p:with-option name="relative-uri" select="substring-after($relative-uri, 'data/')"/>
			</ex:data>
		</p:when>
		<p:when test="starts-with($relative-uri, 'oai-harvest/')">
			<oai:harvester xmlns:oai="tag:conaltuohy.com,2014:oai-harvest">
				<p:with-option name="relative-uri" select="substring-after($relative-uri, 'oai-harvest/')"/>
				<p:with-option name="directory" select=" '/var/lib/xproc-z/oai-harvester/subscriptions' "/>
			</oai:harvester>
		</p:when>-->
		<p:otherwise>
			<z:not-found/>
		</p:otherwise>
	</p:choose>

</p:declare-step>
