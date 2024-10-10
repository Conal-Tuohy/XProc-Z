<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step"  version="1.0" name="main">

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
	
	<p:variable name="path" select="replace(/c:request/@href, 'https?://[^/]+/(.*)', '$1')"/>
	<p:choose>
		<p:when test="$path = ''">
			<p:identity>
				<p:input port="source">
					<p:inline>
						<c:response status="200">
							<c:body content-type="application/xhtml+xml">
								<html xmlns="http://www.w3.org/1999/xhtml">
									<head>
										<title>Welcome to Dockerized XProc-Z</title>
									</head>
									<body>
										<h1>Welcome to Dockerized XProc-Z</h1>
										<p>If you see this page, you have successfully run the XProc-Z Docker image.</p>
										
									</body>
								</html>
							</c:body>
						</c:response>
					</p:inline>
				</p:input>
			</p:identity>
		</p:when>
		<p:otherwise>
			<p:identity>
				<p:input port="source">
					<p:inline>
						<c:response status="404">
							<c:body content-type="text/plain">404 not found</c:body>
						</c:response>
					</p:inline>
				</p:input>
			</p:identity>
		</p:otherwise>
	</p:choose>

</p:declare-step>
