<?xml version="1.1"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
	
	<xsl:template match="/rdf:RDF">
		<json>
		[
			<xsl:apply-templates mode="subject-or-object"/>
		]
		</json>
	</xsl:template>
	
	<xsl:template match="*" mode="subject-or-object">
		<xsl:if test="position() &gt; 1">,</xsl:if>
		{
		<xsl:apply-templates select="." mode="id-and-type"/>
		<xsl:apply-templates select="*" mode="predicate"/>
		}
	</xsl:template>
	
	<xsl:template match="text()[normalize-space()]" mode="subject-or-object">
		<xsl:text>"</xsl:text>
		<xsl:variable name="regex">[&quot;\\&#x1;-&#x1F;]</xsl:variable>
		<xsl:analyze-string select="." regex="{$regex}">
			<xsl:matching-substring>
				<xsl:text>\u</xsl:text>
				<xsl:value-of select="format-number(string-to-codepoints(.), '0000')"/>
			</xsl:matching-substring>
			<xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
		</xsl:analyze-string>
		<xsl:text>"</xsl:text>
	</xsl:template>
	
	<xsl:template match="*" mode="predicate">,
		<xsl:text>"</xsl:text>
		<xsl:value-of select="concat(namespace-uri(.), local-name(.))"/>
		<xsl:text>": </xsl:text> 
		<xsl:apply-templates select="* | text()[normalize-space()] | @rdf:about | @rdf:ID" mode="subject-or-object"/>
	</xsl:template>
	
	<xsl:template match="@rdf:about" mode="subject-or-object">
		{
			"@id": "<xsl:value-of select="resolve-uri(., (ancestor-or-self::*/@xml:base)[1])"/>"
		}
	</xsl:template>
	
	<xsl:template match="@rdf:ID" mode="subject-or-object">
		{
			"@id": "<xsl:value-of select="resolve-uri(concat('#', .), (ancestor-or-self::*/@xml:base)[1])"/>"
		}
	</xsl:template>
	
	<xsl:template match="*" mode="id-and-type">
		<xsl:text>"@id": "</xsl:text>
			<xsl:choose>
				<xsl:when test="@rdf:about">
					<xsl:value-of select="resolve-uri(@rdf:about, (ancestor-or-self::*/@xml:base)[1])"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="resolve-uri(concat('#', @rdf:ID), (ancestor-or-self::*/@xml:base)[1])"/>
				</xsl:otherwise>
			</xsl:choose>
		<xsl:text>",
		"@type": "</xsl:text>
		<xsl:value-of select="concat(namespace-uri(.), local-name(.))"/>
		<xsl:text>"</xsl:text>
	</xsl:template>
	
</xsl:stylesheet>
