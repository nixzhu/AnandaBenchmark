# AnandaBenchmark

Benchmark for [Ananda](https://github.com/nixzhu/Ananda).

Run `swift run -c release`:

```
name                       time         std        iterations
-------------------------------------------------------------
Codable decoding           19709.000 ns ±  10.69 %      69880
SwiftyJSON decoding        41042.000 ns ±  10.14 %      33536
Ananda decoding             2584.000 ns ±  24.45 %     527670
Ananda decoding with Macro  2583.000 ns ±  24.34 %     531991
```

On my M1 Pro MacBook Pro, Ananda decoding is 7x faster than Codable decoding and 15x faster than SwiftyJSON decoding.
