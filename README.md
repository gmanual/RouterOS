# RouterOS

## Telstra EA Outbound Shaper Configuration for Mikrotik RouterOS.

This script will generate a Outbound shaper profile for a Mikrotik RouterOS with a generic QoS profile.

As per Telstra EA Fibre documentation rate limit applied at 98% of max upload speed, applying as recommended within 2ms via bucket size/buffer, bfifo used to match policier rate limiting. Queue buffer calcualted to hold 5ms of data. (This could be adjusted/increased, but be cautious of buffer bloat.

I also included a very generic DSCP marking/queuing of packets, designed from scratch because there are some very terrible QoS examples on the RouterOS/Mikrotik Wiki as well as 3rd party websites. It's simple at will order/mark the packets in DSCP order, this may not be ideal and does not match Telstra document for priority classes of services, but we don't use them so I didn't bother writing it to match them. Other notes is because markings are generated from source devices. There is a catch all no-mark just in case fast path is turned on, but you'll need to disable fast path if you want this QoS to actually work.
