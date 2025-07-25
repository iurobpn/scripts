#!/bin/sh

# -----------------------------
# aliases / helpers / variables
# -----------------------------

# The following alias is meant for rc options we'll always set unconditionally
# so the UI will work
tw='task rc.defaultwidth=0 rc.defaultheight=0 rc.verbose=nothing rc._forcecolor=on'

maximum_unsupported_fzf_version=0.18.0
fzf_version="$(fzf --version)"
if printf "${maximum_unsupported_fzf_version}\n%s" "$fzf_version" | sort -V | tail -1 | grep -q ${maximum_unsupported_fzf_version}; then
	echo taskfzf: Your fzf version "($fzf_version)" is not supported >&2
	echo taskfzf: Please install 0.19.0 or higher from https://github.com/junegunn/fzf/releases >&2
	exit 1
fi

# Make all less invocations interpret ANSI colors
# export LESS="-r"
export LESS=""

basename="$(basename "$0")"

if [ "${_TASKFZF_SHOW}" = "keys" ]; then
	printf '%s\t%s\n'   KEY    Action
	printf '%s\t%s\n'   ===    ======
	printf '%s\t\t%s\n' D      "Mark tasks as Done"
	printf '%s\t\t%s\n' X      "Delete tasks"
	printf '%s\t\t%s\n' U      "Undo last action"
	printf '%s\t\t%s\n' E      "Edit selected tasks with \$EDITOR"
	printf '%s\t\t%s\n' T      "Add a new task"
	printf '%s\t\t%s\n' I      "Add a new task, with the filter arguments with which it was launched"
	printf '%s\t\t%s\n' A      "Append to first selected task"
	printf '%s\t\t%s\n' N      "Annotate the first selected task"
	printf '%s\t\t%s\n' M      "Modify the first selected task"
	printf '%s\t\t%s\n' R      "Change report"
	printf '%s\t\t%s\n' C      "Change context"
	printf '%s\t\t%s\n' CTRL-R "Reload the current report"
	printf '%s\t\t%s\n' S      "Start task"
	printf '%s\t\t%s\n' P      "Stop task"
	printf '%s\t\t%s\n' ?      "Show keys"
	exit 0
fi

# set a file path that it's content will mark how to execute the next command
# in the main loop
current_filter=${XDG_RUNTIME_DIR:-${XDG_CACHE_DIR:-${TMP-/tmp}}}/taskfzf-current-filter
if ! touch "$current_filter"; then
	echo "${basename}: Can't create a marker file needed for internal state management." >&2
	echo "${basename}: It's default location according to your environment is $current_filter" >&2
	echo "${basename}: Please update either of the following environment variables so the file will be creatable." >&2
	echo "${basename}: TMP" >&2
	echo "${basename}: XDG_RUNTIME_DIR" >&2
	echo "${basename}: XDG_CACHE_DIR" >&2
	exit 3
fi

# --------------------------------------------------------------------------
# If a _TASKFZF_ environmental variables is set (see explanation near
# the main loop at the end), we'll need to do the following:
# --------------------------------------------------------------------------

