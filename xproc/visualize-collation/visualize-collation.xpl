<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:vc="https://github.com/leoba/VisColl" >
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<p:import href="../xproc-z-library.xpl"/>
	
	<p:declare-step type="vc:visualize-collation" name="visualize-collation">
		<p:input port="source" primary="true"/>
		<p:input port="parameters" kind="parameter" primary="true"/>
		<p:output port="result" primary="true" sequence="true"/>
		<p:option name="relative-uri" select=" '' "/>
		<p:choose>
			<p:when test="not(/c:request/c:multipart)">
				<!-- No files were uploaded -->
				<!-- Return a form for the user to upload data files -->
				<p:load href="upload-form.html"/>
				<z:make-http-response/>
			</p:when>
			<p:otherwise>
				<!-- User uploaded files - process and return them -->
				<!-- 
					The manuscript is the content of the /c:request/c:multipart/c:body 
					whose @disposition starts with 'form-data; name="collation-model"' 
				-->
				<p:identity name="collation-model">
					<p:input port="source" select="
						/c:request/c:multipart/c:body[
							starts-with(
								@disposition,
								concat(
									'form-data; name=',
									codepoints-to-string(34),
									'collation-model',
									codepoints-to-string(34)
								)
							)
						]
						/*
					">
						<p:pipe port="source" step="visualize-collation"/>
					</p:input>
				</p:identity>
				<!-- process the manuscript -->
				<vc:transform xslt="process4.xsl"/>
				<vc:transform xslt="process5.xsl" name="process5"/>

				<!-- now what? -->
				<!-- merge the transformed collation-model and the spreadsheet into a single				
				document and pass it to the resulting couple of transforms -->
				<p:identity name="image-list">
					<p:input port="source" select="
						/c:request/c:multipart/c:body[
							starts-with(
								@disposition,
								concat(
									'form-data; name=',
									codepoints-to-string(34),
									'image-list',
									codepoints-to-string(34)
								)
							)
						]
						/*
					">
						<p:pipe port="source" step="visualize-collation"/>
					</p:input>
				</p:identity>
				<p:wrap-sequence wrapper="manuscript-and-images">
					<p:input port="source">
						<p:pipe step="process5" port="result"/>
						<p:pipe step="image-list" port="result"/>
					</p:input>
				</p:wrap-sequence>
				<vc:transform xslt="process6-excel.xsl"/>
				<p:xslt name="process7" output-base-uri="file:/">
					<p:input port="stylesheet">
						<p:document href="process7.xsl"/>
					</p:input>
				</p:xslt>				
				<!-- create a zip manifest  -->
				<p:for-each>
					<p:iteration-source>
						<p:pipe step="process7" port="secondary"/>
					</p:iteration-source>
					<p:template>
						<p:input port="template">
							<p:inline>
								<c:entry name="{substring-after(base-uri(), 'file:/')}" href="{base-uri()}"/>
							</p:inline>
						</p:input>
					</p:template>
				</p:for-each>
				<p:wrap-sequence wrapper="c:zip-manifest" name="manifest"/>
				<!-- get global parameters to find a safe place to write a temp file -->
				<p:parameters name="global-parameters">
					<p:input port="parameters">
						<p:pipe step="visualize-collation" port="parameters"/>
					</p:input>
				</p:parameters>
				<p:group>
					<!-- We need an absolute URI for the temporary zip file, based on the "realPath" parameter -->
					<p:variable name="zip-file-name" select="
						concat(
							'file:', 
							/c:param-set/c:param[@name='realPath'][@namespace='tag:conaltuohy.com,2015:servlet-context']/@value,
							'/VisColl.zip'
						)
					">
						<p:pipe step="global-parameters" port="result"/>
					</p:variable>
					<!-- zip up the sequence of documents according to the manifest and stash it in the temporary file -->
					<zip name="zip" xmlns="http://exproc.org/proposed/steps">
						<p:with-option name="href" select="$zip-file-name"/>
						<p:input port="source">
							<p:pipe step="process7" port="secondary"/>
						</p:input>
						<p:input port="manifest">
							<p:pipe step="manifest" port="result"/>
						</p:input>
					</zip>
					<!-- create a request document to read the temporary file back in -->
					<p:in-scope-names name="parameters"/>
					<p:template name="zip-file-request">
						<p:input port="source">
							<p:inline><test/></p:inline>
						</p:input>
						<p:input port="template">
							<p:inline>
								<c:request method="get" href="{$zip-file-name}"/>
							</p:inline>
						</p:input>
						<p:input port="parameters">
							<p:pipe step="parameters" port="result"/>
						</p:input>
					</p:template>
					<!-- Read ZIP file back in. NB explicit dependency on preceding step -->
					<p:http-request cx:depends-on="zip" xmlns:cx="http://xmlcalabash.com/ns/extensions"/>
				</p:group>
				<!-- Return the ZIP file to the browser -->
				<p:template name="http-response">
					<p:input port="template">
						<p:inline>
							<c:response status="200">
								<c:header name="X-Powered-By" value="XProc using XML Calabash"/>
								<c:header name="Server" value="XProc-Z"/>
								<c:body 
									content-type="{/c:body/@content-type}" 
									disposition="attachment; filename='VisColl.zip'" 
									encoding="{/c:body/@encoding}">{/c:body/node()}</c:body>
							</c:response>
						</p:inline>
					</p:input>
				</p:template>
			</p:otherwise>
		</p:choose>
	</p:declare-step>
	
	<!-- shorthand for executing an XSLT  -->
	<p:declare-step type="vc:transform" name="transform">
		
		<p:input port="source"/>
		<p:output port="result" primary="true"/>
		<p:input port="parameters" kind="parameter"/>
		
		<p:option name="xslt" required="true"/>
		
		<p:load name="load-stylesheet">
			<p:with-option name="href" select="$xslt"/>
		</p:load>
		
		<p:xslt name="execute-xslt">
			<p:input port="source">
				<p:pipe step="transform" port="source"/>
			</p:input>
			<p:input port="stylesheet">
				<p:pipe step="load-stylesheet" port="result"/>
			</p:input>
		</p:xslt>
	</p:declare-step>
</p:library>
