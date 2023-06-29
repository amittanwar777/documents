if [ $A -eq 0 ] || [ $B -eq 0 ]; then
    order="$B $A"
else
    order="$A $B"
fi

# Displaying the value of 'order' using a for loop
for value in $order; do
    echo "$value"
done
