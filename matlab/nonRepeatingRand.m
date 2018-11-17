function result = nonRepeatingRand(top, N, seed)
	rng(seed)
    diff = randi(top - 1, 1, N);
    result = rem(cumsum(diff) + randi(1, 1, N) - 1, top) + 1;

end
