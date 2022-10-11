# ethernet-switch
Design of 4-port gigabit ethernet switch

Ethernet is a family of wired computer networking technologies used in LANs, MANs and WANs. It is one of the most commonly used protocols for private and corporate local area networks (LANs). The objective of our project is to design and simulate a basic 4-port gigabit ethernet switch for the standard ethernet protocol and frame format with FCS-check (CRC-32), appro- priate layer-2 buffering architecture of OSI model comprising of a fair queuing/scheduling algorithm. The project is divided into three parts namely, input module, MAC learning and output module. 

This project focuses on the input module of the switch which is responsible to first buffer the incoming frame and subsequently send it to the right output port based on the decision taken by the MAC learning module.

The architecture of the switch is shown below
![Specification](../arch/Specifications_2.png?raw=true)