# we'd want to quit after the action upon the tasks was made and only if we are
# not changing the list we are viewing
if [ -n "$_TASKFZF_TASK_ACT" ]; then
	# We clear the screen from previous output so it'll be easy to see what
	# taskwarrior printed when doing the actions below.
	clear
	# checks if the arguments given to the task are numbers only
	if [ "$_TASKFZF_TASK_ACT" != add-from-empty ]; then
		if [ "$_TASKFZF_REPORT" = "all" ]; then
			tasks_args=$(grep -o '[0-9a-f]\{8\}' "$@" | tr '\n' ' ')
		else
			tasks_args=$(awk '{printf $1" "} END {printf "\n"}' "$@")
		fi
		case "$tasks_args" in
			^[a-f0-9])
				echo "${basename}: chosen tasks: $tasks_args"
				echo "${basename}: Unless your report is 'all', you should use reports with numbers at their first columns."
				echo "${basename}: Please update your taskrc so all of your reports will print the task's ID/UUID at the left most column."
				echo "${basename}: Or, alternatively, choose a line that has a number in it's beginning."
				echo ---------------------------------------------------------------------------
				echo Press any key to continue
				# shellcheck disable=SC2034
				read -r n
				exit $?
				;;
		esac
	else
		printf "%s\n=======" "${basename}: Since there are no tasks, we straight present you with the task add prompt:"
	fi
	# Other actions (such as edit / append etc) can't be used upon multiple
	# tasks
	case "$_TASKFZF_TASK_ACT" in
		modify|append|annotate)
			if [ "$tasks_args" = "${tasks_args%% *}" ]; then
				tasks_args="${tasks_args%% *}"
				clear
				echo "${basename}: WARNING: Only the first task ($tasks_args) will be used when $_TASKFZF_TASK_ACT -ing it."
				echo ---------------------------------------------------------------------------
				echo Press any key to continue
				# shellcheck disable=SC2034
				read -r n
			fi
			;;
	esac
	# Actually perform the actions upon the tasks
	case "$_TASKFZF_TASK_ACT" in
		undo)
			# Doesn't need arguments
			task undo
			;;
		add)
			# Needs no arguments but does need a prompt
			echo "Add task:"
			echo ---------
			printf "set tags or project? "
			read -r attribute_args
			printf "Task description: "
			read -r description_args
			# We intentionally want taskwarrior to separate attribute like
			# arguments from others to make it interpret correctly attributes
			# v.s task description words:
			#
			# shellcheck disable=2086
			task $attribute_args add "$description_args"
			;;
		add-with-filter|add-from-empty)
			filter="$(cat "$current_filter")"
			echo "Add task with attributes:"
			echo "$filter"
			echo ---------
			printf "set additional attributes? "
			read -r attribute_args
			printf "Task description: "
			read -r description_args
			# Same arguments as above...
			# 
			# shellcheck disable=2086
			task $filter $attribute_args add "$description_args"
			;;
		append|modify|annotate)
			echo "Run command:"
			printf "%s %s%s " task "$tasks_args" "$_TASKFZF_TASK_ACT"
			read -r args
			# Same arguments as above...
			# 
			# shellcheck disable=2086
			task $tasks_args "$_TASKFZF_TASK_ACT" $args
			;;
		*)
			# Same as above, even here, only $tasks_args might include spaces
			# which we want taskwarrior to interpret as separate arguments. 
			#
			# shellcheck disable=2086
			task $tasks_args "$_TASKFZF_TASK_ACT"
			;;
	esac
	# Prints a banner for after action view - it's a dirty and dumb version of
	# piping to less.
	echo ---------------------------------------------------------------------------
	echo End of \`taskfzf "$_TASKFZF_TASK_ACT"\` output. Press any key to continue
	# shellcheck disable=SC2034
	read -r n
	exit $?
fi

if [ -n "$_TASKFZF_LIST_CHANGE" ]; then
	# We'll generate a tiny bit different string to save in our marker file in
	# the case we are changing the report or the context
	case $_TASKFZF_LIST_CHANGE in
		report)
			report_str="$($tw reports | sed '$d' | fzf --ansi --no-multi \
				--bind='enter:execute@echo {1}@+abort' \
			)"
			;;
		context)
			context_str='rc.context='"$($tw context | fzf --ansi --no-multi \
				--bind='enter:execute@echo {1}@+abort' \
			)"
			;;
	esac

	# We save the next command line arguments for the next, outer loop
	echo "$context_str" "$report_str" > "$current_filter"
	exit
fi

if [ -n "$_TASKFZF_RELOAD" ]; then
	filter="$(cat "$current_filter")"
	output=$($tw "$filter")
	# If there's no output at all, fzf be unusable saying something like:
	# [Command failed: env _TASKFZF_RELOAD=true ./taskfzf]
	# Hence, we check it first and print a more gracefull message instead
	if [ -n "$output" ]; then
		echo "$output"
	else
		echo No tasks were found in filter "$filter"
	fi
	exit
fi

# We remove the marker file so we'll be able to know once inside the loop
# whether this is an initial execution of our program or not. We can't use the
# variables _TASKFZF_LIST_CHANGE and _TASKFZF_TASK_ACT themselves since we exit
# if either of these variables is set and so we let go the outer loop continue
# to execute.
if [ -z "${_TASKFZF_LIST_CHANGE+1}" ] && [ -z "${_TASKFZF_TASK_ACT+1}" ] && [ "${_TASKFZF_INTERNAL}" != "reload" ]; then
	rm -f "$current_filter"
fi

# --------------------------
# Here starts the real thing
# --------------------------

# Every binding in fzf's interface, calls this very script with a special
# environment variable _TASKFZF_TASK_ACT set to the appropriate value. This is
# how we essentially accomplish 'helpers' which fzf needs to execute as
# standalone scripts because it's a program and not a pure shell function.

# While Ctrl-c wasn't pressed inside fzf
while [ $? != 130 ]; do

	# If the marker file does exists, it's because the variables
	# _TASKFZF_TASK_ACT / _TASKFZF_LIST_CHANGE or _TASKFZF_INTERNAL were set.
	# That's why we get the arguments for tw from there.
	if [ -w "$current_filter" ]; then
		tw_args="$(cat "$current_filter")"
	else
		# otherwise, we can rest assure this is the initial run of this program and so: 
		tw_args="$*"
		# Save the current filter used as in our marker file for the next execution
		echo "$tw_args" > "$current_filter"
	fi

	# all is a type of report we need to apply some heuristics to, we at least
	# try to detect it as so, see
	# https://gitlab.com/doronbehar/taskwarrior-fzf/-/issues/8#note_339724564
	case "$tw_args" in
		*all*) export _TASKFZF_REPORT=all ;;
	esac
	# If we are supposed to reload the list, we count on the if procedure of
	# current_filter to load the current arguments in $tw_args, and we use it
	# here
	if [ "${_TASKFZF_INTERNAL}" = "reload" ]; then
		$tw "$tw_args"
		exit $?
	fi
	# A few things to notice: 
	# 
	# - See https://github.com/junegunn/fzf/issues/1593#issuecomment-498007983
	# for an explanation of that tty redirection.
	#
	# - We add a 'print-query' action after 'execute' so this fzf process will
	# quit afterwards, leaving space for the next iteration of the loop. We
	# can't use abort because otherwise we'll get $? == 130 and the loop will
	# quit.
	#
	# - We use {+f} instead of {+} because it's easier to parse a file
	# containing the lines chosen instead of one line containing all lines
	# chosen given as a CLI argument
	#
	# We intentionally want taskwarrior to separate attribute like
	# arguments from others to make it interpret correctly attributes
	# v.s task description words:
	#
	# shellcheck disable=2086
	$tw $tw_args | fzf --ansi \
		--multi \
		--bind="zero:execute(env _TASKFZF_TASK_ACT=add-from-empty $0)" \
		--bind="D:execute(env _TASKFZF_TASK_ACT=do $0 {+f} < /dev/tty > /dev/tty 2>&1 )+print-query" \
		--bind="X:execute(env _TASKFZF_TASK_ACT=delete $0 {+f} < /dev/tty > /dev/tty 2>&1 )+print-query" \
		--bind="U:execute(env _TASKFZF_TASK_ACT=undo $0< /dev/tty > /dev/tty 2>&1 )+print-query" \
		--bind="E:execute(env _TASKFZF_TASK_ACT=edit $0 {+f} < /dev/tty > /dev/tty 2>&1 )+print-query" \
		--bind="T:execute(env _TASKFZF_TASK_ACT=add $0 {+f} < /dev/tty > /dev/tty 2>&1 )+print-query" \
		--bind="I:execute(env _TASKFZF_TASK_ACT=add-with-filter $0 {+f} < /dev/tty > /dev/tty 2>&1 )+print-query" \
		--bind="A:execute(env _TASKFZF_TASK_ACT=append $0 {+f} < /dev/tty > /dev/tty 2>&1 )+print-query" \
		--bind="N:execute(env _TASKFZF_TASK_ACT=annotate $0 {+f} < /dev/tty > /dev/tty 2>&1 )+print-query" \
		--bind="M:execute(env _TASKFZF_TASK_ACT=modify $0 {+f} < /dev/tty > /dev/tty 2>&1 )+print-query" \
		--bind="S:execute(env _TASKFZF_TASK_ACT=start $0 {+f} < /dev/tty > /dev/tty 2>&1 )+print-query" \
		--bind="P:execute(env _TASKFZF_TASK_ACT=stop $0 {+f} < /dev/tty > /dev/tty 2>&1 )+print-query" \
		--bind="R:execute(env _TASKFZF_LIST_CHANGE=report $0)+reload(env _TASKFZF_RELOAD=true $0)" \
		--bind="C:execute(env _TASKFZF_LIST_CHANGE=context $0)+reload(env _TASKFZF_RELOAD=true $0)" \
		--bind="ctrl-r:reload(env _TASKFZF_INTERNAL=reload $0)" \
		--bind="?:execute(env _TASKFZF_SHOW=keys $0 | bat)+print-query" \
		--bind="enter:execute(env _TASKFZF_TASK_ACT=information $0 {+f} | bat)"
done
