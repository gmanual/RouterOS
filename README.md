# RouterOS

## Telstra EA Outbound Shaper Configuration for Mikrotik RouterOS.

This script will generate a Outbound shaper profile for a Mikrotik RouterOS with a generic QoS profile.

As per Telstra EA Fibre documentation rate limit applied at 98% of max upload spped, with 2ms buffer, bfifo used to match policier. Buffer calcualted by default to hold 5ms of data. (This could be adjusted, but be cautious of buffer bloat.
