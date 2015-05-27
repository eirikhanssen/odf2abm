#!/bin/sh
saxon /home/hanson/Dropbox/abm/info/bunkan/content.xml extract.xsl | tee flat.xml | pygmentize -l xml | less -RS
