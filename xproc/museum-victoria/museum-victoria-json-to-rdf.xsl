<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:j="http://marklogic.com/json" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:e="http://erlangen-crm.org/current/"
	xmlns:html="http://www.w3.org/1999/xhtml"
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
	<xsl:variable name="id" select="substring-after($relative-uri, 'data/')"/>
	<xsl:variable name="type" select="substring-before($id, '/')"/><!-- articles, items, species, specimens -->
	
	<xsl:template match="/">
		<rdf:RDF>
			<xsl:apply-templates/>
			<!--
			<xsl:comment>Public URI: <xsl:value-of select="$public-uri"/></xsl:comment>
			<xsl:comment>Relative URI: <xsl:value-of select="$relative-uri"/></xsl:comment>
			<xsl:comment>Base URI: <xsl:value-of select="$base-uri"/></xsl:comment>
			<xsl:comment>JSON:</xsl:comment>
			<xsl:copy-of select="j:json"/>-->
		</rdf:RDF>
	</xsl:template>
	
	<!-- specimens -->
	<xsl:template match="j:json[@type='specimen']">
		<e:E20_Biological_Object rdf:about="{$base-uri}resource/{$id}">
			<xsl:apply-templates/>
		</e:E20_Biological_Object>
	</xsl:template>	
	
	<!-- species -->
	<xsl:template match="j:json[@type='species']">
		<e:E55_Type rdf:about="{$base-uri}resource/{$id}">
			<xsl:apply-templates/>
		</e:E55_Type>
	</xsl:template>
	
	<xsl:template match="j:taxonName">
	</xsl:template>
	
	<!-- articles -->
	<xsl:template match="j:json[@type='article']">
		<e:E31_Document rdf:about="{$base-uri}resource/{$id}">
			<xsl:apply-templates/>
		</e:E31_Document>
	</xsl:template>
	
	<xsl:template match="j:title">
		<e:P102_has_title>
			<e:E35_Title rdf:ID="title">
				<rdf:value><xsl:value-of select="."/></rdf:value>
			</e:E35_Title>
		</e:P102_has_title>
	</xsl:template>
	
	<!-- an item -->
	<xsl:template match="j:json[@type='item']">
		<e:E19_Physical_Object rdf:about="{$base-uri}resource/{$id}">
			<xsl:apply-templates/>
		</e:E19_Physical_Object>
		<xsl:apply-templates mode="reverse"/>
	</xsl:template>
	
	<xsl:template match="j:objectName">
		<e:P1_is_identified_by>
			<e:E41_Appellation rdf:ID="objectName">
				<rdf:value><xsl:value-of select="."/></rdf:value>
			</e:E41_Appellation>
		</e:P1_is_identified_by>
	</xsl:template>
	
	<xsl:template match="j:objectSummary">
		<e:P3_has_note>
			<e:E62_Note rdf:ID="objectSummary">
				<rdf:value><xsl:value-of select="."/></rdf:value>
			</e:E62_Note>
		</e:P3_has_note>
	</xsl:template>
	
	<xsl:template match="j:json[@type='item']/j:relatedArticleIds/j:item" mode="reverse">
		<!-- the related articles of an item document the item-->
		<e:E31_Document rdf:about="{$base-uri}resource/{.}">
			<e:P70_Documents>
				<e:E19_Physical_Object rdf:about="{$base-uri}resource/{$id}"/>
			</e:P70_Documents>
		</e:E31_Document>
	</xsl:template>
	
	<xsl:template match="j:content">
		<rdf:value rdf:parseType="Literal">
			<div xmlns="http://www.w3.org/1999/xhtml">
				<xsl:apply-templates select="html:html/html:body/node()"/>
			</div>
		</rdf:value>
	</xsl:template>
	
	
	<xsl:template match="j:json[@type='article']/j:relatedItemIds/j:item">
		<!-- the related items of an article are things which the article documents -->
		<e:P70_Documents>
			<e:E19_Physical_Object rdf:about="{$base-uri}resource/{.}"/>
		</e:P70_Documents>
	</xsl:template>
	
	<xsl:template match="j:json[@type='article']/j:relatedArticleIds/j:item">
		<!-- the related articles of an article have some non-specific similarity relation -->
		<e:P130_shows_features_of>
			<e:E31_Document rdf:about="{$base-uri}resource/{.}"/>
		</e:P130_shows_features_of>
	</xsl:template>
	
	<xsl:template match="j:json[@type='item']/j:relatedItemIds/j:item">
		<!-- the related items of an item are things with some non-specific similarity relation -->
		<e:P130_shows_features_of>
			<e:E19_Physical_Object rdf:about="{$base-uri}resource/{.}"/>
		</e:P130_shows_features_of>
	</xsl:template>
	
	<xsl:template match="html:*">
		<xsl:element name="{local-name()}" xmlns="http://www.w3.org/1999/xhtml">
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="*[*]" priority="-1">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="*" priority="-2"/>
	<xsl:template match="*[*]" priority="-1" mode="reverse">
		<xsl:apply-templates mode="reverse"/>
	</xsl:template>
	<xsl:template match="*" priority="-2" mode="reverse"/>	
</xsl:stylesheet>
					
