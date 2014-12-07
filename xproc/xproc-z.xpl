<p:pipeline 
	xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" version="1.0" name="main">
	
	<p:import href="xproc-z-library.xpl"/>
	<!--
	<p:import href="test.xpl"/>
	<z:form-test/>
	-->
	<p:import href="visualize-distribution.xpl"/>
	<v:visualize-distribution xmlns:v="https://github.com/leoba/distributionVis"/>
	

</p:pipeline>
