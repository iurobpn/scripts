sed -e 's/^\([a-zA-Z_\/-]\+\).*/\1/' # get current local branch
sed -e 's/.*(ahead \([0-9]\+\)).*/\1/' # get ahead number of commits
sed -e 's/.*(behind \([0-9]\+\)).*/\1/' # get behind number of commits
sed -e 's#^.*) \([a-zA-Z]\+\)/\([a-zA-Z0-9_\-\/]\+\) *.*#\1 \2#' # get remote/branch info
# sed -E "s/.*'([^]+)\/([^']+)'.*/\1 \2/"
