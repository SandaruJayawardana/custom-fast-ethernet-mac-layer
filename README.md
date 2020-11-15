# Custom Fast Ethernet MAC Layer 
## Introduction
> This is a rtl design to customize the Fast Ethernet MAC layer using MII (Media Independent Interface). Current version supports only the full duplex transmision and collision detection method is not available. The Rx module returns the receive data with suppressing the preamable and SFD (Start Frame Delimeter) and we can pass the transmit data to the Tx module using RAM interface (Dont pass preamable and SFD). Management unit contols the MDIO interface in the Ethernet Phy. That module can be control using avalon MM interface.
> Design was tested using DE2-115 Altera board.

## Test Results
> Test result was obtained using the Signal Tap Logic Analyzer.

