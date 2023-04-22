print("10 RANDOM NUMBERS")

for i = 1, 10 do
	print(math.random())
end

print("10 GENERATED NUMBERS FROM  NOISE")

for i = 1, 10 do
	print(math.noise(i / 10))
end
