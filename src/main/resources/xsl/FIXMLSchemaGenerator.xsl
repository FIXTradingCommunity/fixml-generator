<?xml version="1.0" encoding="UTF-8"?>
<!--************************************************************************
*
*   Generates FIXML V1.2 Schema files from an Orchestra Version 1.0 XML file
*
****************************************************************************-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xso="http://www.w3.org/1999/XSL/TransformAlias" xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:localfn="http://dummy" exclude-result-prefixes="xs localfn"
xmlns:fixr="http://fixprotocol.io/2020/orchestra/repository" xmlns:dc="http://purl.org/dc/elements/1.1/">
	<xsl:output method="xml" encoding="utf-8" indent="yes"/>
	<xsl:param name="targetDir"/>
	<xsl:namespace-alias stylesheet-prefix="xso" result-prefix="xs"/>

	<xsl:function name="localfn:cleanUrl">
		<xsl:param name="url"/>
		<xsl:value-of select="concat('file:///',translate($url,'\','/'))"/>
	</xsl:function>
	<xsl:template name="generation-info-comment-block">
		<xsl:text/>
		<xsl:comment>
		FIXML Schema Version <xsl:value-of select="/fixr:repository/@name"/> <xsl:value-of select="concat(' ',/fixr:repository/substring-after(@version,'_'))"/>

		Generated: <xsl:value-of select="current-dateTime()"/>

		Copyright(c) FIX Protocol Limited. All rights reserved.

        Comments and errors should be posted on the FIX Protocol web-site https://www.fixtrading.org/
		</xsl:comment>
	<xsl:text>

