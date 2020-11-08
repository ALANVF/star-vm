kind Fruit {
	has apple
	has banana
	has cherry
}

module Main {
	on [main] {
		my f (Fruit) = Fruit.banana
		Core[say: f] ;=> Fruit.banana
	}
}