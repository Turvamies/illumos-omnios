# Copyright 2014 Bart Coddens <bart.coddens@gmail.com>
# Copyright 2015 Nexenta Systems, Inc.  All rights reserved.
#
<meta http-equiv="Content-Type" content="text/xhtml;charset=utf-8"></meta>
#
# CSS for the HTML version of the man pages.
#
MANCSS='
html { max-width: 880px; margin-left: 1em; }
body { font-size: smaller; font-family: Helvetica,Arial,sans-serif; }
h1 { margin-bottom: 1ex; font-size: 110%; margin-left: -4ex; }
h2 { margin-bottom: 1ex; font-size: 105%; margin-left: -2ex; }
table { width: 100%; margin-top: 0ex; margin-bottom: 0ex; }
td { vertical-align: top; }
blockquote { margin-left: 5ex; margin-top: 0ex; margin-bottom: 0ex; }
div.section { margin-bottom: 2ex; margin-left: 5ex; }
table.foot { font-size: smaller; margin-top: 1em;
    border-top: 1px dotted #dddddd; }
td.foot-date { width: 50%; }
td.foot-os { width: 50%; text-align: right; }
table.head { font-size: smaller; margin-bottom: 1em;
    border-bottom: 1px dotted #dddddd; }
td.head-ltitle { width: 10%; }
td.head-vol { width: 80%; text-align: center; }
td.head-rtitle { width: 10%; text-align: right; }
.emph { font-style: italic; font-weight: normal; }
.symb { font-style: normal; font-weight: bold; }
.lit { font-style: normal; font-weight: normal; font-family: monospace; }
i.addr { font-weight: normal; }
i.arg { font-weight: normal; }
b.cmd { font-style: normal; }
b.config { font-style: normal; }
b.diag { font-style: normal; }
i.farg { font-weight: normal; }
i.file { font-weight: normal; }
b.flag { font-style: normal; }
b.fname { font-style: normal; }
i.ftype { font-weight: normal; }
b.includes { font-style: normal; }
i.link-sec { font-weight: normal; }
b.macro { font-style: normal; }
b.name { font-style: normal; }
i.ref-book { font-weight: normal; }
i.ref-issue { font-weight: normal; }
i.ref-jrnl { font-weight: normal; }
span.ref-title { text-decoration: underline; }
span.type { font-style: italic; font-weight: normal; }
b.utility { font-style: normal; }
b.var { font-style: normal; }
dd.list-ohang { margin-left: 0ex; }
ul.list-bul { list-style-type: disc; padding-left: 1em; }
ul.list-dash { list-style-type: none; padding-left: 0em; }
li.list-dash:before { content: "\2014  "; }
ul.list-hyph { list-style-type: none; padding-left: 0em; }
li.list-hyph:before { content: "\2013  "; }
ul.list-item { list-style-type: none; padding-left: 0em; }
ol.list-enum { padding-left: 2em; }
'

	ppath=$ppath:/opt/onbld/bin
	if [[ $SCM_MODE == "mercurial" ]]; then
[[ -z $MANDOC ]] && MANDOC=`look_for_prog mandoc`
[[ -z $COL ]] && COL=`look_for_prog col`
if [[ $SCM_MODE == "mercurial" ]]; then
mercurial|git|subversion)
if [[ -n $wflag ]]; then
if [[ $SCM_MODE == "mercurial" ]]; then
	#       - GNU patch doesn't interpret the output of illumos diff
	#	  properly when it comes to adds and deletes.  We need to
	#	  do some "cleansing" transformations:
	#
	# Check if it's man page, and create plain text, html and raw (ascii)
	# output for the new version, as well as diffs against old version.
	#
	if [[ -f "$nfile" && "$nfile" = *.+([0-9])*([a-zA-Z]) && \
	    -x $MANDOC && -x $COL ]]; then
		$MANDOC -Tascii $nfile | $COL -b > $nfile.man.txt
		source_to_html txt < $nfile.man.txt > $nfile.man.txt.html
		print " man-txt\c"
		print "$MANCSS" > $WDIR/raw_files/new/$DIR/man.css
		$MANDOC -Thtml -Ostyle=man.css $nfile > $nfile.man.html
		print " man-html\c"
		$MANDOC -Tascii $nfile > $nfile.man.raw
		print " man-raw\c"
		if [[ -f "$ofile" && -z $mv_but_nodiff ]]; then
			$MANDOC -Tascii $ofile | $COL -b > $ofile.man.txt
			${CDIFFCMD:-diff -bt -C 5} $ofile.man.txt \
			    $nfile.man.txt > $WDIR/$DIR/$F.man.cdiff
			diff_to_html $F $DIR/$F "C" "$COMM" < \
			    $WDIR/$DIR/$F.man.cdiff > \
			    $WDIR/$DIR/$F.man.cdiff.html
			print " man-cdiffs\c"
			${UDIFFCMD:-diff -bt -U 5} $ofile.man.txt \
			    $nfile.man.txt > $WDIR/$DIR/$F.man.udiff
			diff_to_html $F $DIR/$F "U" "$COMM" < \
			    $WDIR/$DIR/$F.man.udiff > \
			    $WDIR/$DIR/$F.man.udiff.html
			print " man-udiffs\c"
			if [[ -x $WDIFF ]]; then
				$WDIFF -c "$COMM" -t "$WNAME Wdiff $DIR/$F" \
				    $ofile.man.txt $nfile.man.txt > \
				    $WDIR/$DIR/$F.man.wdiff.html 2>/dev/null
				if [[ $? -eq 0 ]]; then
					print " man-wdiffs\c"
				else
					print " man-wdiffs[fail]\c"
				fi
			fi
			sdiff_to_html $ofile.man.txt $nfile.man.txt $F.man $DIR \
			    "$COMM" > $WDIR/$DIR/$F.man.sdiff.html
			print " man-sdiffs\c"
			print " man-frames\c"
		fi
		rm -f $ofile.man.txt $nfile.man.txt
		rm -f $WDIR/$DIR/$F.man.cdiff $WDIR/$DIR/$F.man.udiff
	fi

		sdiff_url="$(print $P.sdiff.html | url_encode)"
		frames_url="$(print $P.frames.html | url_encode)"
		print " ------ ------"
		print " ------ ------"
	manpage=
	if [[ -f $F.man.cdiff.html || \
	    -f $WDIR/raw_files/new/$P.man.txt.html ]]; then
		manpage=1
		print "<br/>man:"
	fi

	if [[ -f $F.man.cdiff.html ]]; then
		mancdiff_url="$(print $P.man.cdiff.html | url_encode)"
		manudiff_url="$(print $P.man.udiff.html | url_encode)"
		mansdiff_url="$(print $P.man.sdiff.html | url_encode)"
		manframes_url="$(print $P.man.frames.html | url_encode)"
		print "<a href=\"$mancdiff_url\">Cdiffs</a>"
		print "<a href=\"$manudiff_url\">Udiffs</a>"
		if [[ -f $F.man.wdiff.html && -x $WDIFF ]]; then
			manwdiff_url="$(print $P.man.wdiff.html | url_encode)"
			print "<a href=\"$manwdiff_url\">Wdiffs</a>"
		fi
		print "<a href=\"$mansdiff_url\">Sdiffs</a>"
		print "<a href=\"$manframes_url\">Frames</a>"
	elif [[ -n $manpage ]]; then
		print " ------ ------"
		if [[ -x $WDIFF ]]; then
			print " ------"
		fi
		print " ------ ------"
	fi

	if [[ -f $WDIR/raw_files/new/$P.man.txt.html ]]; then
		mantxt_url="$(print raw_files/new/$P.man.txt.html | url_encode)"
		print "<a href=\"$mantxt_url\">TXT</a>"
		manhtml_url="$(print raw_files/new/$P.man.html | url_encode)"
		print "<a href=\"$manhtml_url\">HTML</a>"
		manraw_url="$(print raw_files/new/$P.man.raw | url_encode)"
		print "<a href=\"$manraw_url\">Raw</a>"
	elif [[ -n $manpage ]]; then
		print " --- ---- ---"
	fi

	# Insert delta comments
	if [[ $SCM_MODE == "mercurial" ||