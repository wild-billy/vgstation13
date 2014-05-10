// We use 9-bit directions rather than 4-bit, in order to
// properly handle diagonals and UP.
#define NET_NORTH     1
#define NET_SOUTH     2
#define NET_EAST      4
#define NET_WEST      8
#define NET_NORTHWEST 16
#define NET_NORTHEAST 32
#define NET_SOUTHWEST 64
#define NET_SOUTHEAST 128
#define NET_NODE        256

var/list/all_netdirs = list(
	NET_NORTH,
	NET_SOUTH,
	NET_WEST,
	NET_EAST,
	NET_NORTHWEST,
	NET_NORTHEAST,
	NET_SOUTHWEST,
	NET_SOUTHEAST
)

/proc/netdir2dir(var/powerdir)
	switch(powerdir)
		if(NET_NORTH)     return NORTH
		if(NET_SOUTH)     return SOUTH
		if(NET_WEST)      return WEST
		if(NET_EAST)      return EAST
		if(NET_NORTHWEST) return NORTHWEST
		if(NET_NORTHEAST) return NORTHEAST
		if(NET_SOUTHWEST) return SOUTHWEST
		if(NET_SOUTHEAST) return SOUTHEAST
		if(NET_NODE)        return UP
	return null

/proc/dir2netdir(var/dir)
	switch(dir)
		if(NORTH)     return NET_NORTH
		if(SOUTH)     return NET_SOUTH
		if(WEST)      return NET_WEST
		if(EAST)      return NET_EAST
		if(NORTHWEST) return NET_NORTHWEST
		if(NORTHEAST) return NET_NORTHEAST
		if(SOUTHWEST) return NET_SOUTHWEST
		if(SOUTHEAST) return NET_SOUTHEAST
		if(UP)        return NET_NODE
		if(DOWN)      return NET_NODE
	return null
