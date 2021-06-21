# PE-Processing-Element-implementing-1-D-row-Convolution-
PE (Processing Element implementing 1-D row Convolution):

Using SystemVerilogCSP, implement the system described in this block diagram:
![image](https://user-images.githubusercontent.com/66343787/122694268-b3df2000-d1f1-11eb-9ae3-42179a4c543a.png)

PE (Processing element)
The module interact with the testbench (provided) and performs a 1-D Row Convolution. (Based on slides of “Tutorial of Hardware Acceleration for Deep Neural Networks”, MIT. http://eyeriss.mit.edu/tutorial.html). Additionally, check discussion slides and video for more information.
PE performs multiplication on memories outputs and then adds with previous results.

Submodules:
ifmap memory: It is a dual-port memory, it can perform a write - read operation at the same time. The filter_in channels are exclusively for writing, ifmap_out channels are exclusively for reading.

filter memory: Dual-port memory, can perform a write - read operation at the same time. filter_out channels are exclusively for reading.Multiplier: Multiplies ifmap_out and filter_out values, the result is provided to the adder.

Adder: This is a 3-input adder, that selects 2 of the inputs to perform the add operation at a time: multiplier(.c) + Accumulator(.a) or psum_in(.b) + Accumulator(.a) , depending on addder_sel signal.

Split: Steers the adder output depending on split_sel signal.Accumulator: 2-input accumulator implementing a clear signal. When channel acc_clear = 1, the accumulator sends to the adder a token = 0.

Control: It is responsible for control the operation on memories(providing the address to read) and control signals to Accumulator(clear signal), adder (selecting inputs) and split(steering to psum_outthe result).Control operation starts with a token transfer in channel start, and flag the end of operation sending a token in channel done, getting ready to operate again. (Note: the value of the token is not important, what is important is the transfer. suggested value = 0).
