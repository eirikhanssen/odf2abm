﻿<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:mml="http://www.w3.org/1998/Math/MathML"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
    xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
    xmlns:sm="https://github.com/eirikhanssen/odf2jats/stylemap"
    xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
    xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
    exclude-result-prefixes="xs sm style office text table fo draw svg mml xsi xlink">
    <xsl:output method="xml" indent="yes"/>
    <xsl:param name="documentStylesPath"/>

    <xsl:variable name="style:style_defs" as="element(style:style)+">
        <xsl:sequence select="//style:style, doc($documentStylesPath)//style:style"/>
    </xsl:variable>
    
    <xsl:variable name="text:list-style_defs" as="element(text:list-style)+">
        <xsl:sequence select="//text:list-style, doc($documentStylesPath)//text:list-style"/>
    </xsl:variable>

    <xsl:variable name="style-map"
        select="doc('')/xsl:stylesheet/sm:styles/sm:style" as="element(sm:style)+"/>

    <xsl:template match="/">
        <publication>
            <xsl:apply-templates/>
        </publication>
    </xsl:template>

    <xsl:template match="text:p">
        <!-- Use the $style-map lookup to define what elements should be generated -->

        <xsl:variable
            name="current_style_index_name"
            select="if(current()/@text:style-name) then (current()/@text:style-name) else('')"
            as="xs:string"/>
        
        <xsl:variable name="current_automatic_style"
            select="/office:document-content/office:automatic-styles/style:style[@style:name=$current_style_index_name]" 
            as="element(style:style)?"/>

        <xsl:variable name="current_stylename" 
            select="
                if (matches(current()/@text:style-name, '^P\d'))
                then ($current_automatic_style/@style:parent-style-name)
                else (
                    if(current()/@text:style-name) then (current()/@text:style-name) else('')
                )
            " as="xs:string"/>

        <xsl:variable name="elementName" as="xs:string?">
            <xsl:choose>
                <xsl:when test="$style-map[sm:name=$current_stylename]">
                    <xsl:value-of select="$style-map[sm:name=$current_stylename]/sm:transformTo"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>Style name match not found</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable> 

        <xsl:choose>
            <!-- if text:p is empty, don't output anything -->
            <xsl:when test=".='' and not(element())">
                <xsl:message>removed empty element: text:p</xsl:message>
            </xsl:when>
            <xsl:when test="$elementName = 'p' and
                $current_automatic_style/style:text-properties[@fo:font-style='italic']">
                    <xsl:element name="{$elementName}">
                        <italic><xsl:apply-templates/></italic>
                    </xsl:element>
            </xsl:when>
            <xsl:when test="$elementName !=''">
                <xsl:element name="{$elementName}">
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <!-- paragraphs without a style in the style-mapping should just transform to p elements -->
                    <xsl:element name="p">
                        <xsl:if test="matches($current_stylename, '[^\s]+')">
                            <xsl:attribute name="style">
                                <xsl:value-of select="$current_stylename"/>
                            </xsl:attribute>
                            <xsl:message>
                                <xsl:text>Not mapped - text:p[@style='</xsl:text>
                                <xsl:value-of select="$current_stylename"/>
                                <xsl:text>'] &#xa;Textcontent: </xsl:text>
                                <xsl:value-of select="substring(./text()[1],1,30)"/>
                                <xsl:if test="string-length( . /text()[1]) &gt; 30">
                                    <xsl:text> …</xsl:text>
                                </xsl:if>
                            </xsl:message>
                        </xsl:if>
                        <xsl:apply-templates/>
                    </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="text:list">
        <xsl:variable name="this" select="."/>
        <xsl:variable name="text:style-name" select="ancestor-or-self::text:list[@text:style-name][1]/@text:style-name" as="xs:string?"/>

        <!--
            Figure out the type of list, and set the optional @list-type=
            "order|bullet|alpha-lower|alpha-upper|roman-lower|roman-upper|simple"
 
            The root (topmost) text:list will have a @text:style-name referring to a list definition 
            with definitions for up to 10 sublevels of lists. decendant text:list will not have @text:style-name

            Determining list level:
            If a <text:list> element has a @text:style-name then it is a lvl 1 list.
            If it doesn't, then count all ancestor-or-self::text:list that don't have this attribute and add 1.
            (the ancestor that has @text:style-name).
        -->

        <xsl:variable name="list-type" as="xs:string?">
            <xsl:choose>
                <xsl:when test="not(empty(@text:style-name))">
                    <xsl:variable name="list-level" select="1"/>
                    <xsl:choose>
                        <xsl:when test="
                            $text:list-style_defs[@style:name eq $text:style-name]/text:list-level-style-bullet[xs:integer(@text:level) eq $list-level]">
                            <xsl:text>bullet</xsl:text>
                        </xsl:when>
                        <xsl:when test="
                            $text:list-style_defs[@style:name eq $text:style-name]/text:list-level-style-number[xs:integer(@text:level) eq $list-level]">
                            <xsl:variable name="num-format" select="$text:list-style_defs[@style:name eq $text:style-name]/text:list-level-style-number[xs:integer(@text:level) eq $list-level]/@style:num-format" as="xs:string"/>
                            <xsl:choose>
                                <xsl:when test="$num-format = 'a'">alpha-lower</xsl:when>
                                <xsl:when test="$num-format = 'A'">alpha-upper</xsl:when>
                                <xsl:when test="$num-format = 'i'">roman-lower</xsl:when>
                                <xsl:when test="$num-format = 'I'">roman-upper</xsl:when>
                                <xsl:when test="$num-format = '1'">order</xsl:when>
                                <xsl:otherwise>order<xsl:message>Unknown text:list-level-style-number/@style:num-format was encountered. Defaulting to 'order'</xsl:message></xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise><xsl:message>Didn't find a list type for top level list!! This is probably an error. Contact the developer.</xsl:message></xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="empty(@text:style-name)">
                    <xsl:variable name="list-level" select="count(ancestor-or-self::text:list[empty(@text:style-name)])+1"/>
                    <xsl:choose>
                        <xsl:when test="
                            $text:list-style_defs[@style:name eq $text:style-name]/text:list-level-style-bullet[xs:integer(@text:level) eq $list-level]">
                            <xsl:text>bullet</xsl:text>
                        </xsl:when>
                        <xsl:when test="
                            $text:list-style_defs[@style:name eq $text:style-name]/text:list-level-style-number[xs:integer(@text:level) eq $list-level]">
                            <xsl:variable name="num-format" select="$text:list-style_defs[@style:name eq $text:style-name]/text:list-level-style-number[xs:integer(@text:level) eq $list-level]/@style:num-format" as="xs:string"/>
                            <xsl:choose>
                                <xsl:when test="$num-format = 'a'">alpha-lower</xsl:when>
                                <xsl:when test="$num-format = 'A'">alpha-upper</xsl:when>
                                <xsl:when test="$num-format = 'i'">roman-lower</xsl:when>
                                <xsl:when test="$num-format = 'I'">roman-upper</xsl:when>
                                <xsl:when test="$num-format = '1'">order</xsl:when>
                                <xsl:otherwise>order<xsl:message>Unknown text:list-level-style-number/@style:num-format was encountered. Defaulting to 'order'</xsl:message></xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>Didn't find a list type for top level list!! This is probably an error. Contact the developer.</xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>

        <xsl:element name="list">
            <xsl:if test="not(empty($list-type))">
                <xsl:attribute name="list-type">
                    <xsl:value-of select="$list-type"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:element>

    </xsl:template>

    <!-- insert a | character when encountering text:tab in a p that has the paragraph style ArticleIdentifiers -->
    <xsl:template match="text:tab[ancestor::text:p[@text:style-name='ArticleIdentifiers']]"><xsl:text>|</xsl:text></xsl:template>

    <xsl:template match="text:list-item">
        <list-item><xsl:apply-templates/></list-item>
    </xsl:template>

    <!--
        footnotes and endnotes are mapped to xref and fn elements used in JATS
        in the place where the footnote/endnote is located in odf.
        Later in the pipeline all the fn elements (that are not part of a table's footnote group)
        should be put in the back/fn-group section, leaving just the xref elements referring to the
        footnotes in place.
    -->
    <xsl:template match="text:note">
        <sup>
            <xsl:element name="xref">
                <xsl:attribute name="ref-type" select="'fn'"/>
                <xsl:attribute name="rid" select="@text:id"/>
                <xsl:apply-templates select="text:note-citation"/>
            </xsl:element>
        </sup>
        <xsl:element name="fn">
            <xsl:attribute name="id" select="@text:id"/>
            <xsl:apply-templates select="text:note-body"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="text:h">
        <!-- store the outline_level in a variable, default to 1 -->
        <xsl:variable name="outline_level" select="if (current()/@text:outline-level) then (current()/@text:outline-level) else (1)" as="xs:integer"/>
        
        <xsl:variable
            name="current_style_index_name"
            select="if(current()/@text:style-name) then (current()/@text:style-name) else('')"
            as="xs:string"/>
        
        <xsl:variable name="current_automatic_style"
            select="/office:document-content/office:automatic-styles/style:style[@style:name=$current_style_index_name]" 
            as="element(style:style)?"/>

        <xsl:variable name="current_stylename" 
            select="
            if (matches(current()/@text:style-name, '^P\d'))
            then ($current_automatic_style/@style:parent-style-name)
            else (
            if(current()/@text:style-name) then (current()/@text:style-name) else('')
            )
            " as="xs:string"/>

        <xsl:variable name="elementName" as="xs:string">
            <!-- if outline level is 1, check the style name -->
            <xsl:choose>
                <xsl:when test="$outline_level = 1">
                    <xsl:choose>
                        <xsl:when test="$style-map[sm:name=current()/@text:style-name]">
                            <xsl:value-of select="$style-map[sm:name=current()/@text:style-name]/sm:transformTo"/>
                        </xsl:when>
                        <xsl:when test="$style-map[sm:name=$current_stylename]">
                            <xsl:value-of select="$style-map[sm:name=$current_stylename]/sm:transformTo"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat('h', $outline_level)"/>
                            <xsl:message> created a h1 element poof</xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('h', $outline_level)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$elementName}">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="table:table">
        <!-- Determine what number table this is in the document order, and use this number when generating table id -->
        <xsl:variable name="table_total_count" select="count(//table:table)" as="xs:integer"/>
        <xsl:variable name="table_after_count" select="count(following::table:table|descendant::table:table)" as="xs:integer"/>
        <xsl:variable name="table_num" select="$table_total_count - $table_after_count" as="xs:integer"/>
        <xsl:variable name="table-id" select="concat('tbl' , string($table_num))" as="xs:string"/>
        <table-wrap id="{$table-id}">
            <label>____</label><xsl:comment> optional label and caption </xsl:comment>
            <caption><p>____</p></caption>
            <table>
                <xsl:apply-templates select="table:table-header-rows"/>
                <tbody>
                    <xsl:apply-templates select="table:table-row[not(parent::table:table-header-rows)]"/>
                </tbody>
            </table>
        </table-wrap>
    </xsl:template>

    <xsl:template match="table:table-header-rows">
        <thead>
            <xsl:apply-templates/>
        </thead>
    </xsl:template>

    <xsl:template match="table:table-row">
        <tr>
            <xsl:apply-templates/>
        </tr>
    </xsl:template>

    <xsl:template match="table:table-cell[not(ancestor::table:table-header-rows)]">
        <td>
            <xsl:apply-templates/>
        </td>
    </xsl:template>

    <xsl:template match="table:table-cell[ancestor::table:table-header-rows]">
        <th>
            <xsl:apply-templates/>
        </th>
    </xsl:template>

    <!-- Preserve italic and bold text -->
    <xsl:template match="text:span">
        <xsl:variable name="mapped-style-def" select="$style:style_defs[@style:name = current()/@text:style-name]/style:text-properties" as="element(style:text-properties)?"/>
        <xsl:variable name="isBold" select="$mapped-style-def/@fo:font-weight='bold'" as="xs:boolean"/>
        <xsl:variable name="isItalic" select="$mapped-style-def/@fo:font-style='italic'" as="xs:boolean"/>
        <xsl:variable name="isSubScript" select="matches($mapped-style-def/@style:text-position, '^sub')" as="xs:boolean"/>
        <xsl:variable name="isSuperScript" select="matches($mapped-style-def/@style:text-position, '^super')" as="xs:boolean"/>
        <xsl:choose>
            <xsl:when test="count($mapped-style-def) = 0">
                <xsl:message>(o2j WARNING): Empty Sequence $mapped-style-def</xsl:message>
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:when test="$isBold eq true() and $isItalic eq true() and $isSubScript">
                <sub><bold><italic><xsl:apply-templates/></italic></bold></sub>
            </xsl:when>
            <xsl:when test="$isBold eq true() and $isItalic eq true() and $isSuperScript">
                <sup><bold><italic><xsl:apply-templates/></italic></bold></sup>
            </xsl:when>
            <xsl:when test="$isBold eq true() and $isItalic eq true()">
                <bold><italic><xsl:apply-templates/></italic></bold>
            </xsl:when>
            <xsl:when test="$isBold eq true() and $isSubScript">
                <sub><bold><xsl:apply-templates/></bold></sub>
            </xsl:when>
            <xsl:when test="$isBold eq true() and $isSuperScript">
                <sup><bold><xsl:apply-templates/></bold></sup>
            </xsl:when>
            <xsl:when test="$isBold eq true()">
                <bold><xsl:apply-templates/></bold>
            </xsl:when>
            <xsl:when test="$isItalic eq true() and $isSubScript">
                <sub><italic><xsl:apply-templates/></italic></sub>
            </xsl:when>
            <xsl:when test="$isItalic eq true() and $isSuperScript">
                <sup><italic><xsl:apply-templates/></italic></sup>
            </xsl:when>
            <xsl:when test="$isItalic eq true()">
                <italic><xsl:apply-templates/></italic>
            </xsl:when>
            <xsl:when test="$isSubScript eq true()">
                <sub><xsl:apply-templates/></sub>
            </xsl:when>
            <xsl:when test="$isSuperScript eq true()">
                <sup><xsl:apply-templates/></sup>
            </xsl:when>
            <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- mark up links -->
    <xsl:template match="text:a[@xlink:href]">
        <uri><xsl:value-of select="@xlink:href"/></uri>
    </xsl:template>

    <xsl:template match="draw:frame">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- Graphics -->
    <xsl:template match="draw:frame[draw:image]">
        <xsl:for-each select="draw:image">
            <cover-image>
                <xsl:attribute name="original-href">
                    <xsl:value-of select="@xlink:href"/>
                </xsl:attribute>
            </cover-image>
        </xsl:for-each>
    </xsl:template>

    <!-- preserve tabs -->
    <xsl:template match="text:tab"><xsl:text>&#x09;</xsl:text></xsl:template>

    <!-- Stylemap - map styles to elements -->
    <sm:styles>
        <sm:style>
            <sm:name>abm-about</sm:name>
            <sm:transformTo>about-para</sm:transformTo>
        </sm:style>
        <sm:style>
            <sm:name>abm-data</sm:name>
            <sm:transformTo>publication-meta-entry</sm:transformTo>
        </sm:style>
        <sm:style>
            <sm:name>abm-summary</sm:name>
            <sm:transformTo>summary-para</sm:transformTo>
        </sm:style>
        <sm:style>
            <sm:name>abm-title-1</sm:name>
            <sm:transformTo>publication-title</sm:transformTo>
        </sm:style>
    </sm:styles>
</xsl:stylesheet>