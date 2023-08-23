check_product_status() {
    max_attempts=45  # Maximum attempts
    attempt=1

    status=$(command C1 | grep -oE 'AVAILABLE|ERROR|TAINTED|UNDER_CHANGE')

    while [ "$status" != "AVAILABLE" ] && [ "$attempt" -lt "$max_attempts" ]; do
        if [ "$status" = "UNDER_CHANGE" ]; then
            sleep 60
            status=$(command C1 | grep -oE 'AVAILABLE|ERROR|TAINTED|UNDER_CHANGE')
        fi
        attempt=$((attempt + 1))
    done

    if [ "$status" = "AVAILABLE" ]; then
        echo "Success"
    else
        exit 1
    fi
}
