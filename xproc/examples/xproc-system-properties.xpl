<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:ex="https://github.com/Conal-Tuohy/XProc-Z/tree/master/xproc/examples" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z"
	xmlns:fn="http://www.w3.org/2005/xpath-functions">
	
	<p:import href="../xproc-z-library.xpl"/>
	
	<p:declare-step type="ex:system-properties" name="main">
		<p:input port='source'/>
		<p:output port="result"/>
		<p:template>
			<p:input port="template">
				<p:inline>
					<c:response status="200">
						<c:header name="X-Powered-By" value="XProc using XML Calabash"/>
						<c:header name="Server" value="XProc-Z"/>
						<c:body content-type="application/xhtml+xml">
							<html xmlns="http://www.w3.org/1999/xhtml"
								xmlns:servlet-init="tag:conaltuohy.com,2015:servlet-init-parameters"
								xmlns:webapp-init="tag:conaltuohy.com,2015:webapp-init-parameters"
								xmlns:servlet-context="tag:conaltuohy.com,2015:servlet-context"
								xmlns:os-env="tag:conaltuohy.com,2015:os-environment-variables"
								xmlns:java="tag:conaltuohy.com,2015:java-system-properties"
								xmlns:xproc-z="tag:conaltuohy.com,2019:xproc-z-system-properties"
							>
								<head>
									<title>System Properties</title>
								</head>
								<body>
									<p>This example shows how to use the 
										<a href="https://www.w3.org/TR/xproc/#f.system-property"><code>system-property</code></a> function
										to access information about the environment in which the XProc pipeline is running.</p>
									<p>A pipeline running in XProc-Z can use the <code>system-property</code> function to access the standard
										set of system properties defined by the XProc specification, as well as extension properties provided by
										XMLCalabash, plus 5 more system property namespaces defined by XProc-Z itself, providing access to other 
										sources of named properties accessible from the runtime environment of the XProc-Z Servlet:
										<table>
											<tr>
												<th>Property source</th>
												<th>Property namespace</th>
												<th>Property names</th>
											</tr>
											<tr>
												<td>XProc-Z build properties</td>
												<td>tag:conaltuohy.com,2019:xproc-z-system-properties</td>
												<td><code>url</code>, <code>version</code></td>
											</tr>
											<tr>
												<td>Servlet initialization parameters</td>
												<td>tag:conaltuohy.com,2015:servlet-init-parameters</td>
												<td>See <a href="https://docs.oracle.com/javaee/6/api/javax/servlet/ServletConfig.html#getInitParameter(java.lang.String)">javax.servlet.ServletConfig.getInitParameter(java.lang.String)</a></td>
											</tr>
											<tr>
												<td>Application initialization parameters</td>
												<td>tag:conaltuohy.com,2015:webapp-init-parameters</td>
												<td>See <a href="https://docs.oracle.com/javaee/6/api/javax/servlet/ServletContext.html#getInitParameter(java.lang.String)">javax.servlet.ServletContext.getInitParameter(java.lang.String)</a></td>
											</tr>
											<tr>
												<td>Operating System environment variables</td>
												<td>tag:conaltuohy.com,2015:os-environment-variables</td>
												<td>Environment variables defined for the Servlet container's user. See 
												<a href="https://docs.oracle.com/javase/7/docs/api/java/lang/System.html#getenv()">java.lang.System.getenv(java.lang.String)</a></td>
											</tr>
											<tr>
												<td>Java system properties</td>
												<td>tag:conaltuohy.com,2015:java-system-properties</td>
												<td>System properties passed to the JVM on initialization. See 
												<a href="https://docs.oracle.com/javase/7/docs/api/java/lang/System.html#getProperty(java.lang.String)">java.lang.System.getProperty(java.lang.String)</a></td>
											</tr>
										</table>
									</p>
									<p>Examples: 
										<table>
											<tr>
												<td>p:system-property('os-env:user')</td><td>{p:system-property('os-env:user')}</td>
											</tr>
											<tr>
												<td>p:system-property('java:java.version')</td><td>{p:system-property('java:java.version')}</td>
											</tr>
										</table>
									</p>
								</body>
							</html>
						</c:body>
					</c:response>
				</p:inline>
			</p:input>
		</p:template>
	</p:declare-step>
		
</p:library>
