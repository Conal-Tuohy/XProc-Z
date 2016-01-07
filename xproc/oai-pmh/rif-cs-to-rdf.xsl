<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:oai="http://www.openarchives.org/OAI/2.0/"
	xmlns:rif="http://ands.org.au/standards/rif-cs/registryObjects"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:crm="http://erlangen-crm.org/current/"
	xmlns:xlink="http://www.w3.org/1999/xlink">
	
	<xsl:param name="resource-base-uri"/>
	<xsl:variable name="resource-uri" select="
		concat(
			'resource/',
			encode-for-uri(
				/oai:record/oai:metadata/rif:registryObjects/rif:registryObject/rif:key
			)
		)
	"/>

	<xsl:template match="/oai:record">
		<rdf:RDF>
			<xsl:attribute name="xml:base"><xsl:value-of select="$resource-base-uri"/></xsl:attribute>
			<xsl:apply-templates select="oai:metadata/rif:registryObjects/rif:registryObject"/>
		</rdf:RDF>
	</xsl:template>
	
	<xsl:template match="rif:registryObject[rif:collection]">
		<crm:E78_Collection rdf:about="{$resource-uri}">
			<xsl:apply-templates/>
		</crm:E78_Collection>
	</xsl:template>
	
	<!--
		The RIF-CS address refers to some kind of digital surrogate
		http://www.cidoc-crm.org/issues.php?id=53
	-->
	<xsl:template match="rif:location/rif:address/rif:electronic[@type='url']/rif:value">
		<crm:P70_is_documented_in>
			<crm:E31_document rdf:about="{.}"/>
		</crm:P70_is_documented_in>
	</xsl:template>
	
	<xsl:template match="rif:registryObject[rif:party]">
		<crm:E74_Group rdf:about="{$resource-uri}">
			<xsl:apply-templates/>
		</crm:E74_Group>
	</xsl:template>
	
	<xsl:template match="rif:registryObject[rif:activity]">
		<crm:E7_Activity rdf:about="{$resource-uri}">
			<xsl:apply-templates/>
		</crm:E7_Activity>
	</xsl:template>
	
	<xsl:template match="rif:collection | rif:party | rif:activity">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="*">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="text()"/>
	
	<xsl:template match="rif:activity/rif:identifier | rif:collection/rif:identifier | rif:party/rif:identifier">
		<crm:P1_is_identified_by>
			<crm:E42_Identifier rdf:about="{$resource-uri}#identifier">
				<rdf:value><xsl:value-of select="normalize-space(.)"/></rdf:value>
			</crm:E42_Identifier>
		</crm:P1_is_identified_by>
	</xsl:template>
	
	<xsl:template match="rif:activity/rif:name | rif:collection/rif:name">
		<crm:P1_is_identified_by>
			<crm:E41_Appellation rdf:about="{$resource-uri}#name">
				<rdf:value><xsl:value-of select="normalize-space(.)"/></rdf:value>
			</crm:E41_Appellation>
		</crm:P1_is_identified_by>
	</xsl:template>

	<xsl:template match="rif:party/rif:name">
		<crm:P1_is_identified_by>
			<crm:E82_Actor_Appellation rdf:about="{$resource-uri}#name">
				<rdf:value><xsl:value-of select="normalize-space(.)"/></rdf:value>
			</crm:E82_Actor_Appellation>
		</crm:P1_is_identified_by>
	</xsl:template>	
	
	<!-- Collections are created by Agencies -->
	<xsl:template match="rif:collection/rif:relatedObject[rif:relation/@type=('hasCreator', 'hasCollector')]">
		<!-- NB "hasCollector" is the correct type, but PROV records have "hasCreator" -->
		<crm:P147_was_curated_by>
			<crm:E87_Curation_Activity rdf:about="{$resource-uri}#curation">
				<crm:P14_carried_out_by>
					<crm:E74_Group rdf:about="resource/{encode-for-uri(rif:key)}"/>
				</crm:P14_carried_out_by>
			</crm:E87_Curation_Activity>
		</crm:P147_was_curated_by>
	</xsl:template>
	
	<!-- Functions are managed by Agencies -->
	<xsl:template match="rif:activity/rif:relatedObject[rif:relation/@type='isManagedBy']">
		<crm:P14_carried_out_by>
			<crm:E74_Group rdf:about="resource/{encode-for-uri(rif:key)}"/>
		</crm:P14_carried_out_by>
	</xsl:template>
	
	<xsl:template name="render-date-value">
		<xsl:param name="date-value"/>
		<xsl:choose>
			<xsl:when test="string-length($date-value)=4">
				<rdf:value rdf:datatype="http://www.w3.org/2001/XMLSchema#gYear"><xsl:value-of select="$date-value"/></rdf:value>
			</xsl:when>
			<xsl:when test="string-length($date-value)=6">
				<rdf:value rdf:datatype="http://www.w3.org/2001/XMLSchema#gYearMonth"><xsl:value-of select="
					concat(substring($date-value, 1, 4), '-', substring($date-value, 5, 2))
				"/></rdf:value>
			</xsl:when>
			<xsl:otherwise>
				<rdf:value rdf:datatype="http://www.w3.org/2001/XMLSchema#date"><xsl:value-of select="
					concat(substring($date-value, 1, 4), '-', substring($date-value, 5, 2), '-', substring($date-value, 7, 2))
				"/></rdf:value>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>
