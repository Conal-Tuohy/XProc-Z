<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z">
	<xsl:param name="uri-template"/>
	<xsl:template match="/c:request">
		<!-- check if the @href URI matches the $uri-template -->

		<!-- convert the URI template into a regex and use it to parse the URI -->
		<xsl:variable name="bracketed-expression-regex">\{[^}]+\}</xsl:variable>
		<xsl:variable name="tokenized-template" select="analyze-string($uri-template, $bracketed-expression-regex)/*"/>
		<xsl:variable name="uri-regex" select="
			string-join(
				(
					'^',
					for $token in $tokenized-template return
						if ($token/self::fn:non-match) then 
							replace($token, '\^|\.|\\|\?|\*|\+|\{|\}|\(|\)|\||\^|\$|\[|\]', '\\$0')
						else
							'(.*?)',
					'$'
				)
			)
		"/>
		
		<xsl:variable name="matches" select="matches(@href, $uri-regex)"/>
		<xsl:choose>
			<xsl:when test="$matches">
				<c:parameters>
					<xsl:variable name="variable-names" select="for $token in $tokenized-template/self::fn:match return substring($token, 2, string-length($token) - 2)"/>
					<xsl:variable name="uri-analysis" select="analyze-string(@href, $uri-regex)"/>
					<xsl:for-each select="$uri-analysis//*[@nr]">
						<xsl:variable name="variable-index" select="number(@nr)"/>
						<c:parameter name="{$variable-names[$variable-index]}" value="{.}"/>
					</xsl:for-each>
				</c:parameters>
			</xsl:when>
			<xsl:otherwise>
				<z:non-match/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="xsl:initial-template">
		<xsl:message expand-text="true" terminate="true">c:request input document missing, uri-template="{$uri-template}"</xsl:message>
	</xsl:template>
</xsl:stylesheet>
