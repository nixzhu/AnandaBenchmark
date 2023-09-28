# AnandaBenchmark

Benchmark for [Ananda](https://github.com/nixzhu/Ananda).

Run `swift run -c release`

```
name                       time         std        iterations
-------------------------------------------------------------
Codable decoding           18709.000 ns ±  10.41 %      71431
Ananda decoding             2542.000 ns ±  21.32 %     541405
Ananda decoding with Macro  2583.000 ns ±  26.22 %     543106
```
