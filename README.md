# Traffic-Light-Control-Unit

This project, developed by myself Jordan Leis and Christopher Pederson , is a traffic light control system for a standard intersection (East-West and North-South) built using VHDL in Quartus. The system utilizes a Mealy state machine that cycles through 16 states to coordinate traffic efficiently, giving each light an apropiate colour absed on the state machine. An added feature includes pedestrian push buttons that allow the state machine to skip states, prioritizing pedestrian crossing when needed. This project ensures smooth traffic flow and pedestrian safety in real-time scenarios.

The main state machine code is in State_Machine.vhd and the main logic is in the TOP file.
