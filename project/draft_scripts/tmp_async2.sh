func() {
    time=$1
    while true; do
        echo "process sleep $time"
        sleep $time
    done
}

func 1 &
func 2
