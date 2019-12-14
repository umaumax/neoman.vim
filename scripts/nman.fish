function nman
	if [ (count $argv) -gt 2 ]
		echo "Too many arguments"
		return
	else if [ (count $argv) -eq 0 ]
		echo "What manual page do you want?"
		return
	end
	set page $argv[1..-1]
	set out (eval "command man -w $page 2>&1")
	set code $status
	if [ (count $out) -gt 1 -a (count $argv) -gt 1 ]
		echo "Too many manpages: " (count $out)
		return
	else if [ $code != 0 ]
		printf '%s\n' $out
		return
	end
	if [ -z $NVIM_LISTEN_ADDRESS ]
		command nvim -c "Nman $page"
	else
		nvr --remote-send "<c-n>" -c "Nman $page"
	end
end
complete --command nman --wraps=man
