<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:ex="https://github.com/Conal-Tuohy/XProc-Z/tree/master/xproc/examples" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z"
	xmlns:fn="http://www.w3.org/2005/xpath-functions">
	
	<p:import href="../xproc-z-library.xpl"/>
	
	<p:declare-step type="ex:echo" name="main">
		<p:input port='source' primary='true'/>
		<p:input port='parameters' kind='parameter' primary='true'/>
		<p:output port="result" primary="true" sequence="true"/>
		<p:option name="relative-uri" select="''"/>

			<z:parse-request-uri name="request-uri"/>
			<z:parse-parameters name="request-parameters">
				<p:input port="source">
					<p:pipe step="main" port="source"/>
				</p:input>
			</z:parse-parameters>
			<p:parameters name="environment-parameters">
				<p:input port="parameters">
					<p:pipe step="main" port="parameters"/>
				</p:input>
			</p:parameters>
			<p:wrap-sequence wrapper="parsed-http-request">
				<p:input port="source">
					<p:pipe step="request-uri" port="result"/>
					<p:pipe step="request-parameters" port="result"/>
					<p:pipe step="environment-parameters" port="result"/>
				</p:input>
			</p:wrap-sequence>
			<p:template>
				<p:input port="template">
					<p:inline>
						<c:response status="200">
							<c:header name="X-Powered-By" value="XProc using XML Calabash"/>
							<c:header name="Server" value="XProc-Z"/>
							<c:body content-type="application/xml">{/*}</c:body>
						</c:response>
					</p:inline>
				</p:input>
			</p:template>
	</p:declare-step>
		
</p:library>
