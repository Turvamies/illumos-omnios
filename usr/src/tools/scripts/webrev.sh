#

#
# comments_from_teamware {text|html} parent-file child-file
#
# Find the first delta in the child that's not in the parent.  Get the
# newest delta from the parent, get all deltas from the child starting
# with that delta, and then get all info starting with the second oldest
# delta in that list (the first delta unique to the child).
#
# This code adapted from Bill Shannon's "spc" script
#
comments_from_teamware()
{
	fmt=$1
	pfile=$PWS/$2
	cfile=$CWS/$3

	if [[ ! -f $PWS/${2%/*}/SCCS/s.${2##*/} && -n $RWS ]]; then
		pfile=$RWS/$2
	fi

	if [[ -f $pfile ]]; then
		psid=$($SCCS prs -d:I: $pfile 2>/dev/null)
	else
		psid=1.1
	fi

	set -A sids $($SCCS prs -l -r$psid -d:I: $cfile 2>/dev/null)
	N=${#sids[@]}

	nawkprg='
		/^COMMENTS:/	{p=1; continue}
		/^D [0-9]+\.[0-9]+/ {printf "--- %s ---\n", $2; p=0; }
		NF == 0u	{ continue }
		{if (p==0) continue; print $0 }'

	if [[ $N -ge 2 ]]; then
		sid1=${sids[$((N-2))]}	# Gets 2nd to last sid

		if [[ $fmt == "text" ]]; then
			$SCCS prs -l -r$sid1 $cfile  2>/dev/null | \
			    $AWK "$nawkprg"
			return
		fi

		$SCCS prs -l -r$sid1 $cfile  2>/dev/null | \
		    html_quote | its2url | $AWK "$nawkprg"
	fi
}

	else
		if [[ $SCM_MODE == "teamware" ]]; then
			comments_from_teamware $fmt $pp $p
		fi
#
# flist_from_teamware [ <args-to-putback-n> ]
#
# Generate the file list by extracting file names from a putback -n.  Some
# names may come from the "update/create" messages and others from the
# "currently checked out" warning.  Renames are detected here too.  Extract
# values for CODEMGR_WS and CODEMGR_PARENT from the output of the putback
# -n as well, but remove them if they are already defined.
#
function flist_from_teamware
{
	if [[ -n $codemgr_parent && -z $parent_webrev ]]; then
		if [[ ! -d $codemgr_parent/Codemgr_wsdata ]]; then
			print -u2 "parent $codemgr_parent doesn't look like a" \
			    "valid teamware workspace"
			exit 1
		fi
		parent_args="-p $codemgr_parent"
	fi

	print " File list from: 'putback -n $parent_args $*' ... \c"

	putback -n $parent_args $* 2>&1 |
	    $AWK '
		/^update:|^create:/	{print $2}
		/^Parent workspace:/	{printf("CODEMGR_PARENT=%s\n",$3)}
		/^Child workspace:/	{printf("CODEMGR_WS=%s\n",$3)}
		/^The following files are currently checked out/ {p = 1; continue}
		NF == 0			{p=0 ; continue}
		/^rename/		{old=$3}
		$1 == "to:"		{print $2, old}
		/^"/			{continue}
		p == 1			{print $1}' |
	    sort -r -k 1,1 -u | sort > $FLIST

	print " Done."
}

	ppath=$ppath:/opt/teamware/bin:/opt/onbld/bin
function build_old_new_teamware
{
	typeset olddir="$1"
	typeset newdir="$2"

	# If the child's version doesn't exist then
	# get a readonly copy.

	if [[ ! -f $CWS/$DIR/$F && -f $CWS/$DIR/SCCS/s.$F ]]; then
		$SCCS get -s -p $CWS/$DIR/$F > $CWS/$DIR/$F
	fi

	# The following two sections propagate file permissions the
	# same way SCCS does.  If the file is already under version
	# control, always use permissions from the SCCS/s.file.  If
	# the file is not under SCCS control, use permissions from the
	# working copy.  In all cases, the file copied to the webrev
	# is set to read only, and group/other permissions are set to
	# match those of the file owner.  This way, even if the file
	# is currently checked out, the webrev will display the final
	# permissions that would result after check in.

	#
	# Snag new version of file.
	#
	rm -f $newdir/$DIR/$F
	cp $CWS/$DIR/$F $newdir/$DIR/$F
	if [[ -f $CWS/$DIR/SCCS/s.$F ]]; then
		chmod `get_file_mode $CWS/$DIR/SCCS/s.$F` \
		    $newdir/$DIR/$F
	fi
	chmod u-w,go=u $newdir/$DIR/$F

	#
	# Get the parent's version of the file. First see whether the
	# child's version is checked out and get the parent's version
	# with keywords expanded or unexpanded as appropriate.
	#
	if [[ -f $PWS/$PDIR/$PF && ! -f $PWS/$PDIR/SCCS/s.$PF && \
	    ! -f $PWS/$PDIR/SCCS/p.$PF ]]; then
		# Parent is not a real workspace, but just a raw
		# directory tree - use the file that's there as
		# the old file.

		rm -f $olddir/$PDIR/$PF
		cp $PWS/$PDIR/$PF $olddir/$PDIR/$PF
	else
		if [[ -f $PWS/$PDIR/SCCS/s.$PF ]]; then
			real_parent=$PWS
		else
			real_parent=$RWS
		fi

		rm -f $olddir/$PDIR/$PF

		if [[ -f $real_parent/$PDIR/$PF ]]; then
			if [ -f $CWS/$DIR/SCCS/p.$F ]; then
				$SCCS get -s -p -k $real_parent/$PDIR/$PF > \
				    $olddir/$PDIR/$PF
			else
				$SCCS get -s -p    $real_parent/$PDIR/$PF > \
				    $olddir/$PDIR/$PF
			fi
			chmod `get_file_mode $real_parent/$PDIR/SCCS/s.$PF` \
			    $olddir/$PDIR/$PF
		fi
	fi
	if [[ -f $olddir/$PDIR/$PF ]]; then
		chmod u-w,go=u $olddir/$PDIR/$PF
	fi
}

	if [[ $SCM_MODE == "teamware" ]]; then
		build_old_new_teamware "$olddir" "$newdir"
	elif [[ $SCM_MODE == "mercurial" ]]; then
SCM Specific Options:
	TeamWare: webrev [common-options] -l [arguments to 'putback']

	#
	# If -l has been specified, we need to abort further options
	# processing, because subsequent arguments are going to be
	# arguments to 'putback -n'.
	#
	l)	lflag=1
		break;;

