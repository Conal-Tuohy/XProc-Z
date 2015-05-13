<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:ex="https://github.com/Conal-Tuohy/XProc-Z/tree/master/xproc/examples" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" >
	
	<p:import href="../xproc-z-library.xpl"/>
	
	
	<p:declare-step type="ex:data" name="data">
		<p:input port='source' primary='true'/>
		<p:input port='parameters' kind='parameter' primary='true'/>
		<p:output port="result" primary="true" sequence="true"/>	
		<p:option name="relative-uri" select="''"/>
		<p:variable name="data-directory" select=" '.' "/>
		<p:choose>
			<p:when test="$relative-uri = '' ">
				<!-- list all files -->
				<p:directory-list>
					<p:with-option name="path" select="."/>
				</p:directory-list>
			</p:when>
			<p:otherwise>
				<!-- particular file -->
				<p:choose>
					<p:when test=" /c:request/@method='PUT' ">
						<!-- saving a file -->
						<p:store>
							<p:with-option name="href" select="$relative-uri"/>
						</p:store>
						<p:identity>
							<p:input port="source">
								<p:inline>
										<html xmlns="http://www.w3.org/1999/xhtml">
											<head>
												<title>File Uploaded</title>
											</head>
											<body>
												<h1>File Uploaded</h1>
											</body>
										</html>
								</p:inline>
							</p:input>
						</p:identity>
						<z:make-http-response/>
					</p:when>
					<p:otherwise>
						<p:try>
							<p:group>
								<p:load>
									<p:with-option name="href" select="$relative-uri"/>
								</p:load>
								<z:make-http-response/>
							</p:group>
							<p:catch>
								<z:not-found/>
							</p:catch>
						</p:try>
					</p:otherwise>
				</p:choose>
			</p:otherwise>
		</p:choose>
	</p:declare-step>
	
	<p:declare-step type="ex:file-upload-and-download" name="file-upload-and-download">
		<p:input port='source' primary='true'/>
		<p:input port='parameters' kind='parameter' primary='true'/>
		<p:output port="result" primary="true" sequence="true"/>
		<p:option name="relative-uri" select=" '' "/>
		<p:choose>
			<p:when test="not(/c:request/c:multipart)"><!--
$relative-uri = '' ">-->
				<p:identity>
					<p:input port="source">
						<p:inline>
							<c:response status="200">
								<c:body content-type="application/xml">
									<html xmlns="http://www.w3.org/1999/xhtml">
										<head>
											<title>File Upload and Download</title>
										</head>
										<body>
											<h1>File Upload and Download</h1>
											<p>This is a test of uploading and downloading files.</p>
											<p>This pipeline accepts an uploaded file and in response it returns the same file.</p>
											<form action="request" method="post" enctype="multipart/form-data">
												<div>
													<input type="file" name="file-upload" value="File"/>
													<button type="submit">Upload and download the file</button>
												</div>
											</form>
										</body>
									</html>
								</c:body>
							</c:response>
						</p:inline>
					</p:input>
				</p:identity>
			</p:when>
			<p:otherwise><!-- upload and download file -->
				<p:xslt>
					<p:input port="stylesheet">
						<p:inline>
							<c:response status="200" xsl:version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
								<xsl:variable name="upload" select="/c:request/c:multipart/c:body[1]"/>
								<c:header name="Server" value="XProc-Z"/>
								<c:body>
									<xsl:copy-of select="$upload/@*"/>
									<xsl:if test="$upload/@disposition">
										<xsl:attribute name="disposition">
											<xsl:value-of select="concat('attachment; filename=', substring-after($upload/@disposition, 'filename='))"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:copy-of select="$upload/node()"/>
								</c:body>
							</c:response>
						</p:inline>
					</p:input>
				</p:xslt>
				<!--
				<z:make-http-response/>
				-->
			</p:otherwise>
		</p:choose>
	</p:declare-step>
		
</p:library>
