<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:j="http://marklogic.com/json" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	
	xmlns:html="http://www.w3.org/1999/xhtml"
	xmlns="http://www.w3.org/1999/xhtml"
	exclude-result-prefixes="j xs">
	
	<xsl:param name="public-uri"/>
	<xsl:param name="relative-uri"/>
	<xsl:variable name="base-uri" select="
		substring(
			$public-uri, 
			1, 
			string-length($public-uri) - string-length($relative-uri)
		)
	"/>
	<xsl:variable name="id" select="substring-after($relative-uri, 'data/html/')"/>
	
	<xsl:template match="/">
		<html>
			<head>
				<title><xsl:value-of select="j:json/j:title"/></title>
				<link rev="http://erlangen-crm.org/efrbroo/R4_carriers_provided_by" href="{$base-uri}resource/{$id}"/>
			</head>
			<body>
				<h1><xsl:value-of select="j:json/j:title"/></h1>
				<xsl:apply-templates select="j:json/j:content/html:html/html:body/node()"/>
			</body>
		</html>
	</xsl:template>
	
	<xsl:template match="html:*">
		<xsl:element name="{local-name()}" xmlns="http://www.w3.org/1999/xhtml">
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
</xsl:stylesheet>
					
