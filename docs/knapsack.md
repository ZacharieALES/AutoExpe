# Application to a multiple knapsack problem

This page describes the multiple knapsack problem considered as an example in the folder [src/examples/knapsack](src/examples/knapsack).

## Problem definition

This problem considers <img src="https://render.githubusercontent.com/render/math?math=m\in\mathbb N^+"> knapsack of capacity <img src="https://render.githubusercontent.com/render/math?math=K\in\mathbb N^+"> and <img src="https://render.githubusercontent.com/render/math?math=n"> objects. Each object <img src="https://render.githubusercontent.com/render/math?math=i"> has a weight <img src="https://render.githubusercontent.com/render/math?math=w_i"> and a value <img src="https://render.githubusercontent.com/render/math?math=v_i">. The objective is to assign objects to knapsacks such that the value of the objects in the knapsack is maximal and that the sum of the weights of the objects in each knapsack does not exceed <img src="https://render.githubusercontent.com/render/math?math=K">. This can be modelled by an [ILP](https://en.wikipedia.org/wiki/Integer_programming#Canonical_and_standard_form_for_ILPs) in which binary variable <img src="https://render.githubusercontent.com/render/math?math=x_{ij}"> is equal to <img src="https://render.githubusercontent.com/render/math?math=1"> if and only if object <img src="https://render.githubusercontent.com/render/math?math=i"> is in knapsack <img src="https://render.githubusercontent.com/render/math?math=j">:

<img src="https://render.githubusercontent.com/render/math?math=\renewcommand{\arraystretch}{1.6}
\begin{equation}
  \label{eq:pb}
  (P)\left\{
    \begin{array}{lll}
      \max & \displaystyle\sum_{i=1}^n\displaystyle\sum_{j=1}^n v_{ij}x_{ij}&\\

      \mbox{s.c.} & \displaystyle\sum_{i=1}^n w_i x_{i,j} \leq K & j\in\{1, ..., m\}\\

           & \displaystyle\sum_{j=1}^m x_{i,j} \leq 1 & i\in\{1, ..., n\}\\
      & x_{ij}\in\{0, 1\} & i\in\{1, ..., n\},~j\in\{1, ..., m\}
    \end{array}
\right.
\end{equation}">

<a name="heuristics">
## Resolution methods considered
</a>
In this example, we consider two heuristic resolution methods:
* **heuristique <img src="https://render.githubusercontent.com/render/math?math=(H_1)">**: randomly add objects to random knapsacks ;
  
* **heuristique <img src="https://render.githubusercontent.com/render/math?math=(H_2)">**: sort the objects by decreasing ratio <img src="https://render.githubusercontent.com/render/math?math=\frac v
  w">  and add objects to one of the fullest knapsack.
\end{itemize}
