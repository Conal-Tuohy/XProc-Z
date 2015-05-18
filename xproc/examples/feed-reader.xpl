<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:feed="tag:conaltuohy.com,2015:feed-reader" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:html="http://www.w3.org/1999/xhtml">
	
	<!-- An RSS feed reader for embedding blog feeds in a web page -->
	
	<!-- Find any links to RSS feeds in the input HTML, and transclude them as a list of articles -->
	<p:pipeline type="feed:transclude" name="transclude-feed">
		<p:viewport name="insert-blog-feed" match="html:a[@type='application/rss+xml']">
			<feed:read>
				<p:with-option name="href" select="/html:a/@href"/>
			</feed:read>
		</p:viewport>
	</p:pipeline>
	
	<!-- Read an RSS feed and output a list of articles in HTML -->
	<p:pipeline type="feed:read" name="read-feed">
		
		<!-- the URI of the RSS feed -->
		<p:option name="href" required="true"/>
		
		<!-- try to load and transform the feed; in the event of any HTTP error just output an empty sequence -->
		<p:try>
			<p:group name="read-and-transform-rss">
				<!-- load the feed -->
				<p:load>
					<p:with-option name="href" select="$href"/>
				</p:load>
			</p:group>
			
			<p:catch name="failed-to-read-rss">
				<!-- an error must have occurred when reading or parsing the RSS XML -->
				
				<!-- emit an empty sequence -->
				<p:identity>
					<p:input port="source">
						<p:inline>
							<span xmlns="http://www.w3.org/1999/xhtml">transclusion failed</span>
						</p:inline>
					</p:input>
				</p:identity>
			</p:catch>
		</p:try>
		
		<!-- decode encoded HTML in the RSS -->
		<p:viewport name="escaped-portions" match="item/description">
			<p:unescape-markup/>
			<!--<p:rename match="a" new-name="a" new-namespace="http://www.w3.org/1999/xhtml"/>-->
		</p:viewport>
				
		<!-- render the RSS as HTML -->
		<p:xslt name="convert-to-html">
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml">
						<xsl:template match="/*">
							<xsl:copy-of select="."/>
						</xsl:template>
						<xsl:template match="/rss">
							<div class="transcluded-feed">
								<xsl:for-each select="channel">
									<div class="channel">
										<h2><a href="{link}"><xsl:value-of select="title"/></a></h2>
										<xsl:for-each select="item">
											<div class="item">
												<h3><a href="{link}"><xsl:value-of select="title"/></a></h3>
												<p><xsl:apply-templates select="description/node()"/></p>
											</div>
										</xsl:for-each>
									</div>
								</xsl:for-each>
							</div>
						</xsl:template>
						<xsl:template match="*">
							<xsl:element name="{local-name()}" namespace="http://www.w3.org/1999/xhtml">
								<xsl:copy-of select="@*"/>
								<xsl:apply-templates/>
							</xsl:element>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
		
	</p:pipeline>
</p:library>
