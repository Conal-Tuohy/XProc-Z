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
				
				<!-- TODO finally execute the final transform process7, 
				zip up (into a temporary file) the sequence of "secondary" documents which it outputs
				then read the zip file back in, and send it to the user  -->
				<!--
				<vc:transform xslt="process7.xsl" name="process7"/>
				<p:for-each>
					<p:iteration-source>
						<p:pipe step="process7" port="secondary"/>
					</p:iteration-source>
				</p:for-each>
				-->
				<p:xslt name="process7">
					<p:input port="stylesheet">
						<p:document href="process7.xsl"/>
					</p:input>
				</p:xslt>
				<p:wrap-sequence wrapper="output-files">
					<p:input port="source">
						<p:pipe step="process7" port="secondary"/>
					</p:input>
				</p:wrap-sequence>
				<z:make-http-response/>
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
