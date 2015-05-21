<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:vc="https://github.com/leoba/VisColl" >
	
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
				<p:for-each name="collation-model">
					<!-- 
						The manuscript is the content of the /c:request/c:multipart/c:body 
						whose @disposition starts with 'form-data; name="collation-model"' 
					-->
					<p:iteration-source select="
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
						]/manuscript
					"/>
					<!-- process the manuscript -->
					<!--
					process4 stylesheet triggers a type conversion error - hmmm
					<vc:transform xslt="process4.xsl"/>
					<vc:transform xslt="process5.xsl"/>
					-->
					<!-- for now, don't transform the collation-model; just copy it -->
					<p:identity/>
					
				</p:for-each>
				<!-- now what? -->
				<!-- merge the transformed collation-model and the spreadsheet into a single
				document and pass it to the resulting couple of transforms -->
				<!-- finally zip up the sequence of documents output from the final transform
				into a temporary zip file, then open the zip file and send it to the user  -->
				<!--
				<p:for-each name="image-list">
					<p:iteration-source select="
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
						]/manuscript
					"/>
				</p:for-each>
				-->
				
				<z:make-http-response/>
			</p:otherwise>
		</p:choose>
	</p:declare-step>
	
	<p:declare-step type="vc:transform" name="transform">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:input port="parameters" kind="parameter"/>
		<p:option name="xslt" required="true"/>
		<p:load name="stylesheet">
			<p:with-option name="href" select="$xslt"/>
		</p:load>
		<p:xslt>
			<p:input port="stylesheet">
				<p:pipe step="stylesheet" port="result"/>
			</p:input>
		</p:xslt>
	</p:declare-step>

</p:library>
