# VHDL_project

See .pdf files for more details
## General description 󠁧󠁢󠁥
The specification requires implementing a hardware module (described in VHDL) that interfaces with a memory and complies with the indications provided in the following specification. At a high level of abstraction, the system receives indications about a memory location, whose content must be directed to one of the four available output channels. Indications regarding the channel to use and the memory address to access are provided through a serial input of one bit, while the outputs of the system, namely the aforementioned channels, provide all the bits of the memory word in parallel.

Interfaces: The module to be implemented has two primary 1-bit inputs (W and START) and 5 primary outputs. The outputs are as follows: four 8-bit outputs (Z0, Z1, Z2, Z3) and one 1-bit output (DONE). Additionally, the module has a clock signal CLK, which is unique for the entire system, and a reset signal RESET, which is also unique.

## Descrizione generale ita 
La specifica chiede di implementare un modulo HW (descritto in VHDL) che si interfacci con una memoria e che rispetti le indicazioni riportate nella seguente specifica. Ad elevato livello di astrazione, il sistema riceve indicazioni circa una locazione di memoria, il cui contenuto deve essere indirizzato verso un canale di uscita fra i quattro disponibili. Le indicazioni circa il canale da utilizzare e l’indirizzo di memoria a cui accedere vengono forniti mediante un ingresso seriale da un bit, mentre le uscite del sistema, ovvero i succitati canali, forniscono tutti i bit della parola di memoria in parallelo. Interfacce Il modulo da implementare ha due ingressi primari da 1 bit ( W e START ) e 5 uscite primarie . Le uscite sono le seguenti: quattro da 8 bit ( Z0, Z1, Z2, Z3 ) e una da 1 bit ( DONE ). Inoltre, il modulo ha un segnale di clock CLK , unico per tutto il sistema e un segnale di reset RESET anch’esso unico.
