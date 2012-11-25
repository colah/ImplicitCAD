import Criterion.Main
import Graphics.Implicit
import Graphics.Implicit.Primitives
import Data.AffineSpace.Point

obj2d_1 :: SymbolicObj2
obj2d_1 =
	union
		[ circle 10
		, translate (22,0) $ circle 10
		, translate (0,22) $ circle 10
		, translate (-22,0) $ circle 10
		, translate (0,-22) $ circle 10
		]

object1 :: SymbolicObj3
object1 = extrudeRM 0 (Just twist) Nothing Nothing obj2d_1 (Left 40)
	where twist h = 35*cos(h*2*pi/60)

object2 :: SymbolicObj3
object2 = squarePipe (10,10,10) 1 100
	where squarePipe (x,y,z) diameter precision =
			  union
			  $ map (\start-> translate start
							$ rect3R 0 origin (P (diameter,diameter,diameter))
					)
			  $ zip3 (map (\n->(n/precision)*x) [0..precision])
					 (map (\n->(n/precision)*y) [0..precision])
					 (map (\n->(n/precision)*z) [0..precision])

obj2Benchmarks :: String -> SymbolicObj2 -> Benchmark
obj2Benchmarks name obj =
	bgroup name
	[ bench "SVG write" $ writeSVG 1 "benchmark.svg" obj
	, bench "PNG write" $ writePNG2 1 "benchmark.png" obj
	]

obj3Benchmarks :: String -> SymbolicObj3 -> Benchmark
obj3Benchmarks name obj =
	bgroup name
	[ --bench "PNG write" $ writePNG3 1 "benchmark.png" obj
	  bench "STL write" $ writeSTL 1 "benchmark.stl" obj
	]

benchmarks =
	[ obj3Benchmarks "Object 1" object1
	, obj3Benchmarks "Object 2" object2
	]

main = defaultMain benchmarks