</xsl:text>
	</xsl:template>
	<xsl:template name="fixml-namespace">
		<xsl:variable name="VersionString" select="/fixr:repository/substring-after(@name,'.')"/>
		<xsl:variable name="schemaNamespace" select="concat('http://www.fixprotocol.org/FIXML-',$VersionString)"/>
		<xsl:variable name="fmNamespace" select="concat($schemaNamespace,'/METADATA')"/>

		<xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
		<xsl:namespace name="">
			<xsl:value-of select="$schemaNamespace"/>
		</xsl:namespace>
		<xsl:namespace name="fm">
			<xsl:value-of select="$fmNamespace"/>
		</xsl:namespace>
		<xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
		<xsl:attribute name="xsi:schemaLocation" namespace="http://www.w3.org/2001/XMLSchema-instance"><xsl:text>http://www.fixprotocol.org/FIXML-</xsl:text><xsl:value-of select="$VersionString"/><xsl:text>/METADATA fixml-metadata-</xsl:text><xsl:value-of select="lower-case($VersionString)"/><xsl:text>.xsd</xsl:text></xsl:attribute>
		<xsl:attribute name="targetNamespace"><xsl:value-of select="$schemaNamespace"/></xsl:attribute>
		<xsl:attribute name="elementFormDefault">qualified</xsl:attribute>
		<xsl:attribute name="attributeFormDefault">unqualified</xsl:attribute>
	</xsl:template>
	<!-- For legacy special cases of component names -->
	<xsl:function name="localfn:fixupCompName" as="xs:string">
		<xsl:param name="component"/>
		<xsl:choose>
			<!-- XXX: HACK: Special case for legacy compatibility i.e. JimN design errors -->
			<!-- xsl:when test="$component/Name='HopGrp'">Hop</xsl:when -->
			<xsl:when test="$component/@name='StandardHeader'">BaseHeader</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$component/@name"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- For legacy special cases of component types -->
	<xsl:function name="localfn:generateCompType" as="xs:string">
		<xsl:param name="component"/>
		<xsl:choose>
			<xsl:when test="$component/@name='StandardHeader'">BaseHeader_t</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat($component/@name,'_Block_t')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<xsl:function name="localfn:isComponent" as="xs:boolean">
		<xsl:param name="node"/>
		<xsl:variable name="TYPE" select="local-name($node)"/>
		<xsl:choose>
			<xsl:when test="$TYPE = ('component','componentRef')">true</xsl:when>
			<xsl:otherwise>false</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<xsl:function name="localfn:isInlinedComponent" as="xs:boolean">
		<xsl:param name="node"/>
		<xsl:variable name="TYPE" select="local-name($node)"/>
		<xsl:choose>
			<!-- XXX: Attribute "rendering" exists in Basic. Unified has "inlined".
								Orchestra has "rendering" but unified2orchestra does not seem to create it.
								See unified2orchestra issue #8
			-->
			<xsl:when test="$TYPE='component' and contains($node/@rendering, 'fixml=Inlined')">true</xsl:when>
			<xsl:otherwise>false</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<xsl:function name="localfn:isGroup" as="xs:boolean">
		<xsl:param name="node"/>
		<xsl:variable name="TYPE" select="local-name($node)"/>
		<xsl:choose>
			<xsl:when test="$TYPE = ('group','groupRef')">true</xsl:when>
			<xsl:otherwise>false</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<xsl:function name="localfn:isField" as="xs:boolean">
		<xsl:param name="fieldRef"/>
		<xsl:variable name="TYPE" select="local-name($fieldRef)"/>
		<xsl:choose>
			<xsl:when test="$TYPE = ('field','fieldRef')">true</xsl:when>
			<xsl:otherwise>false</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<xsl:template name="fixml-components-root">
		<xso:simpleType name="Version_t">
			<xso:restriction base="xs:string">
				<xso:pattern value="(FIX.2.7)|(FIX.3.0)|(FIX\.4\.[0-4])|(FIX\.5\.0(SP[1-2]))|(FIXT.1.[1-2])"/>
			</xso:restriction>
		</xso:simpleType>
		<!-- Special case, generate required session component definitions (exception: StandardTrailer)-->
		<xsl:for-each select="/fixr:repository/fixr:components/fixr:component[@category='Session'and not(@name='StandardTrailer')]|/fixr:repository/fixr:groups/fixr:group[@category='Session']">
			<xsl:variable name="ComponentType">
				<xsl:choose>
					<!-- First test identifies repeating groups, otherwise it can only be a simple component but maybe XML data. -->
					<!-- Second test checks all fields of type XMLData for a field whose id is used as a field reference in the current component or group -->
					<xsl:when test="local-name(current()) = ('group','groupRef')">BlockRepeating</xsl:when>
					<xsl:when test="/fixr:repository/fixr:fields/fixr:field[@type='XMLData' and @id = current()/fixr:fieldRef/@id]">XMLDataBlock</xsl:when>
					<xsl:otherwise>Block</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:call-template name="GenerateElementSequence">
				<xsl:with-param name="ComponentType" select="$ComponentType"/>
			</xsl:call-template>
			<xsl:choose>
				<xsl:when test="@name='StandardHeader'">
					<xsl:call-template name="GenerateAttributeGroup">
						<xsl:with-param name="ComponentType" select="$ComponentType"/>
						<xsl:with-param name="MakeAllReferencesOptional" select="1"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="GenerateAttributeGroup">
						<xsl:with-param name="ComponentType" select="$ComponentType"/>
						<xsl:with-param name="MakeAllReferencesOptional" select="0"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:call-template name="GenerateComponent">
				<xsl:with-param name="ComponentType" select="$ComponentType"/>
			</xsl:call-template>
		</xsl:for-each>
		<!-- Message Header -->
		<xso:attributeGroup name="MessageHeaderAttributes"> </xso:attributeGroup>
		<xso:complexType name="MessageHeader_t">
			<xso:complexContent>
				<xso:extension base="BaseHeader_t">
					<xso:attributeGroup ref="MessageHeaderAttributes"/>
				</xso:extension>
			</xso:complexContent>
		</xso:complexType>
		<!-- BatchHeader -->
		<xso:group name="BatchHeaderElements">
			<xso:sequence/>
		</xso:group>
		<xso:attributeGroup name="BatchHeaderAttributes"/>
		<xso:complexType name="BatchHeader_t">
			<xso:complexContent>
				<xso:extension base="BaseHeader_t">
					<xso:sequence>
						<xso:group ref="BatchHeaderElements"/>
					</xso:sequence>
					<xso:attributeGroup ref="BatchHeaderAttributes"/>
				</xso:extension>
			</xso:complexContent>
		</xso:complexType>
		<!-- Message -->
		<xso:complexType name="Abstract_message_t">
			<xso:sequence>
				<xso:element name="Hdr" type="MessageHeader_t" minOccurs="0"/>
			</xso:sequence>
		</xso:complexType>
		<xso:element name="Message" type="Abstract_message_t" abstract="true"/>
		<!-- Batch -->
		<xso:group name="BatchElements">
			<xso:sequence>
				<xso:element name="Hdr" type="BatchHeader_t" minOccurs="0"/>
				<xso:element ref="Message" minOccurs="0" maxOccurs="unbounded"/>
			</xso:sequence>
		</xso:group>
		<xso:attributeGroup name="BatchAttributes">
	        <xso:attribute name="ID" type="BatchID_t" use="optional"/>
	        <xso:attribute name="TotMsg" type="BatchTotalMessages_t" use="optional"/>
	        <xso:attribute name="ProcMode" type="BatchProcessMode_enum_t" use="optional"/>
		</xso:attributeGroup>
		<xso:complexType name="Batch_t">
			<xso:sequence>
				<xso:group ref="BatchElements"/>
			</xso:sequence>
			<xso:attributeGroup ref="BatchAttributes"/>
		</xso:complexType>
		<!-- FIXML Root Element Declaration -->
		<!-- FIX version as of EP260 only "FIX.Latest"-->
		<xsl:variable name="VersionString" select="/fixr:repository/@name"/>
		<xsl:variable name="schemaDate" select="/fixr:repository/fixr:metadata/dc:date"/>
		<xso:attributeGroup name="FixmlAttributes">
			<xso:attribute name="v" type="Version_t" fixed="{$VersionString}"/>
			<xso:attribute name="r" type="xs:string" use="optional"/>
			<xso:attribute name="xv" type="xs:int" use="optional"/>
			<xso:attribute name="cv" type="xs:string" use="optional"/>
			<xso:attribute name="xr" type="xs:string" use="optional"/>
			<xso:attribute name="s" type="xs:date" fixed="{$schemaDate}"/>
		</xso:attributeGroup>
		<xso:element name="FIXML">
			<xso:complexType>
				<xso:choice>
					<xso:element ref="Message"/>
					<xso:element name="Batch" type="Batch_t" maxOccurs="unbounded"/>
				</xso:choice>
				<xso:attributeGroup ref="FixmlAttributes"/>
			</xso:complexType>
		</xso:element>
	</xsl:template>
	<!-- template to create a documentation node -->
	<xsl:template name="DocumentationBuilder">
		<xsl:param name="DocText"/>
		<xso:documentation>
			<xsl:value-of select="$DocText"/>
		</xso:documentation>
	</xsl:template>
	<xsl:template name="appinfo-Xref-builder">
		<xsl:param name="name"/>
		<xsl:param name="Tag"/>
		<xsl:param name="ComponentID"/>
		<xsl:param name="Type"/>
		<xsl:param name="ComponentType"/>
		<xsl:param name="AbbrName"/>
		<xsl:param name="Section"/>
		<xsl:param name="CategoryID"/>
		<xsl:param name="CategoryAbbrName"/>
		<xsl:param name="EnumDatatype"/>
		<xsl:variable name="VersionString" select="/fixr:repository/substring-after(@name,'.')"/>
		<xsl:variable name="schemaNamespace" select="concat('http://www.fixprotocol.org/FIXML-',$VersionString)"/>
		<xsl:variable name="fmNamespace" select="concat($schemaNamespace,'/METADATA')"/>
		<xso:appinfo>
			<xsl:element name="fm:Xref" namespace="{$fmNamespace}">
				<xsl:attribute name="Protocol">FIX</xsl:attribute>
				<xsl:if test="$name">
					<xsl:attribute name="name" select="$name"/>
				</xsl:if>
				<xsl:if test="$ComponentType">
					<xsl:attribute name="ComponentType" select="$ComponentType"/>
				</xsl:if>
				<xsl:if test="$Tag">
					<xsl:attribute name="Tag" select="$Tag"/>
				</xsl:if>
				<xsl:if test="$Type != ''">
					<xsl:attribute name="Type" select="$Type"/>
				</xsl:if>
				<!-- Exception: field is the original one with the code set (they share the same ID)-->
				<xsl:if test="$EnumDatatype and not($Tag = $EnumDatatype)">
					<xsl:attribute name="UsesEnumsFromTag" select="$EnumDatatype"/>
				</xsl:if>
				<xsl:if test="$AbbrName">
					<xsl:attribute name="AbbrName" select="$AbbrName"/>
				</xsl:if>
				<xsl:if test="$CategoryID">
					<xsl:attribute name="Category" select="$CategoryID"/>
				</xsl:if>
				<xsl:if test="$CategoryAbbrName">
					<xsl:attribute name="CategoryAbbrName" select="$CategoryAbbrName"/>
				</xsl:if>
			</xsl:element>
		</xso:appinfo>
	</xsl:template>
	<xsl:template name="MessageTemplate">
		<xsl:param name="MessageCategory"/>
		<xsl:for-each select="/fixr:repository/fixr:messages/fixr:message[@category=$MessageCategory]">
			<xsl:sort select="@id"/>
			<xsl:variable name="MessID" select="@id"/>
			<!-- Required Elements-->
			<xso:group name="{@name}Elements">
				<xso:sequence>
					<xsl:for-each select="/fixr:repository/fixr:messages/fixr:message[@id = $MessID]/fixr:structure/child::*">
					<xsl:choose>
						<xsl:when test="localfn:isComponent(current())">
							<xsl:variable name="component" select="/fixr:repository/fixr:components/fixr:component[@id=current()/@id]"/>
							<xsl:variable name="componentRef" select="/fixr:repository/fixr:messages/fixr:message[@id=$MessID]/fixr:structure/fixr:componentRef[@id=$component/@id]"/>
							<xsl:if test="$component/@name != 'StandardHeader' and $component/@name != 'StandardTrailer'">
								<xso:element name="{$component/@abbrName}" type="{localfn:generateCompType($component)}">
									<xsl:if test="not($componentRef/@presence = 'required')">
										<xsl:attribute name="minOccurs">0</xsl:attribute>
									</xsl:if>
								</xso:element>
							</xsl:if>
						</xsl:when>
						<xsl:when test="localfn:isGroup(current())">
							<xsl:variable name="group" select="/fixr:repository/fixr:groups/fixr:group[@id=current()/@id]"/>
							<xsl:variable name="groupRef" select="/fixr:repository/fixr:messages/fixr:message[@id=$MessID]/fixr:structure/fixr:groupRef[@id=$group/@id]"/>
							<xso:element name="{$group/@abbrName}" type="{localfn:generateCompType($group)}">
								<xsl:if test="not($groupRef/@presence = 'required')">
									<xsl:attribute name="minOccurs">0</xsl:attribute>
								</xsl:if>
								<xsl:attribute name="maxOccurs">unbounded</xsl:attribute>
							</xso:element>
						</xsl:when>
					</xsl:choose>
					</xsl:for-each>
				</xso:sequence>
			</xso:group>
			<!-- Required Attributes-->
			<xso:attributeGroup name="{@name}Attributes">
				<xsl:for-each select="/fixr:repository/fixr:messages/fixr:message[@id = $MessID]/fixr:structure/child::*">
					<!-- No special handling of fields for XML definitions of securities needed here as they are never on the meesage root level -->
					<xsl:if test="localfn:isField(current())">
						<xsl:variable name="field" select="/fixr:repository/fixr:fields/fixr:field[@id=current()/@id]"/>
						<xso:attribute>
							<xsl:choose>
								<xsl:when test="$field/@baseCategory = $MessageCategory">
									<xsl:attribute name="name" select="$field/@baseCategoryAbbrName"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:attribute name="name" select="$field/@abbrName"/>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:attribute name="type" select="concat($field/@name,'_t')"/>
							<xsl:choose>
								<xsl:when test="@presence = 'required'">
									<xsl:attribute name="use">required</xsl:attribute>
								</xsl:when>
								<xsl:otherwise>
									<xsl:attribute name="use">optional</xsl:attribute>
								</xsl:otherwise>
							</xsl:choose>
						</xso:attribute>
					</xsl:if>
				</xsl:for-each>
			</xso:attributeGroup>
			<xsl:variable name="VersionString" select="/fixr:repository/substring-after(@name,'.')"/>
			<xsl:variable name="schemaNamespace" select="concat('http://www.fixprotocol.org/FIXML-',$VersionString)"/>
			<xsl:variable name="fmNamespace" select="concat($schemaNamespace,'/METADATA')"/>
			<!-- Complex Type that implements message-->
			<xso:complexType name="{@name}_message_t" final="#all">
				<xsl:variable name="sid" select="/fixr:repository/fixr:categories/fixr:category[@name=$MessageCategory]/@section"/>
				<xso:annotation>
					<xso:documentation xml:lang="en">
						<xsl:value-of select="@name"/> can be found at https://www.fixtrading.org/online-specification/business-area-<xsl:value-of select="$sid"/>#msg<xsl:value-of select="@id"/>
					</xso:documentation>
					<xso:appinfo>
						<xsl:element name="fm:Xref" namespace="{$fmNamespace}">
							<xsl:attribute name="Protocol">FIX</xsl:attribute>
							<xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
							<xsl:attribute name="ComponentType">Message</xsl:attribute>
							<xsl:attribute name="MsgID"><xsl:value-of select="@id"/></xsl:attribute>
							<xsl:attribute name="Section"><xsl:value-of select="$sid"/></xsl:attribute>
							<xsl:attribute name="Category"><xsl:value-of select="$MessageCategory"/></xsl:attribute>
						</xsl:element>
					</xso:appinfo>
				</xso:annotation>
				<xso:complexContent>
					<xso:extension base="Abstract_message_t">
						<xso:sequence>
							<xso:group ref="{@name}Elements"/>
						</xso:sequence>
						<xso:attributeGroup ref="{@name}Attributes"/>
					</xso:extension>
				</xso:complexContent>
			</xso:complexType>
			<xso:element name="{@abbrName}" type="{@name}_message_t" substitutionGroup="Message" final="#all"/>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="ComponentTemplate">
		<xsl:param name="MessageCategory"/>
		<xsl:for-each select="/fixr:repository/fixr:components/fixr:component[@category=$MessageCategory]|/fixr:repository/fixr:groups/fixr:group[@category=$MessageCategory]">
			<xsl:sort select="@id"/>
			<xsl:variable name="ComponentType">
				<xsl:choose>
					<!-- First test identifies repeating groups, otherwise it can only be a simple component but maybe XML data. -->
					<!-- Second test checks all fields of type XMLData for a field whose id is used as a field reference in the current component or group -->
					<xsl:when test="local-name(current()) = ('group','groupRef')">BlockRepeating</xsl:when>
					<xsl:when test="/fixr:repository/fixr:fields/fixr:field[@type='XMLData' and @id = current()/fixr:fieldRef/@id]">XMLDataBlock</xsl:when>
					<xsl:otherwise>Block</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:call-template name="GenerateElementSequence">
				<xsl:with-param name="ComponentType" select="$ComponentType"/>
			</xsl:call-template>
			<xsl:call-template name="GenerateAttributeGroup">
				<xsl:with-param name="ComponentType" select="$ComponentType"/>
				<xsl:with-param name="MakeAllReferencesOptional" select="0"/>
			</xsl:call-template>
			<xsl:call-template name="GenerateComponent">
				<xsl:with-param name="ComponentType" select="$ComponentType"/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
	<!-- Generates the element statement for a component reference within an element sequence -->
	<xsl:template name="GenerateAnElement">
		<xsl:param name="component"/>
		<xsl:param name="presence"/>
			<xso:element name="{$component/@abbrName}" type="{localfn:generateCompType($component)}">
			<!-- Option 1: Only set minOccurs and maxOccurs when different from the default value 1 -->
				<!-- <xsl:if test="not($presence = 'required')">
					<xsl:attribute name="minOccurs">0</xsl:attribute>
				</xsl:if>
				<xsl:if test="local-name(current()) = 'group' or local-name(current()) = 'groupRef'">
					<xsl:attribute name="maxOccurs">unbounded</xsl:attribute>
				</xsl:if> -->
			<!-- Option 2: Explictly set minOccurs and maxOccurs regardless of default value -->
			<xsl:choose>
				<xsl:when test="not($presence = 'required')"><xsl:attribute name="minOccurs">0</xsl:attribute></xsl:when>
				<xsl:otherwise><xsl:attribute name="minOccurs">1</xsl:attribute></xsl:otherwise>
			</xsl:choose>
			<xsl:choose>
				<xsl:when test="local-name(current()) = ('group','groupRef')"><xsl:attribute name="maxOccurs">unbounded</xsl:attribute></xsl:when>
				<xsl:otherwise><xsl:attribute name="maxOccurs">1</xsl:attribute></xsl:otherwise>
			</xsl:choose>
			</xso:element>
	</xsl:template>
	<xsl:template name="SelectElements">
		<xsl:for-each select="current()/child::*">
		<xsl:choose>
			<xsl:when test="localfn:isComponent(.)">
				<xsl:variable name="component" select="/fixr:repository/fixr:components/fixr:component[@id=current()/@id]"/>
				<xsl:choose>
					<!-- Components are inlined if their abbreviated name is identical to their parent's in the given context (exceptions explicitly excluded) -->
					<!-- Example: InstrmtLegGrp contains InstrumentLeg -->
					<xsl:when test="$component/@abbrName = ../@abbrName and not(../@name='QuotReqLegsGrp')">

						<xsl:comment>Start of inlined elements from component: <xsl:value-of select="$component/@name"/> <xsl:value-of select="concat(' in ',../@name)"/>
						</xsl:comment>
						<xso:group ref="{localfn:fixupCompName($component)}Elements"/>
						<xsl:comment>End of inlined elements from component: <xsl:value-of select="$component/@name"/> <xsl:value-of select="concat(' in ',../@name)"/>
						</xsl:comment>
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="GenerateAnElement">
							<xsl:with-param name="component" select="$component"/>
							<xsl:with-param name="presence" select="current()/@presence"/>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="localfn:isGroup(.)">
				<xsl:variable name="group" select="/fixr:repository/fixr:groups/fixr:group[@id=current()/@id]"/>
				<xsl:call-template name="GenerateAnElement">
					<xsl:with-param name="component" select="$group"/>
					<xsl:with-param name="presence" select="current()/@presence"/>
				</xsl:call-template>
			</xsl:when>
		</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="GenerateElementSequence">
		<xsl:param name="ComponentType"/>
			<xsl:if test="not($ComponentType = 'XMLDataBlock')">
			<xso:group name="{localfn:fixupCompName(.)}Elements">
				<xso:sequence>
					<xsl:call-template name="SelectElements"/>
				</xso:sequence>
			</xso:group>
		</xsl:if>
	</xsl:template>
	<xsl:template name="GenerateAttribute">
		<xsl:param name="MakeAllReferencesOptional"/>
		<xsl:param name="TagID"/>
		<xsl:param name="MsgCategory"/>
		<xsl:param name="Presence"/>
		<xsl:variable name="field" select="/fixr:repository/fixr:fields/fixr:field[@id=$TagID]"/>
		<!-- Special handling of fields for XML definitions of securities required as only the XML schema fields are needed in FIXML -->
		<!-- Currently 8 exceptions: (Derivative/Underlying/Leg)SecurityXML(Len) -->
		<!-- Fields cannot be excluded based on type (data/Length/XMLData) as this would also exclude all EncodedXXX(Len) fields -->
		<xsl:if test="not(ends-with($field/@name,'SecurityXML') or ends-with($field/@name,'SecurityXMLLen'))">
			<xso:attribute>
				<xsl:choose>
					<xsl:when test="$field/@baseCategory=$MsgCategory">
						<xsl:attribute name="name" select="$field/@baseCategoryAbbrName"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:attribute name="name" select="$field/@abbrName"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:attribute name="type" select="concat($field/@name,'_t')"/>
				<xsl:choose>
					<!-- XXX HACK: Add the parameter to this method just to make it so
									 MsgSeqNum in the StandardHeader could be made optional -->
					<xsl:when test="$Presence='required' and $MakeAllReferencesOptional=0">
						<xsl:attribute name="use">required</xsl:attribute>
					</xsl:when>
					<xsl:otherwise>
						<xsl:attribute name="use">optional</xsl:attribute>
					</xsl:otherwise>
				</xsl:choose>
		</xso:attribute>
		</xsl:if>
	</xsl:template>
	<xsl:template name="SelectAttributes">
		<xsl:param name="ComponentType"/>
		<xsl:param name="MakeAllReferencesOptional"/>
		<xsl:param name="MessID"/>
		<xsl:param name="MsgCategory"/>
		<xsl:for-each select="child::*">
		  <xsl:variable name="TagID" select="@id"/>
			<xsl:choose>
				<xsl:when test="localfn:isField(.)">
				<xsl:variable name="field" select="/fixr:repository/fixr:fields/fixr:field[@id=$TagID]"/>
				<xsl:variable name="TYPE" select="$field/@type"/>
				<!-- Exclude standard header fields that are not applicable to FIXML or are covered by being part of the FIXML root element -->
				<xsl:if test="not($field/@name=('ApplExtID','BeginString','BodyLength','CstmApplVerID','LastMsgSeqNumProcessed','SecureData','SecureDataLen','XmlData','XmlDataLen'))">
					<xsl:call-template name="GenerateAttribute">
						<xsl:with-param name="MakeAllReferencesOptional" select="$MakeAllReferencesOptional"/>
						<xsl:with-param name="TagID" select="$TagID"/>
						<xsl:with-param name="MsgCategory" select="$MsgCategory"/>
						<xsl:with-param name="Presence" select="@presence"/>
					</xsl:call-template>
				</xsl:if>
			</xsl:when>
			<xsl:when test="localfn:isComponent(.)">
					<xsl:variable name="component" select="/fixr:repository/fixr:components/fixr:component[@id=$TagID]"/>
					<!-- Components are inlined if their abbreviated name is identical to their parent's in the given context (exceptions explicitly excluded) -->
					<!-- Example: InstrmtLegGrp contains InstrumentLeg -->
					<xsl:if test="$component/@abbrName = ../@abbrName and not(../@name='QuotReqLegsGrp')">

						<xsl:comment>Start of inlined attributes from component: <xsl:value-of select="$component/@name"/> <xsl:value-of select="concat(' in ',../@name)"/>
						</xsl:comment>
						<xso:attributeGroup ref="{localfn:fixupCompName($component)}Attributes"/>
						<xsl:comment>End of inlined attributes from component: <xsl:value-of select="$component/@name"/> <xsl:value-of select="concat(' in ',../@name)"/>
						</xsl:comment>
					</xsl:if>
				</xsl:when>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="GenerateAttributeGroup">
		<xsl:param name="ComponentType"/>
		<xsl:param name="MakeAllReferencesOptional"/>
		<xsl:variable name="MessID" select="@id"/>
		<xsl:variable name="MsgCategory" select="@category"/>
		<xso:attributeGroup name="{localfn:fixupCompName(.)}Attributes">
			<xsl:call-template name="SelectAttributes">
				<xsl:with-param name="ComponentType" select="$ComponentType"/>
				<xsl:with-param name="MakeAllReferencesOptional" select="$MakeAllReferencesOptional"/>
				<xsl:with-param name="MessID" select="$MessID"/>
				<xsl:with-param name="MsgCategory" select="$MsgCategory"/>
			</xsl:call-template>
		</xso:attributeGroup>
	</xsl:template>
	<xsl:template name="GenerateComponent">
		<xsl:param name="ComponentType"/>
		<xsl:variable name="MsgElemID" select="@id"/>
		<xso:complexType>
			<xsl:choose>
				<xsl:when test="@name='StandardHeader'">
					<xsl:attribute name="name">BaseHeader_t</xsl:attribute>
				</xsl:when>
				<xsl:otherwise>
					<xsl:attribute name="name"><xsl:value-of select="@name"/>_Block_t</xsl:attribute>
				</xsl:otherwise>
			</xsl:choose>
			<xso:annotation>
				<xsl:call-template name="appinfo-Xref-builder">
					<xsl:with-param name="name" select="@name"/>
					<xsl:with-param name="ComponentType" select="$ComponentType"/>
					<xsl:with-param name="CategoryID" select="@category"/>
				</xsl:call-template>
			</xso:annotation>
			<xso:sequence>
				<xsl:choose>
					<xsl:when test="$ComponentType = 'XMLDataBlock'">
						<xso:any>
							<xsl:attribute name="minOccurs">0</xsl:attribute>
							<xsl:attribute name="maxOccurs">unbounded</xsl:attribute>
							<xsl:attribute name="processContents">skip</xsl:attribute>
						</xso:any>
					</xsl:when>
					<xsl:otherwise>
						<xso:group>
							<xsl:attribute name="ref" select="concat(localfn:fixupCompName(.),'Elements')"/>
						</xso:group>
					</xsl:otherwise>
				</xsl:choose>
			</xso:sequence>
			<xso:attributeGroup>
				<xsl:attribute name="ref" select="concat(localfn:fixupCompName(.),'Attributes')"/>
			</xso:attributeGroup>
		</xso:complexType>
		<!--  End of complex type -->
	</xsl:template>
	<!-- builds the simpleType node for a field -->
	<xsl:template name="simpleTypeBuilder">
		<xsl:variable name="TAGNUM" select="@id"/>
		<xsl:variable name="TYPEORCODESETNAME" select="@type"/>
		<xsl:variable name="CODESET" select="/fixr:repository/fixr:codeSets/fixr:codeSet[@name=$TYPEORCODESETNAME]"/>
		<xsl:variable name="TYPE">
			<xsl:choose>
				<xsl:when test="$CODESET"><xsl:value-of select="$CODESET/@type"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="$CODESET">
			<xsl:comment>
				<xsl:value-of select="@name"/>(<xsl:value-of select="$TAGNUM"/>) defined in
				implementation file</xsl:comment>
		</xsl:if>

		<!-- create Field Type name - either _t or *_enum_t -->
		<xsl:variable name="TYPE_NAME">
			<xsl:value-of select="@name"/>
			<xsl:if test="$CODESET">
				<xsl:text>_enum</xsl:text>
			</xsl:if>
			<xsl:text>_t</xsl:text>
		</xsl:variable>
		<!-- create the simpleType element for this field -->
		<xso:simpleType>
			<xsl:attribute name="name"><xsl:value-of select="$TYPE_NAME"/></xsl:attribute>
			<xso:annotation>
				<!-- Elaboration is not retrieved -->
				<xsl:call-template name="DocumentationBuilder">
					<xsl:with-param name="DocText" select="current()/fixr:annotation/fixr:documentation[@purpose='SYNOPSIS']"/>
				</xsl:call-template>
				<xsl:call-template name="appinfo-Xref-builder">
					<xsl:with-param name="name" select="@name"/>
					<xsl:with-param name="Tag" select="@id"/>
					<xsl:with-param name="Type" select="$TYPE"/>
					<xsl:with-param name="ComponentType" select="'Field'"/>
					<xsl:with-param name="AbbrName" select="@abbrName"/>
					<xsl:with-param name="CategoryID" select="@baseCategory"/>
					<xsl:with-param name="CategoryAbbrName" select="@baseCategoryAbbrName"/>
					<!-- ID from codeset required for UsesEnumsFromTag attribute in FIXML -->
					<xsl:with-param name="EnumDatatype" select="$CODESET/@id"/>
				</xsl:call-template>
				<xsl:if test="$CODESET">
					<xsl:call-template name="AppinfoEnumsDocBuilder">
						<xsl:with-param name="CODES" select="$CODESET"/>
					</xsl:call-template>
				</xsl:if>
			</xso:annotation>
			<xsl:variable name="DATATYPE" select="/fixr:repository/fixr:datatypes/fixr:datatype[@name=$TYPE]"/>
			<xsl:variable name="OUTPUT_TYPE">
				<xsl:choose>
					<!-- Only use mapped datatype if the FIX datatype is a base XML datatype, e.g. int results in xs:integer. -->
					<xsl:when test="$DATATYPE/fixr:mappedDatatype[@standard='XML' and @builtin='true']">
						<xsl:value-of select="$DATATYPE/fixr:mappedDatatype[@standard='XML' and @builtin='true']/@base"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$TYPE"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xso:restriction>
				<xsl:attribute name="base" select="$OUTPUT_TYPE"/>
				<xsl:if test="$CODESET">
					<xsl:choose>
						<xsl:when test="$TYPE = 'MultipleCharValue'">
							<xsl:attribute name="base">xs:string</xsl:attribute>
							<xso:pattern>
								<xsl:variable name="PATTERN_STRING">
									<xsl:value-of>[</xsl:value-of>
									<xsl:for-each select="$CODESET/fixr:code">
										<xsl:sort select="@sort" data-type="number"/>
										<xsl:value-of select="@value"/>
									</xsl:for-each>
									<xsl:value-of>](\s[</xsl:value-of>
									<xsl:for-each select="$CODESET/fixr:code">
										<xsl:sort select="@sort" data-type="number"/>
										<xsl:value-of select="@value"/>
									</xsl:for-each>
									<xsl:value-of>])*</xsl:value-of>
								</xsl:variable>
								<xsl:attribute name="value" select="$PATTERN_STRING"/>
							</xso:pattern>
						</xsl:when>
						<xsl:when test="$TYPE = 'MultipleStringValue'">
							<xsl:attribute name="base">xs:string</xsl:attribute>
							<xso:pattern>
								<xsl:variable name="PATTERN_STRING">
									<xsl:value-of>(</xsl:value-of>
									<xsl:for-each select="$CODESET/fixr:code">
										<xsl:sort select="@sort" data-type="number"/>
										<xsl:value-of>(</xsl:value-of>
										<xsl:value-of select="@value"/>
										<xsl:value-of>)</xsl:value-of>
										<xsl:if test="position() &lt; count($CODESET/fixr:code)">
											<xsl:value-of>|</xsl:value-of>
										</xsl:if>
									</xsl:for-each>
									<xsl:value-of>)(\s(</xsl:value-of>
									<xsl:for-each select="$CODESET/fixr:code">
										<xsl:sort select="@sort" data-type="number"/>
										<xsl:value-of>(</xsl:value-of>
										<xsl:value-of select="@value"/>
										<xsl:value-of>)</xsl:value-of>
										<xsl:if test="position() &lt;  count($CODESET/fixr:code)">
											<xsl:value-of>|</xsl:value-of>
										</xsl:if>
									</xsl:for-each>
									<xsl:value-of>))*</xsl:value-of>
								</xsl:variable>
								<xsl:attribute name="value" select="$PATTERN_STRING"/>
							</xso:pattern>
						</xsl:when>
						<xsl:otherwise>
							<xsl:for-each select="$CODESET/fixr:code">
								<xsl:sort select="@sort" data-type="number"/>
								<xso:enumeration>
									<xsl:attribute name="value" select="@value"/>
								</xso:enumeration>
							</xsl:for-each>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
			</xso:restriction>
		</xso:simpleType>
	</xsl:template>
	<!-- generates an appinfo element with Code Set defined in the FIXML Schema Metadata file -->
	<xsl:template name="AppinfoEnumsDocBuilder">
		<xsl:param name="CODES"/>
		<xsl:variable name="VersionString" select="/fixr:repository/substring-after(@name,'.')"/>
		<xsl:variable name="schemaNamespace" select="concat('http://www.fixprotocol.org/FIXML-',$VersionString)"/>
		<xsl:variable name="fmNamespace" select="concat($schemaNamespace,'/METADATA')"/>
		<!-- Add enums appinfo section -->
		<xso:appinfo>
			<xsl:for-each select="$CODES/fixr:code">
				<xsl:sort select="@sort" data-type="number"/>
				<xsl:element name="fm:EnumDoc" namespace="{$fmNamespace}">
					<xsl:attribute name="value" select="@value"/>
					<!-- Name of the value (not the symbolic name) to be retrieved from its synopsis. Remove leading/trailing whitespaces -->
					<xsl:value-of select="normalize-space(current()/fixr:annotation/fixr:documentation[@purpose='SYNOPSIS'][1])"/>
				</xsl:element>
			</xsl:for-each>
		</xso:appinfo>
	</xsl:template>
	<xsl:template name="simple-type-restriction">
		<xsl:param name="TypeName"/>
		<xsl:param name="EnumTypeName"/>
		<xso:simpleType>
			<xsl:attribute name="name" select="concat($TypeName,'_t')"/>
			<xso:restriction>
				<xsl:attribute name="base" select="concat($EnumTypeName,'_enum_t')"/>
			</xso:restriction>
		</xso:simpleType>
	</xsl:template>
	<xsl:template name="simple-type-union">
		<xsl:param name="TypeName"/>
		<xsl:param name="EnumTypeName"/>
		<xsl:param name="UnionTypeName"/>
		<xso:simpleType>
			<xsl:attribute name="name" select="concat($TypeName,'_t')"/>
			<xso:union>
				<xsl:attribute name="memberTypes" select="concat($EnumTypeName,'_enum_t ',$UnionTypeName)"/>
			</xso:union>
		</xso:simpleType>
	</xsl:template>
	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="fixr:repository">
		<xsl:variable name="VersionString" select="substring-after(@name,'.')"/>
		<xsl:variable name="FileSuffix" select="concat('-',lower-case($VersionString),'.xsd')"/>
		<xsl:variable name="schemaNamespace" select="concat('http://www.fixprotocol.org/FIXML-',$VersionString)"/>
		<xsl:variable name="fmNamespace" select="concat($schemaNamespace,'/METADATA')"/>

		<!-- generate the metadata schema file -->
		<xsl:result-document href="{localfn:cleanUrl(concat($targetDir,'/','fixml-metadata',$FileSuffix))}">
			<xsl:call-template name="generation-info-comment-block"/>
			<xsl:text/>
			<xso:schema>
				<!-- create the namespace for the metadata -->
				<xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
				<xsl:namespace name="">
					<xsl:value-of select="$fmNamespace"/>
				</xsl:namespace>
				<xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
				<xsl:attribute name="targetNamespace"><xsl:value-of select="$fmNamespace"/></xsl:attribute>
				<xsl:attribute name="elementFormDefault">qualified</xsl:attribute>
				<xsl:attribute name="attributeFormDefault">unqualified</xsl:attribute>
				<xsl:comment>FIXML meta data</xsl:comment>
				<xso:element name="Xref">
					<xso:complexType>
						<xso:attribute name="Protocol" type="xs:string" use="optional"/>
						<xso:attribute name="name" type="xs:string" use="optional"/>
						<xso:attribute name="Tag" type="xs:positiveInteger" use="optional"/>
						<xso:attribute name="MsgID" type="xs:positiveInteger" use="optional"/>
						<xso:attribute name="Type" type="xs:string" use="optional"/>
						<xso:attribute name="ComponentType" type="xs:string" use="optional"/>
						<xso:attribute name="AbbrName" type="xs:string" use="optional"/>
						<xso:attribute name="Section" type="xs:string" use="optional"/>
						<xso:attribute name="Category" type="xs:string" use="optional"/>
						<xso:attribute name="CategoryAbbrName" type="xs:string" use="optional"/>
						<xso:attribute name="UsesEnumsFromTag" type="xs:string" use="optional"/>
					</xso:complexType>
				</xso:element>
				<xso:element name="EnumDoc">
					<xso:complexType>
						<xso:simpleContent>
							<xso:extension base="xs:string">
								<xso:attribute name="value" use="required" type="xs:string"/>
							</xso:extension>
						</xso:simpleContent>
					</xso:complexType>
				</xso:element>
			</xso:schema>
		</xsl:result-document>
		<!-- generate the main file -->
		<xsl:result-document href="{localfn:cleanUrl(concat($targetDir,'/','fixml-main',$FileSuffix))}">
			<xsl:call-template name="generation-info-comment-block"/>
			<xso:schema>
				<xsl:call-template name="fixml-namespace"/>
				<!-- get a list of the sections pretrade,trade,posttrade,infrastructure, etc.)-->
				<xsl:for-each select="/fixr:repository/fixr:sections/fixr:section[not(@name = 'Session')]/@FIXMLFileName">
					<xso:include schemaLocation="{concat('fixml-',.,$FileSuffix)}"/>
				</xsl:for-each>
			</xso:schema>
		</xsl:result-document>
		<!-- generate section files that contain includes for the categories -->
		<xsl:for-each select="/fixr:repository/fixr:sections/fixr:section[not(@name = 'Session')]">
			<xsl:result-document href="{localfn:cleanUrl(concat($targetDir,'/','fixml-',@FIXMLFileName,$FileSuffix))}">
				<xsl:call-template name="generation-info-comment-block"/>
				<xso:schema>
					<xsl:call-template name="fixml-namespace"/>
					<xsl:variable name="SectionID" select="@name"/>
					<xsl:for-each select="/fixr:repository/fixr:categories/fixr:category[@section = $SectionID]">
						<xso:include>
							<xsl:attribute name="schemaLocation"><xsl:value-of select="concat('fixml-',@FIXMLFileName,'-impl',$FileSuffix)"/></xsl:attribute>
						</xso:include>
					</xsl:for-each>
				</xso:schema>
			</xsl:result-document>
		</xsl:for-each>
		<!-- generate message category base files -->
		<xsl:for-each select="/fixr:repository/fixr:categories/fixr:category[@componentType='Message' and not(@name = 'Session')]">
			<xsl:variable name="fn">
				<xsl:value-of select="@FIXMLFileName"/>
			</xsl:variable>
			<xsl:result-document href="{localfn:cleanUrl(concat($targetDir,'/','fixml-',$fn,'-base',$FileSuffix))}">
				<xsl:variable name="FileName">
					<xsl:choose>
						<xsl:when test="@name = 'Common'">fields-impl</xsl:when>
						<xsl:otherwise>components-impl</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:call-template name="generation-info-comment-block"/>
				<xso:schema>
					<xsl:call-template name="fixml-namespace"/>
					<xso:include>
						<xsl:attribute name="schemaLocation"><xsl:value-of select="concat('fixml-',$FileName,$FileSuffix)"/></xsl:attribute>
					</xso:include>
					<xsl:if test="@name = 'Common'">
						<xsl:call-template name="fixml-components-root"/>
					</xsl:if>
					<xsl:call-template name="MessageTemplate">
						<xsl:with-param name="MessageCategory" select="@name"/>
					</xsl:call-template>
					<xsl:call-template name="ComponentTemplate">
						<xsl:with-param name="MessageCategory" select="@name"/>
					</xsl:call-template>
				</xso:schema>
			</xsl:result-document>
		</xsl:for-each>
		<!-- generate message category impl files -->
		<xsl:for-each select="/fixr:repository/fixr:categories/fixr:category[@componentType='Message' and not(@name = 'Session')]/@FIXMLFileName">
			<xsl:result-document href="{localfn:cleanUrl(concat($targetDir,'/','fixml-',.,'-impl',$FileSuffix))}">
				<xsl:call-template name="generation-info-comment-block"/>
				<xso:schema>
					<xsl:call-template name="fixml-namespace"/>
					<xso:include>
						<xsl:attribute name="schemaLocation"><xsl:value-of select="concat('fixml-',.,'-base',$FileSuffix)"/></xsl:attribute>
					</xso:include>
				</xso:schema>
			</xsl:result-document>
		</xsl:for-each>
		<!-- generate fields base files -->
		<xsl:result-document href="{localfn:cleanUrl(concat($targetDir,'/fixml-fields-base',$FileSuffix))}">
			<xsl:call-template name="generation-info-comment-block"/>
			<xso:schema>
				<xsl:call-template name="fixml-namespace"/>
				<xso:include>
					<xsl:attribute name="schemaLocation" select="concat('fixml-datatypes',$FileSuffix)"/>
				</xso:include>
				<!-- Special handling of fields for XML definitions of securities required as only the XML schema fields are needed in FIXML -->
				<!-- Currently 10 exceptions: (Derivative/Underlying/Leg)SecurityXML(Len), SecureDataLen, SecureData, XmlDataLen, XmlData -->
				<!-- <xsl:for-each select="/fixr:repository/fixr:fields/fixr:field[not(@type='NumInGroup' or
					@name=('BeginString','BodyLength','ApplExtID','CstmApplVerID','LastMsgSeqNumProcessed') or
					ends-with(@name,'SecurityXML') or ends-with(@name,'SecurityXMLLen') or
					starts-with(@name,'SecureData') or starts-with(@name,'XmlData'))]"> -->
				<xsl:for-each select="/fixr:repository/fixr:fields/fixr:field[not(current()/fixr:annotation/fixr:appinfo[@purpose='FIXML']/fixml:FIXMLencodingType[@notReqXML='1'])]">
					<xsl:sort select="@id" data-type="number" order="ascending"/>
					<xsl:variable name="TAGNUM" select="@id"/>
					<!-- Look for a reference to the given field in components, groups and messages that have a category other than "Session" -->
					<!-- Exceptions for category "Session": component StandardHeader (partially, see above), group HopGrp -->
					<xsl:variable name="COMPREF" select="/fixr:repository/fixr:components/fixr:component[not(@category='Session') or @name='StandardHeader']/fixr:fieldRef[@id=$TAGNUM]"/>
					<xsl:variable name="GROUPREF" select="/fixr:repository/fixr:groups/fixr:group[not(@category='Session') or @name='HopGrp']/fixr:fieldRef[@id=$TAGNUM]/@id"/>
					<xsl:variable name="MSGREF" select="/fixr:repository/fixr:messages/fixr:message[not(@category='Session')]/fixr:structure/fixr:fieldRef[@id=$TAGNUM]"/>
					<!-- If the search is successful in any one of them, then the field is (also) used outside of the session category -->
					<!-- Exceptions: create simple types for FIXML batch header and other fields explicitly listed below -->
					<!-- XXX: to be confirmed why they should be part of FIXML -->
					<xsl:if test="$COMPREF or $GROUPREF or $MSGREF or
						starts-with(@name,'Batch') or
						@name=('DefaultApplExtID','DefaultApplVerID','DefaultVerIndicator','RefTagID','SessionStatus')" >
						<xsl:call-template name="simpleTypeBuilder"/>
					</xsl:if>
				</xsl:for-each>
			</xso:schema>
		</xsl:result-document>
		<!-- generate fields impl files -->
		<xsl:result-document href="{localfn:cleanUrl(concat($targetDir,'/fixml-fields-impl',$FileSuffix))}">
			<xsl:call-template name="generation-info-comment-block"/>
			<xso:schema>
				<xsl:call-template name="fixml-namespace"/>
				<xso:include>
					<xsl:attribute name="schemaLocation"><xsl:value-of select="concat('fixml-fields-base',$FileSuffix)"/></xsl:attribute>
				</xso:include>
				<xsl:for-each select="/fixr:repository/fixr:fields/fixr:field">
					<xsl:sort select="@id" data-type="number" order="ascending"/>
					<xsl:variable name="FldTag" select="@id"/>
					<xsl:variable name="TYPEORCODESETNAME" select="@type"/>
					<xsl:variable name="CODESET" select="/fixr:repository/fixr:codeSets/fixr:codeSet[@name=$TYPEORCODESETNAME]"/>
					<xsl:choose>
						<xsl:when test="$CODESET">
							<xsl:choose>
								<xsl:when test="@unionDataType">
									<xsl:call-template name="simple-type-union">
										<xsl:with-param name="TypeName" select="@name"/>
										<!-- Strip "CodeSet" from the enumeration type name to avoid change to FIXML schema generated from Basis repository -->
										<xsl:with-param name="EnumTypeName" select="substring-before(@type,'CodeSet')"/>
										<xsl:with-param name="UnionTypeName" select="@unionDataType"/>
									</xsl:call-template>
								</xsl:when>
								<xsl:otherwise>
									<xsl:call-template name="simple-type-restriction">
										<xsl:with-param name="TypeName" select="@name"/>
										<!-- Strip "CodeSet" from the enumeration type name to avoid change to FIXML schema generated from Basis repository -->
										<xsl:with-param name="EnumTypeName" select="substring-before(@type,'CodeSet')"/>
									</xsl:call-template>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
					</xsl:choose>
				</xsl:for-each>
			</xso:schema>
		</xsl:result-document>
		<!-- generate datatypes files -->
		<xsl:result-document href="{localfn:cleanUrl(concat($targetDir,'/fixml-datatypes',$FileSuffix))}">
			<xsl:call-template name="generation-info-comment-block"/>
			<xso:schema>
				<xsl:call-template name="fixml-namespace"/>
				<xsl:for-each select="/fixr:repository/fixr:datatypes/fixr:datatype">
					<!-- Only use mapped datatype if it is not already a base XML datatype. -->
					<xsl:if test="child::fixr:mappedDatatype[@standard='XML' and @builtin='false']">
						<xso:simpleType>
							<xsl:attribute name="name" select="@name"/>
							<xso:annotation>
								<xso:documentation>
									<xsl:value-of select="child::fixr:mappedDatatype/fixr:annotation/fixr:documentation"/>
								</xso:documentation>
							</xso:annotation>
							<xsl:if test="child::fixr:mappedDatatype[@standard='XML']/@base">
								<xso:restriction>
									<xsl:attribute name="base" select="child::fixr:mappedDatatype[@standard='XML']/@base"/>
									<xsl:if test="child::fixr:mappedDatatype[@standard='XML']/@pattern">
										<xso:pattern>
											<xsl:attribute name="value" select="child::fixr:mappedDatatype[@standard='XML']/@pattern"/>
										</xso:pattern>
									</xsl:if>
									<xsl:if test="child::fixr:mappedDatatype[@standard='XML']/@minInclusive">
										<xso:minInclusive>
											<xsl:attribute name="value" select="child::fixr:mappedDatatype[@standard='XML']/@minInclusive"/>
										</xso:minInclusive>
									</xsl:if>
								</xso:restriction>
							</xsl:if>
						</xso:simpleType>
					</xsl:if>
				</xsl:for-each>
			</xso:schema>
		</xsl:result-document>
	</xsl:template>
</xsl:stylesheet>
