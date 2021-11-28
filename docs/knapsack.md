# Application to a multiple knapsack problem

This page describes the multiple knapsack problem considered as an example in the folder [src/examples/knapsack](src/examples/knapsack).

## Problem definition

This problem considers <img src="https://render.githubusercontent.com/render/math?math=m\in\mathbb N"> knapsack of capacity <img src="https://render.githubusercontent.com/render/math?math=K\in\mathbb N"> and <img src="https://render.githubusercontent.com/render/math?math=n"> objects. Each object <img src="https://render.githubusercontent.com/render/math?math=i"> has a weight <img src="https://render.githubusercontent.com/render/math?math=w_i"> and a value <img src="https://render.githubusercontent.com/render/math?math=v_i">. The objective is to assign objects to knapsacks such that the value of the objects in the knapsack is maximal and that the sum of the weights of the objects in each knapsack does not exceed <img src="https://render.githubusercontent.com/render/math?math=K">. This can be modelled by an [ILP](https://en.wikipedia.org/wiki/Integer_programming#Canonical_and_standard_form_for_ILPs) in which binary variable <img src="https://render.githubusercontent.com/render/math?math=x_{ij}"> is equal to <img src="https://render.githubusercontent.com/render/math?math=1"> if and only if object <img src="https://render.githubusercontent.com/render/math?math=i"> is in knapsack <img src="https://render.githubusercontent.com/render/math?math=j">:

<img src="https://render.githubusercontent.com/render/math?math=%5Cbegin%7Bequation%7D%0A%20%20%5Clabel%7Beq%3Apb%7D%0A%20%20(P)%5Cleft%5C%7B%0A%20%20%20%20%5Cbegin%7Barray%7D%7Blll%7D%0A%20%20%20%20%20%20%5Cmax%20%26%20%5Cdisplaystyle%5Csum_%7Bi%3D1%7D%5En%5Cdisplaystyle%5Csum_%7Bj%3D1%7D%5En%20v_%7Bij%7Dx_%7Bij%7D%26%5C%5C%0A%0A%20%20%20%20%20%20%5Cmbox%7Bs.c.%7D%20%26%20%5Cdisplaystyle%5Csum_%7Bi%3D1%7D%5En%20w_i%20x_%7Bi%2Cj%7D%20%5Cleq%20K%20%26%20j%5Cin%5C%7B1%2C%20...%2C%20m%5C%7D%5C%5C%0A%0A%20%20%20%20%20%20%20%20%20%20%20%26%20%5Cdisplaystyle%5Csum_%7Bj%3D1%7D%5Em%20x_%7Bi%2Cj%7D%20%5Cleq%201%20%26%20i%5Cin%5C%7B1%2C%20...%2C%20n%5C%7D%5C%5C%0A%20%20%20%20%20%20%26%20x_%7Bij%7D%5Cin%5C%7B0%2C%201%5C%7D%20%26%20i%5Cin%5C%7B1%2C%20...%2C%20n%5C%7D%2C~j%5Cin%5C%7B1%2C%20...%2C%20m%5C%7D%0A%20%20%20%20%5Cend%7Barray%7D%0A%5Cright.%0A%5Cend%7Bequation%7D">

<a name="heuristics">
## Resolution methods considered
</a>
In this example, we consider two heuristic resolution methods:
* **heuristique <img src="https://render.githubusercontent.com/render/math?math=(H_1)">**: randomly add objects to random knapsacks ;
  
* **heuristique <img src="https://render.githubusercontent.com/render/math?math=(H_2)">**: sort the objects by decreasing ratio <img src="https://render.githubusercontent.com/render/math?math=\frac v w">  and add objects to one of the fullest knapsack.

