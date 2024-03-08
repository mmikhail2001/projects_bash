string='1'
if [[ "1,2" == *"$string"* ]]; then
  echo "It's there!"
fi
