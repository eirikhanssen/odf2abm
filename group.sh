#!/bin/sh
saxon flat.xml group.xsl | tee grouped.xml | pygmentize -l xml | less -RS
