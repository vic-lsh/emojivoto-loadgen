#!/bin/sh

APP_NAMESPACE=emojivoto

# kubectl cp requires leaving out the leading '/'
TRACE_FPATH=logging/tracing.folded

OUT_PATH_LOCAL=/scratch/shli

list_pods() {
    kubectl get pods -n $APP_NAMESPACE
}

get_first_match_pod() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: must supply argument on k8s prefix pattern to match for"
        return 1
    fi

    # to match all (not just the first found), remove the '; exit' at the end
    awk -v pattern="^$1" '$0 ~ pattern {print $1; exit}'
}

# given an example pod name (e.g., web-55b5bdb69b-27pr7), return the part that's
# not a unique id (i.e. web).
get_readable_name() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: must supply pod name"
        return 1
    fi

    input=$1
    part_before_dash=$(echo "$input" | cut -d '-' -f1)
    echo "$part_before_dash"
}

copy_trace_file_from_pod() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: must supply pod to copy from"
        return 1
    fi

    pod=$1
    echo "copying trace file from pod $pod" >&2

    name=$(get_readable_name $pod)
    out_name=$OUT_PATH_LOCAL/tracing.folded.$name

    kubectl cp -n $APP_NAMESPACE $pod:$TRACE_FPATH $out_name >&2
    echo $out_name
}

trace_to_flamegraph() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: must supply folded trace file"
        return 1
    fi

    trace_file=$1

    # trace file follows the form: tracing.folded.<name>; this gets <name>
    name=$(echo "$trace_file" | rev | cut -d '.' -f1 | rev)
    flamegraph_name=$OUT_PATH_LOCAL/tracing-flamegraph-$name.svg

    cat $trace_file | inferno-flamegraph > $flamegraph_name

    echo $flamegraph_name
}

gather_trace() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: must supply pod prefix pattern"
        return 1
    fi

    pattern=$1
    pod=$(list_pods | get_first_match_pod $pattern)

    trace_file=$(copy_trace_file_from_pod $pod)
    echo "trace file stored at '$trace_file'" >&2

    flamegraph=$(trace_to_flamegraph $trace_file)
    echo "flamegraph stored at '$flamegraph'" >&2

    echo $flamegraph
}


gather_trace voting &
VOTE_PID=$!
gather_trace web &
WEB_PID=$!

# FIXME
# this is used to kill the background processes we've started above on Ctrl-C.
# it doesn't seem to work too well -- seems like the background processes started
# new processes themselves?
trap 'pkill -P $VOTE_PID; pkill -P $WEB_PID; exit' INT

wait $VOTE_PID $WEB_PID
