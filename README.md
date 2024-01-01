This is for personal review of what I did in UIUC ECE411 2023. 

**Cachelien Adapter**

When typical microprocessors load or store a byte of data, the memory controller interfacing with DRAM will typically request an entire “cacheline” of data. These cachelines are typically 32 or 64 bytes data in the address space contiguous with the requested byte, and aligned to 32 or 64 byte boundries. However, pin limitations on packages, as well as the design of DRAM DIMMs make it infeasible to send an entire cacheline concurrently. Instead, DRAMs support burst transmission modes, in which the cacheline is sent over several cycles. You must design an adapter allow the smooth transmission of data between the LLC and DRAM despite this difference in transaction size.

Your cacheline adaptor will interface DRAM with a 4-burst 64-bit naive interface, and a straightforward 256-bit naive interface to last-level cache (LLC). A burst here means that a very long data will be send over the channel/interface over multiple cycles.