if [[ $SCM_MODE == "teamware" ]]; then
	#
	# Teamware priorities:
	# 1. CODEMGR_WS from the environment
	# 2. workspace name
	#
	[[ -z $codemgr_ws && -n $CODEMGR_WS ]] && codemgr_ws=$CODEMGR_WS
	if [[ -n $codemgr_ws && ! -d $codemgr_ws ]]; then
		print -u2 "$codemgr_ws: no such workspace"
		exit 1
	fi
	[[ -z $codemgr_ws ]] && codemgr_ws=$(workspace name)
	codemgr_ws=$(cd $codemgr_ws;print $PWD)
	CODEMGR_WS=$codemgr_ws
	CWS=$codemgr_ws
elif [[ $SCM_MODE == "mercurial" ]]; then
teamware|mercurial|git|subversion)
if [[ -n $lflag ]]; then
	#
	# If the -l flag is given instead of the name of a file list,
	# then generate the file list by extracting file names from a
	# putback -n.
	#
	shift $(($OPTIND - 1))
	if [[ $SCM_MODE == "teamware" ]]; then
		flist_from_teamware "$*"
	else
		print -u2 -- "Error: -l option only applies to TeamWare"
		exit 1
	fi
	flist_done=1
	shift $#
elif [[ -n $wflag ]]; then

if [[ $SCM_MODE == "teamware" ]]; then

	#
	# Teamware priorities:
	#
	#      1) via -p command line option
	#      2) in the user environment
	#      3) in the flist
	#      4) automatically based on the workspace
	#

	#
	# For 1, codemgr_parent will already be set.  Here's 2:
	#
	[[ -z $codemgr_parent && -n $CODEMGR_PARENT ]] && \
	    codemgr_parent=$CODEMGR_PARENT
	if [[ -n $codemgr_parent && ! -d $codemgr_parent ]]; then
		print -u2 "$codemgr_parent: no such directory"
		exit 1
	fi

	#
	# If we're in auto-detect mode and we haven't already gotten the file
	# list, then see if we can get it by probing for wx.
	#
	if [[ -z $flist_done && $flist_mode == "auto" && -n $codemgr_ws ]]; then
		if [[ ! -x $WX ]]; then
			print -u2 "WARNING: wx not found!"
		fi

		#
		# We need to use wx list -w so that we get renamed files, etc.
		# but only if a wx active file exists-- otherwise wx will
		# hang asking us to initialize our wx information.
		#
		if [[ -x $WX && -f $codemgr_ws/wx/active ]]; then
			print -u2 " File list from: 'wx list -w' ... \c"
			$WX list -w > $FLIST
			$WX comments > /tmp/$$.wx_comments
			wxfile=/tmp/$$.wx_comments
			print -u2 "done"
			flist_done=1
		fi
	fi

	#
	# If by hook or by crook we've gotten a file list by now (perhaps
	# from the command line), eval it to extract environment variables from
	# it: This is method 3 for finding the parent.
	#
	if [[ -z $flist_done ]]; then
		flist_from_teamware
	fi
	env_from_flist

	#
	# (4) If we still don't have a value for codemgr_parent, get it
	# from workspace.
	#
	[[ -z $codemgr_parent ]] && codemgr_parent=`workspace parent`
	if [[ ! -d $codemgr_parent ]]; then
		print -u2 "$CODEMGR_PARENT: no such parent workspace"
		exit 1
	fi

	PWS=$codemgr_parent

	[[ -n $parent_webrev ]] && RWS=$(workspace parent $CWS)

elif [[ $SCM_MODE == "mercurial" ]]; then
	#	- Solaris patch(1m) can't cope with file creation
	#	  (and hence renames) as of this writing.
	#       - To make matters worse, gnu patch doesn't interpret the
	#	  output of Solaris diff properly when it comes to
	#	  adds and deletes.  We need to do some "cleansing"
	#         transformations:








		sdiff_url="$(print $P.sdiff.html | url_encode)"

		frames_url="$(print $P.frames.html | url_encode)"
		print " ------ ------ ------"


		print " ------"
	#
	#



	if [[ $SCM_MODE == "teamware" ||
	    $SCM_MODE == "mercurial" ||

