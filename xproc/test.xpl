<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions">
	
	<p:import href="xproc-z-library.xpl"/>
		
	<p:pipeline type="z:form-test" name="form-test">
	<p:variable name="current-time" select="current-dateTime() "/>
	<p:in-scope-names name="variables"/>
	<z:parse-parameters name="query-parameters">
		<p:input port="source">
			<p:pipe step="form-test" port="source"/>
		</p:input>
	</z:parse-parameters>
	<p:insert position="first-child" name="insert-parsed-parameters">
		<p:input port="source">
			<p:pipe step="form-test" port="source"/>
		</p:input>
		<p:input port="insertion">
			<p:pipe step="query-parameters" port="result"/>
		</p:input>
	</p:insert>
	<p:template>
		<p:input port="template">
			<p:inline>
				<c:response status="200">
					<c:header name="X-Powered-By" value="XProc using XML Calabash"/>
					<c:header name="Server" value="XProc-Z"/>
					<c:body content-type="application/xml">
						<html xmlns="http://www.w3.org/1999/xhtml">
							<head>
								<title>Hello World!</title>
							</head>
							<body>
								<h1>Hello World!</h1>
								<p>Your user agent is "{ string(/c:request/c:header[@name='user-agent']/@value) }".</p>
								<p>Your request URI was "{ string(/c:request/@href) }".</p>
								<p>Current time is {$current-time}</p>
								<p>Content type submitted: "{ string(/c:request/c:body/@content-type) }".</p>
								<p>Submitted content string value was: "{ string(/c:request/c:body) }".</p>
								<p>Multipart content string value was: "{ string(/c:request/c:multipart) }".</p>
								<form action="?" method="post" enctype="application/x-www-form-urlencoded">
								<!--
								<form action="" method="post" enctype="multipart/form-data">
								-->
									<div>
										<textarea name="text1">{string(/c:request/c:multipart/c:part[@name='text2'])}</textarea>
										<textarea name="text2">{string(/c:request/c:multipart/c:part[@name='text1'])}</textarea>
										<button type="submit">Swap values</button>
									</div>
								</form>
							</body>
						</html>
					</c:body>
				</c:response>
			</p:inline>
		</p:input>
		<p:input port="source">
			<p:pipe step="insert-parsed-parameters" port="result"/>
		</p:input>
		<p:input port="parameters">
			<p:pipe step="variables" port="result"/>
		</p:input>
	</p:template>
	</p:pipeline>
</p:library>
