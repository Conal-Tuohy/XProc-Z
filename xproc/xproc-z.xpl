<p:pipeline xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" version="1.0" name="main">

	<!--
	<p:identity/>
	-->	
	<p:variable name="ip-address" select=" string(/c:request/c:header[@name='user-agent']/@value) "/>
	<p:in-scope-names name="variables"/>
	<p:template>
		<p:input port="template">
			<p:inline>
				<c:response status="200">
					<c:header name="X-Powered-By" value="XProc using XML Calabash"/>
					<c:header name="Server" value="XProc-Z"/>
					<c:body content-type="application/xml">
						<html>
							<!-- xmlns="http://www.w3.org/1999/xhtml"> -->
							<head>
								<title>Hello World!</title>
							</head>
							<body>
								<h1>Hello World!</h1>
								<p>Your user agent is "{ string(/c:request/c:header[@name='user-agent']/@value) }".</p>
								<p>Your request URI was "{ string(/c:request/@href) }".</p>
								<p>Current time is {current-dateTime()}</p>
								<p>Content type submitted: "{ string(/c:request/c:body/@content-type) }".</p>
								<p>Submitted content string value was: "{ string(/c:request/c:body) }".</p>
								<p>Multipart content string value was: "{ string(/c:request/c:multipart) }".</p>
								<form target="" method="post" enctype="multipart/form-data">
									<div>
										<textarea name="text"></textarea>
										<textarea name="text2"></textarea>
										<button type="submit">Submit</button>
									</div>
								</form>
								{/*}
							</body>
						</html>
					</c:body>
				</c:response>
			</p:inline>
		</p:input>
		<p:input port="source">
			<p:pipe step="main" port="source"/>
		</p:input>
		<p:input port="parameters">
			<p:pipe step="variables" port="result"/>
		</p:input>
	</p:template>
</p:pipeline>
