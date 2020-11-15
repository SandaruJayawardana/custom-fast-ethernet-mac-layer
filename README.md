# Custom Fast Ethernet MAC Layer 
## Introduction

> This is a rtl design to customize the Fast Ethernet MAC layer using MII (Media Independent Interface). Current version supports only the full duplex transmission and collision detection method is not available. The Rx module returns the receive data with suppressing the preamable and SFD (Start Frame Delimeter) and we can pass the transmit data to the Tx module using RAM interface (Don't pass preamable and SFD). Management unit controls the MDIO interface in the Ethernet Phy. That module can be control using Avalon MM interface.

> __This module originally designed to implement the 'processing on the fly' data transmission over the network and measure the link propagation delay inbetween connected two ports__

> Design was tested using DE2-115 Altera board.

* __Top design uses PLL (Altera IP) to convert 50MHz clock input to 200MHz clock for the RX_Ethernet and TX_Ethernet modules__
* __MDIO controller uses internal clock divider to reduce the 50MHz clock input (You should change the physical ID of Phy ICs. Further you can change that frequency according to the Ethernet Phy specifitions)__
* __MDIO Controller design to check the link status continuously__


## Test Results
> Test result was obtained using the Signal Tap Logic Analyzer.

<img src="https://github.com/SandaruJayawardana/custom-fast-ethernet-mac-layer/blob/main/ethernet_mac_results.png" alt="alt text" width="800" height="300">
