<p:pipeline xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" version="1.0" name="main">
	
	<p:import href="xproc-z-library.xpl"/>
	<!--
	<p:import href="test.xpl"/>
	<z:form-test/>
	-->
	<p:import href="visualize-distribution.xpl"/>
	
	<p:variable name="relative-uri" select="substring-after(/c:request/@href, '/xproc-z/')"/>
	
	<p:choose>
		<p:when test="starts-with($relative-uri, 'test/')">
			<z:parse-request-uri name="request-uri"/>
			<z:parse-parameters name="request-parameters">
				<p:input port="source">
					<p:pipe step="main" port="source"/>
				</p:input>
			</z:parse-parameters>
			<p:wrap-sequence wrapper="parsed-http-request">
				<p:input port="source">
					<p:pipe step="request-uri" port="result"/>
					<p:pipe step="request-parameters" port="result"/>
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
		</p:when>
		<p:when test="starts-with($relative-uri, 'tei-viz/')">
			<v:visualize-distribution xmlns:v="https://github.com/leoba/distributionVis"/>
		</p:when>
		<p:otherwise>
			<p:identity>
				<p:input port="source">
					<p:inline>
						<c:response status="200">
							<c:header name="X-Powered-By" value="XProc using XML Calabash"/>
							<c:header name="Server" value="XProc-Z"/>
							<c:body content-type="application/xml">
								<html xmlns="http://www.w3.org/1999/xhtml">
									<head>
										<title>XProc-Z Samples</title>
									</head>
									<body>
										<h1>XProc-Z Samples</h1>
										<ul>
											<li>
												<a href="tei-viz/">Visualization of distribution of illustrations in TEI-encoded manuscripts</a>
											</li>
										</ul>
									</body>
								</html>
							</c:body>
						</c:response>
					</p:inline>
				</p:input>
			</p:identity>
		</p:otherwise>
	</p:choose>

</p:pipeline>
