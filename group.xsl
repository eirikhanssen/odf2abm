<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs" version="2.0">
    <xsl:output method="xml" indent="yes"/>

    <xsl:variable name="publication-meta-entries">
        <meta>
            <xsl:call-template name="publication-meta-entry"/>
        </meta>
    </xsl:variable>

    <xsl:variable name="isbn" select="$publication-meta-entries/*/isbn" as="xs:string"/>

    <xsl:variable name="image-extension">
        <xsl:value-of select="concat('.',substring-after(/*/cover-image/@original-href, '.'))"/>
    </xsl:variable>

    <xsl:template match="publication">
        <publication>
            <meta>
                <xsl:apply-templates select="publication-title, cover-image"/>
                <xsl:sequence select="$publication-meta-entries/*/*"/>
                <summary>
                    <xsl:apply-templates select="summary-para"/>
                </summary>
                <about>
                    <xsl:apply-templates select="about-para"/>
                </about>
            </meta>
        </publication>
    </xsl:template>

    <xsl:template match="summary-para | about-para">
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    

    <xsl:template match="publication-title">
        <title>
            <xsl:apply-templates/>
        </title>
    </xsl:template>
    
    <xsl:template match="cover-image">
        <cover-image>
            <xsl:attribute name="href"><xsl:text>img/</xsl:text><xsl:value-of select="concat($isbn, $image-extension)"/></xsl:attribute>
        </cover-image>
    </xsl:template>
    
    <xsl:template match="publication-meta-entry|h2"/>

    <xsl:template name="publication-meta-entry">
        <xsl:for-each select="//publication-meta-entry">
            <xsl:variable name="isAuthor" select="matches(normalize-space(lower-case(.)),'^forfatter:')"/>
            <xsl:variable name="isISBN" select="matches(normalize-space(lower-case(.)),'^isbn:')"/>
            <xsl:variable name="isKeywords" select="matches(normalize-space(lower-case(.)),'^emneord:')"/>
            <xsl:variable name="isLanguage" select="matches(normalize-space(lower-case(.)),'^språk:')"/>
            <xsl:variable name="isYearPublished" select="matches(normalize-space(lower-case(.)),'^utgitt:')"/>
            <xsl:variable name="isPublisher" select="matches(normalize-space(lower-case(.)),'^forlag:')"/>
            <xsl:variable name="isEdition" select="matches(normalize-space(lower-case(.)),'^utgave:')"/>
            <xsl:variable name="isPageCount" select="matches(normalize-space(lower-case(.)),'^ant. sider:')"/>
            <xsl:variable name="isPrice" select="matches(normalize-space(lower-case(.)),'^pris:')"/>
            <xsl:variable name="metacontent" select="normalize-space(substring-after(.,':'))" as="xs:string"/>
            <xsl:choose>
                <xsl:when test="$isAuthor eq true()">
                    <xsl:variable name="elName" select="'author'"/>
                    <xsl:element name="{$elName}"><xsl:value-of select="$metacontent" /></xsl:element>
                </xsl:when>
                <xsl:when test="$isISBN eq true()">
                    <xsl:variable name="elName" select="'isbn'"/>
                    <xsl:element name="{$elName}"><xsl:value-of select="$metacontent" /></xsl:element>
                </xsl:when>
                <xsl:when test="$isKeywords eq true()">
                    <xsl:variable name="elName" select="'keywords'"/>
                    <xsl:element name="{$elName}"><xsl:value-of select="$metacontent" /></xsl:element>
                </xsl:when>
                <xsl:when test="$isLanguage eq true()">
                    <xsl:variable name="elName" select="'language'"/>
                    <xsl:element name="{$elName}"><xsl:value-of select="$metacontent" /></xsl:element>
                </xsl:when>
                <xsl:when test="$isYearPublished eq true()">
                    <xsl:variable name="elName" select="'pub-year'"/>
                    <xsl:element name="{$elName}"><xsl:value-of select="$metacontent" /></xsl:element>
                </xsl:when>
                <xsl:when test="$isPublisher eq true()">
                    <xsl:variable name="elName" select="'publisher-name'"/>
                    <xsl:element name="{$elName}"><xsl:value-of select="$metacontent" /></xsl:element>
                </xsl:when>
                <xsl:when test="$isEdition eq true()">
                    <xsl:variable name="elName" select="'edition'"/>
                    <xsl:element name="{$elName}"><xsl:value-of select="$metacontent" /></xsl:element>
                </xsl:when>
                <xsl:when test="$isPageCount eq true()">
                    <xsl:variable name="elName" select="'pagecount'"/>
                    <xsl:element name="{$elName}"><xsl:value-of select="$metacontent" /></xsl:element>
                </xsl:when>
                <xsl:when test="$isPrice eq true()">
                    <xsl:variable name="elName" select="'price'"/>
                    <xsl:element name="{$elName}"><xsl:value-of select="$metacontent" /></xsl:element>
                </xsl:when>
            </xsl:choose>    
        </xsl:for-each>
    </xsl:template>

    <!--<xsl:template match="node() | @*">
        <!-\- if it has preceding ref nodes, and it is not a ref node itself, then copy to the appendix -\->
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>-->

</xsl:stylesheet>
