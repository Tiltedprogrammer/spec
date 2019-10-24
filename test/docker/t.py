from array import array
import sys

with open(sys.argv[1], 'rb') as f:
	l = f.read(100)
	t = sys.argv[2].encode('ascii')
	print(l.find(t))

