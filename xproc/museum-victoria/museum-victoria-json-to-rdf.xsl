<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:j="http://marklogic.com/json" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:crm="http://erlangen-crm.org/current/"
	xmlns:frbr="http://erlangen-crm.org/efrbroo/"
	xmlns:html="http://www.w3.org/1999/xhtml"
	xmlns:skos=" 	http://www.w3.org/2004/02/skos/core#"
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
			<!--<xsl:copy-of select="j:json"/>-->
		</rdf:RDF>
	</xsl:template>
	
	<!-- taxa (other than species -->
			<!-- TODO disclose the Linnaean type system here, by giving this type its own type e.g. "Phylum", "Class" -->
	<xsl:template match="/*[@type='taxon']">
		<!-- find the taxonomic rank of this taxon -->
		<xsl:variable name="taxon-rank-and-name" select="substring-after($id, '/')"/><!-- e.g. "genus-Ischnochiton" -->
		<xsl:variable name="taxon-rank" select="substring-before($taxon-rank-and-name, '-')"/><!-- "genus" -->
		<xsl:variable name="taxon-name" select="substring-after($taxon-rank-and-name, '-')"/> <!-- "Ischnochiton " -->
		<xsl:variable name="taxa" select="
			(
				j:json/j:taxonomy/j:subgenus,
				j:json/j:taxonomy/j:genus,
				j:json/j:taxonomy/j:subfamily,
				j:json/j:taxonomy/j:family,
				j:json/j:taxonomy/j:infraorder,
				j:json/j:taxonomy/j:suborder,
				j:json/j:taxonomy/j:order,
				j:json/j:taxonomy/j:superorder,
				j:json/j:taxonomy/j:subclass,
				j:json/j:taxonomy/j:subclass,
				j:json/j:taxonomy/j:class,
				j:json/j:taxonomy/j:superclass,
				j:json/j:taxonomy/j:subphylum,
				j:json/j:taxonomy/j:phylum,
				j:json/j:taxonomy/j:kingdom
			)
		"/>
		<xsl:variable name="taxon" select="j:json/j:taxonomy/*[$taxon-rank=local-name(.)]"/><!-- <j:genus type="string">Ischnochiton</j:genus> -->
		<xsl:variable name="specified-taxa" select="for $t in $taxa[not(@type='null')] return $t"/><!-- the superior taxa actually defined for this taxon -->
		<xsl:variable name="taxon-ranks" select="for $t in $specified-taxa return local-name($t)"/><!-- the ranks of the superior taxa -->
		<xsl:variable name="current-taxon-position" select="index-of($taxon-ranks, $taxon-rank)"/><!-- position of this taxon in the ranking -->
		<xsl:variable name="relevant-taxa" select="subsequence($specified-taxa, $current-taxon-position)"/><!-- this taxon, and superior (but not inferior) taxa -->
		<crm:E55_Type rdf:about="{$base-uri}resource/taxon/{local-name($taxon)}-{$taxon}">
			<xsl:call-template name="render-taxonomic-hierarchy">
				<xsl:with-param name="taxa" select="$relevant-taxa"/>
			</xsl:call-template>
		</crm:E55_Type>
		<xsl:variable name="species" select="j:results/j:item"/>
		<xsl:for-each select="$species">
			<crm:E55_Type rdf:about="{$base-uri}resource/{j:id}">
				<crm:P1_is_identified_by>
					<crm:E41_Appellation rdf:ID="{translate(j:id, '/', '-')}">
						<rdf:value><xsl:value-of select="substring-before(substring-after(j:displayTitle, '&lt;em&gt;'), '&lt;/em&gt;')"/></rdf:value>
					</crm:E41_Appellation>
				</crm:P1_is_identified_by>
				<crm:P127_has_broader_term rdf:resource="{$base-uri}resource/taxon/{local-name($taxon)}-{$taxon}"/>
			</crm:E55_Type>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="render-taxonomic-hierarchy">
		<xsl:param name="taxa"/>
		<xsl:variable name="taxon" select="$taxa[1]"/>
		<xsl:variable name="super-taxon" select="$taxa[2]"/>
		<xsl:if test="$taxon">
			<crm:P1_is_identified_by>
				<crm:E41_Appellation rdf:ID="{local-name($taxon)}">
					<rdf:value><xsl:value-of select="$taxon"/></rdf:value>
				</crm:E41_Appellation>
			</crm:P1_is_identified_by>
			<xsl:if test="$super-taxon">
				<crm:P127_has_broader_term>
					<crm:E55_Type rdf:about="{$base-uri}resource/taxon/{local-name($super-taxon)}-{$super-taxon}">
						<xsl:call-template name="render-taxonomic-hierarchy">
							<xsl:with-param name="taxa" select="subsequence($taxa, 2)"/>
						</xsl:call-template>
					</crm:E55_Type>
				</crm:P127_has_broader_term>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	
	<!-- specimens -->
	<xsl:template match="j:json[@type='specimen']">
		<crm:E20_Biological_Object rdf:about="{$base-uri}resource/{$id}">
			<xsl:apply-templates/>
		</crm:E20_Biological_Object>
	</xsl:template>	
	
	<!-- species -->
	<xsl:template match="j:json[@type='species']">
		<crm:E55_Type rdf:about="{$base-uri}resource/{$id}">
			<xsl:apply-templates/>
		</crm:E55_Type>
	</xsl:template>
	
	<xsl:template
		xmlns:c="http://www.w3.org/ns/xproc-step"
		xmlns:sr="http://www.w3.org/2005/sparql-results#"
		match="j:json[@type='species']
			/c:response[@status='200']/c:body/
			sr:sparql/sr:results/sr:result/sr:binding[@name='species']/sr:uri">
		<skos:closeMatch rdf:resource="{.}"/>
	</xsl:template>
	
	
	<xsl:template match="j:json[@type='species']/j:taxonomy">
		<xsl:variable name="taxa" select="
			(
				j:subgenus,
				j:genus,
				j:subfamily,
				j:family,
				j:infraorder,
				j:suborder,
				j:order,
				j:superorder,
				j:subclass,
				j:subclass,
				j:class,
				j:superclass,
				j:subphylum,
				j:phylum,
				j:kingdom
			)
		"/>	
		<xsl:variable name="specified-taxa" select="for $t in $taxa[not(@type='null')] return $t"/><!-- the superior taxa actually defined for this taxon -->	
		<xsl:variable name="super-taxon" select="$specified-taxa[1]"/>
		<xsl:apply-templates select="j:taxonName"/>
		<crm:P127_has_broader_term>
			<crm:E55_Type rdf:about="{$base-uri}resource/taxon/{local-name($super-taxon)}-{$super-taxon}">
				<xsl:call-template name="render-taxonomic-hierarchy">
					<xsl:with-param name="taxa" select="$specified-taxa"/>
				</xsl:call-template>
			</crm:E55_Type>
		</crm:P127_has_broader_term>
	</xsl:template>
	
	<xsl:template match="j:taxonName">
		<crm:P1_is_identified_by>
			<crm:E41_Appellation rdf:ID="taxonName">
				<rdf:value><xsl:value-of select="."/></rdf:value>
			</crm:E41_Appellation>
		</crm:P1_is_identified_by>
	</xsl:template>
	
	<!-- articles -->
	<xsl:template match="j:json[@type='article']">
		<crm:E31_Document rdf:about="{$base-uri}resource/{$id}">
			<xsl:apply-templates/>
		</crm:E31_Document>
	</xsl:template>
	
	<xsl:template match="j:title">
		<crm:P102_has_title>
			<crm:E35_Title rdf:ID="title">
				<rdf:value><xsl:value-of select="."/></rdf:value>
			</crm:E35_Title>
		</crm:P102_has_title>
	</xsl:template>
	
	<!-- an item -->
	<xsl:template match="j:json[@type='item']">
		<crm:E19_Physical_Object rdf:about="{$base-uri}resource/{$id}">
			<xsl:apply-templates/>
		</crm:E19_Physical_Object>
		<xsl:apply-templates mode="reverse"/>
	</xsl:template>
	
	<xsl:template match="j:objectName">
		<crm:P1_is_identified_by>
			<crm:E41_Appellation rdf:ID="objectName">
				<rdf:value><xsl:value-of select="."/></rdf:value>
			</crm:E41_Appellation>
		</crm:P1_is_identified_by>
	</xsl:template>
	
	<xsl:template match="j:objectSummary">
		<crm:P3_has_note>
			<crm:E62_Note rdf:ID="objectSummary">
				<rdf:value><xsl:value-of select="."/></rdf:value>
			</crm:E62_Note>
		</crm:P3_has_note>
	</xsl:template>
	
	<xsl:template match="j:json[@type='item']/j:relatedArticleIds/j:item" mode="reverse">
		<!-- the related articles of an item document the item-->
		<crm:E31_Document rdf:about="{$base-uri}resource/{.}">
			<crm:P70_Documents>
				<crm:E19_Physical_Object rdf:about="{$base-uri}resource/{$id}"/>
			</crm:P70_Documents>
		</crm:E31_Document>
	</xsl:template>
	
	<!--
		XML Literal is pragmatically not a good choice to represent the article content
	-->
	<!--
	<xsl:template match="j:content">
		<rdf:value rdf:parseType="Literal">
			<div xmlns="http://www.w3.org/1999/xhtml">
				<xsl:apply-templates select="html:html/html:body/node()"/>
			</div>
		</rdf:value>
	</xsl:template>
	-->
	<xsl:template match="j:content">
		<frbr:R4_carriers_provided_by rdf:about="{$base-uri}data/html/{$id}"/>
	</xsl:template>
	
	<xsl:template match="j:json[@type='article']/j:relatedItemIds/j:item">
		<!-- the related items of an article are things which the article documents -->
		<crm:P70_Documents>
			<crm:E19_Physical_Object rdf:about="{$base-uri}resource/{.}"/>
		</crm:P70_Documents>
	</xsl:template>
	
	<xsl:template match="j:json[@type='article']/j:relatedArticleIds/j:item">
		<!-- the related articles of an article have some non-specific similarity relation -->
		<crm:P130_shows_features_of>
			<crm:E31_Document rdf:about="{$base-uri}resource/{.}"/>
		</crm:P130_shows_features_of>
	</xsl:template>
	
	<xsl:template match="j:json[@type='item']/j:relatedItemIds/j:item">
		<!-- the related items of an item are things with some non-specific similarity relation -->
		<crm:P130_shows_features_of>
			<crm:E19_Physical_Object rdf:about="{$base-uri}resource/{.}"/>
		</crm:P130_shows_features_of>
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
					
