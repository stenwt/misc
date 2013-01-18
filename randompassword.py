#!/usr/bin/python
length = 32 
import random, string 

myrg = random.SystemRandom() 
alpha = string.letters[0:52] + string.digits 
pw = str().join(myrg.choice(alpha) for _ in range(length)) 
print pw
