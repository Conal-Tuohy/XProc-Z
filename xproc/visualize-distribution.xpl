<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:v="https://github.com/leoba/distributionVis" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions">
	
	<!-- Visualize a selection of TEI-encoded manuscript descriptions -->
	<p:pipeline type="v:visualize-distribution" name="main">
		<!-- Input to the pipeline is a c:request element: http://www.w3.org/TR/xproc/#cv.request -->
		<!-- Output is a c:response element in response: http://www.w3.org/TR/xproc/#c.response -->
		
		<!-- Dot's XSLT: https://raw.githubusercontent.com/leoba/distributionVis/master/distributionVis.xsl -->
		<!-- Page listing the manuscripts: http://www.thedigitalwalters.org/Data/WaltersManuscripts/ManuscriptDescriptions/ -->
		
		<p:variable name="parameter-string" select="substring-after(/c:request/@href, '?')"/>
		
		<p:choose>
			<p:when test="contains($parameter-string, 'file=')">
			
				<!-- decode the request parameters into a c:param-set document http://www.w3.org/TR/xproc/#cv.param-set -->
				<p:www-form-urldecode>
					<p:with-option name="value" select="$parameter-string"/>
				</p:www-form-urldecode>
				
				<!-- interpret parameters as a list of xml file names -->
				<!-- go through each of the c:param elements and replace each one with an html visualisation of the file with that name -->
				<p:viewport name="file-set" match="/c:param-set/c:param[@name='file']">
					
					<!-- load the file indicated by the current c:param -->
					<p:load>
						<p:with-option name="href" select="concat(
							'http://www.thedigitalwalters.org/Data/WaltersManuscripts/ManuscriptDescriptions/', 
							/c:param/@value
						)"/>
					</p:load>
					
					<!-- transform the TEI document into the HTML visualisation -->
					<p:xslt>
						<p:input port="stylesheet">
							<p:document href="https://raw.githubusercontent.com/leoba/distributionVis/master/distributionVis.xsl"/>
						</p:input>
						<p:input port="parameters">
							<p:empty/>
						</p:input>
					</p:xslt>
					
				</p:viewport>
				
				<!-- Transform the c:param-set (now containing not param elements but HTML documents, 
				each a visualisation of a single TEI text) into a single HTML document -->
				<p:xslt>
					<p:input port="parameters">
						<p:empty/>
					</p:input>
					<p:input port="stylesheet">
						<p:inline>
							<xsl:stylesheet version="1.0" 
								xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
								xmlns:html="http://www.w3.org/1999/xhtml"
								exclude-result-prefixes="html">
								<xsl:template match="/">
									<html xmlns="http://www.w3.org/1999/xhtml">
										<head>
											 <title>Visualize Distribution of Illustrations in Walters Manuscripts</title>
										</head>
										<body>
											<xsl:for-each select="//html:body">
												<div style="position: relative; height: 60px; width: 100%">
													<xsl:copy-of select="html:div"/>
												</div>
											</xsl:for-each>
										</body>
									</html>
								</xsl:template>
							</xsl:stylesheet>
						</p:inline>
					</p:input>
				</p:xslt>
			</p:when>
			<p:otherwise>
				<!-- no parameters specified, so provide the user with a list of documents from which they can make a selection -->
				
				<!-- request the HTML page containing the list of documents from server -->
				<p:http-request>
					<p:input port="source">
						<p:inline>
							<c:request 
								method="get"
								href="http://www.thedigitalwalters.org/Data/WaltersManuscripts/ManuscriptDescriptions/"/>
						</p:inline>
					</p:input>
				</p:http-request>
				
				<!-- convert the HTML to XML -->
				<p:unescape-markup content-type="text/html"/>
				
				<!-- transform the XHTML to convert the list of links to files into a selectable list -->
				<p:xslt>
					<p:input port="parameters">
						<p:empty/>
					</p:input>
					<p:input port="stylesheet">
						<p:inline>
							<xsl:stylesheet version="1.0" 
								xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
								xmlns:html="http://www.w3.org/1999/xhtml"
								exclude-result-prefixes="html">
								<xsl:template match="/">
									<html xmlns="http://www.w3.org/1999/xhtml">
										<head>
											 <title>Visualize Distribution of Illustrations in Walters Manuscripts</title>
										</head>
										<body>
											<form action="#" method="get">
												<p>Select manuscripts to visualize.</p>
												<p>
													<button type="submit" name="visualize" value="visualize">Visualize</button>
												</p>
												<!-- the manuscripts are the links to .xml files -->
												<xsl:variable name="manuscripts" select="//html:table//html:td/html:a[contains(@href, '.xml')]"/>
												<select name="file" multiple="multiple" size="{count($manuscripts)}">
													<xsl:for-each select="$manuscripts">
														<option><xsl:value-of select="."/></option>
													</xsl:for-each>
												</select>
											</form>
										</body>
									</html>
								</xsl:template>
							</xsl:stylesheet>
						</p:inline>
					</p:input>
				</p:xslt>
			</p:otherwise>
		</p:choose>
		
		<!-- wrap HTML document in an HTTP 200 OK response -->
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
	</p:pipeline>
</p:library>
