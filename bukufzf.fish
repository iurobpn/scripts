#!//usr/local/bin/fish

function bf
    buku --suggest -p -f 10 $argv | fzf
end
