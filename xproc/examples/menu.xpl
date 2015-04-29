<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:ex="https://github.com/Conal-Tuohy/XProc-Z/tree/master/xproc/examples" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions">
	
	<p:import href="../xproc-z-library.xpl"/>
	
	<p:pipeline type="ex:menu" name="menu">
		<p:option name="relative-uri" select="''"/>

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
										<li>
											<a href="echo/?example-parameter=example-value">HTTP request parser demo</a>
										</li>
										<!-- under development -->
										<!--
										<li>
											<a href="oai-harvest/">OAI-PMH Harvester</a>
										</li>
										<li>
											<a href="file/">Upload a file and receive the same file in response.</a>
										</li>
										<li>
											<a href="data/">Upload and download files</a>
										</li>
										-->
									</ul>
								</body>
							</html>
						</c:body>
					</c:response>
				</p:inline>
			</p:input>
		</p:identity>
	</p:pipeline>
		
</p:library>
