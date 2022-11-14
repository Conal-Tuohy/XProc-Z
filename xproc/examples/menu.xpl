<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:ex="https://github.com/Conal-Tuohy/XProc-Z/tree/master/xproc/examples" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:feed="tag:conaltuohy.com,2015:feed-reader" 
	xmlns:html="http://www.w3.org/1999/xhtml">
	
	<p:import href="../xproc-z-library.xpl"/>
	<p:import href="feed-reader.xpl"/>
	
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
									<link rel="stylesheet" type="text/css" href="http://fonts.googleapis.com/css?family=Open+Sans"/>
									<link rel="stylesheet" type="text/css" href="static/sample.css"/>
									<link rel="icon" type="image/png" href="static/xproc-z-logo.png"/>
								</head>
								<body>
									<h1>XProc-Z Samples</h1>
									<!-- reference to the "XProc-Z" RSS feed from the conaltuohy.com blog will be transcluded -->
									<!--
									<div class="sidebar">
										<a href="http://conaltuohy.com/blog/tag/xproc-z/feed/" type="application/rss+xml"/>
									</div>
									-->
									<div class="main">
										<div class="sample">
											<h2><a href="tei-viz/">Visualization of the distribution of illustrations in TEI-encoded manuscripts ▶</a></h2>
											<p>This sample displays a list of TEI XML files representing medieval manuscripts from <a href="http://www.thedigitalwalters.org/">The Digital Walters</a>. The user can select which manuscripts they want to visualize. The sample app then retrieves the selected files from the Digital Walters, and transforms each one into a visualization of the placement of images in that manuscript.</p>
										</div>
										<div class="sample">
											<h2><a href="echo/?example-parameter=example-value">HTTP request parser demo ▶</a></h2>
											<p>This sample demonstrates how to parse a request. It shows the environment variables, the request URI, the URI parameters, and any posted form parameters, including file uploads.</p>
										</div>
										<div class="sample">
											<h2><a href="upload-download/">Upload a file and receive the same file in response ▶</a></h2>
											<p>This sample provides a form for uploading a file. On receipt of a file upload, the sample app returns the very same file. The sample demonstrates how to deal with XML, plain text (including e.g. JSON and CSV), and binary files.</p>
										</div>
										<div class="sample">
											<h2><a href="system-properties/">System Properties</a></h2>
											<p>This example shows how to use the 
											<a href="https://www.w3.org/TR/xproc/#f.system-property"><code>system-property</code></a> function
											to access information about the environment in which the XProc pipeline is running.</p>
										</div>
									</div>
								</body>
							</html>
						</c:body>
					</c:response>
				</p:inline>
			</p:input>
		</p:identity>
		
		<!-- transclude blog feed -->
		<feed:transclude/>
	</p:pipeline>
		
</p:library>
