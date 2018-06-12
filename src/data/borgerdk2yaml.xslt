<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
    <xsl:output method="text" omit-xml-declaration="yes" indent="no"/>

    <xsl:strip-space elements="*"/>

    <xsl:variable name="rootid" select="/item/@id"/>


    <xsl:template match="/"># Organisation and their points of contact from borger.dk as of 20180501
        <xsl:apply-templates />
    </xsl:template>


<xsl:template match="item[@template='municipalauthority'] | item[@template='authority']">
    <xsl:variable name="thisid" select="@id" />
    <xsl:variable name="parentid" select="@parentid"/>
    <xsl:result-document href="org/{replace($thisid,'[{}]','')}.yaml">
'@context'         : ./context.json
'@id'              : https://data.gov.dk/id/organisation/<xsl:value-of select="replace($thisid,'[{}]','')"/>
'id'               : <xsl:value-of select="replace($thisid,'[{}]','')"/>
prefLabel          : "<xsl:value-of select="version/fields/field[@key='__display name']/content"/>"
prefLabel_en       :
altLabel           :
description        : "<xsl:value-of select="version/fields/field[@key='description']/content"/>"
authorityCode      :
municipalityCode   : <xsl:value-of select="version/fields/field[@key='municipalitycode']/content"/>
regionCode         :
po-classification  : <xsl:choose>
        <xsl:when test=" @template='municipalauthority'">"Kommune"</xsl:when>
        <xsl:when test="starts-with(@name,'Region-')">"Region"</xsl:when>
        <xsl:when test="$rootid = $parentid">"Anden Myndighed"</xsl:when>
        <xsl:otherwise>...</xsl:otherwise></xsl:choose>
actsThrough        : cvr:/<xsl:value-of select="version/fields/field[@key='cvr']/content"/>
<xsl:for-each select="//item[@parentid=$thisid and @template='authority'] | //item[@parentid=$thisid and @template='municipalitiauthority']" >
<xsl:if test="position() = 1 ">
hasSubOrganization :</xsl:if>
    - '@id'      : https://data.gov.dk/id/organisation/<xsl:value-of select="replace(@id,'[{}]','')"/>
      id         : <xsl:value-of select="replace(@id,'[{}]','')"/>
      prefLabel  : "<xsl:value-of select="./version/fields/field[@key='__display name']/content"/>"
</xsl:for-each>
<xsl:if test="$rootid != $parentid">
isSubOrganizationOf:
    - '@id'      : https://data.gov.dk/id/organisation/<xsl:value-of select="replace($parentid,'[{}]','')"/>
      id         : <xsl:value-of select="replace($parentid,'[{}]','')"/>
      prefLabel  : "<xsl:value-of select="/item/item[@id=$parentid]/version/fields/field[@key='__display name']/content"/>"
</xsl:if>
contactpoint :
    - autoritativeClassificationRefencence  : '*'
      hasContactChannel  :<xsl:apply-templates select="item[@name='Phone']" />
    <xsl:apply-templates select="item[@name='Email']" />
    <xsl:apply-templates select="item[@name='Homepage']" />
    <xsl:apply-templates select="item[@name='Physical']" />
    <xsl:text>&#xA;</xsl:text>
    <xsl:text>&#xA;</xsl:text>
<!--    <xsl:for-each select="version/fields/field">
        <xsl:text></xsl:text>
        <xsl:value-of select="@key"/> : <xsl:value-of select="content"/>
        <xsl:text>&#xA;</xsl:text>
    </xsl:for-each>
-->
</xsl:result-document>
    <xsl:apply-templates select="item[@template='municipalauthority'] | item[@template='authority']" />
</xsl:template>



<xsl:template match="item[@name='Phone']">
       - channeltype    : "phone"
         channeladdress : "<xsl:value-of select="version/fields/field[@key='telephonenumber']/content"/>"
         <xsl:if test="version/fields/field[starts-with(@key, 'opening')]">
         hoursAvailable  :
             - "Mo <xsl:value-of select="version/fields/field[@key='openingtimemonday']/content"/>-<xsl:value-of select="version/fields/field[@key='closingtimemonday']/content"/>"
             - "Tu <xsl:value-of select="version/fields/field[@key='openingtimetuesday']/content"/>-<xsl:value-of select="version/fields/field[@key='closingtimetuesday']/content"/>"
             - "We <xsl:value-of select="version/fields/field[@key='openingtimewednesday']/content"/>-<xsl:value-of select="version/fields/field[@key='closingtimewednesday']/content"/>"
             - "Th <xsl:value-of select="version/fields/field[@key='openingtimethursday']/content"/>-<xsl:value-of select="version/fields/field[@key='closingtimethursday']/content"/>"
             - "Fr <xsl:value-of select="version/fields/field[@key='openingtimefriday']/content"/>-<xsl:value-of select="version/fields/field[@key='closingtimefriday']/content"/>"
             - "Sa <xsl:value-of select="version/fields/field[@key='openingtimesaturday']/content"/>-<xsl:value-of select="version/fields/field[@key='closingtimesaturday']/content"/>"
             - "Su <xsl:value-of select="version/fields/field[@key='openingtimesunday']/content"/>-<xsl:value-of select="version/fields/field[@key='closingtimesunday']/content"/>"
         </xsl:if>


</xsl:template>

<xsl:template match="item[@name='Email']">
       - channeltype    : "email"
         channeladdress : "<xsl:value-of select="version/fields/field[@key='email']/content"/>"
</xsl:template>

<xsl:template match="item[@name='Homepage']">
       - channeltype    : "web"
         channeladdress : <xsl:value-of select="version/fields/field[@key='website']/content"/>
</xsl:template>

<xsl:template match="item[@name='Stamadresse']">
       - channeltype    : "physical"
         address :
            streetname : <xsl:value-of select="version/fields/field[@key='streetname']/content"/>
            number     : <xsl:value-of select="version/fields/field[@key='housenumber']/content"/>
            postal     : <xsl:value-of select="version/fields/field[@key='postcode']/content"/>
            city       : <xsl:value-of select="version/fields/field[@key='district']/content"/>

</xsl:template>

    <xsl:template match="content" />

</xsl:stylesheet>
